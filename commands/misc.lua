local Session = require 'utils.datastore.session_data'
local Modifiers = require 'player_modifiers'
local Server = require 'utils.server'
local Color = require 'utils.color_presets'
local Event = require 'utils.event'
local Global = require 'utils.global'

local this = {
    players = {},
    activate_custom_buttons = false,
    bottom_right = false,
    bottom_quickbar_button = {}
}

Global.register(
    this,
    function(t)
        this = t
    end
)

local Public = {}

commands.add_command(
    'spaghetti',
    'Does spaghett.',
    function(cmd)
        local player = game.player
        local param = tostring(cmd.parameter)
        local force = game.forces['player']

        if not (player and player.valid) then
            return
        end
        local p = player.print
        if not player.admin then
            p("[ERROR] You're not admin!", Color.fail)
            return
        end

        if param == nil then
            player.print('[ERROR] Arguments are true/false', Color.yellow)
            return
        end
        if param == 'true' then
            if not this.spaghetti_are_you_sure then
                this.spaghetti_are_you_sure = true
                player.print('Spaghetti is not enabled, run this command again to enable spaghett', Color.yellow)
                return
            end
            if this.spaghetti_enabled then
                player.print('Spaghetti is already enabled.', Color.yellow)
                return
            end
            game.print('The world has been spaghettified!', Color.success)
            force.technologies['logistic-system'].enabled = false
            force.technologies['construction-robotics'].enabled = false
            force.technologies['logistic-robotics'].enabled = false
            force.technologies['robotics'].enabled = false
            force.technologies['personal-roboport-equipment'].enabled = false
            force.technologies['personal-roboport-mk2-equipment'].enabled = false
            force.technologies['character-logistic-trash-slots-1'].enabled = false
            force.technologies['character-logistic-trash-slots-2'].enabled = false
            force.technologies['auto-character-logistic-trash-slots'].enabled = false
            force.technologies['worker-robots-storage-1'].enabled = false
            force.technologies['worker-robots-storage-2'].enabled = false
            force.technologies['worker-robots-storage-3'].enabled = false
            force.technologies['character-logistic-slots-1'].enabled = false
            force.technologies['character-logistic-slots-2'].enabled = false
            force.technologies['character-logistic-slots-3'].enabled = false
            force.technologies['character-logistic-slots-4'].enabled = false
            force.technologies['character-logistic-slots-5'].enabled = false
            force.technologies['character-logistic-slots-6'].enabled = false
            force.technologies['worker-robots-speed-1'].enabled = false
            force.technologies['worker-robots-speed-2'].enabled = false
            force.technologies['worker-robots-speed-3'].enabled = false
            force.technologies['worker-robots-speed-4'].enabled = false
            force.technologies['worker-robots-speed-5'].enabled = false
            force.technologies['worker-robots-speed-6'].enabled = false
            this.spaghetti_enabled = true
        elseif param == 'false' then
            if this.spaghetti_enabled == false or this.spaghetti_enabled == nil then
                player.print('Spaghetti is already disabled.', Color.yellow)
                return
            end
            game.print('The world is no longer spaghett!', Color.yellow)
            force.technologies['logistic-system'].enabled = true
            force.technologies['construction-robotics'].enabled = true
            force.technologies['logistic-robotics'].enabled = true
            force.technologies['robotics'].enabled = true
            force.technologies['personal-roboport-equipment'].enabled = true
            force.technologies['personal-roboport-mk2-equipment'].enabled = true
            force.technologies['character-logistic-trash-slots-1'].enabled = true
            force.technologies['character-logistic-trash-slots-2'].enabled = true
            force.technologies['auto-character-logistic-trash-slots'].enabled = true
            force.technologies['worker-robots-storage-1'].enabled = true
            force.technologies['worker-robots-storage-2'].enabled = true
            force.technologies['worker-robots-storage-3'].enabled = true
            force.technologies['character-logistic-slots-1'].enabled = true
            force.technologies['character-logistic-slots-2'].enabled = true
            force.technologies['character-logistic-slots-3'].enabled = true
            force.technologies['character-logistic-slots-4'].enabled = true
            force.technologies['character-logistic-slots-5'].enabled = true
            force.technologies['character-logistic-slots-6'].enabled = true
            force.technologies['worker-robots-speed-1'].enabled = true
            force.technologies['worker-robots-speed-2'].enabled = true
            force.technologies['worker-robots-speed-3'].enabled = true
            force.technologies['worker-robots-speed-4'].enabled = true
            force.technologies['worker-robots-speed-5'].enabled = true
            force.technologies['worker-robots-speed-6'].enabled = true
            this.spaghetti_enabled = false
        end
    end
)

