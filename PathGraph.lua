local class = require "lib.middleclass"
local math = require "math"

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
	local paths = self:_dijkstra_modified()

    self.path = {}
    for pp = 1, #paths[2] do
        local p = paths[2][pp]
        local px, py = self.nodes[p][1], self.nodes[p][2]

        table.insert(self.path, {px, py})
    end
end

--- Построение списка всех значимых узлов на карте
function PathGraph:_buildNodes()
    self.nodes = {}
    table.insert(self.nodes, {self.source.x + self.source.w / 2, self.source.y + self.source.h / 2})
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
        local p = nodes_open[1]
        table.remove(nodes_open, 1)
        nodes_close[p] = true
        for l = 1, #self.edges do
            local p2 = -1
            if self.edges[l][1] == p then
                p2 =  self.edges[l][2];
            end
            if self.edges[l][2] == p then
                p2 =  self.edges[l][1];
            end
            if p2 ~= -1 and not nodes_close[p2] then
                local new_weigth = weigths[p] + self.edges[l][3]
                if new_weigth < weigths[p2] then
                    table.insert(nodes_open, p2)
                    weigths[p2] = new_weigth
                    paths[p2] = table_copy(paths[p])
                    table.insert(paths[p2], p2)
                end
            end
        end
    end

    return paths
end

function PathGraph:_dijkstra_modified()
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
        table.sort(nodes_open, function(a, b)
            local dist_a = ((self.nodes[a][1] - self.nodes[2][1])^2 + (self.nodes[a][2] - self.nodes[2][2])^2)
            local dist_b = ((self.nodes[b][1] - self.nodes[2][1])^2 + (self.nodes[b][2] - self.nodes[2][2])^2)
            return dist_a < dist_b
        end)
        local p = nodes_open[1]
        table.remove(nodes_open, 1)
        nodes_close[p] = true
        for l = 1, #self.edges do
            local p2 = -1
            if self.edges[l][1] == p then
                p2 =  self.edges[l][2];
            end
            if self.edges[l][2] == p then
                p2 =  self.edges[l][1];
            end
            if p2 ~= -1 and not nodes_close[p2] then
                local new_weigth = weigths[p] + self.edges[l][3]
                if new_weigth < weigths[p2] then
                    table.insert(nodes_open, p2)
                    weigths[p2] = new_weigth
                    paths[p2] = table_copy(paths[p])
                    table.insert(paths[p2], p2)
                end
            end
        end
    end

    return paths
end

return PathGraph