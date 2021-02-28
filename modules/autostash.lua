--this adds a button that stashes/sorts your inventory into nearby chests in some kind of intelligent way - mewmew
-- modified by gerkiz

local Global = require 'utils.global'
local Event = require 'utils.event'
local BottomFrame = require 'comfy_panel.bottom_frame'
local math_floor = math.floor
local print_color = {r = 120, g = 255, b = 0}

local this = {
    floating_text_y_offsets = {},
    whitelist = {},
    insert_into_furnace = false,
    insert_into_wagon = false,
    bottom_button = false,
    small_radius = 2
}

local Public = {}

Global.register(
    this,
    function(t)
        this = t
    end
)

local function create_floaty_text(surface, position, name, count)
    if this.floating_text_y_offsets[position.x .. '_' .. position.y] then
        this.floating_text_y_offsets[position.x .. '_' .. position.y] = this.floating_text_y_offsets[position.x .. '_' .. position.y] - 0.5
    else
        this.floating_text_y_offsets[position.x .. '_' .. position.y] = 0
    end
    surface.create_entity(
        {
            name = 'flying-text',
            position = {
                position.x,
                position.y + this.floating_text_y_offsets[position.x .. '_' .. position.y]
            },
            text = {'', '-', count, ' ', game.item_prototypes[name].localised_name},
            color = {r = 255, g = 255, b = 255}
        }
    )
end

local function chest_is_valid(chest, inventory)
    if chest.type == 'cargo-wagon' then
        local t = {}
        local chest_inventory = chest.get_inventory(defines.inventory.cargo_wagon)
        inventory = inventory.get_contents()
        for index = 1, 40 do
            if chest_inventory.get_filter(index) ~= nil then
                local n = chest_inventory.get_filter(index)
                if inventory[n] then
                    if (t[n] and t[n].valid) then
                        t[n].count = inventory[n]
                    else
                        t[n] = {count = inventory[n], valid = true}
                    end
                end
            end
        end

        if not next(t) then
            return false, {}
        end

        return true, t
    end

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

    local i1 = chest.surface.find_entity('long-handed-inserter', {chest.position.x - 2, chest.position.y})
    if i1 then
        if i1.direction == 2 or i1.direction == 6 then
            return false
        end
    end
    local i2 = chest.surface.find_entity('long-handed-inserter', {chest.position.x + 2, chest.position.y})
    if i2 then
        if i2.direction == 2 or i2.direction == 6 then
            return false
        end
    end

    local i3 = chest.surface.find_entity('long-handed-inserter', {chest.position.x, chest.position.y - 2})
    if i3 then
        if i3.direction == 0 or i3.direction == 4 then
            return false
        end
    end
    local i4 = chest.surface.find_entity('long-handed-inserter', {chest.position.x, chest.position.y + 2})
    if i4 then
        if i4.direction == 0 or i4.direction == 4 then
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

local function get_nearby_chests(player, a, furnace, wagon)
    local r = player.force.character_reach_distance_bonus + 10
    local r_square = r * r
    local chests = {}
    local size_of_chests = 0
    local area = {{player.position.x - r, player.position.y - r}, {player.position.x + r, player.position.y + r}}

    area = a or area

    local container_type = {'container', 'logistic-container'}
    local containers = {}
    local i = 0

    if furnace then
        container_type = {'furnace'}
    end
    if wagon then
        container_type = {'cargo-wagon'}
    end

    for _, e in pairs(player.surface.find_entities_filtered({type = container_type, area = area, force = 'player'})) do
        if ((player.position.x - e.position.x) ^ 2 + (player.position.y - e.position.y) ^ 2) <= r_square then
            i = i + 1
            containers[i] = e
        end
    end
    if #containers <= 0 then
        if is_mod_loaded('Krastorio2') then
            for _, e in pairs(player.surface.find_entities_filtered({type = 'assembling-machine', area = area, force = 'player'})) do
                if ((player.position.x - e.position.x) ^ 2 + (player.position.y - e.position.y) ^ 2) <= r_square then
                    i = i + 1
                    containers[i] = e
                end
            end
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
    for name, _ in pairs(inventory.get_contents()) do
        local t = game.item_prototypes[name]
        if t and t.subgroup.name == item_subgroup then
            return true
        end
    end
    return false
end

