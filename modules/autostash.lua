--this adds a button that stashes/sorts your inventory into nearby chests in some kind of intelligent way - mewmew
-- modified by gerkiz

local Global = require 'utils.global'

local math_floor = math.floor
local print_color = {r = 120, g = 255, b = 0}

local autostash = {
    floating_text_y_offsets = {},
    insert_into_furnace = false
}

local Public = {}

Global.register(
    autostash,
    function(t)
        autostash = t
    end
)

local ore_names = {
    ['coal'] = true,
    ['stone'] = true,
    ['iron-ore'] = true,
    ['copper-ore'] = true
}

local function create_floaty_text(surface, position, name, count)
    if autostash.floating_text_y_offsets[position.x .. '_' .. position.y] then
        autostash.floating_text_y_offsets[position.x .. '_' .. position.y] =
            autostash.floating_text_y_offsets[position.x .. '_' .. position.y] - 0.5
    else
        autostash.floating_text_y_offsets[position.x .. '_' .. position.y] = 0
    end
    surface.create_entity(
        {
            name = 'flying-text',
            position = {
                position.x,
                position.y + autostash.floating_text_y_offsets[position.x .. '_' .. position.y]
            },
            text = {'', '-', count, ' ', game.item_prototypes[name].localised_name},
            color = {r = 255, g = 255, b = 255}
        }
    )
end

local function chest_is_valid(chest)
    for _, e in pairs(
        chest.surface.find_entities_filtered(
            {
                type = {'inserter', 'loader'},
                area = {{chest.position.x - 1, chest.position.y - 1}, {chest.position.x + 1, chest.position.y + 1}}
            }
        )
    ) do
        if e.name ~= 'long-handed-inserter' then
            if e.position.x == chest.position.x then
                if e.direction == 0 or e.direction == 4 then
                    return false
                end
            end
            if e.position.y == chest.position.y then
                if e.direction == 2 or e.direction == 6 then
                    return false
                end
            end
        end
    end

    local inserter = chest.surface.find_entity('long-handed-inserter', {chest.position.x - 2, chest.position.y})
    if inserter then
        if inserter.direction == 2 or inserter.direction == 6 then
            return false
        end
    end
    local inserter = chest.surface.find_entity('long-handed-inserter', {chest.position.x + 2, chest.position.y})
    if inserter then
        if inserter.direction == 2 or inserter.direction == 6 then
            return false
        end
    end

    local inserter = chest.surface.find_entity('long-handed-inserter', {chest.position.x, chest.position.y - 2})
    if inserter then
        if inserter.direction == 0 or inserter.direction == 4 then
            return false
        end
    end
    local inserter = chest.surface.find_entity('long-handed-inserter', {chest.position.x, chest.position.y + 2})
    if inserter then
        if inserter.direction == 0 or inserter.direction == 4 then
            return false
        end
    end

    return true
end

local function sort_entities_by_distance(position, entities)
    local t = {}
    local distance
    local index
    local size_of_entities = #entities
    if size_of_entities < 2 then
        return
    end

    for _, entity in pairs(entities) do
        distance = (entity.position.x - position.x) ^ 2 + (entity.position.y - position.y) ^ 2
        index = math_floor(distance) + 1
        if not t[index] then
            t[index] = {}
        end
        table.insert(t[index], entity)
    end

    local i = 0
    for _, range in pairs(t) do
        for _, entity in pairs(range) do
            i = i + 1
            entities[i] = entity
        end
    end
end

local function get_nearby_chests(player)
    local r = player.force.character_reach_distance_bonus + 10
    local r_square = r * r
    local chests = {}
    local size_of_chests = 0
    local area = {{player.position.x - r, player.position.y - r}, {player.position.x + r, player.position.y + r}}

    local type

    local containers = {}
    local i = 0
    if autostash.insert_into_furnace then
        type = {'furnace', 'container', 'logistic-container'}
    else
        type = {'container', 'logistic-container'}
    end
    for _, e in pairs(player.surface.find_entities_filtered({type = type, area = area})) do
        if ((player.position.x - e.position.x) ^ 2 + (player.position.y - e.position.y) ^ 2) <= r_square then
            i = i + 1
            containers[i] = e
        end
    end
    sort_entities_by_distance(player.position, containers)
    for _, entity in pairs(containers) do
        size_of_chests = size_of_chests + 1
        chests[size_of_chests] = entity
    end

    return chests
