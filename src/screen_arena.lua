local UI = require("src.ui")
local Anim = require("src.anim")

local Arena = {
    selected_char = nil,
    slots = {},
    
    -- Estado do Jogador
    x = 420,
    y = 360,
    speed = 130, -- Velocidade de movimento configurável
    facing = 1,
    dir_x = 1,
    dir_y = 0,
    walk_in_place = false,
    anim_state = Anim.new_state(),

    -- Parâmetros de Caminhada
    walk_config = {
        step_frequency = 13,
        max_tilt_deg = 6,
        bob_pixels = 1.5,
        squash_amount = 0.05,
        stop_smoothness = 12
    },

    -- Visual & Câmera
    zoom = 4,
    show_shadow = true,
    bg_style = 1,
    screen_shake = 0,

    -- Efeitos ativos
    active_projectiles = {},
    active_particles = {},
    active_areas = {},
    
    -- Estado do Ataque Melee
    is_attacking = false,
    attack_timer = 0,
    attack_duration = 0.22,
    attack_lunge_x = 0,
    attack_lunge_y = 0,
    current_melee_slot = nil,

    -- Estado do Dash
    is_dashing = false,
    dash_timer = 0,
    dash_duration = 0.20,
    dash_start_x = 0,
    dash_start_y = 0,
    dash_target_x = 0,
    dash_target_y = 0,

    -- Estado de Feedback / Exportação
    export_popup_timer = 0,
    export_code = ""
}

local function get_short_type(slot)
    if not slot then return "Skill" end
    if slot.type == "melee" then return "Melee" end
    if slot.type == "projectile" then return "Projétil" end
    if slot.type == "dash" then return "Dash" end
    if slot.type == "area" then return "Área" end
    return "Skill"
end

function Arena.init(data)
    Arena.selected_char = data.character
    Arena.slots = data.slots or {}
    Arena.x = 420
    Arena.y = 360
    Arena.speed = 130
    Arena.active_projectiles = {}
    Arena.active_particles = {}
    Arena.active_areas = {}
    Arena.is_attacking = false
    Arena.is_dashing = false
    Arena.export_popup_timer = 0
end

function Arena.trigger_skill(slot_id)
    local slot = Arena.slots[slot_id]
    if not slot then return end

    if slot.type == "melee" then
        if Arena.is_attacking then return end
        Arena.is_attacking = true
        Arena.current_melee_slot = slot
        Arena.attack_timer = 0
        Arena.screen_shake = 3.5

        local angle = math.atan2(Arena.dir_y, Arena.dir_x)
        for _ = 1, 10 do
            local p_angle = angle + (math.random() - 0.5) * 1.2
            local p_spd = math.random(100, 260)
            table.insert(Arena.active_particles, {
                x = Arena.x + Arena.dir_x * 16 * Arena.zoom,
                y = Arena.y - 8 * Arena.zoom + Arena.dir_y * 16 * Arena.zoom,
                vx = math.cos(p_angle) * p_spd,
                vy = math.sin(p_angle) * p_spd,
                life = 0.22,
                max_life = 0.22,
                color = {1, 0.9, 0.3}
            })
        end

    elseif slot.type == "projectile" then
        table.insert(Arena.active_projectiles, {
            x = Arena.x + Arena.dir_x * 12 * Arena.zoom,
            y = Arena.y - 8 * Arena.zoom + Arena.dir_y * 12 * Arena.zoom,
            dir_x = Arena.dir_x,
            dir_y = Arena.dir_y,
            dist_traveled = 0,
            max_dist = slot.range_pixels or 240,
            speed = slot.speed or 340,
            rotation = 0,
            sprite = slot.sprite
        })

    elseif slot.type == "dash" then
        if Arena.is_dashing then return end
        Arena.is_dashing = true
        Arena.dash_timer = 0
        Arena.dash_start_x = Arena.x
        Arena.dash_start_y = Arena.y
        local dist = slot.dash_pixels or 80
        Arena.dash_target_x = Arena.x + Arena.dir_x * dist
        Arena.dash_target_y = Arena.y + Arena.dir_y * dist

    elseif slot.type == "area" then
        local radius = slot.radius_pixels or 45
        table.insert(Arena.active_areas, {
            x = Arena.x,
            y = Arena.y,
            max_radius = radius,
            life = 0.50,
            max_life = 0.50,
            sprite = slot.sprite
        })

        for _ = 1, 16 do
            local p_angle = math.random() * math.pi * 2
            local p_dist = math.random(5, radius) * (Arena.zoom / 4)
            table.insert(Arena.active_particles, {
                x = Arena.x + math.cos(p_angle) * p_dist,
                y = Arena.y + math.sin(p_angle) * (p_dist * 0.4),
                vx = 0,
                vy = -math.random(60, 140),
                life = 0.45,
                max_life = 0.45,
                color = {0.3, 0.7, 1}
            })
        end
    end
