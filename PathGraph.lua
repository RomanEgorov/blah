local class = require "lib.middleclass"

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

function PathGraph:findPath(source, dest)
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
	local paths = self:_dijkstra()

    self.path = {}
    for pp = 1, #paths[2] do
        local p = paths[2][pp]
        local px, py = self.nodes[p][1], self.nodes[p][2]
        -- print('p', pp, px, py)
        table.insert(self.path, {px, py})
    end
end

function PathGraph:_buildNodes()
    self.nodes = {}
    table.insert(self.nodes, {self.source.x + self.source.w / 2, self.source.y + self.source.h / 2})
    table.insert(self.nodes, {self.dest[1], self.dest[2]})

    --    добавление выпуклых точек
    for b = 1, #self.staticObjects do
        --        левый верх
        table.insert(self.nodes, {self.staticObjects[b].x - self.source.w / 2, self.staticObjects[b].y - self.source.h / 2})

        --        правый верх
        table.insert(self.nodes, {self.staticObjects[b].x + self.staticObjects[b].w + self.source.w / 2, self.staticObjects[b].y - self.source.h / 2})

        --        левый низ
        table.insert(self.nodes, {self.staticObjects[b].x - self.source.w / 2, self.staticObjects[b].y + self.staticObjects[b].h + self.source.h / 2})

        --        правый низ
        table.insert(self.nodes, {self.staticObjects[b].x + self.staticObjects[b].w + self.source.w / 2, self.staticObjects[b].y + self.staticObjects[b].h + self.source.h / 2})
    end

    --    удаление невозможных точек
    for p = #self.nodes, 1, -1  do
        local inBox = false
        for b = 1, #self.staticObjects do
            if (self.nodes[p][1] > self.staticObjects[b].x - self.source.w / 2 and self.nodes[p][1] < self.staticObjects[b].x + self.staticObjects[b].w + self.source.w / 2
                    and self.nodes[p][2] > self.staticObjects[b].y - self.source.h/2 and self.nodes[p][2] < self.staticObjects[b].y + self.staticObjects[b].h + self.source.h/2) then
                inBox = true
            end
        end
        if inBox then
            table.remove(self.nodes, p)
        end
    end
end

function PathGraph:_buildEdges()
    self.edges = {}
    for p1 = 1, #self.nodes do
        for p2 = p1 + 1, #self.nodes do
            local isCross = false
            local abw = self.source.w/2
            local abh = self.source.h/2
            for b = 1, #self.staticObjects do
                --                верх
                if isLineCross(self.nodes[p1][1],self.nodes[p1][2],self.nodes[p2][1],self.nodes[p2][2],self.staticObjects[b].x - abw, self.staticObjects[b].y, self.staticObjects[b].x + self.staticObjects[b].w + abw, self.staticObjects[b].y) then
                    isCross = true
                    break
                end
                --                низ
                if isLineCross(self.nodes[p1][1],self.nodes[p1][2],self.nodes[p2][1],self.nodes[p2][2], self.staticObjects[b].x - abw, self.staticObjects[b].y + self.staticObjects[b].h, self.staticObjects[b].x + self.staticObjects[b].w + abw, self.staticObjects[b].y + self.staticObjects[b].h) then
                    isCross = true
                    break
                end
                --                лево
                if isLineCross(self.nodes[p1][1],self.nodes[p1][2],self.nodes[p2][1],self.nodes[p2][2],self.staticObjects[b].x, self.staticObjects[b].y - abh, self.staticObjects[b].x, self.staticObjects[b].y + self.staticObjects[b].h + abh) then
                    isCross = true
                    break
                end
                --                право
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

function PathGraph:_dijkstra()
    local weigths = {0}
    local nodes_close = {false}
    local paths = {{1}}
    for p = 2, #self.nodes do
        weigths[p] = 1000000 -- Очень большой вес
        nodes_close[p] = false
        paths[p] = {}
    end

    local nodes_open = {1}

    -- print('count', #self.nodes)
    while #nodes_open > 0 do
        table.sort(nodes_open, function(a, b) return weigths[a] < weigths[b]  end)
        local p = nodes_open[1]
        -- print('visit', p, weigths[p] )
        table.remove(nodes_open, 1)
        nodes_close[p] = true
        for l = 1, #self.edges do
            if self.edges[l][1] == p and not nodes_close[self.edges[l][2]] then
                local new_weigth = weigths[p] + self.edges[l][3]
                if new_weigth < weigths[self.edges[l][2]] then
                    table.insert(nodes_open, self.edges[l][2])
                    -- print('add', self.edges[l][2])

                    weigths[self.edges[l][2]] = new_weigth
                    paths[self.edges[l][2]] = table_copy(paths[p])
                    table.insert(paths[self.edges[l][2]], self.edges[l][2])
                end
            end
            if self.edges[l][2] == p and not nodes_close[self.edges[l][1]] then
                local new_weigth = weigths[p] + self.edges[l][3]
                if new_weigth < weigths[self.edges[l][1]] then
                    table.insert(nodes_open, self.edges[l][1])
                    -- print('add', self.edges[l][1])

                    weigths[self.edges[l][1]] = new_weigth
                    paths[self.edges[l][1]] = table_copy(paths[p])
                    table.insert(paths[self.edges[l][1]], self.edges[l][1])
                end
            end
        end
    end

    return paths
end

return PathGraph