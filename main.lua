-- Loci Studio — Sandbox de Sprites & Animações 16x16
local UI = require("src.ui")
local ScreenSelector = require("src.screen_selector")
local ScreenArena = require("src.screen_arena")

local current_screen = "selector"

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    ScreenSelector.load()
end

function love.update(dt)
    UI.update()

    if current_screen == "selector" then
        local action = ScreenSelector.update(dt)
        if action == "start_arena" then
            local data = ScreenSelector.get_selected_data()
            ScreenArena.init(data)
            current_screen = "arena"
        end
    elseif current_screen == "arena" then
        local action = ScreenArena.update(dt)
        if action == "back_to_selector" then
            current_screen = "selector"
        end
    end
end

function love.draw()
    if current_screen == "selector" then
        local action = ScreenSelector.draw()
        if action == "start_arena" then
            local data = ScreenSelector.get_selected_data()
            ScreenArena.init(data)
            current_screen = "arena"
        end
    elseif current_screen == "arena" then
        local action = ScreenArena.draw()
        if action == "back_to_selector" then
            current_screen = "selector"
        end
    end
end

function love.keypressed(key)
    if key == "p" and current_screen == "arena" then
        ScreenArena.walk_in_place = not ScreenArena.walk_in_place
    end
end