commands.add_command(
    'generate_map',
    'Pregenerates map.',
    function(cmd)
        local player = game.player
        local param = tonumber(cmd.parameter)

        if not (player and player.valid) then
            return
        end

        local p = player.print
        if not player.admin then
            p("[ERROR] You're not admin!", Color.fail)
            return
        end
        if param == nil then
            player.print('[ERROR] Must specify radius!', Color.fail)
            return
        end
        if param > 50 then
            player.print('[ERROR] Value is too big.', Color.fail)
            return
        end

        if not this.generate_map then
            this.generate_map = true
            player.print('[WARNING] This command will make the server LAG, run this command again if you really want to do this!', Color.yellow)
            return
        end
        local radius = param
        local surface = game.players[1].surface
        if surface.is_chunk_generated({radius, radius}) then
            game.print('Map generation done!', Color.success)
            this.generate_map = nil
            return
        end
        surface.request_to_generate_chunks({0, 0}, radius)
        surface.force_generate_chunk_requests()
        for _, pl in pairs(game.connected_players) do
            pl.play_sound {path = 'utility/new_objective', volume_modifier = 1}
        end
        game.print('Map generation done!', Color.success)
        this.generate_map = nil
    end
)

commands.add_command(
    'dump_layout',
    'Dump the current map-layout.',
    function()
        local player = game.player

        if not (player and player.valid) then
            return
        end

        local p = player.print
        if not player.admin then
            p("[ERROR] You're not admin!", Color.warning)
            return
        end
        if not this.dump_layout then
            this.dump_layout = true
            player.print('[WARNING] This command will make the server LAG, run this command again if you really want to do this!', Color.yellow)
            return
        end
        local surface = game.players[1].surface
        game.write_file('layout.lua', '', false)

        local area = {
            left_top = {x = 0, y = 0},
            right_bottom = {x = 32, y = 32}
        }

        local entities = surface.find_entities_filtered {area = area}
        local tiles = surface.find_tiles_filtered {area = area}

        for _, e in pairs(entities) do
            local str = '{position = {x = ' .. e.position.x
            str = str .. ', y = '
            str = str .. e.position.y
            str = str .. '}, name = "'
            str = str .. e.name
            str = str .. '", direction = '
            str = str .. tostring(e.direction)
            str = str .. ', force = "'
            str = str .. e.force.name
            str = str .. '"},'
            if e.name ~= 'character' then
                game.write_file('layout.lua', str .. '\n', true)
            end
        end

        game.write_file('layout.lua', '\n', true)
        game.write_file('layout.lua', '\n', true)
        game.write_file('layout.lua', 'Tiles: \n', true)

        for _, t in pairs(tiles) do
            local str = '{position = {x = ' .. t.position.x
            str = str .. ', y = '
            str = str .. t.position.y
            str = str .. '}, name = "'
            str = str .. t.name
            str = str .. '"},'
            game.write_file('layout.lua', str .. '\n', true)
            player.print('Dumped layout as file: layout.lua', Color.success)
        end
        this.dump_layout = false
    end
)

