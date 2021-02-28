local Server = require 'utils.server'
local Modifers = require 'player_modifiers'
local Global = require 'utils.global'
local Event = require 'utils.event'

local Public = {}
local resettable = {}

---------------------------global table-----------------------------------------
Global.register(
    resettable,
    function(tbl)
        resettable = tbl
    end
)

function Public.reset_table()
    for k, _ in pairs(resettable) do
        resettable[k] = nil
    end
    resettable.soft_reset_counter = 0
    resettable.original_surface_name = nil
    resettable.schedule_step = 0
    resettable.schedule_max_step = 0
    resettable.schedule = {}
    resettable.initial_tick = 0
end

function Public.get_table()
    return resettable
end

local on_init = function ()
    Public.reset_table()
end

Event.on_init(on_init)

-------------------------scheduled deletion-------------------------------------
local function add_step()
    if resettable.schedule_step ~= resettable.schedule_max_step then
        resettable.schedule_step = resettable.schedule_step + 1
    end
end

local function scheduled_surface_clearing()
    if resettable.initial_tick > game.tick then return end
    local step = resettable.schedule_step
    local schedule = resettable.schedule
    if schedule[step] then
        local surface = schedule[step].surface
        if not surface.valid then
            schedule[step] = nil
            add_step()
            return
        end
        if schedule[step].operation == "biter_clearing" then
            local biters = surface.find_entities_filtered{type = "unit", limit = 10000}
            for _,biter in pairs(biters) do
                if biter.valid then biter.destroy() end
            end
            schedule[step] = nil
            add_step()
        elseif schedule[step].operation == "nest_clearing" then
            local nests = surface.find_entities_filtered{type = "unit-spawner"}
            for _, nest in pairs(nests) do
                if nest.valid then nest.destroy() end
            end
            schedule[step] = nil
            add_step()
        elseif schedule[step].operation == "scrap_clearing" then
            local scrap = surface.find_entities_filtered{force = "neutral", limit = 5000}
            for _, e in pairs(scrap) do
                if e.valid then e.destroy() end
            end
            schedule[step] = nil
            add_step()
        elseif schedule[step].operation == "clear" then
            surface.clear()
            schedule[step] = nil
            add_step()
        elseif schedule[step].operation == "delete" then
            game.delete_surface(surface)
            schedule[step] = nil
            add_step()
        end
    end
end

function Public.add_schedule_to_delete_surface(surface)
    local step = resettable.schedule_max_step
    local add = 1
    resettable.schedule[step + add] = {operation = "nest_clearing", surface = surface}
    add = add + 1
    local count_biters = surface.count_entities_filtered{type = "unit"}
    for i = 1, count_biters, 10000 do
        resettable.schedule[step + add] = {operation = "biter_clearing", surface = surface}
        add = add + 1
    end
    local count_scrap = surface.count_entities_filtered{force = "neutral"}
    for i = 1, count_scrap, 5000 do
        resettable.schedule[step + add] = {operation = "scrap_clearing", surface = surface}
        add = add + 1
    end
    resettable.schedule[step + add] = {operation = "clear", surface = surface}
    add = add + 1
    resettable.schedule[step + add] = {operation = "delete", surface = surface}
    resettable.schedule_max_step = resettable.schedule_max_step + add
    if resettable.schedule_step == step then
        resettable.schedule_step = resettable.schedule_step + 1
    end
    if resettable.initial_tick <= game.tick then
        --add offset for starting of deletion, so new map can generate peacefully for a minute and tiny bit
        resettable.initial_tick = game.tick + 4000
    end
end

function Public.change_entities_to_neutral(surface, force, delete_pollution)
    local entities = surface.find_entities_filtered{force = force or "player"}
    for _, entity in pairs(entities) do
        if entity.valid then
            entity.force = "neutral"
            entity.active = false
        end
    end
    if delete_pollution then
        local pollution = surface.get_total_pollution()
        surface.clear_pollution()
        game.pollution_statistics.on_flow("power-switch", -pollution)
    end
end

Event.on_nth_tick(10, scheduled_surface_clearing)

---------------------------soft reset-------------------------------------------

local function reset_forces(new_surface, old_surface)
    for _, f in pairs(game.forces) do
        local spawn = {
            x = game.forces.player.get_spawn_position(old_surface).x,
            y = game.forces.player.get_spawn_position(old_surface).y
        }
        f.reset()

        for _, tech in pairs(game.forces.player.technologies) do
            tech.researched = false
            game.forces.player.set_saved_technology_progress(tech, 0)
        end
        f.reset_evolution()
        f.set_spawn_position(spawn, new_surface)
    end
end

local function teleport_players(surface)
    for _, player in pairs(game.connected_players) do
        local spawn = player.force.get_spawn_position(surface)
        local chunk = {math.floor(spawn.x / 32), math.floor(spawn.y / 32)}
        if not surface.is_chunk_generated(chunk) then
            surface.request_to_generate_chunks(spawn, 1)
            surface.force_generate_chunk_requests()
        end
        local pos = surface.find_non_colliding_position('character', spawn, 3, 0.5)
        player.teleport(pos, surface)
    end
end

local function equip_players(player_starting_items)
    for k, player in pairs(game.connected_players) do
        if player.character then
            player.character.destroy()
        end
        player.character = nil
        player.set_controller({type = defines.controllers.god})
        player.create_character()
        for item, amount in pairs(player_starting_items) do
            player.insert({name = item, count = amount})
        end
        Modifers.update_player_modifiers(player)
    end
end

function Public.soft_reset_map(old_surface, map_gen_settings, player_starting_items)
    if not resettable.original_surface_name then
        resettable.original_surface_name = old_surface.name
    end
    resettable.soft_reset_counter = resettable.soft_reset_counter + 1

    local new_surface =
        game.create_surface(
        resettable.original_surface_name .. '_' .. tostring(resettable.soft_reset_counter),
        map_gen_settings
    )
    new_surface.request_to_generate_chunks({0, 0}, 1)
    new_surface.force_generate_chunk_requests()

    reset_forces(new_surface, old_surface)
    teleport_players(new_surface)
    equip_players(player_starting_items)

    Public.change_entities_to_neutral(old_surface)
    Public.add_schedule_to_delete_surface(old_surface)

    local message = {'modules.soft_reset_welcome', resettable.original_surface_name}
    if resettable.soft_reset_counter > 1 then
        message =
            {
                'modules.soft_reset_reshape',
                resettable.original_surface_name,
                tostring(resettable.soft_reset_counter),
            }
    end
    game.print(message, {r = 0.98, g = 0.66, b = 0.22})
    Server.to_discord_embed(message, true)

    return new_surface
end

return Public
