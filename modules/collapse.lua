local Global = require 'utils.global'
local Public = {}

local math_floor = math.floor
local table_shuffle_table = table.shuffle_table

local collapse = {
    debug = false
}
Global.register(
    collapse,
    function(tbl)
        collapse = tbl
    end
)

local directions = {
    ['north'] = function(position)
        local width = collapse.surface.map_gen_settings.width
        if width > collapse.max_line_size then
            width = collapse.max_line_size
        end
        local a = width * 0.5 + 1
        collapse.vector = {0, -1}
        collapse.area = {{position.x - a, position.y - 1}, {position.x + a, position.y}}
    end,
    ['south'] = function(position)
        local width = collapse.surface.map_gen_settings.width
        if width > collapse.max_line_size then
            width = collapse.max_line_size
        end
        local a = width * 0.5 + 1
        collapse.vector = {0, 1}
        collapse.area = {{position.x - a, position.y}, {position.x + a, position.y + 1}}
    end,
    ['west'] = function(position)
        local width = collapse.surface.map_gen_settings.height
        if width > collapse.max_line_size then
            width = collapse.max_line_size
        end
        local a = width * 0.5 + 1
        collapse.vector = {-1, 0}
        collapse.area = {{position.x - 1, position.y - a}, {position.x, position.y + a}}
    end,
    ['east'] = function(position)
        local width = collapse.surface.map_gen_settings.height
        if width > collapse.max_line_size then
            width = collapse.max_line_size
        end
        local a = width * 0.5 + 1
        collapse.vector = {1, 0}
        collapse.area = {{position.x, position.y - a}, {position.x + 1, position.y + a}}
    end
}

local function print_debug(a)
    if not collapse.debug then
        return
    end
    print('Collapse error #' .. a)
end

local function set_collapse_tiles(surface)
    if not surface or surface.valid then
        print_debug(45)
    end
    game.forces.player.chart(surface, collapse.area)
    collapse.tiles = surface.find_tiles_filtered({area = collapse.area})
    if not collapse.tiles then
        return
    end
    collapse.size_of_tiles = #collapse.tiles
    if collapse.size_of_tiles > 0 then
        table_shuffle_table(collapse.tiles)
    end
    collapse.position = {x = collapse.position.x + collapse.vector[1], y = collapse.position.y + collapse.vector[2]}
    local v = collapse.vector
    local area = collapse.area
    collapse.area = {{area[1][1] + v[1], area[1][2] + v[2]}, {area[2][1] + v[1], area[2][2] + v[2]}}
    game.forces.player.chart(surface, collapse.area)
end

local function progress()
    local surface = collapse.surface

    if not collapse.start_now then
        collapse.tiles = nil
        return
    end

    local tiles = collapse.tiles
    if not tiles then
        set_collapse_tiles(surface)
        tiles = collapse.tiles
    end
    if not tiles then
        return
    end

    for _ = 1, collapse.amount, 1 do
        local tile = tiles[collapse.size_of_tiles]
        if not tile then
            collapse.tiles = nil
            return
        end
        collapse.size_of_tiles = collapse.size_of_tiles - 1
        if not tile.valid then
            return
        end
        if collapse.specific_entities.enabled then
            local position = {tile.position.x + 0.5, tile.position.y + 0.5}
            local entities = collapse.specific_entities.entities
            for _, e in pairs(surface.find_entities_filtered({area = {{position[1] - 2, position[2] - 2}, {position[1] + 2, position[2] + 2}}})) do
                if entities[e.name] and e.valid and e.health then
                    e.die()
                elseif e.valid then
                    e.destroy()
                end
            end
        end
        if collapse.kill then
            local position = {tile.position.x + 0.5, tile.position.y + 0.5}
            for _, e in pairs(surface.find_entities_filtered({area = {{position[1] - 2, position[2] - 2}, {position[1] + 2, position[2] + 2}}})) do
                if e.valid and e.health then
                    e.die()
                end
            end
        end
        surface.set_tiles({{name = 'out-of-map', position = tile.position}}, true)
    end
end

function Public.set_surface(surface)
    if not surface then
        print_debug(1)
        return
    end
    if not surface.valid then
        print_debug(2)
        return
    end
    if not game.surfaces[surface.index] then
        print_debug(3)
        return
    end
    collapse.surface = surface
end

function Public.set_direction(direction)
    if not directions[direction] then
        print_debug(11)
        return
    end
    directions[direction](collapse.position)
end

function Public.set_speed(speed)
    if not speed then
        print_debug(8)
        return
    end
    speed = math_floor(speed)
    if speed < 1 then
        speed = 1
    end
    collapse.speed = speed
end

function Public.set_amount(amount)
    if not amount then
        print_debug(9)
        return
    end
    amount = math_floor(amount)
    if amount < 0 then
        amount = 0
    end
    collapse.amount = amount
end

function Public.set_position(position)
    if not position then
        print_debug(4)
        return
    end
    if not position.x and not position[1] then
        print_debug(5)
        return
    end
    if not position.y and not position[2] then
        print_debug(6)
        return
    end
    local x = 0
    local y = 0
    if position[1] then
        x = position[1]
    end
    if position[2] then
        y = position[2]
    end
    if position.x then
        x = position.x
    end
    if position.y then
        y = position.y
    end
    collapse.position = {x = x, y = y}
end

function Public.get_position()
    return collapse.position
end

function Public.get_amount()
    return collapse.amount
end

function Public.get_speed()
    return collapse.speed
end

function Public.start_now(status)
    if status == true then
        collapse.start_now = true
    elseif status == false then
        collapse.start_now = false
    end
    return collapse.start_now
end

function Public.set_max_line_size(size)
    if not size then
        print_debug(22)
        return
    end
    size = math_floor(size)
    if size <= 0 then
        print_debug(21)
        return
    end
    collapse.max_line_size = size
end

function Public.set_kill_entities(a)
    collapse.kill = a
end

function Public.set_kill_specific_entities(tbl)
    if tbl then
        collapse.specific_entities = tbl
    else
        collapse.specific_entities = {
            enabled = false
        }
    end
end

local function on_init()
    Public.set_surface(game.surfaces.nauvis)
    Public.set_position({0, 32})
    Public.set_max_line_size(256)
    Public.set_direction('north')
    Public.set_kill_entities(true)
    Public.set_kill_specific_entities()
    collapse.tiles = nil
    collapse.speed = 1
    collapse.amount = 8
    collapse.start_now = true
end

local function on_tick()
    if game.tick % collapse.speed ~= 0 then
        return
    end
    progress()
end

local Event = require 'utils.event'
Event.on_init(on_init)
Event.add(defines.events.on_tick, on_tick)

return Public
