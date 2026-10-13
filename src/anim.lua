-- Motor de Animação Procedural 16x16 (Base da Paola)
local Anim = {}

function Anim.new_state()
    return {
        walk_timer = 0,
        tilt_angle = 0,
        target_tilt = 0,
        bob_offset = 0,
        squash_x = 1,
        squash_y = 1,
        facing = 1,
        is_moving = false
    }
end

function Anim.update_walk(state, is_moving, facing, dt, config)
    state.is_moving = is_moving
    if facing and facing ~= 0 then
        state.facing = facing
    end

    if is_moving then
        state.walk_timer = state.walk_timer + dt
        local cycle = state.walk_timer * config.step_frequency
        local max_rad = math.rad(config.max_tilt_deg)

        -- Rotação sutil / tilt de balanço nos pés
        state.target_tilt = math.sin(cycle) * max_rad * state.facing

        -- Bobbing (elevação vertical de cada passada)
        state.bob_offset = -math.abs(math.sin(cycle)) * config.bob_pixels

        -- Squash & Stretch (leve deformação no impacto do chão)
        local squash = math.sin(cycle * 2) * config.squash_amount
        state.squash_x = 1 + squash
        state.squash_y = 1 - squash
    else
        -- Parado: lerp suave para neutro
        state.target_tilt = 0
        state.bob_offset = state.bob_offset + (0 - state.bob_offset) * config.stop_smoothness * dt
        state.squash_x = state.squash_x + (1 - state.squash_x) * config.stop_smoothness * dt
        state.squash_y = state.squash_y + (1 - state.squash_y) * config.stop_smoothness * dt
        state.walk_timer = 0
    end

    -- Interpolação suave do ângulo de inclinação
    state.tilt_angle = state.tilt_angle + (state.target_tilt - state.tilt_angle) * 16 * dt
end

function Anim.draw_sprite(img, x, y, state, zoom, facing, show_shadow, shadow_color)
    local width = img:getWidth()
    local height = img:getHeight()

    -- 1. Sombra Elíptica na base (chão)
    if show_shadow then
        local r, g, b, a = 0.1, 0.1, 0.1, 0.45
        if shadow_color then
            r, g, b, a = shadow_color[1], shadow_color[2], shadow_color[3], shadow_color[4] or 0.5
        end
        local shadow_w = (width / 2) * zoom
        local shadow_h = 3.5 * (zoom / 4)

        love.graphics.setColor(r, g, b, a)
        love.graphics.ellipse("fill", x, y, shadow_w, shadow_h)
        love.graphics.setColor(r, g, b, math.min(1, a + 0.3))
        love.graphics.ellipse("line", x, y, shadow_w, shadow_h)
    end

    -- 2. Pivô fixo na base dos pés (ox = centro, oy = base)
    local ox = width / 2
    local oy = height

    -- 3. Renderização do sprite com pivô, escala de zoom e squash
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(
        img,
        x,
        y + (state.bob_offset * zoom),
        state.tilt_angle,
        zoom * state.squash_x * (facing or state.facing),
        zoom * state.squash_y,
        ox,
        oy
    )
end

return Anim
