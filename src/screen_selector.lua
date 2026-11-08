-- src/screen_selector.lua
-- Tela Inicial de Seleção de Personagem e Configuração de Habilidades
-- Preview interativo de animações de sprites 32px (8 direções e quadros reais)
local UI = require("src.ui")
local Anim = require("src.anim")
local CharacterLoader = require("src.character_loader")

local SKILL_TYPES = {
    { id = "melee", label = "Melee (Golpe)" },
    { id = "projectile", label = "Projétil (Disparo)" },
    { id = "dash", label = "Dash (Investida)" },
    { id = "area", label = "Área / Aura (AoE)" }
}

local DIRECTIONS_ORDER = {
    "south",
    "south-west",
    "west",
    "north-west",
    "north",
    "north-east",
    "east",
    "south-east"
}

local DIR_LABELS = {
    ["south"] = "Sul (S ↓)",
    ["south-west"] = "Sudoeste (SW ↙)",
    ["west"] = "Oeste (W ←)",
    ["north-west"] = "Noroeste (NW ↖)",
    ["north"] = "Norte (N ↑)",
    ["north-east"] = "Nordeste (NE ↗)",
    ["east"] = "Leste (E →)",
    ["south-east"] = "Sudeste (SE ↘)"
}

local PREVIEW_STATES = {
    { id = "Rotacao", label = "Repouso" },
    { id = "andando", label = "Andando" },
    { id = "correndo", label = "Correndo" },
    { id = "ataque_furia", label = "Ataque Fúria (17f)" },
    { id = "ataque", label = "Ataque Base" },
    { id = "morte", label = "Morte" }
}

local Selector = {
    characters = {},
    skills = {},
    selected_char_idx = 1,
    skill_types = SKILL_TYPES,
    skill_slots = {
        [1] = { type_idx = 1, sprite_idx = 1 }, -- Melee
        [2] = { type_idx = 4, sprite_idx = 1 }, -- Area
        [3] = { type_idx = 3, sprite_idx = 1 }, -- Dash
        [4] = { type_idx = 2, sprite_idx = 1 }  -- Projectile
    },
    anim_state = Anim.new_state(),

    -- Inspeção 360 e Estados no Preview
    selected_dir_idx = 1, -- 1 = south
    selected_state_idx = 1, -- 1 = Rotacao
    preview_fps = 16,

    -- Estado da Ação de Preview de Skills
    preview_action = {
        active = false,
        slot_id = nil,
        type = nil,
        type_label = nil,
        sprite = nil,
        timer = 0,
        duration = 0.5,
        lunge_x = 0,
        dash_x = 0,
        projectiles = {},
        particles = {},
        areas = {}
    }
}

function Selector.scan_skills(folder_path)
    local items = {}
    local files = love.filesystem.getDirectoryItems(folder_path)
    for _, file in ipairs(files) do
        if file:match("%.png$") or file:match("%.PNG$") then
            local full_path = folder_path .. "/" .. file
            local ok, img = pcall(love.graphics.newImage, full_path)
            if ok then
                img:setFilter("nearest", "nearest")
                table.insert(items, {
                    filename = file,
                    path = full_path,
                    image = img,
                    width = img:getWidth(),
                    height = img:getHeight()
                })
            end
        end
    end
    return items
end