local function insert_item_into_chest(player_inventory, chests, filtered_chests, name, count, furnace, wagon)
    local container = {
        ['container'] = true,
        ['logistic-container'] = true
    }
    local to_insert = math.floor(count / #chests)
    local variator = count % #chests

    --Attempt to store into furnaces.
    if furnace then
        for _, chest in pairs(chests) do
            local chest_inventory
            if chest.type == 'assembling-machine' then
                chest_inventory = chest.get_inventory(defines.inventory.assembling_machine_input)
            else
                chest_inventory = chest.get_inventory(defines.inventory.furnace_source)
            end
            local amount = to_insert
            if variator > 0 then
                amount = amount + 1
                variator = variator - 1
            end
            if amount <= 0 then
                return
            end
            if chest_inventory and (chest.type == 'furnace' or chest.type == 'assembling-machine') then
                if chest_inventory.can_insert({name = name, count = amount}) then
                    local inserted_count = chest_inventory.insert({name = name, count = amount})
                    player_inventory.remove({name = name, count = inserted_count})
                    create_floaty_text(chest.surface, chest.position, name, inserted_count)
                end
            end
        end

        for _, chest in pairs(chests) do
            if chest.type == 'furnace' or chest.type == 'assembling-machine' then
                local amount = to_insert
                if variator > 0 then
                    amount = amount + 1
                    variator = variator - 1
                end
                if amount <= 0 then
                    return
                end
                local chest_inventory = chest.get_inventory(defines.inventory.chest)
                if chest_inventory and chest_inventory.can_insert({name = name, count = amount}) then
                    local inserted_count = chest_inventory.insert({name = name, count = amount})
                    player_inventory.remove({name = name, count = inserted_count})
                    create_floaty_text(chest.surface, chest.position, name, inserted_count)
                end
            end
        end
    end

    -- Attempt to load filtered cargo wagon
    if wagon then
        for _, chest in pairs(chests) do
            if chest.type == 'cargo-wagon' then
                local chest_inventory = chest.get_inventory(defines.inventory.cargo_wagon)
                if chest_inventory and chest_inventory.can_insert({name = name, count = count}) then
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

    --Attempt to store in chests that already have the same item.
    for _, chest in pairs(chests) do
        if container[chest.type] then
            local chest_inventory = chest.get_inventory(defines.inventory.chest)

            if chest_inventory and chest_inventory.can_insert({name = name, count = count}) then
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
            if chest_inventory and chest_inventory.can_insert({name = name, count = count}) then
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
                if chest_inventory and chest_inventory.can_insert({name = name, count = count}) then
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
    local shift = event.shift
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

    local chests
    local r = this.small_radius
    local area = {{player.position.x - r, player.position.y - r}, {player.position.x + r, player.position.y + r}}
    if ctrl then
        if button == defines.mouse_button_type.right and this.insert_into_furnace then
            chests = get_nearby_chests(player, nil, true, false)
        end
    elseif shift then
        if button == defines.mouse_button_type.right and this.insert_into_wagon or button == defines.mouse_button_type.left and this.insert_into_wagon then
            chests = get_nearby_chests(player, area, false, true)
        end
    else
        chests = get_nearby_chests(player)
    end

    if not chests or not chests[1] then
        player.print('No valid nearby containers found.', print_color)
        return
    end
    local filtered_chests = {}
    local filtered_allowed
    for _, e in pairs(chests) do
        local is_valid, t = chest_is_valid(e, inventory)
        filtered_allowed = t
        if is_valid then
            filtered_chests[#filtered_chests + 1] = e
        end
    end

    this.floating_text_y_offsets = {}

    local hotbar_items = {}
    for i = 1, 100, 1 do
        local prototype = player.get_quick_bar_slot(i)
        if prototype then
            hotbar_items[prototype.name] = true
        end
    end

    for name, count in pairs(inventory.get_contents()) do
        local is_resource = this.whitelist[name]

        if not inventory.find_item_stack(name).grid and not hotbar_items[name] then
            if ctrl and this.insert_into_furnace then
                if button == defines.mouse_button_type.right then
                    if is_resource then
                        insert_item_into_chest(inventory, chests, filtered_chests, name, count, true, false)
                    end
                end
            elseif shift and this.insert_into_wagon then
                if button == defines.mouse_button_type.right then
                    if is_resource then
                        insert_item_into_chest(inventory, chests, filtered_chests, name, count, false, true)
                    end
                end
                if button == defines.mouse_button_type.left then
                    if filtered_allowed and filtered_allowed[name] and filtered_allowed[name].valid then
                        local c = filtered_allowed[name].count
                        insert_item_into_chest(inventory, chests, filtered_chests, name, c, false, true)
                    end
                end
            elseif button == defines.mouse_button_type.right then
                if is_resource then
                    insert_item_into_chest(inventory, chests, filtered_chests, name, count)
                end
            elseif button == defines.mouse_button_type.left then
                insert_item_into_chest(inventory, chests, filtered_chests, name, count)
            end
        end
    end

    local c = this.floating_text_y_offsets
    for k, _ in pairs(c) do
        this.floating_text_y_offsets[k] = nil
    end
end

local function create_gui_button(player)
    if player.gui.top.auto_stash then
        return
    end
    local tooltip
    if this.insert_into_furnace and this.insert_into_wagon then
        tooltip =
            'Sort your inventory into nearby chests.\nLMB: Everything, excluding quickbar items.\nRMB: Only ores to nearby chests, excluding quickbar items.\nCTRL+RMB: Fill nearby furnaces.\nSHIFT+LMB: Everything onto filtered slots to wagon.\nSHIFT+RMB: Only ores to wagon'
    elseif this.insert_into_furnace then
        tooltip =
            'Sort your inventory into nearby chests.\nLMB: Everything, excluding quickbar items.\nRMB: Only ores to nearby chests, excluding quickbar items.\nCTRL+RMB: Fill nearby furnaces.'
    elseif this.insert_into_wagon then
        tooltip =
            'Sort your inventory into nearby chests.\nLMB: Everything, excluding quickbar items.\nRMB: Only ores to nearby chests, excluding quickbar items.\nSHIFT+LMB: Everything onto filtered slots to wagon.\nSHIFT+RMB: Only ores to wagon'
    else
        tooltip = 'Sort your inventory into nearby chests.\nLMB: Everything, excluding quickbar items.\nRMB: Only ores to nearby chests, excluding quickbar items.'
    end
    if this.bottom_button then
        local data = BottomFrame.get('bottom_quickbar_button')
        -- save it for later use
        data.tooltip = tooltip
        data.sprite = 'item/wooden-chest'

        if data[player.index] then
            data = data[player.index]
            if data.frame and data.frame.valid then
                data.frame.sprite = 'item/wooden-chest'
                data.frame.tooltip = tooltip
            end
        end
    else
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
        b.style.minimal_height = 40
        b.style.maximal_width = 40
        b.style.minimal_width = 38
        b.style.maximal_height = 38
        b.style.padding = 1
        b.style.margin = 0
    end
end

local function do_whitelist()
    local resources = game.entity_prototypes
    this.whitelist = {}
    for k, _ in pairs(resources) do
        if resources[k] and resources[k].type == 'resource' and resources[k].mineable_properties then
            if resources[k].mineable_properties.products[1] then
                local r = resources[k].mineable_properties.products[1].name
                this.whitelist[r] = true
            elseif resources[k].mineable_properties.products[2] then
                local r = resources[k].mineable_properties.products[2].name
                this.whitelist[r] = true
            end
        end
    end
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
    local player = game.players[event.player_index]
    local name = 'auto_stash'
    if this.bottom_button then
        local data = BottomFrame.get('bottom_quickbar_button')
        if data[player.index] then
            data = data[player.index]
            name = data.name
        end
    end

    if event.element.name == name then
        auto_stash(player, event)
    end
end

function Public.insert_into_furnace(value)
    if value then
        this.insert_into_furnace = value
    else
        this.insert_into_furnace = false
    end
end

function Public.insert_into_wagon(value)
    if value then
        this.insert_into_wagon = value
    else
        this.insert_into_wagon = false
    end
end

function Public.bottom_button(value)
    if value then
        this.bottom_button = value
    else
        this.bottom_button = false
    end
end

Event.on_configuration_changed = function()
    do_whitelist()
    log('[Autostash] on_configuration_changed was called, rebuilding resource whitelist.')
end

Event.on_init(do_whitelist)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_gui_click, on_gui_click)

return Public
