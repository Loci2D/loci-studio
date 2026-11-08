-- src/character_loader.lua
-- Gerenciador de Carregamento de Personagens: PixelLab 32px (8 direções) & Legado 16x16
local json = require("src.json")

local CharacterLoader = {}

-- Ordem canônica das 8 direções no sentido horário a partir do Sul
CharacterLoader.DIRECTIONS = {
    "south",
    "south-west",
    "west",
    "north-west",
    "north",
    "north-east",
    "east",
    "south-east"
}

-- Mapeamento de ângulos (radianos) para as 8 direções
function CharacterLoader.angle_to_direction(angle)
    -- Normaliza ângulo entre 0 e 2*pi
    local two_pi = math.pi * 2
    local a = (angle % two_pi + two_pi) % two_pi

    -- 0 rad = East (+X)
    -- Setores de 45 graus (pi / 4 = 0.785398 rad), deslocados de metade do setor (pi / 8 = 0.392699 rad)
    local octant = math.floor((a + math.pi / 8) / (math.pi / 4)) % 8

    local map = {
        [0] = "east",
        [1] = "south-east",
        [2] = "south",
        [3] = "south-west",
        [4] = "west",
        [5] = "north-west",
        [6] = "north",
        [7] = "north-east"
    }

    return map[octant] or "south"
end

-- Converte vetor de movimento (dx, dy) para nome de direção
function CharacterLoader.vector_to_direction(dx, dy, current_dir)
    if dx == 0 and dy == 0 then
        return current_dir or "south"
    end
    local angle = math.atan2(dy, dx)
    return CharacterLoader.angle_to_direction(angle)
end

-- Carrega um personagem estruturado do PixelLab
function CharacterLoader.load_pixellab_character(folder_path, folder_name)
    local meta_path = folder_path .. "/metadata.json"
    local meta_str = love.filesystem.read(meta_path)
    if not meta_str then return nil end

    local ok, meta = pcall(json.decode, meta_str)
    if not ok or not meta then
        print("[CharacterLoader] Falha ao decodificar JSON:", meta_path)
        return nil
    end

    local char = {
        type = "pixellab",
        name = folder_name:gsub("^%l", string.upper),
        folder_path = folder_path,
        folder_name = folder_name,
        metadata = meta,
        states = {},
        state_list = {},
        texture_cache = {},
        is_32px = true,
        default_dir = "south",
        
        -- Estados identificados por convenção
        state_idle = nil,
        state_walk = nil,
        state_run = nil,
        state_attack = nil,
        state_fury = nil,
        state_death = nil,
        state_projectile = nil
    }

    -- Função interna com cache para carregar texturas Love2D
    function char:get_image(rel_path)
        if not rel_path then return nil end
        if self.texture_cache[rel_path] then
            return self.texture_cache[rel_path]
        end
        local full_path = self.folder_path .. "/" .. rel_path
        local file_ok, img = pcall(love.graphics.newImage, full_path)
        if file_ok and img then
            img:setFilter("nearest", "nearest")
            self.texture_cache[rel_path] = img
            return img
        end
        return nil
    end

    -- Processa os states do metadata.json
    for _, state_data in ipairs(meta.states or {}) do
        local state_name = state_data.folder or (state_data.character and state_data.character.name)
        if state_name then
            local state_info = {
                id = state_name,
                name = (state_data.character and state_data.character.name) or state_name,
                folder = state_data.folder,
                size = (state_data.character and state_data.character.size) or { width = 32, height = 32 },
                rotations = (state_data.frames and state_data.frames.rotations) or {},
                animations = (state_data.frames and state_data.frames.animations) or {}
            }

            char.states[state_name] = state_info
            table.insert(char.state_list, state_info)

            -- Identificação de papéis de estado
            local lower = state_name:lower()
            if lower == "rotacao" or lower == "idle" or lower == "parado" then
                char.state_idle = state_name
            elseif lower == "andando" or lower == "walk" then
                char.state_walk = state_name
            elseif lower == "correndo" or lower == "run" then
                char.state_run = state_name
            elseif lower == "ataque" or lower == "attack" then
                char.state_attack = state_name
            elseif lower == "ataque_furia" or lower:find("furia") then
                char.state_fury = state_name
            elseif lower == "morte" or lower == "death" then
                char.state_death = state_name
            elseif lower == "espada_voa" or lower:find("voa") or lower:find("projetil") then
                char.state_projectile = state_name
            end
        end
    end

    -- Fallbacks de estados
    if not char.state_idle and #char.state_list > 0 then
        char.state_idle = char.state_list[1].id
    end
    if not char.state_walk then
        char.state_walk = char.state_idle
    end

    -- Método para obter imagem estática da direção
    function char:get_rotation_image(state_name, direction)
        direction = direction or self.default_dir
        state_name = state_name or self.state_idle
        local s = self.states[state_name] or self.states[self.state_idle]
        if not s then return nil end

        local rel_path = s.rotations[direction]
        if not rel_path and s.rotations["south"] then
            rel_path = s.rotations["south"]
        end
        return self:get_image(rel_path)
    end

    -- Método para obter sequência de frames da animação
    function char:get_animation_frames(state_name, anim_name, direction)
        direction = direction or self.default_dir
        local s = self.states[state_name]
        if not s then return {} end

        local anim = s.animations[anim_name or state_name]
        if not anim then return {} end

        local frame_paths = anim[direction] or anim["south"] or {}
        local frames = {}
        for _, rel_path in ipairs(frame_paths) do
            local img = self:get_image(rel_path)
            if img then
                table.insert(frames, img)
            end
        end
        return frames
    end

    -- Imagem representativa para miniaturas / seletor
    local thumb_img = char:get_rotation_image(char.state_idle, "south")
    char.preview_image = thumb_img
    char.width = thumb_img and thumb_img:getWidth() or 32
    char.height = thumb_img and thumb_img:getHeight() or 32

    return char
