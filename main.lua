-- Global configurations & love stuff

screenWidth = 800
screenHeight = 600

font_h1 = love.graphics.newFont(36)
font_h2 = love.graphics.newFont(24)
font_button = love.graphics.newFont(16)
font_normal = love.graphics.newFont(14)

-- Language specific fonts - I am unsure of how I want to go about Chinese and Japanese fonts simultaneously... I think its just one or the other currently
font_foreign_main = love.graphics.newFont("res/Noto_Sans_JP/static/NotoSansJP-Regular.ttf", 28) 
font_foreign_reading = love.graphics.newFont("res/Noto_Sans_JP/static/NotoSansJP-Regular.ttf", 18)

logoImage = nil

SCORE_COLOR_GOOD = {0.6, 0.9, 0.6, 1.0}
SCORE_COLOR_OKAY = {0.98, 0.8, 0.5, 1.0}
SCORE_COLOR_BAD = {1.0, 0.6, 0.6, 1.0}
SCORE_COLOR_DEFAULT = {0.6, 0.7, 1.0, 1.0}

currentScreen = nil

customUserDataPath = nil

require("utils")
require("screens")

function love.load()
    love.window.setMode(1920, 1080, { fullscreen = true, resizable = true })
    screenWidth = love.graphics.getWidth()
    screenHeight = love.graphics.getHeight()
    font_normal = love.graphics.newFont(14)
    
    customUserDataPath = ""
    
    currentScreen = StartScreen:new()
end

function love.update(dt)
    if currentScreen and currentScreen.update then
        currentScreen:update(dt)
    end
end

function love.draw()
    love.graphics.setBackgroundColor(0.94, 0.96, 0.98, 1)

    if currentScreen and currentScreen.draw then
        currentScreen:draw()
    end
end

function love.mousepressed(x, y, button)
    if currentScreen and currentScreen.mousepressed then
        currentScreen:mousepressed(x, y, button)
    end
end

function love.mousereleased(x, y, button)
    if currentScreen and currentScreen.mousereleased then
        currentScreen:mousereleased(x, y, button)
    end
end

function love.keypressed(key)
    if currentScreen and currentScreen.keypressed then
        currentScreen:keypressed(key)
    end
end

function love.wheelmoved(x, y)
    if currentScreen and currentScreen.wheelmoved then
        currentScreen:wheelmoved(x, y)
    end
end

function love.resize(w, h)
    screenWidth = w
    screenHeight = h
    if currentScreen and currentScreen.resize then
        currentScreen:resize(w, h)
    end
end