function Selector.load()
    Selector.characters = CharacterLoader.scan_characters("sprites/characters")
    Selector.skills = Selector.scan_skills("sprites/skills")

    if #Selector.characters == 0 then
        local img_data = love.image.newImageData(32, 32)
        for y = 0, 31 do
            for x = 0, 31 do
                img_data:setPixel(x, y, 1, 0.4, 0.7, 1)
            end
        end
        local fallback_img = love.graphics.newImage(img_data)
        fallback_img:setFilter("nearest", "nearest")
        table.insert(Selector.characters, {
            type = "legacy",
            name = "Placeholder",
            filename = "placeholder_32x32.png",
            path = "builtin",
            image = fallback_img,
            preview_image = fallback_img,
            width = 32,
            height = 32,
            is_32px = true,
            get_rotation_image = function() return fallback_img end,
            get_animation_frames = function() return { fallback_img } end
        })
    end

    table.insert(Selector.skills, 1, {
        filename = "(Efeito Procedural Padrão)",
        path = "builtin",
        image = nil,
        width = 16,
        height = 16
    })

    Selector.selected_char_idx = math.min(Selector.selected_char_idx, #Selector.characters)
    for i = 1, 4 do
        Selector.skill_slots[i].type_idx = math.min(Selector.skill_slots[i].type_idx, #SKILL_TYPES)
        Selector.skill_slots[i].sprite_idx = math.min(Selector.skill_slots[i].sprite_idx, #Selector.skills)
    end

    Selector.anim_state = Anim.new_state()
    Selector.anim_state.is_preview = true
    Selector.anim_state.direction = DIRECTIONS_ORDER[Selector.selected_dir_idx]

    local cur_char = Selector.characters[Selector.selected_char_idx]
    local st_id = PREVIEW_STATES[Selector.selected_state_idx].id
    Anim.set_state(Selector.anim_state, cur_char, st_id, true, false, Selector.preview_fps)
end

function Selector.rotate_preview(delta)
    Selector.selected_dir_idx = Selector.selected_dir_idx + delta
    if Selector.selected_dir_idx > #DIRECTIONS_ORDER then
        Selector.selected_dir_idx = 1
    elseif Selector.selected_dir_idx < 1 then
        Selector.selected_dir_idx = #DIRECTIONS_ORDER
    end

    local new_dir = DIRECTIONS_ORDER[Selector.selected_dir_idx]
    Selector.anim_state.direction = new_dir

    local cur_char = Selector.characters[Selector.selected_char_idx]
    if Selector.anim_state.current_anim_name and cur_char and cur_char.type == "pixellab" then
        local cur_idx = Selector.anim_state.frame_idx
        Selector.anim_state.frames = cur_char:get_animation_frames(Selector.anim_state.current_state, Selector.anim_state.current_anim_name, new_dir)
        Selector.anim_state.frame_idx = math.min(cur_idx, math.max(1, #Selector.anim_state.frames))
    end
end

function Selector.set_preview_state(state_idx)
    Selector.selected_state_idx = state_idx
    local st_obj = PREVIEW_STATES[state_idx]
    local cur_char = Selector.characters[Selector.selected_char_idx]
    if st_obj and cur_char then
        Anim.set_state(Selector.anim_state, cur_char, st_obj.id, true, false, Selector.preview_fps)
    end
end

function Selector.play_preview(slot_id)
    local slot_info = Selector.skill_slots[slot_id]
    if not slot_info then return end

    local type_obj = SKILL_TYPES[slot_info.type_idx] or SKILL_TYPES[1]
    local sprite_obj = Selector.skills[slot_info.sprite_idx]
    local cur_char = Selector.characters[Selector.selected_char_idx]

    local act = Selector.preview_action
    act.active = true
    act.slot_id = slot_id
    act.type = type_obj.id
    act.type_label = type_obj.label
    act.sprite = sprite_obj and sprite_obj.image or nil
    act.timer = 0
    act.lunge_x = 0
    act.dash_x = 0
    act.projectiles = {}
    act.particles = {}
    act.areas = {}

    -- Dispara animação dedicada no preview
    local atk_state = (cur_char and cur_char.state_fury) or (cur_char and cur_char.state_attack)
    if cur_char and cur_char.type == "pixellab" and act.type == "melee" and atk_state then
        Anim.play_action(Selector.anim_state, cur_char, atk_state, Selector.anim_state.direction, Selector.preview_fps)
        local frame_count = #Selector.anim_state.frames
        act.duration = (frame_count > 0) and (frame_count / Selector.preview_fps) or 0.45
    elseif cur_char and cur_char.type == "pixellab" and act.type == "projectile" and cur_char.state_projectile then
        Anim.play_action(Selector.anim_state, cur_char, cur_char.state_projectile, Selector.anim_state.direction, Selector.preview_fps)
        act.duration = 0.55
    else
        act.duration = 0.45
    end

    if act.type == "melee" then
        for _ = 1, 8 do
            local p_ang = (math.random() - 0.5) * 1.0
            table.insert(act.particles, {
                x = 20,
                y = -10,
                vx = math.cos(p_ang) * math.random(60, 150),
                vy = math.sin(p_ang) * math.random(40, 100),
                life = 0.25,
                max_life = 0.25,
                color = {1, 0.9, 0.3}
            })
        end
    elseif act.type == "projectile" then
        table.insert(act.projectiles, {
            x = 0,
            y = -16,
            vx = 220,
            vy = 0,
            rotation = 0,
            sprite = act.sprite,
            life = 0.50
        })
    elseif act.type == "dash" then
        act.duration = 0.35
    elseif act.type == "area" then
        act.duration = 0.55
        table.insert(act.areas, {
            max_r = 45,
            life = 0.50,
            max_life = 0.50,
            sprite = act.sprite
        })
        for _ = 1, 14 do
            local ang = math.random() * math.pi * 2
            local d = math.random(6, 38)
            table.insert(act.particles, {
                x = math.cos(ang) * d,
                y = math.sin(ang) * (d * 0.4),
                vx = 0,
                vy = -math.random(40, 90),
                life = 0.45,
                max_life = 0.45,
                color = {0.3, 0.75, 1}
            })
        end
    end
end

function Selector.update(dt)
    local cur_char = Selector.characters[Selector.selected_char_idx]
    Selector.anim_state.is_preview = true
    Selector.anim_state.direction = DIRECTIONS_ORDER[Selector.selected_dir_idx]

    -- Atualiza animação sem forçar transição para idle
    Anim.update(Selector.anim_state, cur_char, false, 0, 0, dt, Selector.preview_fps)

    -- Atualiza efeitos visuais no preview de skill
    local act = Selector.preview_action
    if act.active then
        act.timer = act.timer + dt
        local prog = act.timer / act.duration

        if act.type == "melee" then
            if prog < 0.3 then
                act.lunge_x = -(prog / 0.3) * 6
            elseif prog < 0.7 then
                local r = (prog - 0.3) / 0.4
                act.lunge_x = 24 * math.sin(r * math.pi * 0.5)
            else
                local r = (prog - 0.7) / 0.3
                act.lunge_x = 24 * (1 - r)
            end
        elseif act.type == "dash" then
            if prog < 0.8 then
                act.dash_x = (prog / 0.8) * 55
            else
                local r = (prog - 0.8) / 0.2
                act.dash_x = 55 * (1 - r)
            end
        end

        for i = #act.projectiles, 1, -1 do
            local p = act.projectiles[i]
            p.x = p.x + p.vx * dt
            p.y = p.y + p.vy * dt
            p.rotation = p.rotation + 15 * dt
            p.life = p.life - dt
            if p.life <= 0 then
                for _ = 1, 6 do
                    table.insert(act.particles, {
                        x = p.x,
                        y = p.y,
                        vx = (math.random() - 0.5) * 80,
                        vy = (math.random() - 0.5) * 80,
                        life = 0.2,
                        max_life = 0.2,
                        color = {0.4, 0.8, 1}
                    })
                end
                table.remove(act.projectiles, i)
            end
        end

        for i = #act.areas, 1, -1 do
            local a = act.areas[i]
            a.life = a.life - dt
            if a.life <= 0 then table.remove(act.areas, i) end
        end

        for i = #act.particles, 1, -1 do
            local p = act.particles[i]
            p.life = p.life - dt
            p.x = p.x + p.vx * dt
            p.y = p.y + p.vy * dt
            if p.life <= 0 then table.remove(act.particles, i) end
        end

        if act.timer >= act.duration then
            act.active = false
            act.slot_id = nil
            act.lunge_x = 0
            act.dash_x = 0
            local cur_st = PREVIEW_STATES[Selector.selected_state_idx].id
            Anim.set_state(Selector.anim_state, cur_char, cur_st, true, false, Selector.preview_fps)
        end
    end

    if love.keyboard.isDown("return") or love.keyboard.isDown("kpenter") then
        return "start_arena"
    end
    if love.keyboard.isDown("f5") then
        Selector.load()
    end

    return nil
end

function Selector.draw()
    local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()

    love.graphics.setColor(0.08, 0.09, 0.12, 1)
    love.graphics.rectangle("fill", 0, 0, sw, sh)

    -- Header
    love.graphics.setColor(0.14, 0.17, 0.22, 1)
    love.graphics.rectangle("fill", 0, 0, sw, 70)
    love.graphics.setColor(0.25, 0.30, 0.38, 1)
    love.graphics.line(0, 70, sw, 70)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("LOCI STUDIO — Sandbox de Sprites 32px & Animações", 30, 16)
    love.graphics.setColor(0.4, 0.75, 1, 1)
    love.graphics.print("Inspeção de Animações Reais em 8 Direções (sem wobble)", 30, 40)

    if UI.button("btn_reload", "Recarregar Pastas (F5)", sw - 230, 18, 200, 36) then
        Selector.load()
    end

    -- Coluna 1: Lista de Personagens
    local col1_w = 310
    local col1_x = 30
    local col1_y = 86
    local col1_h = sh - 166

    UI.panel(col1_x, col1_y, col1_w, col1_h, "Personagens (sprites/characters/)")

    local item_y = col1_y + 46
    for i, char in ipairs(Selector.characters) do
        local is_sel = (i == Selector.selected_char_idx)
        local tag = (char.type == "pixellab") and "[PixelLab 8-Dir]" or "[16x16]"
        local label = string.format("%s %s (%dx%d)", tag, char.name, char.width, char.height)
        if UI.button("char_" .. i, label, col1_x + 12, item_y, col1_w - 24, 40, is_sel) then
            Selector.selected_char_idx = i
            local cur_st = PREVIEW_STATES[Selector.selected_state_idx].id
            Anim.set_state(Selector.anim_state, char, cur_st, true, false, Selector.preview_fps)
        end
        item_y = item_y + 46
        if item_y > col1_y + col1_h - 50 then break end
    end

    -- Coluna 2: Preview Ampliado do Personagem Selecionado
    local col2_x = col1_x + col1_w + 16
    local col2_w = 410
    local col2_y = 86
    local col2_h = col1_h

    UI.panel(col2_x, col2_y, col2_w, col2_h, "Pré-Visualização do Sprite")

    local cur_char = Selector.characters[Selector.selected_char_idx]
    if cur_char then
        local prev_cx = col2_x + col2_w / 2
        local prev_cy = col2_y + 155
        local prev_box_w, prev_box_h = 280, 210

        -- Fundo do quadro de pré-visualização (Grid sutil de chão)
        love.graphics.setColor(0.18, 0.22, 0.28, 1)
        love.graphics.rectangle("fill", prev_cx - prev_box_w / 2, prev_cy - prev_box_h / 2, prev_box_w, prev_box_h, 8, 8)
        love.graphics.setColor(0.35, 0.40, 0.50, 1)
        love.graphics.rectangle("line", prev_cx - prev_box_w / 2, prev_cy - prev_box_h / 2, prev_box_w, prev_box_h, 8, 8)

        love.graphics.setScissor(prev_cx - prev_box_w / 2 + 1, prev_cy - prev_box_h / 2 + 1, prev_box_w - 2, prev_box_h - 2)

        local act = Selector.preview_action
        local draw_char_x = prev_cx + (act.active and (act.lunge_x + act.dash_x) or 0)
        local draw_char_y = prev_cy + 55

        local preview_zoom = (cur_char.type == "pixellab") and 4.0 or 7.0

        -- Áreas / AoE no Preview
        for _, a in ipairs(act.areas) do
            local r_pct = 1 - (a.life / a.max_life)
            local rad_x = a.max_r * r_pct * 2
            local rad_y = rad_x * 0.45
            love.graphics.setColor(0.3, 0.75, 1, (1 - r_pct) * 0.8)
            love.graphics.ellipse("line", prev_cx, draw_char_y, rad_x, rad_y)
            love.graphics.setColor(0.3, 0.75, 1, (1 - r_pct) * 0.25)
            love.graphics.ellipse("fill", prev_cx, draw_char_y, rad_x, rad_y)
            if a.sprite then
                love.graphics.setColor(1, 1, 1, 1 - r_pct)
                love.graphics.draw(a.sprite, prev_cx, draw_char_y - rad_y, 0, 4, 4, a.sprite:getWidth() / 2, a.sprite:getHeight() / 2)
            end
        end

        -- Fantasma do Dash no Preview
        if act.active and act.type == "dash" then
            love.graphics.setColor(0.3, 0.7, 1, 0.35)
            local ghost_img = cur_char:get_rotation_image(cur_char.state_idle, Selector.anim_state.direction)
            if ghost_img then
                love.graphics.draw(ghost_img, draw_char_x - 14, draw_char_y, 0, preview_zoom, preview_zoom, ghost_img:getWidth() / 2, ghost_img:getHeight())
            end
        end

        -- Renderização Limpa do Personagem
        Anim.draw_character(cur_char, draw_char_x, draw_char_y, Selector.anim_state, preview_zoom, true, {0.95, 0.2, 0.2, 0.6})

        -- Melee Slash FX (apenas se não houver animação dedicada)
        if act.active and act.type == "melee" and not Selector.anim_state.is_playing_action then
            local prog = act.timer / act.duration
            if prog >= 0.20 and prog <= 0.75 then
                local s_prog = (prog - 0.20) / 0.55
                local arc_cx = draw_char_x + 18
                local arc_cy = draw_char_y - 24

                if act.sprite then
                    love.graphics.setColor(1, 1, 1, 1 - s_prog)
                    love.graphics.draw(act.sprite, arc_cx, arc_cy, 0, 4, 4, act.sprite:getWidth() / 2, act.sprite:getHeight() / 2)
                else
                    love.graphics.setLineWidth(3)
                    love.graphics.setColor(1, 1, 1, (1 - s_prog) * 0.95)
                    love.graphics.arc("line", "open", arc_cx, arc_cy, 28, -0.9 + s_prog * 0.5, 0.9, 16)
                    love.graphics.setColor(1, 0.3, 0.4, (1 - s_prog) * 0.8)
                    love.graphics.arc("line", "open", arc_cx, arc_cy, 22, -0.7, 0.7, 16)
                    love.graphics.setLineWidth(1)
                end
            end
        end

        -- Projéteis no Preview
        for _, p in ipairs(act.projectiles) do
            local px = prev_cx + p.x
            local py = draw_char_y + p.y
            if p.sprite then
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.draw(p.sprite, px, py, p.rotation, 4, 4, p.sprite:getWidth() / 2, p.sprite:getHeight() / 2)
            else
                love.graphics.setColor(0.3, 0.8, 1, 1)
                love.graphics.circle("fill", px, py, 6)
            end
        end

        -- Partículas no Preview
        for _, p in ipairs(act.particles) do
            local alpha = p.life / p.max_life
            love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha)
            love.graphics.rectangle("fill", prev_cx + p.x, draw_char_y + p.y, 4, 4)
        end

        love.graphics.setScissor()

        -- 1. Barra de Rotação 360 no Preview
        local rot_y = prev_cy + prev_box_h / 2 + 8
        local rot_btn_w = 42
        if UI.button("btn_rot_prev", "↺ Q", prev_cx - 125, rot_y, rot_btn_w, 28) then
            Selector.rotate_preview(1)
        end

        local dir_name = DIRECTIONS_ORDER[Selector.selected_dir_idx]
        local dir_label = DIR_LABELS[dir_name] or dir_name
        UI.button("btn_dir_label", dir_label, prev_cx - 78, rot_y, 156, 28, false)

        if UI.button("btn_rot_next", "E ↻", prev_cx + 83, rot_y, rot_btn_w, 28) then
            Selector.rotate_preview(-1)
        end

        -- 2. Seletor de Estados no Preview (Linha 1 e Linha 2 de Botões)
        local st_y = rot_y + 34
        love.graphics.setColor(0.4, 0.8, 1, 1)
        love.graphics.print("Estados de Animação:", col2_x + 14, st_y + 4)

        local btn_grid_w = (col2_w - 28 - 12) / 3
        local r1_y = st_y + 22
        for s_idx = 1, 3 do
            local st_data = PREVIEW_STATES[s_idx]
            local is_active = (Selector.selected_state_idx == s_idx)
            local bx = col2_x + 14 + (s_idx - 1) * (btn_grid_w + 6)
            if UI.button("btn_st_" .. s_idx, st_data.label, bx, r1_y, btn_grid_w, 26, is_active) then
                Selector.set_preview_state(s_idx)
            end
        end

        local r2_y = r1_y + 30
        for s_idx = 4, 6 do
            local st_data = PREVIEW_STATES[s_idx]
            local is_active = (Selector.selected_state_idx == s_idx)
            local bx = col2_x + 14 + (s_idx - 4) * (btn_grid_w + 6)
            if UI.button("btn_st_" .. s_idx, st_data.label, bx, r2_y, btn_grid_w, 26, is_active) then
                Selector.set_preview_state(s_idx)
            end
        end

        -- 3. Controles do Player de Quadros
        local pl_y = r2_y + 34
        local frame_txt = (#Selector.anim_state.frames > 0) and string.format("Frame %d/%d", Selector.anim_state.frame_idx, #Selector.anim_state.frames) or ((Selector.anim_state.current_state == "andando" or Selector.anim_state.current_state == "correndo") and string.format("Passo %d/4", Selector.anim_state.walk_step_phase or 1) or "Pose Estática")
        local p_label = Selector.anim_state.is_paused and "▶ Play" or "⏸ Pause"

        if UI.button("btn_prev_pause", p_label, col2_x + 14, pl_y, 80, 26, Selector.anim_state.is_paused) then
            Anim.toggle_pause(Selector.anim_state)
        end
        if UI.button("btn_prev_step_l", "◀ Frame", col2_x + 100, pl_y, 76, 26) then
            Anim.step_frame(Selector.anim_state, -1)
        end
        UI.button("btn_frame_info", frame_txt, col2_x + 182, pl_y, 140, 26, false)
        if UI.button("btn_prev_step_r", "Frame ▶", col2_x + 328, pl_y, 76, 26) then
            Anim.step_frame(Selector.anim_state, 1)
        end

        -- Rodapé do Preview
        love.graphics.setColor(0.9, 0.95, 1, 1)
        love.graphics.print(string.format("Nome: %s", cur_char.name), col2_x + 14, col2_y + col2_h - 44)
        love.graphics.setColor(0.5, 0.7, 0.9, 1)
        local fmt_str = (cur_char.type == "pixellab") and "Formato: PixelLab 32px (8 Direções nativas, sem wobble)" or "Formato: Legado 16x16"
        love.graphics.print(fmt_str, col2_x + 14, col2_y + col2_h - 26)
    end

    -- Coluna 3: Configuração das 4 Habilidades
    local col3_x = col2_x + col2_w + 16
    local col3_w = sw - col3_x - 30
    local col3_y = 86
    local col3_h = col1_h

    UI.panel(col3_x, col3_y, col3_w, col3_h, "Configuração das 4 Habilidades")

    local slot_y = col3_y + 44
    for slot_id = 1, 4 do
        local slot_info = Selector.skill_slots[slot_id]
        local type_obj = SKILL_TYPES[slot_info.type_idx] or SKILL_TYPES[1]
        local sprite_obj = Selector.skills[slot_info.sprite_idx]
        local sprite_name = sprite_obj and sprite_obj.filename or "(Padrão)"

        -- Título do Slot
        love.graphics.setColor(0.35, 0.75, 1.0, 1)
        love.graphics.print(string.format("Habilidade Slot %d:", slot_id), col3_x + 14, slot_y + 3)

        -- Botão de Play na Habilidade
        local play_w = 66
        local play_x = col3_x + col3_w - 14 - play_w
        local is_playing = (Selector.preview_action.active and Selector.preview_action.slot_id == slot_id)
        if UI.button("btn_play_" .. slot_id, "▶ Play", play_x, slot_y - 2, play_w, 24, is_playing, {0.18, 0.72, 0.40}) then
            Selector.play_preview(slot_id)
        end

        -- 1. Seletor de Tipo / Comportamento
        local btn_w = 28
        local field_w = col3_w - 28 - btn_w * 2 - 12
        local ty = slot_y + 20

        if UI.button("stype_prev_" .. slot_id, "<", col3_x + 14, ty, btn_w, 28) then
            slot_info.type_idx = slot_info.type_idx - 1
            if slot_info.type_idx < 1 then slot_info.type_idx = #SKILL_TYPES end
        end

        UI.button("stype_val_" .. slot_id, "Tipo: " .. type_obj.label, col3_x + 14 + btn_w + 6, ty, field_w, 28, false)

        if UI.button("stype_next_" .. slot_id, ">", col3_x + 14 + btn_w + 6 + field_w + 6, ty, btn_w, 28) then
            slot_info.type_idx = slot_info.type_idx + 1
            if slot_info.type_idx > #SKILL_TYPES then slot_info.type_idx = 1 end
        end

        -- 2. Seletor de Sprite Vinculado
        local sy = ty + 32
        if UI.button("sspr_prev_" .. slot_id, "<", col3_x + 14, sy, btn_w, 28) then
            slot_info.sprite_idx = slot_info.sprite_idx - 1
            if slot_info.sprite_idx < 1 then slot_info.sprite_idx = #Selector.skills end
        end

        UI.button("sspr_val_" .. slot_id, "Sprite: " .. sprite_name, col3_x + 14 + btn_w + 6, sy, field_w, 28, false)

        if UI.button("sspr_next_" .. slot_id, ">", col3_x + 14 + btn_w + 6 + field_w + 6, sy, btn_w, 28) then
            slot_info.sprite_idx = slot_info.sprite_idx + 1
            if slot_info.sprite_idx > #Selector.skills then slot_info.sprite_idx = 1 end
        end

        slot_y = slot_y + 104
    end

    -- Rodapé
    local footer_y = sh - 70
    love.graphics.setColor(0.12, 0.14, 0.18, 1)
    love.graphics.rectangle("fill", 0, footer_y, sw, 70)
    love.graphics.setColor(0.25, 0.30, 0.38, 1)
    love.graphics.line(0, footer_y, sw, footer_y)

    love.graphics.setColor(0.6, 0.7, 0.8, 1)
    love.graphics.print("Dica: Use Q / E para girar as 8 direções e alterne entre os botões de estado para inspecionar cada animação.", 30, footer_y + 26)

    if UI.button("btn_start", "Iniciar Arena Sandbox (Enter)", sw - 320, footer_y + 14, 290, 42, true, {0.15, 0.75, 0.35}) then
        return "start_arena"
    end

    return nil
end

function Selector.get_selected_data()
    local slots_data = {}
    for i = 1, 4 do
        local info = Selector.skill_slots[i]
        local t_obj = SKILL_TYPES[info.type_idx] or SKILL_TYPES[1]
        local s_obj = Selector.skills[info.sprite_idx]

        slots_data[i] = {
            slot_id = i,
            type = t_obj.id,
            type_label = t_obj.label,
            sprite = (s_obj and s_obj.image) and s_obj.image or nil,
            sprite_name = s_obj and s_obj.filename or "(Padrão)",
            lunge_pixels = 8,
            dash_pixels = 80,
            range_pixels = 240,
            radius_pixels = 45,
            speed = 340
        }
    end

    return {
        character = Selector.characters[Selector.selected_char_idx],
        slots = slots_data
    }
end

return Selector