commands.add_command(
    'creative',
    'Enables creative_mode.',
    function()
        local player = game.player
        if not (player and player.valid) then
            return
        end

        local p = player.print
        if not player.admin then
            p("[ERROR] You're not admin!", Color.fail)
            return
        end
        if not this.creative_are_you_sure then
            this.creative_are_you_sure = true
            player.print('[WARNING] This command will enable creative/cheat-mode for all connected players, run this command again if you really want to do this!', Color.yellow)
            return
        end
        if this.creative_enabled then
            player.print('[ERROR] Creative/cheat-mode is already active!', Color.fail)
            return
        end

        game.print('[CREATIVE] ' .. player.name .. ' has activated creative-mode!', Color.warning)
        Server.to_discord_bold(table.concat {'[Creative] ' .. player.name .. ' has activated creative-mode!'})

        for k, v in pairs(game.connected_players) do
            if v.character ~= nil then
                if v.get_inventory(defines.inventory.character_armor) then
                    v.get_inventory(defines.inventory.character_armor).clear()
                end
                v.insert {name = 'power-armor-mk2', count = 1}
                local p_armor = v.get_inventory(5)[1].grid
                if p_armor and p_armor.valid then
                    p_armor.put({name = 'fusion-reactor-equipment'})
                    p_armor.put({name = 'fusion-reactor-equipment'})
                    p_armor.put({name = 'fusion-reactor-equipment'})
                    p_armor.put({name = 'exoskeleton-equipment'})
                    p_armor.put({name = 'exoskeleton-equipment'})
                    p_armor.put({name = 'exoskeleton-equipment'})
                    p_armor.put({name = 'energy-shield-mk2-equipment'})
                    p_armor.put({name = 'energy-shield-mk2-equipment'})
                    p_armor.put({name = 'energy-shield-mk2-equipment'})
                    p_armor.put({name = 'energy-shield-mk2-equipment'})
                    p_armor.put({name = 'personal-roboport-mk2-equipment'})
                    p_armor.put({name = 'night-vision-equipment'})
                    p_armor.put({name = 'battery-mk2-equipment'})
                    p_armor.put({name = 'battery-mk2-equipment'})
                end
                local item = game.item_prototypes
                local i = 0
                local p_modifer = Modifiers.get_table()
                for _k, _v in pairs(item) do
                    i = i + 1
                    if _k and _v.type ~= 'mining-tool' then
                        p_modifer[player.index].character_inventory_slots_bonus['creative'] = tonumber(i)
                        p_modifer[player.index].character_mining_speed_modifier['creative'] = 50
                        p_modifer[player.index].character_health_bonus['creative'] = 2000
                        p_modifer[player.index].character_crafting_speed_modifier['creative'] = 50
                        v.character_inventory_slots_bonus = p_modifer[player.index].character_inventory_slots_bonus['creative']
                        v.insert {name = _k, count = _v.stack_size}
                        v.print('[CREATIVE] Inserted all base items.', Color.success)
                        Modifiers.update_player_modifiers(player)
                    end
                end
                this.creative_enabled = true
            end
        end
    end
)

commands.add_command(
    'delete-uncharted-chunks',
    'Deletes all chunks that are not charted. Can reduce filesize of the savegame. May be unsafe to use in certain custom maps.',
    function()
        local player = game.player
        if not (player and player.valid) then
            return
        end

        local p = player.print
        if not player.admin then
            p("[ERROR] You're not admin!", Color.fail)
            return
        end

        local forces = {}
        for _, force in pairs(game.forces) do
            if force.index == 1 or force.index > 3 then
                table.insert(forces, force)
            end
        end

        local is_charted
        local count = 0
        for _, surface in pairs(game.surfaces) do
            for chunk in surface.get_chunks() do
                is_charted = false
                for _, force in pairs(forces) do
                    if force.is_chunk_charted(surface, {chunk.x, chunk.y}) then
                        is_charted = true
                        break
                    end
                end
                if not is_charted then
                    surface.delete_chunk({chunk.x, chunk.y})
                    count = count + 1
                end
            end
        end

        local message = player.name .. ' deleted ' .. count .. ' uncharted chunks!'
        game.print(message, Color.warning)
        Server.to_discord_bold(table.concat {message})
    end
)