end

function Arena.export_config()
    local char_name = Arena.selected_char and Arena.selected_char.filename or "character.png"

    local slot_code = ""
    for i = 1, 4 do
        local slot = Arena.slots[i]
        if slot then
            local dist_str = ""
            if slot.type == "melee" then
                dist_str = string.format("lunge_pixels = %d", math.floor(slot.lunge_pixels + 0.5))
            elseif slot.type == "projectile" then
                dist_str = string.format("range_pixels = %d", math.floor(slot.range_pixels + 0.5))
            elseif slot.type == "dash" then
                dist_str = string.format("dash_distance_pixels = %d", math.floor(slot.dash_pixels + 0.5))
            elseif slot.type == "area" then
                dist_str = string.format("radius_pixels = %d", math.floor(slot.radius_pixels + 0.5))
            end

            slot_code = slot_code .. string.format("    slot%d = { type = \"%s\", sprite = \"%s\", %s },\n",
                i, slot.type, slot.sprite_name or "(nenhum)", dist_str)
        end
    end

    local code = string.format([[
-- ============================================================================
-- EXPORTAÇÃO DE CONFIGURAÇÕES - LOCI STUDIO
-- Personagem: %s
-- ============================================================================
local WALK_CONFIG = {
    move_speed      = %d,      -- Velocidade de movimento (pixels/s)
    step_frequency  = %d,      -- Ritmo dos passos
    max_tilt_deg    = %d,       -- Inclinação lateral (graus)
    bob_pixels      = %.2f,    -- Elevação vertical em pixels 16x16
    squash_amount   = %.2f,    -- Compressão no solo (squash & stretch)
    stop_smoothness = %d       -- Retorno suave à postura neutra
}

local SKILLS_CONFIG = {
%s}
]],
        char_name,
        math.floor(Arena.speed + 0.5),
        math.floor(Arena.walk_config.step_frequency + 0.5),
        math.floor(Arena.walk_config.max_tilt_deg + 0.5),
        Arena.walk_config.bob_pixels,
        Arena.walk_config.squash_amount,
        math.floor(Arena.walk_config.stop_smoothness + 0.5),
        slot_code
    )

    Arena.export_code = code
    Arena.export_popup_timer = 4.0

    pcall(function()
        love.filesystem.write("config_export.lua", code)
    end)
    print("[Loci Studio] Configurações exportadas para config_export.lua!")
end

