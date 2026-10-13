local UI = require("src.ui")
local Anim = require("src.anim")

local Arena = {
    selected_char = nil,
    selected_skills = {},
    
    -- Estado do Jogador
    x = 420,
    y = 360,
    speed = 130,
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

    -- Parâmetros de Distância e Habilidades
    skill_config = {
        lunge_pixels = 8,           -- Avanço do corpo no ataque básico
        slash_radius = 24,          -- Raio do arco de corte
        dash_distance_pixels = 80,  -- Distância da investida
        projectile_range_pixels = 220, -- Alcance do projétil em pixels
        projectile_speed = 340
    },

    -- Visual & Câmera
    zoom = 4,
    show_shadow = true,
    bg_style = 1, -- 1: Grid Arena, 2: Dark, 3: Light, 4: Blueprint
    screen_shake = 0,

    -- Efeitos ativos
    active_projectiles = {},
    active_particles = {},
    active_effects = {},
    
    -- Estado do Ataque
    is_attacking = false,
    attack_timer = 0,
    attack_duration = 0.22,
    attack_lunge_x = 0,
    attack_lunge_y = 0,

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

function Arena.init(data)
    Arena.selected_char = data.character
    Arena.selected_skills = data.skills
    Arena.x = 420
    Arena.y = 360
    Arena.active_projectiles = {}
    Arena.active_particles = {}
    Arena.active_effects = {}
    Arena.is_attacking = false
    Arena.is_dashing = false
    Arena.export_popup_timer = 0
end

function Arena.trigger_skill(slot)
    if slot == 1 then
        -- Slot 1: Ataque Básico (Slash / Lunge)
        if Arena.is_attacking then return end
        Arena.is_attacking = true
        Arena.attack_timer = 0
        Arena.screen_shake = 3.5

        -- Spawna faíscas
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

    elseif slot == 2 then
        -- Slot 2: Buff / Fúria / Aura
        table.insert(Arena.active_effects, {
            type = "aura",
            x = Arena.x,
            y = Arena.y,
            life = 0.45,
            max_life = 0.45
        })
        for _ = 1, 16 do
            local p_angle = math.random() * math.pi * 2
            local p_dist = math.random(5, 30) * (Arena.zoom / 4)
            table.insert(Arena.active_particles, {
                x = Arena.x + math.cos(p_angle) * p_dist,
                y = Arena.y + math.sin(p_angle) * (p_dist * 0.4),
                vx = 0,
                vy = -math.random(60, 140),
                life = 0.4,
                max_life = 0.4,
                color = {0.95, 0.2, 0.4}
            })
        end

    elseif slot == 3 then
        -- Slot 3: Dash / Investida
        if Arena.is_dashing then return end
        Arena.is_dashing = true
        Arena.dash_timer = 0
        Arena.dash_start_x = Arena.x
        Arena.dash_start_y = Arena.y
        Arena.dash_target_x = Arena.x + Arena.dir_x * Arena.skill_config.dash_distance_pixels
        Arena.dash_target_y = Arena.y + Arena.dir_y * Arena.skill_config.dash_distance_pixels

    elseif slot == 4 then
        -- Slot 4: Projétil / Arremesso
        local skill_data = Arena.selected_skills[4]
        table.insert(Arena.active_projectiles, {
            x = Arena.x + Arena.dir_x * 12 * Arena.zoom,
            y = Arena.y - 8 * Arena.zoom + Arena.dir_y * 12 * Arena.zoom,
            dir_x = Arena.dir_x,
            dir_y = Arena.dir_y,
            dist_traveled = 0,
            max_dist = Arena.skill_config.projectile_range_pixels,
            speed = Arena.skill_config.projectile_speed,
            rotation = 0,
            sprite = skill_data and skill_data.image
        })
    end
end

function Arena.export_config()
    local code = string.format([[
-- ============================================================================
-- EXPORTAÇÃO DE CONFIGURAÇÕES - LOCI STUDIO
-- Personagem: %s
-- ============================================================================
local WALK_CONFIG = {
    step_frequency  = %d,      -- Ritmo dos passos
    max_tilt_deg    = %d,       -- Inclinação lateral (graus)
    bob_pixels      = %.2f,    -- Elevação vertical em pixels 16x16
    squash_amount   = %.2f,    -- Compressão no solo (squash & stretch)
    stop_smoothness = %d       -- Retorno suave à postura neutra
}

local SKILL_CONFIG = {
    lunge_pixels            = %d,   -- Avanço do golpe no ataque básico
    dash_distance_pixels    = %d,   -- Distância da investida/dash
    projectile_range_pixels = %d    -- Alcance máximo do projétil em pixels
}
]],
        Arena.selected_char and Arena.selected_char.filename or "Arya",
        math.floor(Arena.walk_config.step_frequency + 0.5),
        math.floor(Arena.walk_config.max_tilt_deg + 0.5),
        Arena.walk_config.bob_pixels,
        Arena.walk_config.squash_amount,
        math.floor(Arena.walk_config.stop_smoothness + 0.5),
        math.floor(Arena.skill_config.lunge_pixels + 0.5),
        math.floor(Arena.skill_config.dash_distance_pixels + 0.5),
        math.floor(Arena.skill_config.projectile_range_pixels + 0.5)
    )

    Arena.export_code = code
    Arena.export_popup_timer = 4.0

    -- Salva em arquivo no disco
    local ok, err = pcall(function()
        love.filesystem.write("config_export.lua", code)
    end)
    if ok then
        print("[Loci Studio] Configurações exportadas com sucesso para config_export.lua!")
    end
end

function Arena.update(dt)
    -- Atualiza Screen Shake
    if Arena.screen_shake > 0 then
        Arena.screen_shake = Arena.screen_shake - dt * 20
        if Arena.screen_shake < 0 then Arena.screen_shake = 0 end
    end

    -- Atualiza Popup de Exportação
    if Arena.export_popup_timer > 0 then
        Arena.export_popup_timer = Arena.export_popup_timer - dt
    end

    -- Processa Movimentação do Jogador (se não estiver no dash)
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

    -- Atualiza posição no mundo
    if is_input_moving then
        Arena.x = Arena.x + dx * Arena.speed * dt
        Arena.y = Arena.y + dy * Arena.speed * dt

        -- Limites da área do viewport (deixa espaço para a barra lateral)
        Arena.x = math.max(60, math.min(love.graphics.getWidth() - 360, Arena.x))
        Arena.y = math.max(60, math.min(love.graphics.getHeight() - 60, Arena.y))
    end

    -- Atualiza Animação de Caminhada
    Anim.update_walk(Arena.anim_state, is_moving, Arena.facing, dt, Arena.walk_config)

    -- Atualiza Ataque Básico (Lunge + Slash)
    if Arena.is_attacking then
        Arena.attack_timer = Arena.attack_timer + dt
        local prog = Arena.attack_timer / Arena.attack_duration
        if prog < 0.25 then
            -- Windup (recuo)
            local r = prog / 0.25
            Arena.attack_lunge_x = -Arena.dir_x * 4 * r
            Arena.attack_lunge_y = -Arena.dir_y * 4 * r
        elseif prog < 0.65 then
            -- Estocada (lunge)
            local r = (prog - 0.25) / 0.40
            local max_l = Arena.skill_config.lunge_pixels * (Arena.zoom / 4)
            Arena.attack_lunge_x = Arena.dir_x * max_l * math.sin(r * math.pi * 0.5)
            Arena.attack_lunge_y = Arena.dir_y * max_l * math.sin(r * math.pi * 0.5)
        elseif prog < 1.0 then
            -- Retorno
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
            -- Impacto ao fim da distância
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

    -- Atualiza Efeitos
    for i = #Arena.active_effects, 1, -1 do
        local ef = Arena.active_effects[i]
        ef.life = ef.life - dt
        if ef.life <= 0 then
            table.remove(Arena.active_effects, i)
        end
    end

    -- Atalhos de Teclado para Habilidades
    if love.keyboard.isDown("1") or love.keyboard.isDown("space") then Arena.trigger_skill(1) end
    if love.keyboard.isDown("2") then Arena.trigger_skill(2) end
    if love.keyboard.isDown("3") then Arena.trigger_skill(3) end
    if love.keyboard.isDown("4") then Arena.trigger_skill(4) end
    if love.keyboard.isDown("escape") then return "back_to_selector" end

    return nil
end

function Arena.draw_background(w, h)
    if Arena.bg_style == 1 then
        -- Grid Arena (Padrão do Loci Arena)
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
        -- Fundo Escuro Neutro
        love.graphics.setColor(0.06, 0.07, 0.09, 1)
        love.graphics.rectangle("fill", 0, 0, w, h)
    elseif Arena.bg_style == 3 then
        -- Fundo Claro para contraste
        love.graphics.setColor(0.88, 0.90, 0.94, 1)
        love.graphics.rectangle("fill", 0, 0, w, h)
    else
        -- Blueprint / Magenta
        love.graphics.setColor(0.15, 0.05, 0.20, 1)
        love.graphics.rectangle("fill", 0, 0, w, h)
    end
end

function Arena.draw()
    local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
    local sidebar_w = 330
    local viewport_w = sw - sidebar_w

    -- Screen Shake
    local shake_x = (math.random() - 0.5) * Arena.screen_shake * 2
    local shake_y = (math.random() - 0.5) * Arena.screen_shake * 2

    love.graphics.push()
    love.graphics.translate(shake_x, shake_y)

    -- 1. Fundo do Viewport
    Arena.draw_background(viewport_w, sh)

    -- 2. Renderização de Efeitos de Chão (Aura)
    for _, ef in ipairs(Arena.active_effects) do
        if ef.type == "aura" then
            local r_pct = 1 - (ef.life / ef.max_life)
            local rad_x = (18 + r_pct * 32) * (Arena.zoom / 4)
            local rad_y = rad_x * 0.4
            love.graphics.setColor(0.95, 0.2, 0.35, (1 - r_pct) * 0.7)
            love.graphics.ellipse("line", ef.x, ef.y, rad_x, rad_y)
        end
    end

    -- 3. Renderização do Jogador
    local char_img = Arena.selected_char and Arena.selected_char.image
    if char_img then
        local draw_x = Arena.x + Arena.attack_lunge_x
        local draw_y = Arena.y + Arena.attack_lunge_y

        -- Se estiver no dash, desenha ghosts com rotação
        if Arena.is_dashing then
            love.graphics.setColor(0.3, 0.7, 1, 0.4)
            love.graphics.draw(char_img, draw_x - Arena.dir_x * 12, draw_y - Arena.dir_y * 12, 0, Arena.zoom * Arena.facing, Arena.zoom, char_img:getWidth() / 2, char_img:getHeight())
        end

        Anim.draw_sprite(char_img, draw_x, draw_y, Arena.anim_state, Arena.zoom, Arena.facing, Arena.show_shadow, {0.95, 0.2, 0.2, 0.55})

        -- Renderização do Arco de Slash durante ataque básico
        if Arena.is_attacking then
            local prog = Arena.attack_timer / Arena.attack_duration
            if prog >= 0.20 and prog <= 0.70 then
                local s_prog = (prog - 0.20) / 0.50
                local base_angle = math.atan2(Arena.dir_y, Arena.dir_x)
                local radius = Arena.skill_config.slash_radius * (Arena.zoom / 4)
                local arc_cx = draw_x + Arena.dir_x * 8 * (Arena.zoom / 4)
                local arc_cy = draw_y - 8 * Arena.zoom + Arena.dir_y * 8 * (Arena.zoom / 4)

                -- Arco externo branco
                love.graphics.setLineWidth(3 * (Arena.zoom / 4))
                love.graphics.setColor(1, 1, 1, (1 - s_prog) * 0.95)
                love.graphics.arc("line", "open", arc_cx, arc_cy, radius, base_angle - 1.0 + s_prog * 0.5, base_angle + 1.0, 16)
                
                -- Arco interno colorido
                love.graphics.setColor(1, 0.3, 0.4, (1 - s_prog) * 0.8)
                love.graphics.arc("line", "open", arc_cx, arc_cy, radius * 0.8, base_angle - 0.8, base_angle + 0.8, 16)
                love.graphics.setLineWidth(1)
            end
        end
    end

    -- 4. Renderização de Projéteis
    for _, p in ipairs(Arena.active_projectiles) do
        if p.sprite then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(p.sprite, p.x, p.y, p.rotation, Arena.zoom, Arena.zoom, p.sprite:getWidth() / 2, p.sprite:getHeight() / 2)
        else
            love.graphics.setColor(0.3, 0.8, 1, 1)
            love.graphics.circle("fill", p.x, p.y, 4 * (Arena.zoom / 4))
        end
        -- Linha guia da distância máxima (range) sutil
        love.graphics.setColor(0.3, 0.7, 1, 0.2)
        love.graphics.circle("line", Arena.x, Arena.y, Arena.skill_config.projectile_range_pixels)
    end

    -- 5. Renderização de Partículas
    for _, p in ipairs(Arena.active_particles) do
        local alpha = p.life / p.max_life
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha)
        love.graphics.rectangle("fill", p.x, p.y, 3 * (Arena.zoom / 4), 3 * (Arena.zoom / 4))
    end

    love.graphics.pop() -- Restaura Screen Shake

    -- 6. HUD Inferior da Arena (4 Botões de Habilidade)
    local hud_w = 420
    local hud_h = 76
    local hud_x = (viewport_w - hud_w) / 2
    local hud_y = sh - hud_h - 18

    UI.panel(hud_x, hud_y, hud_w, hud_h)

    local btn_w = 90
    local btn_h = 50
    local btn_spacing = 12

    for slot = 1, 4 do
        local bx = hud_x + 14 + (slot - 1) * (btn_w + btn_spacing)
        local by = hud_y + 13
        local label = string.format("[%d] Slot %d", slot, slot)
        if slot == 1 then label = "[1] Slash" end
        if slot == 2 then label = "[2] Buff" end
        if slot == 3 then label = "[3] Dash" end
        if slot == 4 then label = "[4] Shoot" end

        if UI.button("hud_skill_" .. slot, label, bx, by, btn_w, btn_h) then
            Arena.trigger_skill(slot)
        end
    end

    -- 7. Barra Lateral de Configurações em Tempo Real (Direita)
    local sb_x = viewport_w
    local sb_y = 0
    local sb_h = sh

    UI.panel(sb_x, sb_y, sidebar_w, sb_h, "Ajustes em Tempo Real")

    local cy = 48
    local pad = 16
    local ctrl_w = sidebar_w - pad * 2

    -- Seção 1: Distâncias das Habilidades em Pixels
    love.graphics.setColor(0.4, 0.8, 1, 1)
    love.graphics.print("DISTÂNCIA DAS HABILIDADES", sb_x + pad, cy)
    cy = cy + 22

    Arena.skill_config.lunge_pixels = UI.slider("sld_lunge", "Avanço do Golpe (Lunge)", Arena.skill_config.lunge_pixels, 0, 30, 1, sb_x + pad, cy, ctrl_w, 36, " px")
    cy = cy + 44

    Arena.skill_config.dash_distance_pixels = UI.slider("sld_dash", "Distância do Dash", Arena.skill_config.dash_distance_pixels, 20, 180, 5, sb_x + pad, cy, ctrl_w, 36, " px")
    cy = cy + 44

    Arena.skill_config.projectile_range_pixels = UI.slider("sld_range", "Alcance do Projétil", Arena.skill_config.projectile_range_pixels, 60, 400, 10, sb_x + pad, cy, ctrl_w, 36, " px")
    cy = cy + 50

    -- Seção 2: Parâmetros da Caminhada
    love.graphics.setColor(0.4, 0.8, 1, 1)
    love.graphics.print("PARÂMETROS DA CAMINHADA", sb_x + pad, cy)
    cy = cy + 22

    Arena.walk_config.step_frequency = UI.slider("sld_freq", "Ritmo dos Passos", Arena.walk_config.step_frequency, 5, 25, 1, sb_x + pad, cy, ctrl_w, 36)
    cy = cy + 44

    Arena.walk_config.max_tilt_deg = UI.slider("sld_tilt", "Inclinação Lateral (Tilt)", Arena.walk_config.max_tilt_deg, 0, 20, 1, sb_x + pad, cy, ctrl_w, 36, "°")
    cy = cy + 44

    Arena.walk_config.bob_pixels = UI.slider("sld_bob", "Elevação do Passo (Bob)", Arena.walk_config.bob_pixels, 0, 4, 0.25, sb_x + pad, cy, ctrl_w, 36, " px")
    cy = cy + 44

    Arena.walk_config.squash_amount = UI.slider("sld_squash", "Squash & Stretch", Arena.walk_config.squash_amount, 0, 0.15, 0.01, sb_x + pad, cy, ctrl_w, 36)
    cy = cy + 50

    -- Seção 3: Visual & Câmera
    love.graphics.setColor(0.4, 0.8, 1, 1)
    love.graphics.print("VISUALIZAÇÃO", sb_x + pad, cy)
    cy = cy + 22

    -- Toggle Walk in Place
    local wip_text = Arena.walk_in_place and "🚶 Andando no Lugar: [ON]" or "🛑 Andando no Lugar: [OFF]"
    if UI.button("btn_wip", wip_text, sb_x + pad, cy, ctrl_w, 32, Arena.walk_in_place) then
        Arena.walk_in_place = not Arena.walk_in_place
    end
    cy = cy + 38

    -- Zoom Selector (2x, 4x, 6x, 8x)
    local z_w = (ctrl_w - 9) / 4
    for idx, z_val in ipairs({2, 4, 6, 8}) do
        if UI.button("btn_zoom_" .. z_val, z_val .. "x", sb_x + pad + (idx - 1) * (z_w + 3), cy, z_w, 30, (Arena.zoom == z_val)) then
            Arena.zoom = z_val
        end
    end
    cy = cy + 36

    -- Background Selector
    local bg_name = "Fundo: Grid Arena"
    if Arena.bg_style == 2 then bg_name = "Fundo: Escuro Neutro" end
    if Arena.bg_style == 3 then bg_name = "Fundo: Claro (Contraste)" end
    if Arena.bg_style == 4 then bg_name = "Fundo: Magenta" end

    if UI.button("btn_bg", bg_name, sb_x + pad, cy, ctrl_w, 30) then
        Arena.bg_style = Arena.bg_style + 1
        if Arena.bg_style > 4 then Arena.bg_style = 1 end
    end
    cy = cy + 44

    -- Botões de Ação Final
    if UI.button("btn_export", "💾 Exportar Configuração", sb_x + pad, cy, ctrl_w, 36, true, {0.15, 0.70, 0.35}) then
        Arena.export_config()
    end
    cy = cy + 42

    if UI.button("btn_back", "◀ Trocar Sprites (Esc)", sb_x + pad, cy, ctrl_w, 34) then
        return "back_to_selector"
    end

    -- 8. Popup de Confirmação de Exportação
    if Arena.export_popup_timer > 0 then
        love.graphics.setColor(0.1, 0.15, 0.2, 0.95)
        love.graphics.rectangle("fill", (sw - 500) / 2, 80, 500, 110, 10, 10)
        love.graphics.setColor(0.3, 0.8, 0.5, 1)
        love.graphics.rectangle("line", (sw - 500) / 2, 80, 500, 110, 10, 10)

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("✔ CONFIGURAÇÕES EXPORTADAS COM SUCESSO!", (sw - 500) / 2 + 20, 95)
        love.graphics.setColor(0.8, 0.9, 1, 1)
        love.graphics.print("Salvo no arquivo: config_export.lua", (sw - 500) / 2 + 20, 120)
        love.graphics.print("Você pode copiar o código salvo para o Trello ou enviar à equipe.", (sw - 500) / 2 + 20, 142)
    end

    return nil
end

return Arena
