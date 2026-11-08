-- src/anim.lua
-- Motor de Animação de Sprites 32px (8 Direções e Sequências de Quadros)
-- O wobble procedural (tilt/bob/squash) foi completamente removido para preservar a nitidez e a integridade da pixel art 32px.
local CharacterLoader = require("src.character_loader")

local Anim = {}

function Anim.new_state()
    return {
        -- Direção e Orientação
        direction = "south",
        dir_x = 0,
        dir_y = 1,
        facing = 1,
        is_moving = false,

        -- Estado Ativo
        current_state = "Rotacao",   -- ID do estado (ex: Rotacao, andando, correndo, ataque_furia, morte)
        current_anim_name = nil,     -- Nome da animação frame-a-frame se houver
        is_playing_action = false,   -- Trava de ação (ataque, morte) que não é interrompida pela caminhada
        
        -- Controle de Quadros (Frame-by-Frame)
        frames = {},
        frame_idx = 1,
        frame_timer = 0,
        fps = 16,
        is_paused = false,
        is_looping = true,
        action_finished = false
    }
end

-- Define o estado atual e carrega seus frames/rotações
function Anim.set_state(state, char, state_name, loop, is_action, custom_fps)
    if not char then return end

    state.current_state = state_name
    state.is_looping = (loop ~= false)
    state.is_action = (is_action == true)
    state.action_finished = false
    state.frame_timer = 0
    state.frame_idx = 1
    if custom_fps then state.fps = custom_fps end

    if char.type == "pixellab" then
        local s = char.states[state_name]
        if s and s.animations and s.animations[state_name] then
            state.current_anim_name = state_name
            state.frames = char:get_animation_frames(state_name, state_name, state.direction)
        else
            state.current_anim_name = nil
            state.frames = {}
        end
    else
        state.frames = {}
        state.current_anim_name = nil
    end
end

-- Inicia uma ação / habilidade com animação dedicada (ex: ataque_furia)
function Anim.play_action(state, char, action_state_name, direction, fps)
    direction = direction or state.direction
    state.direction = direction
    state.is_playing_action = true
    state.action_finished = false
    state.fps = fps or state.fps or 16
    state.is_looping = false
    state.is_paused = false
    state.frame_timer = 0
    state.frame_idx = 1

    if char and char.type == "pixellab" then
        local s = char.states[action_state_name]
        if s and s.animations and s.animations[action_state_name] then
            state.current_state = action_state_name
            state.current_anim_name = action_state_name
            state.frames = char:get_animation_frames(action_state_name, action_state_name, direction)
            return true
        end
    end

    state.current_state = action_state_name
    state.current_anim_name = nil
    state.frames = {}
    return false
end

-- Interrompe a ação atual e volta ao estado base
function Anim.stop_action(state, char)
    state.is_playing_action = false
    state.action_finished = true
    local base_state = state.is_moving and (char and char.state_walk or "andando") or (char and char.state_idle or "Rotacao")
    Anim.set_state(state, char, base_state, true, false)
end

-- Pausa ou retoma o avanço dos quadros
function Anim.toggle_pause(state)
    state.is_paused = not state.is_paused
end

-- Avança ou retrocede quadros manualmente (inspeção quadro a quadro)
function Anim.step_frame(state, delta)
    if #state.frames <= 1 then return end
    state.frame_idx = state.frame_idx + delta
    if state.frame_idx > #state.frames then
        state.frame_idx = 1
    elseif state.frame_idx < 1 then
        state.frame_idx = #state.frames
    end
end

-- Atualização contínua do motor de animação
function Anim.update(state, char, is_moving, dx, dy, dt, fps_override)
    state.is_moving = is_moving
    if fps_override then state.fps = fps_override end

    local old_dir = state.direction

    -- 1. Atualização da direção vetorial (8 direções)
    if dx ~= 0 or dy ~= 0 then
        state.dir_x = dx
        state.dir_y = dy
        if dx > 0 then state.facing = 1 elseif dx < 0 then state.facing = -1 end
        state.direction = CharacterLoader.vector_to_direction(dx, dy, state.direction)
    end

    -- Se a direção mudou enquanto tocava animação de quadros, atualiza a lista de frames para a nova direção
    if state.direction ~= old_dir and char and char.type == "pixellab" and state.current_anim_name then
        local cur_idx = state.frame_idx
        state.frames = char:get_animation_frames(state.current_state, state.current_anim_name, state.direction)
        state.frame_idx = math.min(cur_idx, math.max(1, #state.frames))
    end

    -- 2. Transição de Estados de Locomoção (quando não estiver em ação prioritária como ataque)
    if not state.is_playing_action and char and char.type == "pixellab" then
        local target_state = is_moving and (char.state_walk or "andando") or (char.state_idle or "Rotacao")
        if state.current_state ~= target_state then
            Anim.set_state(state, char, target_state, true, false)
        end
    end

    -- 3. Avanço de Quadros da Animação (quando houver múltiplos frames e não estiver pausado)
    if #state.frames > 1 and not state.is_paused then
        state.frame_timer = state.frame_timer + dt
        local frame_time = 1.0 / math.max(1, state.fps)

        if state.frame_timer >= frame_time then
            state.frame_timer = state.frame_timer - frame_time
            state.frame_idx = state.frame_idx + 1

            if state.frame_idx > #state.frames then
                if state.is_looping then
                    state.frame_idx = 1
                else
                    state.frame_idx = #state.frames
                    state.action_finished = true
                    if state.is_playing_action then
                        Anim.stop_action(state, char)
                    end
                end
            end
        end
    end
end

-- Renderização limpa e nítida do sprite 32px (SEM WOBBLE)
function Anim.draw_character(char, x, y, state, zoom, show_shadow, shadow_color)
    if not char then return end

    local current_img = nil
    local flip_x = 1

    if char.type == "pixellab" then
        if #state.frames > 0 then
            current_img = state.frames[state.frame_idx] or state.frames[1]
        else
            current_img = char:get_rotation_image(state.current_state or char.state_idle, state.direction)
            if not current_img then
                current_img = char:get_rotation_image(char.state_idle, state.direction)
            end
        end

        if not current_img then
            current_img = char.preview_image
        end
    else
        -- Personagem legado (16x16) com flip horizontal clássico
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

        local shadow_w = (math.min(img_w, 32) * 0.40) * zoom
        local shadow_h = 4 * (zoom / 4)

        love.graphics.setColor(r, g, b, a)
        love.graphics.ellipse("fill", x, y, shadow_w, shadow_h)
        love.graphics.setColor(r, g, b, math.min(1, a + 0.25))
        love.graphics.ellipse("line", x, y, shadow_w, shadow_h)
    end

    -- 2. Pivô Fixo na Base dos Pés (centro horizontal, base vertical)
    local ox = math.floor(img_w / 2)
    local oy = img_h

    -- 3. Renderização Estável e Nítida (Zero Wobble: ângulo = 0, sem deformação squash, sem bob vertical)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(
        current_img,
        math.floor(x),
        math.floor(y),
        0,                  -- Rotação: 0 (sem tilt)
        zoom * flip_x,      -- Escala X: escala de zoom (sem squash)
        zoom,               -- Escala Y: escala de zoom (sem stretch)
        ox,
        oy
    )
end

-- Mantido por compatibilidade
function Anim.update_walk(state, is_moving, facing, dt, config)
    local dx = facing or 0
    Anim.update(state, nil, is_moving, dx, 0, dt, 16)
end

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
