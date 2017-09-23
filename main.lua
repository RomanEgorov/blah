
local bump = require "bump"
local MeleeMob = require "meleeMob"
local EnemyBase = require "EnemyBase"

local world = bump.newWorld()

local player = { id = "player", x = 50, y = 50, w = 40, h = 40, speed = 700 }
local blocks = {}
local enemies = {}
local resources = {}
local resourcesNum = 0
local lastResourceSpawn = 0
local resourceSpawnInterval = 0.01
local blockCount = 10

local enemyBase = EnemyBase(world, 715, 515, 50, 50)

local finalPoint = {575, 500}
local path= {}
local goToPoint = false

-- Helpers
local function drawBox(box, r,g,b)
  love.graphics.setColor(r,g,b,70)
  love.graphics.rectangle("fill", box.x, box.y, box.w, box.h)
  love.graphics.setColor(r,g,b)
  love.graphics.rectangle("line", box.x, box.y, box.w, box.h)
end

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

local pnts = {}
local lines = {}
local weigths = {}



local function table_copy(t)
    local r = {}
    for k, v in next, t do
        r[k] = v
    end
    return r
end


local function findPath()

    local left, rigth, top, bottom = 0, 800, 0, 540

    pnts = {}
    table.insert(pnts, {player.x + player.w / 2, player.y + player.h / 2})
    table.insert(pnts, {finalPoint[1], finalPoint[2]})

    --    добавление выпуклых точек
    for b = 1, #blocks do
        --        левый верх
        table.insert(pnts, {blocks[b].x - player.w / 2, blocks[b].y - player.h / 2})
        --        table.insert(pnts, {blocks[b].x - player.w / 2, blocks[b].y})
        --        table.insert(pnts, {blocks[b].x, blocks[b].y - player.h / 2})

        --        правый верх
        table.insert(pnts, {blocks[b].x + blocks[b].w + player.w / 2, blocks[b].y - player.h / 2})
        --        table.insert(pnts, {blocks[b].x + blocks[b].w + player.w / 2, blocks[b].y})
        --        table.insert(pnts, {blocks[b].x + blocks[b].w, blocks[b].y - player.h / 2})

        --        левый низ
        table.insert(pnts, {blocks[b].x - player.w / 2, blocks[b].y + blocks[b].h + player.h / 2})
        --        table.insert(pnts, {blocks[b].x - player.w / 2, blocks[b].y + blocks[b].h})
        --        table.insert(pnts, {blocks[b].x, blocks[b].y + blocks[b].h + player.h / 2})

        --        правый низ
        table.insert(pnts, {blocks[b].x + blocks[b].w + player.w / 2, blocks[b].y + blocks[b].h + player.h / 2})
        --        table.insert(pnts, {blocks[b].x + blocks[b].w + player.w / 2, blocks[b].y + blocks[b].h})
        --        table.insert(pnts, {blocks[b].x + blocks[b].w, blocks[b].y + blocks[b].h + player.h / 2})

    end
    --    удаление невозможных точек
    for p = #pnts, 1, -1  do
        local inBox = false
        for b = 1, #blocks do
            if (pnts[p][1] > blocks[b].x - player.w /2 and pnts[p][1] < blocks[b].x + blocks[b].w + player.w/2
                    and pnts[p][2] > blocks[b].y - player.h/2 and pnts[p][2] < blocks[b].y + blocks[b].h + player.h/2) then
                inBox = true
            end
        end
        if inBox then
            table.remove(pnts, p)
        end
    end

    lines = {}
    for p1 = 1, #pnts do
        for p2 = p1 + 1, #pnts do
            local isCross = false
            local abw = player.w/2
            local abh = player.h/2
            for b = 1, #blocks do
                --                верх
                if isLineCross(pnts[p1][1],pnts[p1][2],pnts[p2][1],pnts[p2][2],blocks[b].x - abw, blocks[b].y, blocks[b].x + blocks[b].w + abw, blocks[b].y) then
                    isCross = true
                    break
                end
                --                низ
                if isLineCross(pnts[p1][1],pnts[p1][2],pnts[p2][1],pnts[p2][2], blocks[b].x - abw, blocks[b].y + blocks[b].h, blocks[b].x + blocks[b].w + abw, blocks[b].y + blocks[b].h) then
                    isCross = true
                    break
                end
                --                лево
                if isLineCross(pnts[p1][1],pnts[p1][2],pnts[p2][1],pnts[p2][2],blocks[b].x, blocks[b].y - abh, blocks[b].x, blocks[b].y + blocks[b].h + abh) then
                    isCross = true
                    break
                end
                --                право
                if isLineCross(pnts[p1][1],pnts[p1][2],pnts[p2][1],pnts[p2][2],blocks[b].x +  blocks[b].w, blocks[b].y - abh, blocks[b].x + blocks[b].w, blocks[b].y + blocks[b].h + abh) then
                    isCross = true
                    break
                end
            end
            if not isCross then
                local dst = (((pnts[p1][1] - pnts[p2][1])^2 + (pnts[p1][2] - pnts[p2][2])^2)^0.5)
                table.insert(lines, {p1, p2, dst })
            end
        end
    end




    weigths = {0 }
    local pnts_close = {false }
    local paths = {{1}}
    for p = 2, #pnts do
        weigths[p] = 1000000 -- Очень большой вес
        pnts_close[p] = false
        paths[p] = {}
    end

    local pnts_open = {1}

    print('count', #pnts)
    while #pnts_open > 0 do
        table.sort(pnts_open, function(a, b) return weigths[a] < weigths[b]  end)
        local p = pnts_open[1]
        print('visit', p, weigths[p] )
        table.remove(pnts_open, 1)
        pnts_close[p] = true
        for l = 1, #lines do
            if lines[l][1] == p and not pnts_close[lines[l][2]] then
                local new_weigth = weigths[p] + lines[l][3]
                if new_weigth < weigths[lines[l][2]] then
                    table.insert(pnts_open, lines[l][2])
                    print('add', lines[l][2])

                    weigths[lines[l][2]] = new_weigth
                    paths[lines[l][2]] = table_copy(paths[p])
                    table.insert(paths[lines[l][2]], lines[l][2])
                end
            end
            if lines[l][2] == p and not pnts_close[lines[l][1]] then
                local new_weigth = weigths[p] + lines[l][3]
                if new_weigth < weigths[lines[l][1]] then
                    table.insert(pnts_open, lines[l][1])
                    print('add', lines[l][1])

                    weigths[lines[l][1]] = new_weigth
                    paths[lines[l][1]] = table_copy(paths[p])
                    table.insert(paths[lines[l][1]], lines[l][1])
                end
            end
        end
    end

    path = {}
    for pp = 1, #paths[2] do
        local p = paths[2][pp]
        local px, py = pnts[p][1], pnts[p][2]
        print('p', pp, px, py)
        table.insert(path, {px, py})
    end
end

local function drawPlayer()
    drawBox(player, 0, 255, 0)
    love.graphics.print("Game", player.x, player.y - 20)


    --    отрисовка точек
    for p = 1, #pnts do
        love.graphics.points(pnts[p][1], pnts[p][2])
        love.graphics.setColor(250,195,125,250)
        love.graphics.print(p, pnts[p][1], pnts[p][2])
        love.graphics.print(math.floor(weigths[p]), pnts[p][1], pnts[p][2]+15)
    end

--    отрисовка линий
    love.graphics.setColor(0,125,125,250)
    for l = 1, #lines do
        love.graphics.line(pnts[lines[l][1]][1], pnts[lines[l][1]][2], pnts[lines[l][2]][1], pnts[lines[l][2]][2])
    end

    --    отрисовка маршрута
    love.graphics.setColor(250,125,125,250)
    if #path>0 then
        love.graphics.line(player.x + player.w / 2, player.y + player.h / 2, path[1][1], path[1][2])
        for i = 2, #path, 1 do
            love.graphics.line(path[i-1][1], path[i-1][2], path[i][1], path[i][2])
        end
    end

    --    отрисовка финальной точки
    love.graphics.points(finalPoint[1], finalPoint[2])
    love.graphics.setColor(250,195,125,250)

end

local function drawEnemies()
    for _, enemy in ipairs(enemies) do
        drawBox(enemy, 0, 0, 255)
        drawBox(enemy.viewBox, 55, 55, 55)
    end
end

-- Functions
local function addBlock(x,y,w,h)
    local block = {x=x,y=y,w=w,h=h}
    blocks[#blocks+1] = block
    world:add(block, x,y,w,h)
end

local function addEnemy(x, y, w, h, speed)
    local mob = MeleeMob.new(x, y, w, h, speed, world)
    enemies[#enemies+1] = mob
end

local function spawnResource()
    for i = 1, resourcesNum do
        if resources[i] == nil then
            local resource = {
                id = "resource",
                resourceId = i,
                x = math.random(100, 600),
                y = math.random(100, 400),
                w = 10,
                h = 10
            }

            resources[i] = resource
            world:add(resource, resource.x, resource.y, resource.w, resource.h)

            break
        end
    end
end

local function drawResources()
    for i = 1, resourcesNum do
        if resources[i] ~= nil then
            drawBox(resources[i], 255, 255, 255)
        end
    end
end


local function updatePlayer(dt)
    local dx, dy = 0, 0

    if love.keyboard.isDown('1') and #path then
        goToPoint   = true
    end

    if love.keyboard.isDown('2') then
        goToPoint   = false
    end

    if love.keyboard.isDown('3') then
        findPath()
    end

    if #path>0 then
        local pointX, pointY = path[1][1], path[1][2]



        if goToPoint and #path then
            dx = (pointX - player.x - player.w / 2 )
            dy = (pointY - player.y - player.h / 2)
            local dxy = (dx^2 + dy^2)^0.5
            if dxy < 10 then
                table.remove(path, 1)
                if not #path then
                    goToPoint = false
                    return
                end
            else
                dx = dx / dxy
                dy = dy / dxy
                if player.speed * dt < dxy then
                    dxy = player.speed * dt
                end
                dx = dx * dxy
                dy = dy * dxy
            end
        end
    end

    if love.keyboard.isDown('right') then
        dx = player.speed * dt
    elseif love.keyboard.isDown('left') then
        dx = -player.speed * dt
    end
    if love.keyboard.isDown('down') then
        dy = player.speed * dt
    elseif love.keyboard.isDown('up') then
        dy = -player.speed * dt
    end

    if dx ~= 0 or dy ~= 0 then
        player.x, player.y, cols, cols_len = world:move(player, player.x + dx, player.y + dy)
    end
end

local function updateEnemy(enemy, dt)
  enemy:update(dt)
end

local function drawBlocks()
  for _,block in ipairs(blocks) do
    drawBox(block, 255,0,0)
  end
end

-- Callbacks
function love.load()
    world:add(player, player.x, player.y, player.w, player.h)
    world:add(enemyBase, enemyBase.x, enemyBase.y, enemyBase.w, enemyBase.h)

    addBlock(0,       0,     800, 32)
    addBlock(0,      32,      32, 600-32*2)
    addBlock(800-32, 32,      32, 600-32*2)
    addBlock(0,      600-32, 800, 32)

    spawnResource()

       for i=1,blockCount do
         addBlock( math.random(100, 600),
                   math.random(100, 400),
                   math.random(10, 100),
                   math.random(10, 100)
         )
       end


--    for i = 1, 6 do
--        local w = 50
--        addBlock( 2*w*i, (i%2) * w*2 , w, 500 )
--
--    end

    addEnemy(650, 100, 20, 20, 60)

    for _, enemy in ipairs(enemies) do
        world:add(enemy, enemy.x, enemy.y, enemy.w, enemy.h)
        -- world:add(enemy.viewBox, enemy.viewBox.x, enemy.viewBox.y, enemy.viewBox.w, enemy.viewBox.h)
    end
end

function love.update(dt)
    updatePlayer(dt)
    enemyBase:update(dt)

    for _, enemy in ipairs(enemies) do
    -- enemy:update(dt)
        updateEnemy(enemy, dt)
    end

    lastResourceSpawn = lastResourceSpawn + dt

    if lastResourceSpawn >= resourceSpawnInterval then
        lastResourceSpawn = lastResourceSpawn - resourceSpawnInterval
        spawnResource()
    end
end

function love.draw()
  drawBlocks()
  drawPlayer()
  drawEnemies()
  drawResources()

  drawBox(enemyBase, 255, 255, 0)
end

function love.keypressed(k)
  if k == "escape" then love.event.quit() end
end

function love.mousepressed(x, y)
    items, len = world:queryRect(x, y, 10, 10)

    if len > 0 then
        for _, item in ipairs(items) do
            if item.id == "resource" then
                resources[item.resourceId] = nil
            end
        end
    end
    finalPoint = {love.mouse.getX(), love.mouse.getY()}
    findPath()
    goToPoint = true
end
