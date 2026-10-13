local UI = require("src.ui")
local Anim = require("src.anim")

local SKILL_TYPES = {
    { id = "melee", label = "Melee (Golpe)" },
    { id = "projectile", label = "Projétil (Disparo)" },
    { id = "dash", label = "Dash (Investida)" },
    { id = "area", label = "Área / Aura (AoE)" }
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
    preview_config = {
        step_frequency = 13,
        max_tilt_deg = 6,
        bob_pixels = 1.5,
        squash_amount = 0.05,
        stop_smoothness = 12
    },

    -- Estado da Ação de Preview
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

function Selector.scan_folder(folder_path)
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
    Selector.characters = Selector.scan_folder("sprites/characters")
    Selector.skills = Selector.scan_folder("sprites/skills")

    if #Selector.characters == 0 then
        local img_data = love.image.newImageData(16, 16)
        for y = 0, 15 do
            for x = 0, 15 do
                img_data:setPixel(x, y, 1, 0.4, 0.7, 1)
            end
        end
        local fallback_img = love.graphics.newImage(img_data)
        fallback_img:setFilter("nearest", "nearest")
        table.insert(Selector.characters, {
            filename = "placeholder_16x16.png",
            path = "builtin",
            image = fallback_img,
            width = 16,
            height = 16
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
end

function Selector.play_preview(slot_id)
    local slot_info = Selector.skill_slots[slot_id]
    if not slot_info then return end

    local type_obj = SKILL_TYPES[slot_info.type_idx] or SKILL_TYPES[1]
    local sprite_obj = Selector.skills[slot_info.sprite_idx]

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

    if act.type == "melee" then
        act.duration = 0.42
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
        act.duration = 0.60
        table.insert(act.projectiles, {
            x = 0,
            y = -16,
            vx = 220,
            vy = 0,
            rotation = 0,
            sprite = act.sprite,
            life = 0.55
        })
    elseif act.type == "dash" then
        act.duration = 0.40
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
    Anim.update_walk(Selector.anim_state, true, 1, dt, Selector.preview_config)

    -- Atualiza animação da ação de preview
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

        -- Atualiza projéteis do preview
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

        -- Atualiza áreas do preview
        for i = #act.areas, 1, -1 do
            local a = act.areas[i]
            a.life = a.life - dt
            if a.life <= 0 then table.remove(act.areas, i) end
        end

        -- Atualiza partículas do preview
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
    love.graphics.print("LOCI STUDIO — Sandbox de Sprites & Animações", 30, 16)
    love.graphics.setColor(0.4, 0.75, 1, 1)
    love.graphics.print("Passo 1: Escolha o personagem e configure os arquétipos das 4 habilidades", 30, 40)

    if UI.button("btn_reload", "Recarregar Pastas (F5)", sw - 230, 18, 200, 36) then
        Selector.load()
    end

    -- Coluna 1: Lista de Personagens
    local col1_w = 320
    local col1_x = 30
    local col1_y = 90
    local col1_h = sh - 170

    UI.panel(col1_x, col1_y, col1_w, col1_h, "Personagens (sprites/characters/)")

    local item_y = col1_y + 48
    for i, char in ipairs(Selector.characters) do
        local is_sel = (i == Selector.selected_char_idx)
        if UI.button("char_" .. i, string.format("%s (%dx%d)", char.filename, char.width, char.height), col1_x + 14, item_y, col1_w - 28, 42, is_sel) then
            Selector.selected_char_idx = i
        end
        item_y = item_y + 48
        if item_y > col1_y + col1_h - 50 then break end
    end

    -- Coluna 2: Preview Ampliado do Personagem Selecionado
    local col2_x = col1_x + col1_w + 20
    local col2_w = 360
    local col2_y = 90
    local col2_h = col1_h

    UI.panel(col2_x, col2_y, col2_w, col2_h, "Pré-Visualização do Sprite")

    local cur_char = Selector.characters[Selector.selected_char_idx]
    if cur_char then
        local prev_cx = col2_x + col2_w / 2
        local prev_cy = col2_y + 190
        local prev_box_w, prev_box_h = 240, 240

        -- Fundo do quadro de pré-visualização
        love.graphics.setColor(0.18, 0.22, 0.28, 1)
        love.graphics.rectangle("fill", prev_cx - prev_box_w / 2, prev_cy - prev_box_h / 2, prev_box_w, prev_box_h, 8, 8)
        love.graphics.setColor(0.35, 0.40, 0.50, 1)
        love.graphics.rectangle("line", prev_cx - prev_box_w / 2, prev_cy - prev_box_h / 2, prev_box_w, prev_box_h, 8, 8)

        -- Recorte com Scissor para manter os efeitos dentro do quadro
        love.graphics.setScissor(prev_cx - prev_box_w / 2 + 1, prev_cy - prev_box_h / 2 + 1, prev_box_w - 2, prev_box_h - 2)

        local act = Selector.preview_action
        local draw_char_x = prev_cx + (act.active and (act.lunge_x + act.dash_x) or 0)
        local draw_char_y = prev_cy + 55

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
            love.graphics.draw(cur_char.image, draw_char_x - 14, draw_char_y, 0, 8, 8, cur_char.image:getWidth() / 2, cur_char.image:getHeight())
        end

        -- Personagem com balanço procedural
        Anim.draw_sprite(cur_char.image, draw_char_x, draw_char_y, Selector.anim_state, 8, 1, true, {0.95, 0.2, 0.2, 0.6})

        -- Melee Slash FX no Preview
        if act.active and act.type == "melee" then
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

        love.graphics.setScissor() -- Restaura o Scissor

        -- Status do Preview
        if act.active then
            love.graphics.setColor(0.2, 0.85, 0.45, 1)
            love.graphics.print(string.format("▶ Testando: Slot %d [%s]", act.slot_id, act.type_label), prev_cx - 95, prev_cy - prev_box_h / 2 - 20)
        else
            love.graphics.setColor(0.6, 0.7, 0.8, 1)
            love.graphics.print("Clique em [▶ Play] em qualquer skill para testar aqui", prev_cx - 130, prev_cy - prev_box_h / 2 - 20)
        end

        love.graphics.setColor(0.9, 0.95, 1, 1)
        love.graphics.print(string.format("Arquivo: %s", cur_char.filename), col2_x + 20, col2_y + col2_h - 75)
        love.graphics.setColor(0.5, 0.7, 0.9, 1)
        love.graphics.print(string.format("Resolução: %dx%d px (Escala de visualização: 8x)", cur_char.width, cur_char.height), col2_x + 20, col2_y + col2_h - 52)
        love.graphics.print("Animação: Rotação no pivô dos pés + Bobbing vertical", col2_x + 20, col2_y + col2_h - 32)
    end

    -- Coluna 3: Configuração das 4 Habilidades (Modular: Tipo + Sprite + Botão Play)
    local col3_x = col2_x + col2_w + 20
    local col3_w = sw - col3_x - 30
    local col3_y = 90
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
    love.graphics.print("Dica: Clique em [▶ Play] ao lado de cada habilidade para testar visualmente no preview.", 30, footer_y + 26)

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