end

-- Carrega um personagem legado (.png 16x16)
function CharacterLoader.load_legacy_character(file_path, file_name)
    local ok, img = pcall(love.graphics.newImage, file_path)
    if not ok or not img then return nil end

    img:setFilter("nearest", "nearest")
    local char_name = file_name:gsub("%.%w+$", ""):gsub("_legada.*", ""):gsub("^%l", string.upper)

    local char = {
        type = "legacy",
        name = char_name,
        file_path = file_path,
        file_name = file_name,
        image = img,
        preview_image = img,
        width = img:getWidth(),
        height = img:getHeight(),
        is_32px = false,
        default_dir = "south"
    }

    function char:get_rotation_image(state_name, direction)
        return self.image
    end

    function char:get_animation_frames(state_name, anim_name, direction)
        return { self.image }
    end

    return char
end

-- Varre a pasta de personagens e retorna lista ordenada
function CharacterLoader.scan_characters(base_path)
    base_path = base_path or "sprites/characters"
    local characters = {}
    local items = love.filesystem.getDirectoryItems(base_path)

    -- Primeiro procura por pastas PixelLab
    for _, item in ipairs(items) do
        local full_path = base_path .. "/" .. item
        local info = love.filesystem.getInfo(full_path)
        if info and info.type == "directory" then
            if love.filesystem.getInfo(full_path .. "/metadata.json") then
                local char = CharacterLoader.load_pixellab_character(full_path, item)
                if char then
                    table.insert(characters, char)
                end
            end
        end
    end

    -- Depois adiciona arquivos legados (.png)
    for _, item in ipairs(items) do
        if item:match("%.png$") or item:match("%.PNG$") then
            local full_path = base_path .. "/" .. item
            local char = CharacterLoader.load_legacy_character(full_path, item)
            if char then
                table.insert(characters, char)
            end
        end
    end

    return characters
end

return CharacterLoader
