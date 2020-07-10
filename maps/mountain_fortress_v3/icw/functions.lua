local Public = {}

local ICW = require 'maps.mountain_fortress_v3.icw.table'

function Public.request_reconstruction(icw)
    icw.rebuild_tick = game.tick + 30
end

local function validate_entity(entity)
    if not entity then
        return false
    end
    if not entity.valid then
        return false
    end
    return true
end

local function delete_empty_surfaces(icw)
    for k, surface in pairs(icw.surfaces) do
        if not icw.trains[tonumber(surface.name)] then
            game.delete_surface(surface)
            icw.surfaces[k] = nil
        end
    end
end

local function kick_players_out_of_vehicles(wagon)
    for _, player in pairs(game.connected_players) do
        local character = player.character
        if character and character.valid and character.driving then
            if wagon.surface == player.surface then
                character.driving = false
            end
        end
    end
end

local function recreate_players()
    for _, player in pairs(game.connected_players) do
        if not player.character then
            player.set_controller({type = defines.controllers.god})
            player.create_character()
        end
    end
end

local function connect_power_pole(entity, wagon_area_left_top_y)
    local surface = entity.surface
    local max_wire_distance = entity.prototype.max_wire_distance
    local area = {
        {entity.position.x - max_wire_distance, entity.position.y - max_wire_distance},
        {entity.position.x + max_wire_distance, entity.position.y - 1}
    }
    for _, pole in pairs(surface.find_entities_filtered({area = area, name = entity.name})) do
        if pole.position.y < wagon_area_left_top_y then
            entity.connect_neighbour(pole)
            return
        end
    end
end

local function equal_fluid(source_tank, target_tank)
    if not source_tank.valid then
        return
    end
    if not target_tank.valid then
        return
    end

    local source_fluid = source_tank.fluidbox[1]
    if not source_fluid then
        return
    end

    local target_fluid = target_tank.fluidbox[1]
    local source_fluid_amount = source_fluid.amount

    local amount
    if target_fluid then
        amount = source_fluid_amount - ((target_fluid.amount + source_fluid_amount) * 0.5)
    else
        amount = source_fluid.amount * 0.5
    end

    if amount <= 0 then
        return
    end

    local inserted_amount =
        target_tank.insert_fluid({name = source_fluid.name, amount = amount, temperature = source_fluid.temperature})
    if inserted_amount > 0 then
        source_tank.remove_fluid({name = source_fluid.name, amount = inserted_amount})
    end
end

local function divide_fluid(wagon, storage_tank)
    if not validate_entity(wagon.entity) then
        return
    end

    local fluid_wagon = wagon.entity
    equal_fluid(fluid_wagon, storage_tank)
    equal_fluid(storage_tank, fluid_wagon)
end

local function input_filtered(wagon_inventory, chest, chest_inventory, free_slots)
    local request_stacks = {}
    local prototypes = game.item_prototypes
    for slot_index = 1, 30, 1 do
        local stack = chest.get_request_slot(slot_index)
        if stack then
            request_stacks[stack.name] = 10 * prototypes[stack.name].stack_size
        end
    end
    for i = 1, wagon_inventory.get_bar() - 1, 1 do
        if free_slots <= 0 then
            return
        end
        local stack = wagon_inventory[i]
        if stack.valid_for_read then
            local request_stack = request_stacks[stack.name]
            if request_stack and request_stack > chest_inventory.get_item_count(stack.name) then
                chest_inventory.insert(stack)
                stack.clear()
                free_slots = free_slots - 1
            end
        end
    end
end

local function input_cargo(wagon, chest)
    if not chest.request_from_buffers then
        return
    end

    local wagon_entity = wagon.entity
    if not validate_entity(wagon_entity) then
        wagon.transfer_entities = nil
        return
    end

    local wagon_inventory = wagon_entity.get_inventory(defines.inventory.cargo_wagon)
    if wagon_inventory.is_empty() then
        return
    end

    local chest_inventory = chest.get_inventory(defines.inventory.chest)
    local free_slots = 0
    for i = 1, chest_inventory.get_bar() - 1, 1 do
        if not chest_inventory[i].valid_for_read then
            free_slots = free_slots + 1
        end
    end

    if chest.get_request_slot(1) then
        input_filtered(wagon_inventory, chest, chest_inventory, free_slots)
        return
    end

    for i = 1, wagon_inventory.get_bar() - 1, 1 do
        if free_slots <= 0 then
            return
        end
        if wagon_inventory[i].valid_for_read then
            chest_inventory.insert(wagon_inventory[i])
            wagon_inventory[i].clear()
            free_slots = free_slots - 1
        end
    end
