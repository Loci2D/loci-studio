local UI = require("src.ui")
local Anim = require("src.anim")

local Selector = {
    characters = {},
    skills = {},
    selected_char_idx = 1,
    skill_slots = {
        [1] = { name = "Ataque Básico (Slash)", selected_idx = 1 },
        [2] = { name = "Skill 1 (Buff / Fúria)", selected_idx = 1 },
        [3] = { name = "Skill 2 (Dash / Giro)", selected_idx = 1 },
        [4] = { name = "Skill 3 (Projétil / Arremesso)", selected_idx = 1 }
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

    -- Fallback se a pasta estiver vazia
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

    if #Selector.skills == 0 then
        local img_data = love.image.newImageData(16, 16)
        for y = 6, 9 do
            for x = 4, 11 do
                img_data:setPixel(x, y, 0.9, 0.9, 1, 1)
            end
        end
        local fallback_skill = love.graphics.newImage(img_data)
        fallback_skill:setFilter("nearest", "nearest")
        table.insert(Selector.skills, {
            filename = "default_projectile.png",
            path = "builtin",
            image = fallback_skill,
            width = 16,
            height = 16
        })
    end

    Selector.selected_char_idx = math.min(Selector.selected_char_idx, #Selector.characters)
    for i = 1, 4 do
        Selector.skill_slots[i].selected_idx = math.min(Selector.skill_slots[i].selected_idx, #Selector.skills)
    end
end

function Selector.update(dt)
    -- Preview de animação de caminhada em tempo real na tela de seleção
    Anim.update_walk(Selector.anim_state, true, 1, dt, Selector.preview_config)

    -- Atalhos
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
    local title_font = love.graphics.getFont()
    love.graphics.print("LOCI STUDIO — Sandbox de Sprites & Animações", 30, 16)
    love.graphics.setColor(0.4, 0.75, 1, 1)
    love.graphics.print("Passo 1: Escolha o personagem e mapeie as habilidades", 30, 40)

    if UI.button("btn_reload", "🔄 Recarregar Pastas (F5)", sw - 230, 18, 200, 36) then
        Selector.load()
    end

    -- Coluna 1: Lista de Personagens
    local col1_w = 340
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
    local col2_x = col1_x + col1_w + 24
    local col2_w = 400
    local col2_y = 90
    local col2_h = col1_h

    UI.panel(col2_x, col2_y, col2_w, col2_h, "Pré-Visualização do Sprite")

    local cur_char = Selector.characters[Selector.selected_char_idx]
    if cur_char then
        -- Fundo xadrez claro para destaque da pixel art
        local prev_cx = col2_x + col2_w / 2
        local prev_cy = col2_y + 200
        local prev_box_w, prev_box_h = 240, 240

        love.graphics.setColor(0.18, 0.22, 0.28, 1)
        love.graphics.rectangle("fill", prev_cx - prev_box_w / 2, prev_cy - prev_box_h / 2, prev_box_w, prev_box_h, 8, 8)
        love.graphics.setColor(0.35, 0.40, 0.50, 1)
        love.graphics.rectangle("line", prev_cx - prev_box_w / 2, prev_cy - prev_box_h / 2, prev_box_w, prev_box_h, 8, 8)

        -- Desenha sprite animado ampliado em 8x
        Anim.draw_sprite(cur_char.image, prev_cx, prev_cy + 60, Selector.anim_state, 8, 1, true, {0.95, 0.2, 0.2, 0.6})

        love.graphics.setColor(0.9, 0.95, 1, 1)
        love.graphics.print(string.format("Arquivo: %s", cur_char.filename), col2_x + 20, col2_y + col2_h - 80)
        love.graphics.setColor(0.5, 0.7, 0.9, 1)
        love.graphics.print(string.format("Resolução Nativa: %dx%d pixels (Escala de prévia: 8x)", cur_char.width, cur_char.height), col2_x + 20, col2_y + col2_h - 55)
        love.graphics.print("Animação: Rotação no pivô dos pés + Bobbing vertical", col2_x + 20, col2_y + col2_h - 35)
    end

    -- Coluna 3: Mapeamento dos 4 Slots de Habilidades
    local col3_x = col2_x + col2_w + 24
    local col3_w = sw - col3_x - 30
    local col3_y = 90
    local col3_h = col1_h

    UI.panel(col3_x, col3_y, col3_w, col3_h, "Slots de Habilidades (sprites/skills/)")

    local slot_y = col3_y + 50
    for slot_id = 1, 4 do
        local slot_info = Selector.skill_slots[slot_id]
        love.graphics.setColor(0.9, 0.9, 0.95, 1)
        love.graphics.print(string.format("Slot %d: %s", slot_id, slot_info.name), col3_x + 16, slot_y)

        local skill_item = Selector.skills[slot_info.selected_idx]
        local skill_name = skill_item and skill_item.filename or "(Padrão / Procedural)"

        if UI.button("slot_prev_" .. slot_id, "◀", col3_x + 16, slot_y + 22, 34, 32) then
            slot_info.selected_idx = slot_info.selected_idx - 1
            if slot_info.selected_idx < 1 then slot_info.selected_idx = #Selector.skills end
        end

        UI.button("slot_name_" .. slot_id, skill_name, col3_x + 56, slot_y + 22, col3_w - 112, 32, false)

        if UI.button("slot_next_" .. slot_id, "▶", col3_x + col3_w - 50, slot_y + 22, 34, 32) then
            slot_info.selected_idx = slot_info.selected_idx + 1
            if slot_info.selected_idx > #Selector.skills then slot_info.selected_idx = 1 end
        end

        slot_y = slot_y + 74
    end

    -- Rodapé com Botão Principal
    local footer_y = sh - 70
    love.graphics.setColor(0.12, 0.14, 0.18, 1)
    love.graphics.rectangle("fill", 0, footer_y, sw, 70)
    love.graphics.setColor(0.25, 0.30, 0.38, 1)
    love.graphics.line(0, footer_y, sw, footer_y)

    love.graphics.setColor(0.6, 0.7, 0.8, 1)
    love.graphics.print("Dica: Use as setas para trocar de sprite ou Enter para entrar na arena.", 30, footer_y + 26)

    if UI.button("btn_start", "▶ Iniciar Arena Sandbox (Enter)", sw - 320, footer_y + 14, 290, 42, true, {0.15, 0.75, 0.35}) then
        return "start_arena"
    end

    return nil
end

function Selector.get_selected_data()
    return {
        character = Selector.characters[Selector.selected_char_idx],
        skills = {
            [1] = Selector.skills[Selector.skill_slots[1].selected_idx],
            [2] = Selector.skills[Selector.skill_slots[2].selected_idx],
            [3] = Selector.skills[Selector.skill_slots[3].selected_idx],
            [4] = Selector.skills[Selector.skill_slots[4].selected_idx]
        }
    }
end

return Selector
