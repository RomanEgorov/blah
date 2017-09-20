local bump = require "bump"
local MeleeMob = require "meleeMob"

local world = bump.newWorld()

local player = { id = "player", x = 50, y = 50, w = 20, h = 20, speed = 80 }
local blocks = {}
local enemies = {}

-- Helpers
local function drawBox(box, r,g,b)
  love.graphics.setColor(r,g,b,70)
  love.graphics.rectangle("fill", box.x, box.y, box.w, box.h)
  love.graphics.setColor(r,g,b)
  love.graphics.rectangle("line", box.x, box.y, box.w, box.h)
end

local function drawPlayer()
  drawBox(player, 0, 255, 0)
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

local function updatePlayer(dt)
  local dx, dy = 0, 0

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

  addBlock(0,       0,     800, 32)
  addBlock(0,      32,      32, 600-32*2)
  addBlock(800-32, 32,      32, 600-32*2)
  addBlock(0,      600-32, 800, 32)

  -- for i=1,30 do
  --   addBlock( math.random(100, 600),
  --             math.random(100, 400),
  --             math.random(10, 100),
  --             math.random(10, 100)
  --   )
  -- end

  addEnemy(650, 100, 20, 20, 60)

  for _, enemy in ipairs(enemies) do
    world:add(enemy, enemy.x, enemy.y, enemy.w, enemy.h)
    -- world:add(enemy.viewBox, enemy.viewBox.x, enemy.viewBox.y, enemy.viewBox.w, enemy.viewBox.h)
  end
end

function love.update(dt)
  updatePlayer(dt)

  for _, enemy in ipairs(enemies) do
    -- enemy:update(dt)
    updateEnemy(enemy, dt)
  end
end

function love.draw()
  drawBlocks()
  drawPlayer()
  drawEnemies()
end

function love.keypressed(k)
  if k == "escape" then love.event.quit() end
end