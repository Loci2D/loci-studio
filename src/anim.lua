-- src/anim.lua
-- Motor de Animação Híbrido: PixelLab 32px (8 direções + frame-by-frame) & Procedural 16x16
local CharacterLoader = require("src.character_loader")

local Anim = {}

function Anim.new_state()
    return {
        -- Direção e Orientação
        direction = "south",
        dir_x = 0,
        dir_y = 1,
        facing = 1, -- Para compatibilidade com legado (+1 dir, -1 esq)
        
        -- Caminhada & Física Procedural
        walk_timer = 0,
        tilt_angle = 0,
        target_tilt = 0,
        bob_offset = 0,
        squash_x = 1,
        squash_y = 1,
        is_moving = false,

        -- Animação Quadro a Quadro (PixelLab)
        is_playing_anim = false,
        anim_state_name = nil,
        anim_name = nil,
        anim_frames = {},
        anim_frame_idx = 1,
        anim_timer = 0,
        anim_fps = 16,
        anim_loop = false,
        anim_finished = false
    }
end

-- Inicia a reprodução de uma animação frame-a-frame
function Anim.play_animation(state, char, state_name, anim_name, direction, fps, loop)
    direction = direction or state.direction
    state.direction = direction
    state.anim_state_name = state_name
    state.anim_name = anim_name or state_name
    state.anim_fps = fps or 16
    state.anim_loop = (loop == true)
    state.anim_finished = false
    state.anim_timer = 0
    state.anim_frame_idx = 1

    if char and char.type == "pixellab" then
        state.anim_frames = char:get_animation_frames(state_name, state.anim_name, direction)
        if #state.anim_frames > 0 then
            state.is_playing_anim = true
            return true
        end
    end

    state.anim_frames = {}
    state.is_playing_anim = false
    return false
end

-- Para a animação frame-a-frame e retorna ao estado normal
function Anim.stop_animation(state)
    state.is_playing_anim = false
    state.anim_frames = {}
    state.anim_frame_idx = 1
    state.anim_finished = true
end

-- Atualiza o ciclo de animação (quadros ou balanço procedural)
function Anim.update(state, char, is_moving, dx, dy, dt, config)
    config = config or {
        step_frequency = 13,
        max_tilt_deg = 4,
        bob_pixels = 1.2,
        squash_amount = 0.04,
        stop_smoothness = 12
    }

    state.is_moving = is_moving

    -- Atualiza direção vetorial se houver input de movimento
    if dx ~= 0 or dy ~= 0 then
        state.dir_x = dx
        state.dir_y = dy
        if dx > 0 then state.facing = 1 elseif dx < 0 then state.facing = -1 end
        state.direction = CharacterLoader.vector_to_direction(dx, dy, state.direction)
    end

    -- 1. Se estiver tocando animação quadro a quadro (ex: Ataque Fúria)
    if state.is_playing_anim and #state.anim_frames > 0 then
        state.anim_timer = state.anim_timer + dt
        local frame_duration = 1.0 / state.anim_fps

        if state.anim_timer >= frame_duration then
            state.anim_timer = state.anim_timer - frame_duration
            state.anim_frame_idx = state.anim_frame_idx + 1

            if state.anim_frame_idx > #state.anim_frames then
                if state.anim_loop then
                    state.anim_frame_idx = 1
                else
                    state.anim_frame_idx = #state.anim_frames
                    state.is_playing_anim = false
                    state.anim_finished = true
                end
            end
        end

        -- Reseta deformações procedurais durante a animação de ataque
        state.tilt_angle = state.tilt_angle + (0 - state.tilt_angle) * 16 * dt
        state.bob_offset = 0
        state.squash_x = 1
        state.squash_y = 1
        return
    end

    -- 2. Modo de Caminhada (com ou sem frames)
    if is_moving then
        state.walk_timer = state.walk_timer + dt
        local cycle = state.walk_timer * config.step_frequency
        local max_rad = math.rad(config.max_tilt_deg or 4)

        -- Para sprites PixelLab com 8 direções, o balanço de tilt lateral é mais sutil
        local tilt_mult = (char and char.type == "pixellab") and 0.5 or 1.0
        state.target_tilt = math.sin(cycle) * max_rad * state.facing * tilt_mult

        -- Bobbing vertical (passada)
        state.bob_offset = -math.abs(math.sin(cycle)) * (config.bob_pixels or 1.2)

        -- Squash & Stretch suave
        local squash = math.sin(cycle * 2) * (config.squash_amount or 0.04)
        state.squash_x = 1 + squash
        state.squash_y = 1 - squash
    else
        -- Em repouso: retorno suave à postura neutra
        state.target_tilt = 0
        local smoothness = config.stop_smoothness or 12
        state.bob_offset = state.bob_offset + (0 - state.bob_offset) * smoothness * dt
        state.squash_x = state.squash_x + (1 - state.squash_x) * smoothness * dt
        state.squash_y = state.squash_y + (1 - state.squash_y) * smoothness * dt
        state.walk_timer = 0
    end

    state.tilt_angle = state.tilt_angle + (state.target_tilt - state.tilt_angle) * 16 * dt
