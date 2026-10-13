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
        [1] = { type_idx = 1, sprite_idx = 1 }, -- Default: Melee
        [2] = { type_idx = 4, sprite_idx = 1 }, -- Default: Area / Buff
        [3] = { type_idx = 3, sprite_idx = 1 }, -- Default: Dash
        [4] = { type_idx = 2, sprite_idx = 1 }  -- Default: Projectile
    },
    anim_state = Anim.new_state(),
    preview_config = {
        step_frequency = 13,
        max_tilt_deg = 6,
        bob_pixels = 1.5,
        squash_amount = 0.05,
        stop_smoothness = 12
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

    -- Fallback se a pasta de personagens estiver vazia
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

    -- Opção "Sem Sprite / Efeito Padrão" no topo da lista de skills
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

function Selector.update(dt)
    Anim.update_walk(Selector.anim_state, true, 1, dt, Selector.preview_config)

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

    -- Fundo gradiente moderno
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
        local prev_box_w, prev_box_h = 220, 220

        love.graphics.setColor(0.18, 0.22, 0.28, 1)
        love.graphics.rectangle("fill", prev_cx - prev_box_w / 2, prev_cy - prev_box_h / 2, prev_box_w, prev_box_h, 8, 8)
        love.graphics.setColor(0.35, 0.40, 0.50, 1)
        love.graphics.rectangle("line", prev_cx - prev_box_w / 2, prev_cy - prev_box_h / 2, prev_box_w, prev_box_h, 8, 8)

        Anim.draw_sprite(cur_char.image, prev_cx, prev_cy + 55, Selector.anim_state, 8, 1, true, {0.95, 0.2, 0.2, 0.6})

        love.graphics.setColor(0.9, 0.95, 1, 1)
        love.graphics.print(string.format("Arquivo: %s", cur_char.filename), col2_x + 20, col2_y + col2_h - 80)
        love.graphics.setColor(0.5, 0.7, 0.9, 1)
        love.graphics.print(string.format("Resolução: %dx%d px (Escala: 8x)", cur_char.width, cur_char.height), col2_x + 20, col2_y + col2_h - 55)
        love.graphics.print("Animação: Rotação no pivô dos pés + Bobbing", col2_x + 20, col2_y + col2_h - 35)
    end

    -- Coluna 3: Configuração das 4 Habilidades (Modular: Tipo + Sprite)
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
        love.graphics.print(string.format("Habilidade Slot %d:", slot_id), col3_x + 14, slot_y)

        -- 1. Seletor de Tipo / Comportamento
        local btn_w = 28
        local field_w = col3_w - 28 - btn_w * 2 - 12
        local ty = slot_y + 18

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

    -- Rodapé com Botão Principal
    local footer_y = sh - 70
    love.graphics.setColor(0.12, 0.14, 0.18, 1)
    love.graphics.rectangle("fill", 0, footer_y, sw, 70)
    love.graphics.setColor(0.25, 0.30, 0.38, 1)
    love.graphics.line(0, footer_y, sw, footer_y)

    love.graphics.setColor(0.6, 0.7, 0.8, 1)
    love.graphics.print("Dica: Use as setas para alternar os tipos e sprites de cada habilidade.", 30, footer_y + 26)

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
            -- Valores iniciais padrão por arquétipo
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