end

local function output_cargo(wagon, passive_chest)
    if not validate_entity(wagon.entity) then
        return
    end

    if not passive_chest.valid then
        return
    end
    local chest1 = passive_chest.get_inventory(defines.inventory.cargo_wagon)
    local chest2 = wagon.entity.get_inventory(defines.inventory.cargo_wagon)
    for k, v in pairs(chest1.get_contents()) do
        local t = {name = k, count = v}
        local c = chest2.insert(t)
        if (c > 0) then
            chest1.remove({name = k, count = c})
        end
    end
end

local transfer_functions = {
    ['storage-tank'] = divide_fluid,
    ['logistic-chest-requester'] = input_cargo,
    ['logistic-chest-passive-provider'] = output_cargo
}

local function get_wagon_for_entity(icw, entity)
    if not validate_entity(entity) then
        return
    end

    local train = icw.trains[tonumber(entity.surface.name)]

    if not train then
        return
    end

    local position = entity.position
    for k, unit_number in pairs(train.wagons) do
        local wagon = icw.wagons[unit_number]
        if wagon then
            local left_top = wagon.area.left_top
            local right_bottom = wagon.area.right_bottom
            if
                position.x >= left_top.x and position.y >= left_top.y and position.x <= right_bottom.x and
                    position.y <= right_bottom.y
             then
                return wagon
            end
        end
    end
    return false
end

local function kill_wagon_doors(icw, wagon)
    if not validate_entity(wagon.entity) then
        return
    end
    for k, e in pairs(wagon.doors) do
        icw.doors[e.unit_number] = nil
        e.destroy()
        wagon.doors[k] = nil
    end
end

