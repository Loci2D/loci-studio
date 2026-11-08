-- Loci Studio — Sandbox de Sprites 32px & Animações
local UI = require("src.ui")
local ScreenSelector = require("src.screen_selector")
local ScreenArena = require("src.screen_arena")

local current_screen = "selector"

function love.load(args)
    love.graphics.setDefaultFilter("nearest", "nearest")
    ScreenSelector.load()

    -- Modo de teste automatizado
    for _, a in ipairs(args or {}) do
        if a == "--test" then
            print("[TEST MODE] Personagens carregados: " .. #ScreenSelector.characters)
            for _, c in ipairs(ScreenSelector.characters) do
                print(string.format("  - %s (tipo: %s, resolucao: %dx%d)", c.name, c.type, c.width, c.height))
            end
            local data = ScreenSelector.get_selected_data()
            ScreenArena.init(data)
            ScreenArena.update(0.016)
            ScreenArena.draw()
            print("[TEST MODE] Teste concluido com sucesso!")
            love.event.quit(0)
            return
        end
    end
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
    elseif current_screen == "selector" then
        if key == "q" then
            ScreenSelector.rotate_preview(1)
        elseif key == "e" then
            ScreenSelector.rotate_preview(-1)
        end
    end
end

