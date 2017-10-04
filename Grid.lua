local class = require "lib.middleclass"

local function hasItem(arr, item)
	for _, arrItem in ipairs(arr) do
		if arrItem == item then
			return true
		end
	end

	return false
end

function unwind_path ( flat_path, map, current_node )

	if map [ current_node ] then
		table.insert ( flat_path, 1, map [ current_node ] ) 
		return unwind_path ( flat_path, map, map [ current_node ] )
	else
		return flat_path
	end
end

function remove_node ( set, theNode )

	for i, node in ipairs ( set ) do
		if node == theNode then 
			set [ i ] = set [ #set ]
			set [ #set ] = nil
			break
		end
	end	
end

local Cell = class("Cell")

local cellW = 32
local cellH = 32

function Cell:initialize(i, j)
	self.x = i * cellW
	self.y = j * cellH
	self.w = cellW
	self.h = cellH

	self.indices = {i = i, j = j}

	self.type = "empty"

	self.fCost = math.huge
	self.gCost = math.huge
	self.hCost = math.huge

	self.open = false
end

function Cell:getCenterCoords()
	local x = self.x + (self.w / 2)
	local y = self.y + (self.h / 2)

	return x, y
end

local Grid = class("Grid")

function Grid:initialize(world, worldW, worldH) 
	self.world = world
	self.worldW = worldW
	self.worldH = worldH

	self.grid = {}
	self.gridW = worldW / cellW
	self.gridH = worldH / cellH
	print(self.gridW, self.gridH)

	self.dest = {x = 6, y = 3}

	for i = 1, self.gridW do
		self.grid[i] = {}

		for j = 1, self.gridH do
			-- self.grid[i][j] = Cell:new((i - 1) * cellW, (j - 1) * cellH)
			self.grid[i][j] = Cell:new(i - 1, j - 1)
			-- self.grid[i][j].indices = {i = i, j = j}
		end
	end

	for i = 3, 5 do
		self.grid[5][i].type = "wall"
	end	

	self.path = {}
end

function Grid:draw()
	local r, g, b = 125, 125, 125
	local centerX, centerY = 0, 0

	for _, row in ipairs(self.grid) do
		for _, cell in ipairs(row) do
			if cell.type == "wall" then
				love.graphics.setColor(0, 0, 200,70)
				love.graphics.rectangle("fill", cell.x, cell.y, cellW, cellH)
			end

			love.graphics.setColor(r,g,b)
			love.graphics.rectangle("line", cell.x, cell.y, cellW, cellH)

			centerX, centerY = cell:getCenterCoords()

			love.graphics.setColor(255, 0, 0)
			love.graphics.setPointSize(2)
			love.graphics.points(centerX, centerY)

			if cell.fCost ~= math.huge then
				love.graphics.print(cell.fCost, cell.x, cell.y)
			end
		end
	end

	for _, cell in ipairs(self.path) do
		love.graphics.setColor(200, 0, 200,70)
		love.graphics.rectangle("fill", cell.x, cell.y, cellW, cellH)
	end		

	love.graphics.setColor(255, 0, 0)
	love.graphics.rectangle("line", self.dest.x * cellW, self.dest.y * cellH, cellW, cellH)
end

function Grid:findPath(source, dest)
	self:initGrid()

	local destCell = self:getCell(dest.x, dest.y)
	local sourceCell = self:getCell(source.x, source.y)
	-- print("source i: ", sourceCell.indices.i, sourceCell.indices.j)
	-- print("dest i: ", destCell.indices.i)
	local gScore = {}
	local fScore = {}
	local openList = {sourceCell}
	local closedList = {}
	local currentCell = {}
	local neighbours = {}
	local cameFrom = {}

	gScore[sourceCell] = 0
	fScore[sourceCell] = gScore[sourceCell] + self:_calcHCost(sourceCell, destCell)

	while #openList > 0 do
		-- sort the openList by F cost
        -- table.sort(openList, function(a, b) return a.fCost < b.fCost end)
        currentCell = self:getWithLowestFScore(openList, fScore)

		-- take the first point from the openList
        -- table.remove(openList, currentCell)
        remove_node(openList, currentCell)
        table.insert(closedList, currentCell)

		if currentCell.x == destCell.x and currentCell.y == destCell.y then
			local path = unwind_path({}, cameFrom, destCell)
			table.insert(path, destCell)
			self.path = path

			return path
		end

		neighbours = self:_getNeighbours(currentCell)

		for _, cell in ipairs(neighbours) do
			if cell.type == "empty" and not hasItem(closedList, cell) then
				local tentativeGScore = gScore[currentCell] + self:_getGCostFor(currentCell, cell)

				if not hasItem(openList, cell) or tentativeGScore < gScore[cell] then
					cameFrom[cell] = currentCell
					gScore[cell] = tentativeGScore
					fScore[cell] = gScore[cell] + self:_calcHCost(cell, destCell)

					if not hasItem(openList, cell) then
						table.insert(openList, cell)
					end
				end
			end
		end
	end

	return nil
end

-- function Grid:findPath(source, dest)

-- end

function Grid:_calcHCost(cell, dest)
	local hCost = (math.abs(dest.indices.i - cell.indices.i) + math.abs(dest.indices.j - cell.indices.j)) * 10
	-- print("_calcHCost: ", hCost)

	return hCost
end

function Grid:_getNeighbours(cell)
	local neighbours = {}
	local dg = 0

	if cell == nil then
		print("cell == nil")
		return neighbours
	end

	local i = cell.indices.i
	local j = cell.indices.j

	for q = -1, 1 do
		for w = -1, 1 do
			if q ~= w then
				cell = self:getCell(i - q, j - w)
				if cell ~= nil then
					table.insert(neighbours, cell)
				end
			end
		end
	end

	return neighbours
end

function Grid:getCell(i, j)
	if self.grid[i + 1] == nil or self.grid[i + 1][j + 1] == nil then
		return nil
	end

	return self.grid[i + 1][j + 1]
end

function Grid:getCellByCoords(x, y)
	return self.grid[math.floor(x / cellW)][math.floor(y / cellH)]
end

function Grid:_getGCostFor(source, dest)
	if source.indices.i == dest.indices.i or source.indices.j == dest.indices.j then
		return 10
	else
		return 14
	end
end

function Grid:initGrid()
	for _, row in ipairs(self.grid) do
		for _, cell in ipairs(row) do
			cell.gCost = math.huge
			cell.hCost = math.huge
			cell.fCost = math.huge
		end
	end
end

function Grid:getWithLowestFScore(openList, fScore)
	local score, cell = math.huge, nil

	for _, node in ipairs(openList) do
		if fScore[node] < score then
			score, cell = fScore[node], node
		end
	end

	return cell
end

return Grid