local function clear_corpses(cmd)
    local player
    local trusted = Session.get_trusted_table()
    local param
    if cmd and cmd.player then
        player = cmd.player
        param = 50
    elseif cmd then
        player = game.player
        param = tonumber(cmd.parameter)
    end

    if not player or not player.valid then
        return
    end
    local p = player.print
    if not trusted[player.name] then
        if not player.admin then
            p('[ERROR] Only admins and trusted weebs are allowed to run this command!', Color.fail)
            return
        end
    end
    if param == nil then
        player.print('[ERROR] Must specify radius!', Color.fail)
        return
    end
    if param < 0 then
        player.print('[ERROR] Value is too low.', Color.fail)
        return
    end
    if param > 500 then
        player.print('[ERROR] Value is too big.', Color.fail)
        return
    end
    local pos = player.position

    local i = 0

    local radius = {{x = (pos.x + -param), y = (pos.y + -param)}, {x = (pos.x + param), y = (pos.y + param)}}

    for _, entity in pairs(player.surface.find_entities_filtered {area = radius, type = 'corpse'}) do
        if entity.corpse_expires then
            entity.destroy()
            i = i + 1
        end
    end
    local corpse = 'corpse'

    if i > 1 then
        corpse = 'corpses'
    end
    if i == 0 then
        player.print('[color=blue][Cleaner][/color] No corpses to clear!', Color.warning)
    else
        player.print('[color=blue][Cleaner][/color] Cleared ' .. i .. ' ' .. corpse .. '!', Color.success)
    end
end

commands.add_command(
    'clear-corpses',
    'Clears all the biter corpses..',
    function(cmd)
        clear_corpses(cmd)
    end
)

local on_player_joined_game = function(player)
    if this.creative_enabled then
        if not this.players[player.index] then
            Public.insert_all_items(player)
            this.players[player.index] = true
        end
    end
end

function Public.insert_all_items(player)
    if this.creative_enabled then
        if not this.players[player.index] then
            if player.character ~= nil then
                if player.get_inventory(defines.inventory.character_armor) then
                    player.get_inventory(defines.inventory.character_armor).clear()
                end
                player.insert {name = 'power-armor-mk2', count = 1}
                local p_armor = player.get_inventory(5)[1].grid
                if p_armor and p_armor.valid then
                    p_armor.put({name = 'fusion-reactor-equipment'})
                    p_armor.put({name = 'fusion-reactor-equipment'})
                    p_armor.put({name = 'fusion-reactor-equipment'})
                    p_armor.put({name = 'exoskeleton-equipment'})
                    p_armor.put({name = 'exoskeleton-equipment'})
                    p_armor.put({name = 'exoskeleton-equipment'})
                    p_armor.put({name = 'energy-shield-mk2-equipment'})
                    p_armor.put({name = 'energy-shield-mk2-equipment'})
                    p_armor.put({name = 'energy-shield-mk2-equipment'})
                    p_armor.put({name = 'energy-shield-mk2-equipment'})
                    p_armor.put({name = 'personal-roboport-mk2-equipment'})
                    p_armor.put({name = 'night-vision-equipment'})
                    p_armor.put({name = 'battery-mk2-equipment'})
                    p_armor.put({name = 'battery-mk2-equipment'})
                end
                local item = game.item_prototypes
                local i = 0
                local p_modifer = Modifiers.get_table()
                for _k, _v in pairs(item) do
                    i = i + 1
                    if _k and _v.type ~= 'mining-tool' then
                        p_modifer[player.index].character_inventory_slots_bonus['creative'] = tonumber(i)
                        p_modifer[player.index].character_mining_speed_modifier['creative'] = 50
                        p_modifer[player.index].character_health_bonus['creative'] = 2000
                        p_modifer[player.index].character_crafting_speed_modifier['creative'] = 50
                        player.character_inventory_slots_bonus = p_modifer[player.index].character_inventory_slots_bonus['creative']
                        player.insert {name = _k, count = _v.stack_size}
                        player.print('[CREATIVE] Inserted all base items.', Color.success)
                        Modifiers.update_player_modifiers(player)
                    end
                end
            end
        end
    end
end

function Public.get(key)
    if key then
        return this[key]
    else
        return this
    end
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

Event.on_init(
    function()
        this.creative_are_you_sure = false
        this.creative_enabled = false
        this.spaghetti_are_you_sure = false
        this.spaghetti_enabled = false
    end
)

function Public.reset()
    this.creative_are_you_sure = false
    this.creative_enabled = false
    this.spaghetti_are_you_sure = false
    this.spaghetti_enabled = false
    this.players = {}
end

Event.add(
    defines.events.on_player_joined_game,
    function(event)
        local player = game.players[event.player_index]
        on_player_joined_game(player)
    end
)

Public.clear_corpses = clear_corpses

return Public