function Arena.update(dt)
    if Arena.screen_shake > 0 then
        Arena.screen_shake = Arena.screen_shake - dt * 20
        if Arena.screen_shake < 0 then Arena.screen_shake = 0 end
    end

    if Arena.export_popup_timer > 0 then
        Arena.export_popup_timer = Arena.export_popup_timer - dt
    end

    -- Processa Movimentação
    local dx, dy = 0, 0
    if not Arena.is_dashing then
        if love.keyboard.isDown("a", "left") then dx = dx - 1 Arena.facing = -1 end
        if love.keyboard.isDown("d", "right") then dx = dx + 1 Arena.facing = 1 end
        if love.keyboard.isDown("w", "up") then dy = dy - 1 end
        if love.keyboard.isDown("s", "down") then dy = dy + 1 end
    end

    local is_input_moving = (dx ~= 0 or dy ~= 0)
    if is_input_moving then
        local len = math.sqrt(dx * dx + dy * dy)
        dx = dx / len
        dy = dy / len
        Arena.dir_x = dx
        Arena.dir_y = dy
    end

    local is_moving = is_input_moving or Arena.walk_in_place

    if is_input_moving then
        Arena.x = Arena.x + dx * Arena.speed * dt
        Arena.y = Arena.y + dy * Arena.speed * dt

        Arena.x = math.max(60, math.min(love.graphics.getWidth() - 360, Arena.x))
        Arena.y = math.max(60, math.min(love.graphics.getHeight() - 60, Arena.y))
    end

    Anim.update_walk(Arena.anim_state, is_moving, Arena.facing, dt, Arena.walk_config)

    -- Atualiza Ataque Melee
    if Arena.is_attacking then
        Arena.attack_timer = Arena.attack_timer + dt
        local prog = Arena.attack_timer / Arena.attack_duration
        local slot = Arena.current_melee_slot
        local max_lunge = (slot and slot.lunge_pixels or 8) * (Arena.zoom / 4)

        if prog < 0.25 then
            local r = prog / 0.25
            Arena.attack_lunge_x = -Arena.dir_x * 4 * r
            Arena.attack_lunge_y = -Arena.dir_y * 4 * r
        elseif prog < 0.65 then
            local r = (prog - 0.25) / 0.40
            Arena.attack_lunge_x = Arena.dir_x * max_lunge * math.sin(r * math.pi * 0.5)
            Arena.attack_lunge_y = Arena.dir_y * max_lunge * math.sin(r * math.pi * 0.5)
        elseif prog < 1.0 then
            local r = (prog - 0.65) / 0.35
            Arena.attack_lunge_x = Arena.attack_lunge_x * (1 - r)
            Arena.attack_lunge_y = Arena.attack_lunge_y * (1 - r)
        else
            Arena.is_attacking = false
            Arena.attack_lunge_x = 0
            Arena.attack_lunge_y = 0
        end
    end

    -- Atualiza Dash
    if Arena.is_dashing then
        Arena.dash_timer = Arena.dash_timer + dt
        local prog = math.min(1, Arena.dash_timer / Arena.dash_duration)
        Arena.x = Arena.dash_start_x + (Arena.dash_target_x - Arena.dash_start_x) * prog
        Arena.y = Arena.dash_start_y + (Arena.dash_target_y - Arena.dash_start_y) * prog
        if prog >= 1 then
            Arena.is_dashing = false
        end
    end

    -- Atualiza Projéteis
    for i = #Arena.active_projectiles, 1, -1 do
        local p = Arena.active_projectiles[i]
        local step = p.speed * dt
        p.x = p.x + p.dir_x * step
        p.y = p.y + p.dir_y * step
        p.dist_traveled = p.dist_traveled + step
        p.rotation = p.rotation + 18 * dt

        if p.dist_traveled >= p.max_dist then
            for _ = 1, 8 do
                local ang = math.random() * math.pi * 2
                local spd = math.random(40, 160)
                table.insert(Arena.active_particles, {
                    x = p.x,
                    y = p.y,
                    vx = math.cos(ang) * spd,
                    vy = math.sin(ang) * spd,
                    life = 0.18,
                    max_life = 0.18,
                    color = {0.4, 0.8, 1}
                })
            end
            table.remove(Arena.active_projectiles, i)
        end
    end

    -- Atualiza Áreas / AoE
    for i = #Arena.active_areas, 1, -1 do
        local a = Arena.active_areas[i]
        a.life = a.life - dt
        if a.life <= 0 then
            table.remove(Arena.active_areas, i)
        end
    end

    -- Atualiza Partículas
    for i = #Arena.active_particles, 1, -1 do
        local p = Arena.active_particles[i]
        p.life = p.life - dt
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        if p.life <= 0 then
            table.remove(Arena.active_particles, i)
        end
    end

    -- Atalhos de Teclado
    if love.keyboard.isDown("1") or love.keyboard.isDown("space") then Arena.trigger_skill(1) end
    if love.keyboard.isDown("2") then Arena.trigger_skill(2) end
    if love.keyboard.isDown("3") then Arena.trigger_skill(3) end
    if love.keyboard.isDown("4") then Arena.trigger_skill(4) end
    if love.keyboard.isDown("escape") then return "back_to_selector" end

    return nil