local function construct_wagon_doors(icw, wagon)
    local area = wagon.area
    local surface = wagon.surface

    for _, x in pairs({area.left_top.x - 0.55, area.right_bottom.x + 0.55}) do
        local e =
            surface.create_entity(
            {
                name = 'car',
                position = {x, area.left_top.y + ((area.right_bottom.y - area.left_top.y) * 0.5)},
                force = 'neutral',
                create_build_effect_smoke = false
            }
        )
        e.get_inventory(defines.inventory.fuel).insert({name = 'wood', count = 1})
        e.destructible = false
        e.minable = false
        e.operable = false
        icw.doors[e.unit_number] = wagon.entity.unit_number
        wagon.doors[#wagon.doors + 1] = e
    end
end

local function get_player_data(icw, player)
    local player_data = icw.players[player.index]
    if icw.players[player.index] then
        return player_data
    end

    icw.players[player.index] = {
        surface = 1,
        fallback_surface = 1,
        zoom = 0.30,
        map_size = 360
    }
    return icw.players[player.index]
end

function Public.kill_minimap(player)
    local element = player.gui.left.icw_map
    if element then
        element.destroy()
    end
end

function Public.is_minimap_valid(player, surface)
    if validate_entity(player) then
        if player.surface ~= surface then
            Public.kill_minimap(player)
        end
    end
end

function Public.kill_wagon(icw, entity)
    if not validate_entity(entity) then
        return
    end

    local wagon_types = ICW.get('wagon_types')

    if not wagon_types[entity.type] then
        return
    end
    local wagon = icw.wagons[entity.unit_number]
    local surface = wagon.surface
    kick_players_out_of_vehicles(wagon)
    kill_wagon_doors(icw, wagon)
    for _, e in pairs(surface.find_entities_filtered({area = wagon.area})) do
        if e and e.valid and e.name == 'character' and e.player then
            local p = wagon.entity.surface.find_non_colliding_position('character', wagon.entity.position, 128, 0.5)
            if p then
                e.player.teleport(p, wagon.entity.surface)
            else
                e.player.teleport(wagon.entity.position, wagon.entity.surface)
            end
            Public.kill_minimap(e.player)
        else
            e.destroy()
            recreate_players()
        end
    end
    for _, tile in pairs(surface.find_tiles_filtered({area = wagon.area})) do
        surface.set_tiles({{name = 'out-of-map', position = tile.position}}, true)
    end
    wagon.entity.force.chart(surface, wagon.area)
    icw.wagons[entity.unit_number] = nil
    Public.request_reconstruction(icw)
end

function Public.create_room_surface(icw, unit_number)
    if game.surfaces[tostring(unit_number)] then
        return game.surfaces[tostring(unit_number)]
    end
    local map_gen_settings = {
        ['width'] = 2,
        ['height'] = 2,
        ['water'] = 0,
        ['starting_area'] = 1,
        ['cliff_settings'] = {cliff_elevation_interval = 0, cliff_elevation_0 = 0},
        ['default_enable_all_autoplace_controls'] = true,
        ['autoplace_settings'] = {
            ['entity'] = {treat_missing_as_default = false},
            ['tile'] = {treat_missing_as_default = true},
            ['decorative'] = {treat_missing_as_default = false}
        }
    }
    local surface = game.create_surface(tostring(unit_number), map_gen_settings)
    surface.freeze_daytime = true
    surface.daytime = 0.1
    surface.request_to_generate_chunks({16, 16}, 1)
    surface.force_generate_chunk_requests()
    for _, tile in pairs(surface.find_tiles_filtered({area = {{-2, -2}, {2, 2}}})) do
        surface.set_tiles({{name = 'out-of-map', position = tile.position}}, true)
    end
    icw.surfaces[#icw.surfaces + 1] = surface
    return surface
end

function Public.create_wagon_room(icw, wagon)
    local surface = wagon.surface
    local area = wagon.area

    local main_tile_name = 'tutorial-grid'
    if wagon.entity.type == 'locomotive' then
        main_tile_name = 'black-refined-concrete'
    end

    local tiles = {}
    for x = -3, 2, 1 do
        tiles[#tiles + 1] = {name = 'hazard-concrete-right', position = {x, area.left_top.y}}
        tiles[#tiles + 1] = {name = 'hazard-concrete-right', position = {x, area.right_bottom.y - 1}}
    end
    for x = area.left_top.x, area.right_bottom.x - 1, 1 do
        for y = area.left_top.y + 2, area.right_bottom.y - 3, 1 do
            tiles[#tiles + 1] = {name = main_tile_name, position = {x, y}}
        end
    end
    for x = -3, 2, 1 do
        for y = 1, 3, 1 do
            tiles[#tiles + 1] = {name = main_tile_name, position = {x, y}}
        end
        for y = area.right_bottom.y - 4, area.right_bottom.y - 2, 1 do
            tiles[#tiles + 1] = {name = main_tile_name, position = {x, y}}
        end
    end

    local fishes = {}

    if wagon.entity.type == 'locomotive' then
        for x = -3, 2, 1 do
            for y = 10, 12, 1 do
                tiles[#tiles + 1] = {name = 'water', position = {x, y}}
                fishes[#fishes + 1] = {name = 'fish', position = {x, y}}
            end
        end
    end

    surface.set_tiles(tiles, true)

    for _, fish in pairs(fishes) do
        surface.create_entity(fish)
    end

    construct_wagon_doors(icw, wagon)

    if wagon.entity.type == 'fluid-wagon' then
        local height = area.right_bottom.y - area.left_top.y
        local positions = {
            {area.right_bottom.x, area.left_top.y + height * 0.25},
            {area.right_bottom.x, area.left_top.y + height * 0.75},
            {area.left_top.x - 1, area.left_top.y + height * 0.25},
            {area.left_top.x - 1, area.left_top.y + height * 0.75}
        }
        table.shuffle_table(positions)
        local e =
            surface.create_entity(
            {
                name = 'storage-tank',
                position = positions[1],
                force = 'neutral',
                create_build_effect_smoke = false
            }
        )
        e.destructible = false
        e.minable = false
        wagon.transfer_entities = {e}
        return
    end

    -- this.wagon_areas = {
    --     ['cargo-wagon'] = {left_top = {x = -20, y = 0}, right_bottom = {x = 20, y = 60}},
    --     ['artillery-wagon'] = {left_top = {x = -20, y = 0}, right_bottom = {x = 20, y = 60}},
    --     ['fluid-wagon'] = {left_top = {x = -20, y = 0}, right_bottom = {x = 20, y = 60}},
    --     ['locomotive'] = {left_top = {x = -20, y = 0}, right_bottom = {x = 20, y = 60}}
    -- }

    if wagon.entity.type == 'cargo-wagon' then
        local multiple_chests = ICW.get('multiple_chests')
        local wagon_areas = ICW.get('wagon_areas')
        local cargo_wagon = wagon_areas['cargo-wagon']
        local position1 = {cargo_wagon.left_top.x + 7, cargo_wagon.left_top.y + 1}
        local position2 = {cargo_wagon.right_bottom.x - 8, cargo_wagon.left_top.y + 1}
        local position3 = {cargo_wagon.left_top.x + 7, cargo_wagon.right_bottom.y - 2}
        local position4 = {cargo_wagon.right_bottom.x - 8, cargo_wagon.right_bottom.y - 2}

        if multiple_chests then
            local e1 =
                surface.create_entity(
                {
                    name = 'logistic-chest-requester',
                    position = position1,
                    force = 'neutral',
                    create_build_effect_smoke = false
                }
            )
            e1.destructible = false
            e1.minable = false

            local e2 =
                surface.create_entity(
                {
                    name = 'logistic-chest-requester',
                    position = {position1[1] - 1, position1[2]},
                    force = 'neutral',
                    create_build_effect_smoke = false
                }
            )
            e2.destructible = false
            e2.minable = false

            local e3 =
                surface.create_entity(
                {
                    name = 'logistic-chest-passive-provider',
                    position = position2,
                    force = 'neutral',
                    create_build_effect_smoke = false
                }
            )
            e3.destructible = false
            e3.minable = false

            local e4 =
                surface.create_entity(
                {
                    name = 'logistic-chest-passive-provider',
                    position = {position2[1] + 1, position2[2]},
                    force = 'neutral',
                    create_build_effect_smoke = false
                }
            )
            e4.destructible = false
            e4.minable = false

            local e5 =
                surface.create_entity(
                {
                    name = 'logistic-chest-requester',
                    position = position3,
                    force = 'neutral',
                    create_build_effect_smoke = false
                }
            )
            e5.destructible = false
            e5.minable = false

            local e6 =
                surface.create_entity(
                {
                    name = 'logistic-chest-requester',
                    position = {position3[1] - 1, position3[2]},
                    force = 'neutral',
                    create_build_effect_smoke = false
                }
            )
            e6.destructible = false
            e6.minable = false

            local e7 =
                surface.create_entity(
                {
                    name = 'logistic-chest-passive-provider',
                    position = position4,
                    force = 'neutral',
                    create_build_effect_smoke = false
                }
            )
            e7.destructible = false
            e7.minable = false

            local e8 =
                surface.create_entity(
                {
                    name = 'logistic-chest-passive-provider',
                    position = {position4[1] + 1, position4[2]},
                    force = 'neutral',
                    create_build_effect_smoke = false
                }
            )
            e8.destructible = false
            e8.minable = false

            wagon.transfer_entities = {e1, e3}
            wagon.transfer_entities = {e2, e4}
            wagon.transfer_entities = {e5, e7}
            wagon.transfer_entities = {e6, e8}
        else
            local e1 =
                surface.create_entity(
                {
                    name = 'logistic-chest-requester',
                    position = position1,
                    force = 'neutral',
                    create_build_effect_smoke = false
                }
            )
            e1.destructible = false
            e1.minable = false

            local e2 =
                surface.create_entity(
                {
                    name = 'logistic-chest-passive-provider',
                    position = position2,
                    force = 'neutral',
                    create_build_effect_smoke = false
                }
            )
            e2.destructible = false
            e2.minable = false
            wagon.transfer_entities = {e1, e2}
        end
        return
    end
end

function Public.create_wagon(icw, created_entity, delay_surface)
    if not validate_entity(created_entity) then
        return
    end

    local wagon_types = ICW.get('wagon_types')
    local wagon_areas = ICW.get('wagon_areas')

    if not created_entity.unit_number then
        return
    end
    if icw.trains[tonumber(created_entity.surface.name)] or icw.wagons[tonumber(created_entity.surface.name)] then
        return
    end
    if not wagon_types[created_entity.type] then
        return
    end
    local wagon_area = wagon_areas[created_entity.type]

    icw.wagons[created_entity.unit_number] = {
        entity = created_entity,
        area = {
            left_top = {x = wagon_area.left_top.x, y = wagon_area.left_top.y},
            right_bottom = {x = wagon_area.right_bottom.x, y = wagon_area.right_bottom.y}
        },
        doors = {},
        entity_count = 0
    }
    local wagon = icw.wagons[created_entity.unit_number]

    if not delay_surface then
        wagon.surface = Public.create_room_surface(icw, created_entity.unit_number)
        Public.create_wagon_room(icw, icw.wagons[created_entity.unit_number])
    end

    Public.request_reconstruction(icw)
    return wagon
end

function Public.add_wagon_entity_count(icw, added_entity)
    local wagon = get_wagon_for_entity(icw, added_entity)
    if not wagon then
        return
    end
    wagon.entity_count = wagon.entity_count + 1
    wagon.entity.minable = false
end

function Public.subtract_wagon_entity_count(icw, removed_entity)
    local wagon = get_wagon_for_entity(icw, removed_entity)
    if not wagon then
        return
    end
    wagon.entity_count = wagon.entity_count - 1
    if wagon.entity_count > 0 then
        return
    end
    wagon.entity.minable = true
end

function Public.use_cargo_wagon_door(icw, player, door)
    local player_data = get_player_data(icw, player)
    if player_data.state then
        player_data.state = player_data.state - 1
        if player_data.state == 0 then
            player_data.state = nil
        end
        return
    end

    if not door then
        return
    end
    if not door.valid then
        return
    end
    local doors = icw.doors
    local wagons = icw.wagons

    local wagon = false
    if doors[door.unit_number] then
        wagon = wagons[doors[door.unit_number]]
    end
    if wagons[door.unit_number] then
        wagon = wagons[door.unit_number]
    end
    if not wagon then
        return
    end

    player_data.fallback_surface = wagon.entity.surface.index
    player_data.fallback_position = {wagon.entity.position.x, wagon.entity.position.y}

    if wagon.entity.surface.name ~= player.surface.name then
        local surface = wagon.entity.surface
        local x_vector = (door.position.x / math.abs(door.position.x)) * 2
        local position = {wagon.entity.position.x + x_vector, wagon.entity.position.y}
        local surface_position = surface.find_non_colliding_position('character', position, 128, 0.5)
        if not position then
            return
        end
        if not surface_position then
            surface.request_to_generate_chunks({-20, 22}, 1)
            if player.character and player.character.valid and player.character.driving then
                if wagon.surface == player.surface then
                    player.character.driving = false
                end
            end
            return
        end
        if wagon.entity.type == 'locomotive' then
            player.teleport(surface_position, surface)
            player_data.state = 2
            player.driving = true
            Public.kill_minimap(player)
        else
            player.teleport(surface_position, surface)
            Public.kill_minimap(player)
        end
        player_data.surface = surface.index
    else
        local surface = wagon.surface
        local area = wagon.area
        local x_vector = door.position.x - player.position.x
        local position
        if x_vector > 0 then
            position = {area.left_top.x + 0.5, area.left_top.y + ((area.right_bottom.y - area.left_top.y) * 0.5)}
        else
            position = {area.right_bottom.x - 0.5, area.left_top.y + ((area.right_bottom.y - area.left_top.y) * 0.5)}
        end
        local p = surface.find_non_colliding_position('character', position, 128, 0.5)
        if p then
            player.teleport(p, surface)
        else
            player.teleport(position, surface)
        end
        player_data.surface = surface.index
    end
end

local function move_room_to_train(icw, train, wagon)
    if not wagon then
        return
    end
    train.wagons[#train.wagons + 1] = wagon.entity.unit_number

    local destination_area = {
        left_top = {x = wagon.area.left_top.x, y = train.top_y},
        right_bottom = {
            x = wagon.area.right_bottom.x,
            y = train.top_y + (wagon.area.right_bottom.y - wagon.area.left_top.y)
        }
    }

    train.top_y = destination_area.right_bottom.y

    if
        destination_area.left_top.x == wagon.area.left_top.x and destination_area.left_top.y == wagon.area.left_top.y and
            wagon.surface.name == train.surface.name
     then
        return
    end

    kick_players_out_of_vehicles(wagon)
    local player_positions = {}
    for _, e in pairs(wagon.surface.find_entities_filtered({name = 'character', area = wagon.area})) do
        local player = e.player
        if player then
            player_positions[player.index] = {
                player.position.x,
                player.position.y + (destination_area.left_top.y - wagon.area.left_top.y)
            }
            player.teleport({0, 0}, game.surfaces.nauvis)
        end
    end

    kill_wagon_doors(icw, wagon)

    wagon.surface.clone_area(
        {
            source_area = wagon.area,
            destination_area = destination_area,
            destination_surface = train.surface,
            clone_tiles = true,
            clone_entities = true,
            clone_decoratives = true,
            clear_destination_entities = true,
            clear_destination_decoratives = true,
            expand_map = true
        }
    )

    for player_index, position in pairs(player_positions) do
        local player = game.players[player_index]
        player.teleport(position, train.surface)
    end

    recreate_players()

    for _, tile in pairs(wagon.surface.find_tiles_filtered({area = wagon.area})) do
        wagon.surface.set_tiles({{name = 'out-of-map', position = tile.position}}, true)
    end
    wagon.entity.force.chart(wagon.surface, wagon.area)

    wagon.surface = train.surface
    wagon.area = destination_area
    wagon.transfer_entities = {}
    construct_wagon_doors(icw, wagon)

    local left_top_y = wagon.area.left_top.y
    for _, e in pairs(wagon.surface.find_entities_filtered({type = 'electric-pole', area = wagon.area})) do
        connect_power_pole(e, left_top_y)
    end

    for _, e in pairs(wagon.surface.find_entities_filtered({area = wagon.area, force = 'neutral'})) do
        if transfer_functions[e.name] then
            wagon.transfer_entities[#wagon.transfer_entities + 1] = e
        end
    end
end

function Public.construct_train(icw, carriages)
    local unit_number = carriages[1].unit_number

    if icw.trains[unit_number] then
        return
    end

    local train = {surface = Public.create_room_surface(icw, unit_number), wagons = {}, top_y = 0}
    icw.trains[unit_number] = train

    for k, carriage in pairs(carriages) do
        move_room_to_train(icw, train, icw.wagons[carriage.unit_number])
    end
end

function Public.reconstruct_all_trains(icw)
    icw.trains = {}
    for unit_number, wagon in pairs(icw.wagons) do
        if not validate_entity(wagon.entity) then
            icw.wagons[unit_number] = nil
            Public.request_reconstruction(icw)
            return
        end

        if not wagon.surface then
            wagon.surface = Public.create_room_surface(icw, unit_number)
            Public.create_wagon_room(icw, wagon)
        end

        local carriages = wagon.entity.train.carriages
        Public.construct_train(icw, carriages)
    end
    delete_empty_surfaces(icw)
end

function Public.item_transfer(icw)
    for _, wagon in pairs(icw.wagons) do
        if not validate_entity(wagon.entity) then
            return
        end
        if wagon.transfer_entities then
            for k, e in pairs(wagon.transfer_entities) do
                transfer_functions[e.name](wagon, e)
            end
        end
    end
end

function Public.draw_minimap(icw, player, surface, position)
    local element = player.gui.left.icw_map
    if not element then
        local player_data = get_player_data(icw, player)
        element =
            player.gui.left.add(
            {
                type = 'camera',
                name = 'icw_map',
                position = position,
                surface_index = surface.index,
                zoom = player_data.zoom,
                tooltip = 'LMB: Increase zoom level.\nRMB: Decrease zoom level.\nMMB: Toggle camera size.'
            }
        )
        element.style.margin = 1
        element.style.minimal_height = player_data.map_size
        element.style.minimal_width = player_data.map_size
        return
    end
    element.position = position
end

function Public.update_minimap(icw)
    for k, player in pairs(game.connected_players) do
        if player.character and player.character.valid then
            local wagon = get_wagon_for_entity(icw, player.character)
            if wagon then
                Public.draw_minimap(icw, player, wagon.entity.surface, wagon.entity.position)
            end
        end
    end
end

function Public.toggle_minimap(icw, event)
    local element = event.element
    if not element then
        return
    end
    if not element.valid then
        return
    end
    if element.name ~= 'icw_map' then
        return
    end
    local player = game.players[event.player_index]
    local player_data = get_player_data(icw, player)
    if event.button == defines.mouse_button_type.right then
        player_data.zoom = player_data.zoom - 0.07
        if player_data.zoom < 0.07 then
            player_data.zoom = 0.07
        end
        element.zoom = player_data.zoom
        return
    end
    if event.button == defines.mouse_button_type.left then
        player_data.zoom = player_data.zoom + 0.07
        if player_data.zoom > 2 then
            player_data.zoom = 2
        end
        element.zoom = player_data.zoom
        return
    end
    if event.button == defines.mouse_button_type.middle then
        player_data.map_size = player_data.map_size + 50
        if player_data.map_size > 650 then
            player_data.map_size = 250
        end
        element.style.minimal_height = player_data.map_size
        element.style.minimal_width = player_data.map_size
        element.style.maximal_height = player_data.map_size
        element.style.maximal_width = player_data.map_size
        return
    end
end

return Public