end

local function does_inventory_contain_item_type(inventory, item_subgroup)
    for name, count in pairs(inventory.get_contents()) do
        if game.item_prototypes[name].subgroup.name == item_subgroup then
            return true
        end
    end
    return false
end

local function insert_item_into_chest(player_inventory, chests, filtered_chests, name, count, furnace)
    local container = {
        ['container'] = true,
        ['logistic-container'] = true
    }

    local to_insert = math.floor(count / #chests)
    local variator = count % #chests

    --Attempt to store into furnaces.
    if furnace then
        for _, chest in pairs(chests) do
            local chest_inventory = chest.get_inventory(defines.inventory.furnace_source)
            if chest_inventory and chest.type == 'furnace' then
                if chest_inventory.can_insert({name = name, count = count}) then
                    local inserted_count = chest_inventory.insert({name = name, count = count})
                    player_inventory.remove({name = name, count = inserted_count})
                    create_floaty_text(chest.surface, chest.position, name, inserted_count)
                    count = count - inserted_count
                    if count <= 0 then
                        return
                    end
                end
            end
        end

        for _, chest in pairs(chests) do
            if chest.type == 'furnace' then
                local amount = to_insert
                if variator > 0 then
                    amount = amount + 1
                    variator = variator - 1
                end
                if amount <= 0 then
                    return
                end
                local chest_inventory = chest.get_inventory(defines.inventory.chest)
                if chest_inventory.can_insert({name = name, count = amount}) then
                    local inserted_count = chest_inventory.insert({name = name, count = amount})
                    player_inventory.remove({name = name, count = inserted_count})
                    create_floaty_text(chest.surface, chest.position, name, inserted_count)
                end
            end
        end
    end

    --Attempt to store in chests that already have the same item.
    for _, chest in pairs(chests) do
        if container[chest.type] then
            local chest_inventory = chest.get_inventory(defines.inventory.chest)
            if chest_inventory.can_insert({name = name, count = count}) then
                if chest_inventory.find_item_stack(name) then
                    local inserted_count = chest_inventory.insert({name = name, count = count})

                    player_inventory.remove({name = name, count = inserted_count})
                    create_floaty_text(chest.surface, chest.position, name, inserted_count)
                    count = count - inserted_count
                    if count <= 0 then
                        return
                    end
                end
            end
        end
    end

    --Attempt to store in empty chests.
    for _, chest in pairs(filtered_chests) do
        if container[chest.type] then
            local chest_inventory = chest.get_inventory(defines.inventory.chest)
            if chest_inventory.can_insert({name = name, count = count}) then
                if chest_inventory.is_empty() then
                    local inserted_count = chest_inventory.insert({name = name, count = count})
                    player_inventory.remove({name = name, count = inserted_count})
                    create_floaty_text(chest.surface, chest.position, name, inserted_count)
                    count = count - inserted_count
                    if count <= 0 then
                        return
                    end
                end
            end
        end
    end

    --Attempt to store in chests with same item subgroup.
    local item_subgroup = game.item_prototypes[name].subgroup.name
    if item_subgroup then
        for _, chest in pairs(filtered_chests) do
            if container[chest.type] then
                local chest_inventory = chest.get_inventory(defines.inventory.chest)
                if chest_inventory.can_insert({name = name, count = count}) then
                    if does_inventory_contain_item_type(chest_inventory, item_subgroup) then
                        local inserted_count = chest_inventory.insert({name = name, count = count})
                        player_inventory.remove({name = name, count = inserted_count})
                        create_floaty_text(chest.surface, chest.position, name, inserted_count)
                        count = count - inserted_count
                        if count <= 0 then
                            return
                        end
                    end
                end
            end
        end
    end

    --Attempt to store in mixed chests.
    for _, chest in pairs(filtered_chests) do
        if container[chest.type] then
            local chest_inventory = chest.get_inventory(defines.inventory.chest)
            if chest_inventory.can_insert({name = name, count = count}) then
                local inserted_count = chest_inventory.insert({name = name, count = count})
                player_inventory.remove({name = name, count = inserted_count})
                create_floaty_text(chest.surface, chest.position, name, inserted_count)
                count = count - inserted_count
                if count <= 0 then
                    return
                end
            end
        end
    end
end

local function auto_stash(player, event)
    local button = event.button
    local ctrl = event.control
    if not player.character then
        player.print('It seems that you are not in the realm of the living.', print_color)
        return
    end
    if not player.character.valid then
        player.print('It seems that you are not in the realm of the living.', print_color)
        return
    end
    local inventory = player.get_inventory(defines.inventory.character_main)
    if inventory.is_empty() then
        player.print('Inventory is empty.', print_color)
        return
    end
    local chests = get_nearby_chests(player)
    if not chests[1] then
        player.print('No valid nearby containers found.', print_color)
        return
    end

    local filtered_chests = {}
    for _, e in pairs(chests) do
        if chest_is_valid(e) then
            filtered_chests[#filtered_chests + 1] = e
        end
    end

    autostash.floating_text_y_offsets = {}

    local hotbar_items = {}
    for i = 1, 100, 1 do
        local prototype = player.get_quick_bar_slot(i)
        if prototype then
            hotbar_items[prototype.name] = true
        end
    end

    for name, count in pairs(inventory.get_contents()) do
        local is_ore = ore_names[name]
        local is_resource = game.entity_prototypes[name] and game.entity_prototypes[name].type == 'resource'

        if not inventory.find_item_stack(name).grid and not hotbar_items[name] then
            if ctrl then
                if is_ore and autostash.insert_into_furnace then
                    insert_item_into_chest(inventory, chests, filtered_chests, name, count, true)
                end
            elseif button == defines.mouse_button_type.right then
                if is_resource or is_ore then
                    insert_item_into_chest(inventory, chests, filtered_chests, name, count)
                end
            elseif button == defines.mouse_button_type.left then
                insert_item_into_chest(inventory, chests, filtered_chests, name, count)
            end
        end
    end

    local c = autostash.floating_text_y_offsets
    for k, _ in pairs(c) do
        autostash.floating_text_y_offsets[k] = nil
    end
end

local function create_gui_button(player)
    if player.gui.top.auto_stash then
        return
    end
    local tooltip
    if autostash.insert_into_furnace then
        tooltip =
            'Sort your inventory into nearby chests.\nLMB: Everything, excluding quickbar items.\nRMB: Only ores.\nCTRL+LMB: Ores into furnaces.'
    else
        tooltip = 'Sort your inventory into nearby chests.\nLMB: Everything, excluding quickbar items.\nRMB: Only ores.'
    end
    local b =
        player.gui.top.add(
        {
            type = 'sprite-button',
            sprite = 'item/wooden-chest',
            name = 'auto_stash',
            tooltip = tooltip
        }
    )
    b.style.font_color = {r = 0.11, g = 0.8, b = 0.44}
    b.style.font = 'heading-1'
    b.style.minimal_height = 38
    b.style.minimal_width = 38
    b.style.maximal_height = 38
    b.style.maximal_width = 38
    b.style.padding = 1
    b.style.margin = 0
end

local function on_player_joined_game(event)
    create_gui_button(game.players[event.player_index])
end

local function on_gui_click(event)
    if not event.element then
        return
    end
    if not event.element.valid then
        return
    end
    if event.element.name == 'auto_stash' then
        auto_stash(game.players[event.player_index], event)
    end
end

function Public.insert_into_furnace(value)
    if value then
        autostash.insert_into_furnace = value or false
    end
end

local event = require 'utils.event'
event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_gui_click, on_gui_click)

return Public
