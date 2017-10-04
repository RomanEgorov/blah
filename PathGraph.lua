local class = require "lib.middleclass"
local math = require "math"

function remove_node ( set, theNode )

    for i, node in ipairs ( set ) do
        if node == theNode then 
            set [ i ] = set [ #set ]
            set [ #set ] = nil
            break
        end
    end 
end

local function dist ( x1, y1, x2, y2 )
    return math.sqrt ( math.pow ( x2 - x1, 2 ) + math.pow ( y2 - y1, 2 ) )
end

local function hasItem(arr, item)
    for _, arrItem in ipairs(arr) do
        if arrItem == item then
            return true
        end
    end

    return false
end

--- Проверка двух отрезков на пересечение.
--
-- Отрезки имеют координаты:
-- <li>Первый - начало(x1, y1), конец (x2, y2)</li>
-- <li>Второй - начало(x3, y3), конец (x4, y4)</li>
local function isLineCross(x1, y1, x2, y2, x3, y3, x4, y4)
    local dir1 = {x2 - x1, y2 - y1}
    local dir2 = {x4 - x3, y4 - y3}

--    считаем уравнения прямых проходящих через отрезки
    local a1 = -dir1[2];
    local b1 =  dir1[1];
    local d1 = -(a1*x1 + b1*y1);

    local a2 = -dir2[2];
    local b2 =  dir2[1];
    local d2 = -(a2*x3 + b2*y3);

--    подставляем концы отрезков, для выяснения в каких полуплоскотях они
    local seg1_line2_start = a2*x1 + b2*y1 + d2;
    local seg1_line2_end = a2*x2 + b2*y2 + d2;

    local seg2_line1_start = a1*x3 + b1*y3 + d1;
    local seg2_line1_end = a1*x4 + b1*y4 + d1;

--    если концы одного отрезка имеют один знак, значит он в одной полуплоскости и пересечения нет.
    if (seg1_line2_start * seg1_line2_end >= 0 or seg2_line1_start * seg2_line1_end >= 0) then
        return false
    end
    
    return true
end

--- Создание копии массива
-- <font color="yellow">Осторожно Костыль</font>.
local function table_copy(t)
    local r = {}
    for k, v in next, t do
        r[k] = v
    end
    return r
end

local PathGraph = class("PathGraph")

function PathGraph:initialize(staticObjects) 
	self.dest = {575, 500}
	self.path = {}
	self.staticObjects = staticObjects
	self.nodes = {}
	self.edges = {}
	self.source = {}
	self.dest = {}
end

--- Построение оптимального маршрута из одной точки в другую
--
-- Построенный маршрут записывается в self.path как массив массивов.
-- @param source - Начальная точка маршрута; может быть представлена как объект.
--                 Должна содержать информацию о координатах (x, y) и о размерах объекта (w, h)
-- @param dest   - Конечная точка маршрута; может быть представлена как объект.
--                 Должна содержать информацию о координатах объекта (x, y).
function PathGraph:buildPath(source, dest)
	if source ~= nil then
		self.source = source
	end
	if dest ~= nil then
		self.dest = dest
	end
	-- self.source = source
	-- self.dest = dest
	self:_buildNodes()
	self:_buildEdges()
	-- local paths = self:_dijkstra()

    self.path = self:_aStar()
    -- self.path = {}

    -- print("aStar path: ", self.nodes[self.path[1]][1])
    -- self.path = {}
    -- for pp = 1, #paths[2] do
    --     local p = paths[2][pp]
    --     local px, py = self.nodes[p][1], self.nodes[p][2]

    --     table.insert(self.path, {px, py})
    -- end
end

--- Построение списка всех значимых узлов на карте
function PathGraph:_buildNodes()
    self.nodes = {}
    table.insert(self.nodes, {self.source.x + (self.source.w / 2), self.source.y + (self.source.h / 2)})
    table.insert(self.nodes, {self.dest.x, self.dest.y})

    -- добавление выпуклых точек
    for b = 1, #self.staticObjects do
        --  левый верх
        table.insert(self.nodes, {self.staticObjects[b].x - self.source.w / 2, self.staticObjects[b].y - self.source.h / 2})
        -- правый верх
        table.insert(self.nodes, {self.staticObjects[b].x + self.staticObjects[b].w + self.source.w / 2, self.staticObjects[b].y - self.source.h / 2})
        -- левый низ
        table.insert(self.nodes, {self.staticObjects[b].x - self.source.w / 2, self.staticObjects[b].y + self.staticObjects[b].h + self.source.h / 2})
        -- правый низ
        table.insert(self.nodes, {self.staticObjects[b].x + self.staticObjects[b].w + self.source.w / 2, self.staticObjects[b].y + self.staticObjects[b].h + self.source.h / 2})
    end

    -- удаление точек, которые находятся внутри препятствий, в следствии наложения или близкого расположения препядствий
    for p = #self.nodes, 1, -1  do
        local inBox = false
        for b = 1, #self.staticObjects do
            if (self.nodes[p][1] > self.staticObjects[b].x - self.source.w / 2
                    and self.nodes[p][1] < self.staticObjects[b].x + self.staticObjects[b].w + self.source.w / 2
                    and self.nodes[p][2] > self.staticObjects[b].y - self.source.h/2
                    and self.nodes[p][2] < self.staticObjects[b].y + self.staticObjects[b].h + self.source.h/2
            ) then
                inBox = true
            end
        end
        if inBox then
            table.remove(self.nodes, p)
        end
    end
end

--- Построение списка ребер
--
-- Построение списка всех допустимых ребер между  узлами:
-- <li>Ребра не пересекают препядствия</li>
function PathGraph:_buildEdges()
    self.edges = {}
    for p1 = 1, #self.nodes do
        for p2 = p1 + 1, #self.nodes do
            local isCross = false
            local abw = self.source.w/2
            local abh = self.source.h/2
            for b = 1, #self.staticObjects do
                -- верхяя граница препятствия
                if isLineCross(self.nodes[p1][1],self.nodes[p1][2],self.nodes[p2][1],self.nodes[p2][2],self.staticObjects[b].x - abw, self.staticObjects[b].y, self.staticObjects[b].x + self.staticObjects[b].w + abw, self.staticObjects[b].y) then
                    isCross = true
                    break
                end
                -- нижняя граница препятствия
                if isLineCross(self.nodes[p1][1],self.nodes[p1][2],self.nodes[p2][1],self.nodes[p2][2], self.staticObjects[b].x - abw, self.staticObjects[b].y + self.staticObjects[b].h, self.staticObjects[b].x + self.staticObjects[b].w + abw, self.staticObjects[b].y + self.staticObjects[b].h) then
                    isCross = true
                    break
                end
                -- левая граница препятствия
                if isLineCross(self.nodes[p1][1],self.nodes[p1][2],self.nodes[p2][1],self.nodes[p2][2],self.staticObjects[b].x, self.staticObjects[b].y - abh, self.staticObjects[b].x, self.staticObjects[b].y + self.staticObjects[b].h + abh) then
                    isCross = true
                    break
                end
                -- правая граница препятствия
                if isLineCross(self.nodes[p1][1],self.nodes[p1][2],self.nodes[p2][1],self.nodes[p2][2],self.staticObjects[b].x +  self.staticObjects[b].w, self.staticObjects[b].y - abh, self.staticObjects[b].x + self.staticObjects[b].w, self.staticObjects[b].y + self.staticObjects[b].h + abh) then
                    isCross = true
                    break
                end
            end
            if not isCross then
                local dst = (((self.nodes[p1][1] - self.nodes[p2][1])^2 + (self.nodes[p1][2] - self.nodes[p2][2])^2)^0.5)
                table.insert(self.edges, {p1, p2, dst })
            end
        end
    end
end

--- Алгоритм Дейкстры
--
-- Алгоритм определяет кратчайший путь на взвешанном графе из начального узла (№1) в конечный (№2).
-- Резльтат работы сохраняется в self.path как массив массивов.
function PathGraph:_dijkstra()
    local weigths = {0}
    local nodes_close = {false}
    local paths = {{1}}
    for p = 2, #self.nodes do
        weigths[p] = math.huge -- Очень большой вес
        nodes_close[p] = false
        paths[p] = {}
    end

    local nodes_open = {1}
    
    while #nodes_open > 0 do
        table.sort(nodes_open, function(a, b) return weigths[a] < weigths[b]  end)

        local currentPointIndex = nodes_open[1]

        table.remove(nodes_open, 1)

        nodes_close[currentPointIndex] = true

        for l = 1, #self.edges do
            if self.edges[l][1] == currentPointIndex and not nodes_close[self.edges[l][2]] then
                local new_weigth = weigths[currentPointIndex] + self.edges[l][3]
                if new_weigth < weigths[self.edges[l][2]] then
                    table.insert(nodes_open, self.edges[l][2])
                    weigths[self.edges[l][2]] = new_weigth
                    paths[self.edges[l][2]] = table_copy(paths[currentPointIndex])
                    table.insert(paths[self.edges[l][2]], self.edges[l][2])
                end
            end
            if self.edges[l][2] == currentPointIndex and not nodes_close[self.edges[l][1]] then
                local new_weigth = weigths[currentPointIndex] + self.edges[l][3]
                if new_weigth < weigths[self.edges[l][1]] then
                    table.insert(nodes_open, self.edges[l][1])
                    weigths[self.edges[l][1]] = new_weigth
                    paths[self.edges[l][1]] = table_copy(paths[currentPointIndex])
                    table.insert(paths[self.edges[l][1]], self.edges[l][1])
                end
            end
        end
    end

    return paths
end

function PathGraph:_aStar()
    local gScore = {}
    local fScore = {}
    local openList = {1}            -- add the first node to the openList
    local closedList = {}
    local currentCell = {}
    local neighbours = {}
    local cameFrom = {}

    gScore[1] = 0
    fScore[1] = gScore[1] + dist(self.nodes[1][1], self.nodes[1][2], self.dest.x, self.dest.y)

    for i = 2, #self.nodes do
        gScore[i] = math.huge
        fScore[i] = math.huge
    end

    while #openList > 0 do
        local currentPointIndex = self:getWithLowestFScore(openList, fScore)

        if self.nodes[currentPointIndex][1] == self.dest.x and self.nodes[currentPointIndex][2] == self.dest.y then
            local path = self:unwind_path({}, cameFrom, currentPointIndex)
            table.insert(path, self.nodes[currentPointIndex])

            return path
        end

        remove_node(openList, currentPointIndex)

        closedList[currentPointIndex] = true

        for l = 1, #self.edges do
            if self.edges[l][1] == currentPointIndex and not closedList[self.edges[l][2]] then
                local newGScore = gScore[currentPointIndex] + self.edges[l][3]

                if newGScore < gScore[self.edges[l][2]] then
                    table.insert(openList, self.edges[l][2])
                    gScore[self.edges[l][2]] = newGScore
                    fScore[self.edges[l][2]] = newGScore + dist(self.nodes[self.edges[l][2]][1], self.nodes[self.edges[l][2]][2], self.dest.x, self.dest.y)
                    cameFrom[self.edges[l][2]] = currentPointIndex
                end
            end
            if self.edges[l][2] == currentPointIndex and not closedList[self.edges[l][1]] then
                local newGScore = gScore[currentPointIndex] + self.edges[l][3]

                if newGScore < gScore[self.edges[l][1]] then
                    table.insert(openList, self.edges[l][1])
                    gScore[self.edges[l][1]] = newGScore
                    fScore[self.edges[l][1]] = newGScore + dist(self.nodes[self.edges[l][1]][1], self.nodes[self.edges[l][1]][2], self.dest.x, self.dest.y)
                    cameFrom[self.edges[l][1]] = currentPointIndex
                end
            end
        end
    end
end 

function PathGraph:_calcHCost(cell, dest)
    return dist(cell.x, cell.y, dest.x, dest.y)
end

function PathGraph:_getGCostFor(source, dest)
    -- print(source.x, dest.x)

    return dist(source.x, source.y, dest.x, dest.y)

    -- for i = 1, #self.edges do
    --     -- print("edge: ", self.nodes[self.edges[i][1]][1], self.nodes[self.edges[i][1]][2], self.nodes[self.edges[i][2]][1], self.nodes[self.edges[i][2]][2])

    --     if self.nodes[self.edges[i][1]][1] == source.x and self.nodes[self.edges[i][2]][1] == dest.x then
    --         print("gCost: ", self.edges[i][3])
    --         return self.edges[i][3]
    --     end
    -- end
end

function PathGraph:_getNeighbours(currentCell)
    print("_getNeighbours: ",  currentCell.x, currentCell.y)

    local neighbours = {}

    for i = 1, #self.edges do
        -- print("edge: ", self.nodes[self.edges[i][1]][1], self.nodes[self.edges[i][1]][2])

        if self.nodes[self.edges[i][1]][1] == currentCell.x and self.nodes[self.edges[i][1]][2] == currentCell.y then
            table.insert(neighbours, {x = self.nodes[self.edges[i][2]][1], y = self.nodes[self.edges[i][2]][2]})
        elseif self.nodes[self.edges[i][2]][1] == currentCell.x and self.nodes[self.edges[i][2]][2] == currentCell.y then
            table.insert(neighbours, {x = self.nodes[self.edges[i][1]][1], y = self.nodes[self.edges[i][1]][2]})
        end
    end

    return neighbours
end

function PathGraph:getWithLowestFScore(openList, fScore)
    local score, cellIndex = math.huge, nil

    for _, node in ipairs(openList) do
        if fScore[node] < score then
            score, cellIndex = fScore[node], node
        end
    end

    return cellIndex
end

function PathGraph:unwind_path ( flat_path, map, current_node )
    local index = 0

    if map [ current_node ] then
        index = map[current_node]

        table.insert ( flat_path, 1, self.nodes[index]) 
        return self:unwind_path ( flat_path, map, map [ current_node ] )
    else
        return flat_path
    end
end

return PathGraph