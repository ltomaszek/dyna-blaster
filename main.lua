require 'engine.GameEngine'
push = require 'push'

WINDOW_WIDTH = 1920
WINDOW_HEIGHT = 1280

VIRTUAL_WIDTH = 1920 / 1.40
VIRTUAL_HEIGHT = 1280 / 1.40

function love.load()
    love.graphics.setDefaultFilter('nearest', 'nearest')

    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = true,
        vsync = true,
        resizable = true
    })

    engine = newGameEngine()
    engine:load()

    font = love.graphics.newFont(24)
    love.graphics.setFont(font)
end

function love.update(dt)
    engine:update(dt)
end

function love.draw()
    push:apply('start')

    engine:draw()

    push:apply('end')
end