end

-- Retrocompatibilidade para chamadas antigas: Anim.update_walk(...)
function Anim.update_walk(state, is_moving, facing, dt, config)
    local dx = facing or 0
    local dy = 0
    Anim.update(state, nil, is_moving, dx, dy, dt, config)
end

-- Renderização principal do personagem
function Anim.draw_character(char, x, y, state, zoom, show_shadow, shadow_color)
    if not char then return end

    local current_img = nil
    local flip_x = 1

    if char.type == "pixellab" then
        if state.is_playing_anim and #state.anim_frames > 0 then
            current_img = state.anim_frames[state.anim_frame_idx] or state.anim_frames[1]
        elseif state.is_moving then
            current_img = char:get_rotation_image(char.state_walk or "andando", state.direction)
            if not current_img then
                current_img = char:get_rotation_image(char.state_idle or "Rotacao", state.direction)
            end
        else
            current_img = char:get_rotation_image(char.state_idle or "Rotacao", state.direction)
        end

        if not current_img then
            current_img = char.preview_image
        end
    else
        -- Personagem legado (16x16)
        current_img = char.image or char.preview_image
        flip_x = state.facing or 1
    end

    if not current_img then return end

    local img_w = current_img:getWidth()
    local img_h = current_img:getHeight()

    -- 1. Sombra Elíptica na Base (chão)
    if show_shadow then
        local r, g, b, a = 0.08, 0.08, 0.1, 0.45
        if shadow_color then
            r, g, b, a = shadow_color[1], shadow_color[2], shadow_color[3], shadow_color[4] or 0.45
        end

        -- A sombra se adapta à largura real do personagem
        local shadow_w = (math.min(img_w, 32) * 0.42) * zoom
        local shadow_h = 3.5 * (zoom / 4) * (char.type == "pixellab" and 1.3 or 1.0)

        love.graphics.setColor(r, g, b, a)
        love.graphics.ellipse("fill", x, y, shadow_w, shadow_h)
        love.graphics.setColor(r, g, b, math.min(1, a + 0.25))
        love.graphics.ellipse("line", x, y, shadow_w, shadow_h)
    end

    -- 2. Pivô Fixo na Base dos Pés (ox = centro horizontal, oy = base vertical)
    local ox = img_w / 2
    local oy = img_h

    -- 3. Desenho do Sprite
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(
        current_img,
        x,
        y + (state.bob_offset * zoom),
        state.tilt_angle,
        zoom * state.squash_x * flip_x,
        zoom * state.squash_y,
        ox,
        oy
    )
end

-- Retrocompatibilidade para chamadas que passavam love.graphics.Image diretamente:
function Anim.draw_sprite(img, x, y, state, zoom, facing, show_shadow, shadow_color)
    local dummy_char = {
        type = "legacy",
        image = img,
        preview_image = img,
        width = img:getWidth(),
        height = img:getHeight()
    }
    state.facing = facing or state.facing or 1
    Anim.draw_character(dummy_char, x, y, state, zoom, show_shadow, shadow_color)
end

return Anim
