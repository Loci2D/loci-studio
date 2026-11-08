-- src/anim.lua
-- Motor de Animação de Sprites 32px (8 Direções, Ciclo de Passos Alternados e Sequências Frame-a-Frame)
-- Zero wobble: livre de tilts, bobbing e distorções squash.
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
        current_anim_name = nil,     -- Nome da animação quadro a quadro se houver
        is_playing_action = false,   -- Trava de ação (ataque, morte)
        is_preview = false,          -- Se for preview, o seletor controla o estado sem resetar para idle
        
        -- Ciclo de Passada (Alternância de Pernas para Caminhada)
        walk_timer = 0,
        walk_step_phase = 2,         -- 1 = Passo A, 2 = Neutro (Pés Juntos), 3 = Passo B (Alternado), 4 = Neutro
        step_rate = 8,               -- Passos por segundo

        -- Controle de Quadros (Frame-by-Frame para Animações como Ataque Fúria)
        frames = {},
        frame_idx = 1,
        frame_timer = 0,
        fps = 16,
        is_paused = false,
        is_looping = true,
        action_finished = false
    }
end

-- Define o estado atual e carrega seus frames ou rotações
function Anim.set_state(state, char, state_name, loop, is_action, custom_fps)
    if not char then return end

    state.current_state = state_name
    state.is_looping = (loop ~= false)
    state.is_playing_action = (is_action == true)
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

-- Dispara uma ação / habilidade com animação dedicada (ex: ataque_furia)
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
    state.current_state = action_state_name

    if char and char.type == "pixellab" then
        local s = char.states[action_state_name]
        if s and s.animations and s.animations[action_state_name] then
            state.current_anim_name = action_state_name
            state.frames = char:get_animation_frames(action_state_name, action_state_name, direction)
            return true
        end
    end

    state.current_anim_name = nil
    state.frames = {}
    return false
end

-- Interrompe a ação atual e volta ao estado base
function Anim.stop_action(state, char)
    state.is_playing_action = false
    state.action_finished = true
    if not state.is_preview then
        local base_state = state.is_moving and (char and char.state_walk or "andando") or (char and char.state_idle or "Rotacao")
        Anim.set_state(state, char, base_state, true, false)
    end
end

-- Pausa ou despausa a animação
function Anim.toggle_pause(state)
    state.is_paused = not state.is_paused
end

-- Avança ou retrocede quadros manualmente (inspeção frame por frame)
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

    -- 2. Modo Preview: Não força transição de locomoção, mantém o estado escolhido pelo artista
    if state.is_preview then
        -- Se o estado do preview tiver animação quadro a quadro, avança os frames
        if #state.frames > 1 and not state.is_paused then
            state.frame_timer = state.frame_timer + dt
            local frame_time = 1.0 / math.max(1, state.fps)
            if state.frame_timer >= frame_time then
                state.frame_timer = state.frame_timer - frame_time
                state.frame_idx = state.frame_idx + 1
                if state.frame_idx > #state.frames then
                    state.frame_idx = state.is_looping and 1 or #state.frames
                end
            end
        end

        -- Se o preview estiver no estado "andando" ou "correndo", cicla as passadas
        if state.current_state == "andando" or state.current_state == "correndo" then
            state.walk_timer = state.walk_timer + dt
            local step_duration = 1.0 / state.step_rate
            if state.walk_timer >= step_duration then
                state.walk_timer = state.walk_timer - step_duration
                state.walk_step_phase = (state.walk_step_phase % 4) + 1
            end
        else
            state.walk_step_phase = 2 -- Neutro
            state.walk_timer = 0
        end
        return
    end

    -- 3. Modo Arena / Gameplay: Transição entre Repouso e Locomoção
    if not state.is_playing_action and char and char.type == "pixellab" then
        if is_moving then
            -- Em movimento: cicla o passo alternado
            state.current_state = char.state_walk or "andando"
            state.walk_timer = state.walk_timer + dt
            local step_duration = 1.0 / state.step_rate
            if state.walk_timer >= step_duration then
                state.walk_timer = state.walk_timer - step_duration
                state.walk_step_phase = (state.walk_step_phase % 4) + 1
            end
        else
            -- Parado: Retorna IMEDIATAMENTE para a postura de repouso neutra (pés juntos!)
            state.current_state = char.state_idle or "Rotacao"
            state.walk_step_phase = 2 -- Fase neutra
            state.walk_timer = 0
        end
    end

    -- 4. Avanço de Quadros de Ações (ex: Ataque Fúria com 17 frames)
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

-- Renderização Nítida e Estável do Personagem 32px (Com alternância real de passada e zero wobble)
function Anim.draw_character(char, x, y, state, zoom, show_shadow, shadow_color)
    if not char then return end

    local current_img = nil
    local flip_x = 1

    if char.type == "pixellab" then
        -- 1. Se houver sequência de frames reais (ex: ataque_furia)
        if #state.frames > 0 then
            current_img = state.frames[state.frame_idx] or state.frames[1]

        -- 2. Se for estado de locomoção (andando ou correndo)
        elseif state.current_state == "andando" or state.current_state == "correndo" then
            local phase = state.walk_step_phase or 2
            if phase == 1 then
                -- Passo A: Pose de passada normal (perna aberta para frente)
                current_img = char:get_rotation_image(state.current_state, state.direction)
            elseif phase == 3 then
                -- Passo B: Passada alternada da outra perna
                -- Nas direções frontais/traseiras (south/north), invertemos horizontalmente para trocar as pernas
                current_img = char:get_rotation_image(state.current_state, state.direction)
                if state.direction == "south" or state.direction == "north" then
                    flip_x = -1
                elseif char.states["correndo"] and state.current_state == "andando" then
                    -- Em diagonais e laterais, usa a pose de passada alternativa para dar o ritmo
                    current_img = char:get_rotation_image("correndo", state.direction) or current_img
                end
            else
                -- Fases 2 e 4: Pés juntos passando pelo centro (pose neutra de repouso)
                current_img = char:get_rotation_image(char.state_idle or "Rotacao", state.direction)
            end

        -- 3. Estado de Repouso (ou outro estado estático como morte/ataque)
        else
            current_img = char:get_rotation_image(state.current_state or char.state_idle or "Rotacao", state.direction)
            if not current_img then
                current_img = char:get_rotation_image(char.state_idle, state.direction)
            end
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

    -- 3. Renderização Estável e Nítida (Zero Wobble)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(
        current_img,
        math.floor(x),
        math.floor(y),
        0,                  -- Rotação: 0 absoluto
        zoom * flip_x,      -- Escala X: escala com direção do passo
        zoom,               -- Escala Y: escala uniforme sem deformação
        ox,
        oy
    )
end

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
