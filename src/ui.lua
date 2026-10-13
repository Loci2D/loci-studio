-- UI Library para Loci Studio (Leve, responsiva e moderna)
local UI = {
    active_slider = nil,
    clicked_id = nil,
    mouse_x = 0,
    mouse_y = 0,
    mouse_down = false,
    mouse_pressed = false
}

function UI.update()
    UI.mouse_x, UI.mouse_y = love.mouse.getPosition()
    local is_down = love.mouse.isDown(1)
    UI.mouse_pressed = is_down and not UI.mouse_down
    UI.mouse_down = is_down
    if not is_down then
        UI.active_slider = nil
    end
end

function UI.is_hover(x, y, w, h)
    return UI.mouse_x >= x and UI.mouse_x <= x + w and UI.mouse_y >= y and UI.mouse_y <= y + h
end

function UI.panel(x, y, w, h, title)
    -- Fundo do painel
    love.graphics.setColor(0.12, 0.14, 0.18, 0.95)
    love.graphics.rectangle("fill", x, y, w, h, 8, 8)
    
    -- Borda do painel
    love.graphics.setColor(0.25, 0.30, 0.38, 1)
    love.graphics.setLineWidth(1.5)
    love.graphics.rectangle("line", x, y, w, h, 8, 8)

    if title then
        -- Barra de título
        love.graphics.setColor(0.16, 0.19, 0.24, 1)
        love.graphics.rectangle("fill", x + 1, y + 1, w - 2, 34, 8, 8)
        
        love.graphics.setColor(0.95, 0.95, 0.98, 1)
        love.graphics.print(title, x + 14, y + 9)

        love.graphics.setColor(0.25, 0.30, 0.38, 1)
        love.graphics.line(x, y + 35, x + w, y + 35)
    end
end

function UI.button(id, text, x, y, w, h, is_active, custom_color)
    local hover = UI.is_hover(x, y, w, h)
    local clicked = false

    if hover and UI.mouse_pressed then
        clicked = true
    end

    -- Cor de fundo
    if is_active then
        love.graphics.setColor(custom_color and custom_color[1] or 0.25, custom_color and custom_color[2] or 0.65, custom_color and custom_color[3] or 0.95, 1)
    elseif hover then
        love.graphics.setColor(0.24, 0.28, 0.36, 1)
    else
        love.graphics.setColor(0.18, 0.21, 0.27, 1)
    end
    love.graphics.rectangle("fill", x, y, w, h, 6, 6)

    -- Borda
    if is_active then
        love.graphics.setColor(1, 1, 1, 0.9)
    elseif hover then
        love.graphics.setColor(0.40, 0.48, 0.60, 1)
    else
        love.graphics.setColor(0.28, 0.33, 0.42, 1)
    end
    love.graphics.setLineWidth(1.5)
    love.graphics.rectangle("line", x, y, w, h, 6, 6)

    -- Texto
    if is_active then
        love.graphics.setColor(1, 1, 1, 1)
    else
        love.graphics.setColor(hover and 1 or 0.85, hover and 1 or 0.88, hover and 1 or 0.92, 1)
    end
    local font = love.graphics.getFont()
    local tw = font:getWidth(text)
    local th = font:getHeight()
    love.graphics.print(text, x + (w - tw) / 2, y + (h - th) / 2)

    return clicked
end

function UI.slider(id, label, value, min_val, max_val, step, x, y, w, h, suffix)
    suffix = suffix or ""
    local bar_y = y + 20
    local bar_h = 10
    local hover = UI.is_hover(x, bar_y - 4, w, bar_h + 8)

    if (hover and UI.mouse_down) or UI.active_slider == id then
        UI.active_slider = id
        local norm = math.max(0, math.min(1, (UI.mouse_x - x) / w))
        local raw = min_val + norm * (max_val - min_val)
        if step and step > 0 then
            raw = math.floor((raw - min_val) / step + 0.5) * step + min_val
        end
        value = math.max(min_val, math.min(max_val, raw))
    end

    -- Label e valor numérico
    love.graphics.setColor(0.85, 0.88, 0.92, 1)
    love.graphics.print(label, x, y)

    local val_str = (step and step < 1) and string.format("%.2f%s", value, suffix) or string.format("%d%s", math.floor(value + 0.5), suffix)
    local font = love.graphics.getFont()
    local val_w = font:getWidth(val_str)
    love.graphics.setColor(0.35, 0.75, 1.0, 1)
    love.graphics.print(val_str, x + w - val_w, y)

    -- Trilho de fundo
    love.graphics.setColor(0.14, 0.16, 0.22, 1)
    love.graphics.rectangle("fill", x, bar_y, w, bar_h, 5, 5)

    -- Preenchimento
    local ratio = (value - min_val) / (max_val - min_val)
    love.graphics.setColor(0.25, 0.65, 0.95, 1)
    love.graphics.rectangle("fill", x, bar_y, w * ratio, bar_h, 5, 5)

    -- Knob (cabeça do slider)
    local knob_x = x + w * ratio
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.circle("fill", knob_x, bar_y + bar_h / 2, 7)
    love.graphics.setColor(0.1, 0.1, 0.1, 0.8)
    love.graphics.circle("line", knob_x, bar_y + bar_h / 2, 7)

    return value
end

return UI
