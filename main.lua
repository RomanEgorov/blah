local bump = require "bump"
local GuardMob = require "entity.GuardMob"
local ColonyBase = require "entity.ColonyBase"
local SeekerMob = require "entity.SeekerMob"
local TestMob = require "entity.TestMob"
local PathGraph = require "PathGraph"
local ResourceSpawner = require "ResourceSpawner"

local world = bump.newWorld()

resourceSpawner = ResourceSpawner:new(world)

local player = { id = "player", x = 50, y = 50, w = 40, h = 40, speed = 100 }
local playerPath = {}
local goToPoint = false

local blocks = {}
local blockCount = 10

enemies = {}

local pause = false
local speedModifier = 1

local colonyBase = ColonyBase:new(world, 715, 515)


-- Helpers
local function drawBox(box, r,g,b)
  love.graphics.setColor(r,g,b,70)
  love.graphics.rectangle("fill", box.x, box.y, box.w, box.h)
  love.graphics.setColor(r,g,b)
  love.graphics.rectangle("line", box.x, box.y, box.w, box.h)
end

local function drawPlayer()
    drawBox(player, 0, 255, 0)
    -- love.graphics.print("Game", player.x, player.y - 20)

    --    отрисовка финальной точки
    love.graphics.points(playerPath.dest[1], playerPath.dest[2])
    love.graphics.setColor(250,195,125,250)

end

local function drawEnemies()
    for _, enemy in ipairs(enemies) do

        drawBox(enemy, enemy.drawColor.r, enemy.drawColor.g, enemy.drawColor.b)
        drawBox(enemy.viewBox, 55, 55, 55)
        love.graphics.setColor(125, 125, 125)
        love.graphics.setPointSize(2)
        local x, y = enemy:getCenterCoords()
        love.graphics.points(x, y)
        love.graphics.print(enemy.energy, x, y)
        love.graphics.setPointSize(4)
        love.graphics.setColor(255, 0, 0)
        love.graphics.points(enemy.destinationPoint.x, enemy.destinationPoint.y)

--        love.graphics.setColor(0, 255, 0)
--        for _, point in ipairs(enemy.patrolPoints) do
--            love.graphics.points(point.x, point.y)
--        end
    end
end

-- Functions
local function addBlock(x,y,w,h)
    local block = {x=x,y=y,w=w,h=h}
    blocks[#blocks+1] = block
    world.staticObjects[#world.staticObjects + 1] = block
    world:add(block, x,y,w,h)
end

local function addEnemy(x, y, w, h, speed)
    local mob = GuardMob:new(world, x, y)
    enemies[#enemies+1] = mob
end

local function addSeekerEnemy(x, y)
    local mob = SeekerMob(world, x, y)
    local colonyX, colonyY = colonyBase:getCenterCoords()
    -- mob.colonyBaseCoords = {x = colonyX, y = colonyY}
    mob.colonyBase = colonyBase
    mob.resourceSpawner = resourceSpawner
    enemies[#enemies+1] = mob
end

local function drawResources()
    for i = 1, resourceSpawner.resourcesNum do
        if resourceSpawner.resources[i] ~= nil then
            drawBox(resourceSpawner.resources[i], 255, 255, 255)
        end
    end
end

local function drawColonyBase()
    if colonyBase.alive then
        drawBox(colonyBase, 255, 255, 0)
    else
        drawBox(colonyBase, 55, 55, 55)
    end

    love.graphics.print(colonyBase.energy, colonyBase.x + (colonyBase.w / 3), colonyBase.y + (colonyBase.h / 3))
end

local function updatePlayer(dt)
    local dx, dy = 0, 0

    if love.keyboard.isDown('1') and #playerPath.path then
        goToPoint = true
    end

    if love.keyboard.isDown('2') then
        goToPoint = false
    end

    if love.keyboard.isDown('3') then
        playerPath:findPath()
    end

    if #playerPath.path>0 then
        local pointX, pointY = playerPath.path[1][1], playerPath.path[1][2]

        if goToPoint and #playerPath.path then
            dx = (pointX - player.x - player.w / 2)
            dy = (pointY - player.y - player.h / 2)
            local dxy = (dx^2 + dy^2)^0.5
            if dxy < 10 then
                table.remove(playerPath.path, 1)
                if not #playerPath.path then
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

    -- print("enemies num: ", #enemies)
end

local function drawBlocks()
  for _,block in ipairs(blocks) do
    drawBox(block, 255,0,0)
  end
end

-- Callbacks
function love.load()
    math.randomseed(os.time())

    world:add(player, player.x, player.y, player.w, player.h)
    world:add(colonyBase, colonyBase.x, colonyBase.y, colonyBase.w, colonyBase.h)

    addBlock(0,       0,     800, 32)
    addBlock(0,      32,      32, 600-32*2)
    addBlock(800-32, 32,      32, 600-32*2)
    addBlock(0,      600-32, 800, 32)

    resourceSpawner:spawnResource()

    for i=1,blockCount do
        addBlock( math.random(100, 600),
                   math.random(100, 400),
                   math.random(10, 100),
                   math.random(10, 100)
         )
    end

    -- addEnemy(650, 100, 20, 20, 60)
    enemies[#enemies+1] = TestMob:new(world, 50, 300)

    addSeekerEnemy(100, 100)
    -- addEnemy(100, 100, 20, 20, 60)
    -- local mob = GuardMob:new(world, 100, 100)
    -- mob.patrolPoints = {{x = 100, y = 100}, {x = 650, y = 500}}
    -- enemies[#enemies+1] = mob

    for _, enemy in ipairs(enemies) do
        world:add(enemy, enemy.x, enemy.y, enemy.w, enemy.h)
        -- world:add(enemy.viewBox, enemy.viewBox.x, enemy.viewBox.y, enemy.viewBox.w, enemy.viewBox.h)
    end

    playerPath = PathGraph:new(world.staticObjects)
end

function love.update(dt)
    if pause then
        dt = dt * 0
    else
        dt = dt * speedModifier
    end

    updatePlayer(dt)
    colonyBase:update(dt)

    for _, enemy in ipairs(enemies) do
    -- enemy:update(dt)
        updateEnemy(enemy, dt)
    end

    resourceSpawner:update(dt)
end

function love.draw()
    drawBlocks()
    drawPlayer()
    drawEnemies()
    drawResources()
    drawColonyBase()
end

function love.keypressed(k)
    if k == "escape" then love.event.quit() end

    if k == "q" then
        speedModifier = 1
    end
    if k == "w" then
        speedModifier = 2
    end
    if k == "e" then
        speedModifier = 3
    end
    if k == "r" then
        speedModifier = 10
    end

    if k == "p" then 
        if pause then
            pause = false
        else
            pause = true
        end
    end
end

function love.mousepressed(x, y)
    goToPoint = true

    -- playerPath:findPath(player, {love.mouse.getX(), love.mouse.getY()}) 
    playerPath:buildPath(player, {x=x, y=y})
end
