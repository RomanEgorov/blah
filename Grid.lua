local class = require "lib.middleclass"

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

			if cell.fCost < math.huge then
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
	local destCell = self:getCell(dest.x, dest.y)
	local sourceCell = self:getCell(source.x, source.y)
	-- print("source i: ", sourceCell.indices.i, sourceCell.indices.j)
	-- print("dest i: ", destCell.indices.i)
	sourceCell.fCost = 0
	sourceCell.gCost = 0
	local openList = {sourceCell}
	-- local openList = {source}
	local closedList = {}
	local currentCell = {}
	local running = true
	local neighbours = {}
	local hCost = 0
	local blah = 10
	local grid = self.grid

	self.path = {}

	while running and blah > 0 do
		-- sort the openList by F cost
        table.sort(openList, function(a, b) return a.fCost < b.fCost end)

		-- take the first point from the openList
        currentCell = openList[1]
        table.remove(openList, 1)

        if currentCell == nil then
        	-- print("currentCell is nil")

        	break
        end

		if currentCell.x == destCell.x and currentCell.y == destCell.y then
			print("dest found")
			running = false
			break
		end

        if currentCell == nil then
        	-- print("currentCell == nil")
        	break
        end

		-- move it to the closedList
		-- table.insert(closedList, currentCell)
		-- currentCell.closed = true
		closedList[currentCell] = true	
        -- print("current: ", currentCell.indices.i, currentCell.indices.j)

		neighbours = self:_getNeighbours(currentCell)

		for _, cell in ipairs(neighbours) do
			if cell.type == "empty" and not closedList[cell] then
				-- print(cell.indices.i, cell.indices.j)
				cell.parent = currentCell
				hCost = self:_calcHCost(cell, destCell)
				-- print("fCost = ", currentCell.gCost, " + ", cell.gCost, " + ", hCost)
				cell.fCost = currentCell.gCost + cell.gCost + hCost

				table.insert(openList, cell)

				-- if cell.x == destCell.x and cell.y == destCell.y then
				-- 	print("dest found")
				-- 	running = false

				-- 	break
				-- end
			end
		end

		-- running = false

		-- blah = blah - 1
	end

	blah = 0
	while currentCell ~= nil and currentCell.parent ~= nil do
		print("currentCell ~= nil")
		table.insert(self.path, currentCell)
		currentCell = currentCell.parent
		blah = blah + 1

		if blah > 50 then
			break
		end
	end

	print("blah: ", blah)
end

function Grid:_calcHCost(cell, dest)
	return (math.abs(dest.indices.i - cell.indices.i) + math.abs(dest.indices.j - cell.indices.j)) * 10
end

function Grid:_getNeighbours(cell)
	local neighbours = {}

	if cell == nil then
		print("cell == nil")
		return neighbours
	end

	local i = cell.indices.i
	local j = cell.indices.j

	cell = self:getCell(i - 1, j - 1)
	if cell ~= nil then
		cell.gCost = 14
		table.insert(neighbours, cell)
	end

	cell = self:getCell(i - 0, j - 1)
	if cell ~= nil then
		cell.gCost = 10
		table.insert(neighbours, cell)
	end

	cell = self:getCell(i + 1, j - 1)
	if cell ~= nil then
		cell.gCost = 14
		table.insert(neighbours, cell)
	end

	cell = self:getCell(i - 1, j - 0)
	if cell ~= nil then
		cell.gCost = 10
		table.insert(neighbours, cell)
	end

	cell = self:getCell(i + 1, j - 0)
	if cell ~= nil then
		cell.gCost = 10
		table.insert(neighbours, cell)
	end

	cell = self:getCell(i - 1, j + 1)
	if cell ~= nil then
		cell.gCost = 14
		table.insert(neighbours, cell)
	end

	cell = self:getCell(i - 0, j + 1)
	if cell ~= nil then
		cell.gCost = 10
		table.insert(neighbours, cell)
	end

	cell = self:getCell(i + 1, j + 1)
	if cell ~= nil then
		cell.gCost = 14
		table.insert(neighbours, cell)
	end

	return neighbours
end

function Grid:getCell(i, j)
	if self.grid[i] == nil or self.grid[i][j] == nil then
		return nil
	end

	return self.grid[i + 1][j + 1]
end

function Grid:getCellByCoords(x, y)
	return self.grid[math.floor(x / cellW)][math.floor(y / cellH)]
end

return Grid