local Global = require 'utils.global'
local Event = require 'utils.event'

local this = {}
Global.register(
    this,
    function(tbl)
        this = tbl
    end
)

local Public = {
    events = {
        on_player_kicked_from_surface = Event.generate_event_name('on_player_kicked_from_surface')
    }
}

function Public.reset()
    if this.surfaces then
        for k, surface in pairs(this.surfaces) do
            if surface and surface.valid then
                game.delete_surface(surface)
            end
        end
    end
    for k, _ in pairs(this) do
        this[k] = nil
    end
    this.debug_mode = false
    this.restore_on_theft = false
    this.doors = {}
    this.cars = {}
    this.current_car_index = nil
    this.renders = {}
    this.saved_surfaces = {}
    this.allowed_surface = 'nauvis'
    this.trust_system = {}
    this.players = {}
    this.surfaces = {}
    this.minimap = {}
    this.entity_type = {
        ['car'] = true,
        ['tank'] = true,
        ['kr-advanced-tank'] = true,
        ['spidertron'] = true,
        ['spider-vehicle'] = true
    }
    this.car_areas = {
        ['car'] = {left_top = {x = -20, y = 0}, right_bottom = {x = 20, y = 20}},
        ['tank'] = {left_top = {x = -30, y = 0}, right_bottom = {x = 30, y = 40}},
        ['kr-advanced-tank'] = {left_top = {x = -40, y = 0}, right_bottom = {x = 40, y = 60}},
        ['spidertron'] = {left_top = {x = -40, y = 0}, right_bottom = {x = 40, y = 60}},
        ['spider-vehicle'] = {left_top = {x = -40, y = 0}, right_bottom = {x = 40, y = 60}}
    }
end

function Public.get(key)
    if key then
        return this[key]
    else
        return this
    end
end

function Public.get_types()
    return this.entity_type
end

function Public.set(key, value)
    if key and (value or value == false) then
        this[key] = value
        return this[key]
    elseif key then
        return this[key]
    else
        return this
    end
end

function Public.set_car_area(tbl)
    if not tbl then
        return
    end

    this.car_areas = tbl
end

function Public.allowed_surface(value)
    if value then
        this.allowed_surface = value
    end
    return this.allowed_surface
end

return Public