end

function Arena.draw_background(w, h)
    if Arena.bg_style == 1 then
        love.graphics.setColor(0.09, 0.11, 0.15, 1)
        love.graphics.rectangle("fill", 0, 0, w, h)
        local tile = 16 * Arena.zoom
        for y = 0, h, tile do
            for x = 0, w, tile do
                local col = (math.floor(x / tile) + math.floor(y / tile)) % 2
                if col == 0 then
                    love.graphics.setColor(0.12, 0.14, 0.19, 1)
                else
                    love.graphics.setColor(0.10, 0.12, 0.17, 1)
                end
                love.graphics.rectangle("fill", x, y, tile, tile)
            end
        end
    elseif Arena.bg_style == 2 then
        love.graphics.setColor(0.06, 0.07, 0.09, 1)
        love.graphics.rectangle("fill", 0, 0, w, h)
    elseif Arena.bg_style == 3 then
        love.graphics.setColor(0.88, 0.90, 0.94, 1)
        love.graphics.rectangle("fill", 0, 0, w, h)
    else
        love.graphics.setColor(0.15, 0.05, 0.20, 1)
        love.graphics.rectangle("fill", 0, 0, w, h)
    end
end

function Arena.draw()
    local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
    local sidebar_w = 340
    local viewport_w = sw - sidebar_w

    local shake_x = (math.random() - 0.5) * Arena.screen_shake * 2
    local shake_y = (math.random() - 0.5) * Arena.screen_shake * 2

    love.graphics.push()
    love.graphics.translate(shake_x, shake_y)

    -- 1. Fundo
    Arena.draw_background(viewport_w, sh)

    -- 2. Áreas / AoE
    for _, a in ipairs(Arena.active_areas) do
        local r_pct = 1 - (a.life / a.max_life)
        local rad_x = (a.max_radius * r_pct) * (Arena.zoom / 4)
        local rad_y = rad_x * 0.45

        love.graphics.setColor(0.3, 0.75, 1, (1 - r_pct) * 0.8)
        love.graphics.ellipse("line", a.x, a.y, rad_x, rad_y)
        love.graphics.setColor(0.3, 0.75, 1, (1 - r_pct) * 0.2)
        love.graphics.ellipse("fill", a.x, a.y, rad_x, rad_y)

        if a.sprite then
            love.graphics.setColor(1, 1, 1, (1 - r_pct) * 0.9)
            love.graphics.draw(a.sprite, a.x, a.y - rad_y, 0, Arena.zoom * (1 + r_pct * 0.5), Arena.zoom * (1 + r_pct * 0.5), a.sprite:getWidth() / 2, a.sprite:getHeight() / 2)
        end
    end

    -- 3. Jogador
    local char_img = Arena.selected_char and Arena.selected_char.image
    if char_img then
        local draw_x = Arena.x + Arena.attack_lunge_x
        local draw_y = Arena.y + Arena.attack_lunge_y

        if Arena.is_dashing then
            love.graphics.setColor(0.3, 0.7, 1, 0.4)
            love.graphics.draw(char_img, draw_x - Arena.dir_x * 12, draw_y - Arena.dir_y * 12, 0, Arena.zoom * Arena.facing, Arena.zoom, char_img:getWidth() / 2, char_img:getHeight())
        end

        Anim.draw_sprite(char_img, draw_x, draw_y, Arena.anim_state, Arena.zoom, Arena.facing, Arena.show_shadow, {0.95, 0.2, 0.2, 0.55})

        -- Slash / Melee FX
        if Arena.is_attacking then
            local prog = Arena.attack_timer / Arena.attack_duration
            if prog >= 0.20 and prog <= 0.70 then
                local s_prog = (prog - 0.20) / 0.50
                local base_angle = math.atan2(Arena.dir_y, Arena.dir_x)
                local radius = 24 * (Arena.zoom / 4)
                local arc_cx = draw_x + Arena.dir_x * 8 * (Arena.zoom / 4)
                local arc_cy = draw_y - 8 * Arena.zoom + Arena.dir_y * 8 * (Arena.zoom / 4)

                local slot = Arena.current_melee_slot
                if slot and slot.sprite then
                    love.graphics.setColor(1, 1, 1, (1 - s_prog))
                    love.graphics.draw(slot.sprite, arc_cx, arc_cy, base_angle, Arena.zoom, Arena.zoom, slot.sprite:getWidth() / 2, slot.sprite:getHeight() / 2)
                else
                    love.graphics.setLineWidth(3 * (Arena.zoom / 4))
                    love.graphics.setColor(1, 1, 1, (1 - s_prog) * 0.95)
                    love.graphics.arc("line", "open", arc_cx, arc_cy, radius, base_angle - 1.0 + s_prog * 0.5, base_angle + 1.0, 16)
                    love.graphics.setColor(1, 0.3, 0.4, (1 - s_prog) * 0.8)
                    love.graphics.arc("line", "open", arc_cx, arc_cy, radius * 0.8, base_angle - 0.8, base_angle + 0.8, 16)
                    love.graphics.setLineWidth(1)
                end
            end
        end
    end

    -- 4. Projéteis
    for _, p in ipairs(Arena.active_projectiles) do
        if p.sprite then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(p.sprite, p.x, p.y, p.rotation, Arena.zoom, Arena.zoom, p.sprite:getWidth() / 2, p.sprite:getHeight() / 2)
        else
            love.graphics.setColor(0.3, 0.8, 1, 1)
            love.graphics.circle("fill", p.x, p.y, 4 * (Arena.zoom / 4))
        end

        love.graphics.setColor(0.3, 0.7, 1, 0.2)
        love.graphics.circle("line", Arena.x, Arena.y, p.max_dist)
    end

    -- 5. Partículas
    for _, p in ipairs(Arena.active_particles) do
        local alpha = p.life / p.max_life
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha)
        love.graphics.rectangle("fill", p.x, p.y, 3 * (Arena.zoom / 4), 3 * (Arena.zoom / 4))
    end

    love.graphics.pop()

    -- 6. HUD Inferior Redesenhado (Hotbar Limpa e Profissional)
    local btn_w = 100
    local btn_h = 62
    local btn_spacing = 12
    local hud_w = (btn_w * 4) + (btn_spacing * 3) + 24
    local hud_h = 82
    local hud_x = (viewport_w - hud_w) / 2
    local hud_y = sh - hud_h - 14

    UI.panel(hud_x, hud_y, hud_w, hud_h)

    for slot_id = 1, 4 do
        local bx = hud_x + 12 + (slot_id - 1) * (btn_w + btn_spacing)
        local by = hud_y + 10
        local slot = Arena.slots[slot_id]
        local short_name = get_short_type(slot)
        local is_hover = UI.is_hover(bx, by, btn_w, btn_h)

        -- Trigger de clique no botão do HUD
        if is_hover and UI.mouse_pressed then
            Arena.trigger_skill(slot_id)
        end

        -- Fundo do botão
        if is_hover then
            love.graphics.setColor(0.24, 0.29, 0.38, 1)
        else
            love.graphics.setColor(0.16, 0.19, 0.25, 1)
        end
        love.graphics.rectangle("fill", bx, by, btn_w, btn_h, 6, 6)

        -- Borda
        if is_hover then
            love.graphics.setColor(0.35, 0.75, 1.0, 1)
        else
            love.graphics.setColor(0.26, 0.31, 0.40, 1)
        end
        love.graphics.setLineWidth(1.5)
        love.graphics.rectangle("line", bx, by, btn_w, btn_h, 6, 6)

        -- Badge de Tecla (Atalho) no topo esquerdo
        local key_label = tostring(slot_id)
        if slot_id == 1 then key_label = "1/Esp" end
        love.graphics.setColor(0.20, 0.55, 0.90, 0.85)
        love.graphics.rectangle("fill", bx + 6, by + 5, 26 + (slot_id == 1 and 14 or 0), 16, 4, 4)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(key_label, bx + 9, by + 6)

        -- Ícone / Miniatura do Sprite (se houver) no centro
        if slot and slot.sprite then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(slot.sprite, bx + btn_w / 2, by + 26, 0, 1.5, 1.5, slot.sprite:getWidth() / 2, slot.sprite:getHeight() / 2)
        end

        -- Rótulo Conciso no rodapé do botão (Melee, Projétil, Dash, Área)
        local font = love.graphics.getFont()
        local tw = font:getWidth(short_name)
        love.graphics.setColor(is_hover and 1 or 0.85, is_hover and 1 or 0.90, is_hover and 1 or 0.95, 1)
        love.graphics.print(short_name, bx + (btn_w - tw) / 2, by + btn_h - 18)
    end

    -- 7. Barra Lateral de Ajustes Dinâmicos
    local sb_x = viewport_w
    local sb_y = 0
    local sb_h = sh

    UI.panel(sb_x, sb_y, sidebar_w, sb_h, "Ajustes em Tempo Real")

    local cy = 44
    local pad = 14
    local ctrl_w = sidebar_w - pad * 2

    -- Seção 1: Distâncias Dinâmicas por Slot
    love.graphics.setColor(0.4, 0.8, 1, 1)
    love.graphics.print("DISTÂNCIAS DAS HABILIDADES", sb_x + pad, cy)
    cy = cy + 20

    for slot_id = 1, 4 do
        local slot = Arena.slots[slot_id]
        if slot then
            if slot.type == "melee" then
                local lbl = string.format("Slot %d (Melee): Lunge", slot_id)
                slot.lunge_pixels = UI.slider("sld_s_" .. slot_id, lbl, slot.lunge_pixels or 8, 0, 30, 1, sb_x + pad, cy, ctrl_w, 34, " px")
                cy = cy + 40
            elseif slot.type == "projectile" then
                local lbl = string.format("Slot %d (Projétil): Alcance", slot_id)
                slot.range_pixels = UI.slider("sld_s_" .. slot_id, lbl, slot.range_pixels or 240, 50, 400, 10, sb_x + pad, cy, ctrl_w, 34, " px")
                cy = cy + 40
            elseif slot.type == "dash" then
                local lbl = string.format("Slot %d (Dash): Distância", slot_id)
                slot.dash_pixels = UI.slider("sld_s_" .. slot_id, lbl, slot.dash_pixels or 80, 20, 180, 5, sb_x + pad, cy, ctrl_w, 34, " px")
                cy = cy + 40
            elseif slot.type == "area" then
                local lbl = string.format("Slot %d (Área): Raio AoE", slot_id)
                slot.radius_pixels = UI.slider("sld_s_" .. slot_id, lbl, slot.radius_pixels or 45, 15, 100, 5, sb_x + pad, cy, ctrl_w, 34, " px")
                cy = cy + 40
            end
        end
    end

    cy = cy + 6

    -- Seção 2: Parâmetros da Caminhada
    love.graphics.setColor(0.4, 0.8, 1, 1)
    love.graphics.print("PARÂMETROS DA CAMINHADA", sb_x + pad, cy)
    cy = cy + 20

    -- Slider de Velocidade de Movimento (NOVO!)
    Arena.speed = UI.slider("sld_speed", "Velocidade de Movimento", Arena.speed, 50, 300, 5, sb_x + pad, cy, ctrl_w, 34, " px/s")
    cy = cy + 40

    Arena.walk_config.step_frequency = UI.slider("sld_freq", "Ritmo dos Passos", Arena.walk_config.step_frequency, 5, 25, 1, sb_x + pad, cy, ctrl_w, 34)
    cy = cy + 40

    Arena.walk_config.max_tilt_deg = UI.slider("sld_tilt", "Inclinação Lateral (Tilt)", Arena.walk_config.max_tilt_deg, 0, 20, 1, sb_x + pad, cy, ctrl_w, 34, "°")
    cy = cy + 40

    Arena.walk_config.bob_pixels = UI.slider("sld_bob", "Elevação do Passo (Bob)", Arena.walk_config.bob_pixels, 0, 4, 0.25, sb_x + pad, cy, ctrl_w, 34, " px")
    cy = cy + 40

    Arena.walk_config.squash_amount = UI.slider("sld_squash", "Squash & Stretch", Arena.walk_config.squash_amount, 0, 0.15, 0.01, sb_x + pad, cy, ctrl_w, 34)
    cy = cy + 42

    -- Seção 3: Visual & Câmera
    local wip_text = Arena.walk_in_place and "Andando no Lugar: [ON]" or "Andando no Lugar: [OFF]"
    if UI.button("btn_wip", wip_text, sb_x + pad, cy, ctrl_w, 28, Arena.walk_in_place) then
        Arena.walk_in_place = not Arena.walk_in_place
    end
    cy = cy + 32

    local z_w = (ctrl_w - 9) / 4
    for idx, z_val in ipairs({2, 4, 6, 8}) do
        if UI.button("btn_zoom_" .. z_val, z_val .. "x", sb_x + pad + (idx - 1) * (z_w + 3), cy, z_w, 26, (Arena.zoom == z_val)) then
            Arena.zoom = z_val
        end
    end
    cy = cy + 30

    local bg_name = "Fundo: Grid Arena"
    if Arena.bg_style == 2 then bg_name = "Fundo: Escuro Neutro" end
    if Arena.bg_style == 3 then bg_name = "Fundo: Claro" end
    if Arena.bg_style == 4 then bg_name = "Fundo: Magenta" end

    if UI.button("btn_bg", bg_name, sb_x + pad, cy, ctrl_w, 26) then
        Arena.bg_style = Arena.bg_style + 1
        if Arena.bg_style > 4 then Arena.bg_style = 1 end
    end
    cy = cy + 32

    -- Ações
    if UI.button("btn_export", "Exportar Configuração", sb_x + pad, cy, ctrl_w, 32, true, {0.15, 0.70, 0.35}) then
        Arena.export_config()
    end
    cy = cy + 36

    if UI.button("btn_back", "Trocar Configuração (Esc)", sb_x + pad, cy, ctrl_w, 30) then
        return "back_to_selector"
    end

    -- Popup
    if Arena.export_popup_timer > 0 then
        love.graphics.setColor(0.1, 0.15, 0.2, 0.95)
        love.graphics.rectangle("fill", (sw - 500) / 2, 80, 500, 110, 10, 10)
        love.graphics.setColor(0.3, 0.8, 0.5, 1)
        love.graphics.rectangle("line", (sw - 500) / 2, 80, 500, 110, 10, 10)

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("CONFIGURAÇÕES EXPORTADAS COM SUCESSO!", (sw - 500) / 2 + 20, 95)
        love.graphics.setColor(0.8, 0.9, 1, 1)
        love.graphics.print("Salvo em config_export.lua com a definicao dos 4 slots.", (sw - 500) / 2 + 20, 120)
        love.graphics.print("Copie o codigo salvo para o Trello ou envie para a equipe.", (sw - 500) / 2 + 20, 142)
    end

    return nil
end

return Arena
