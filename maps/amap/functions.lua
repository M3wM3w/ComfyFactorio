local Token = require 'utils.token'
local Task = require 'utils.task'
local Event = require 'utils.event'
local Global = require 'utils.global'
local Alert = require 'utils.alert'
local WPT = require 'maps.amap.table'
local WD = require 'modules.wave_defense.table'
local math2d = require 'math2d'
local Commands = require 'commands.misc'
local RPG = require 'modules.rpg.table'

local this = {
    power_sources = {index = 1},
    refill_turrets = {index = 1},
    magic_crafters = {index = 1},
    magic_fluid_crafters = {index = 1},
    art_table = {index = 1},
    surface_cleared = false
}

local starting_items = {['pistol'] = 1, ['firearm-magazine'] = 16,  ['wood'] = 16}

Global.register(
    this,
    function(t)
        this = t
    end
)

local Public = {}

local random = math.random
local floor = math.floor
local remove = table.remove
local sqrt = math.sqrt
local magic_crafters_per_tick = 3
local magic_fluid_crafters_per_tick = 8
local tile_damage = 50

local artillery_target_entities = {
    'character',
    'tank',
    'car',
    'radar',
    'lab',
    'furnace',
    'locomotive',
    'cargo-wagon',
    'fluid-wagon',
    'artillery-wagon',
    'artillery-turret',
    'laser-turret',
    'gun-turret',
    'flamethrower-turret',
    'silo',
    'spidertron'
}

function Public.get_player_data(player, remove_user_data)
    local players = WPT.get('players')
    if remove_user_data then
        if players[player.index] then
            players[player.index] = nil
        end
    end
    if not players[player.index] then
        players[player.index] = {}
    end
    return players[player.index]
end

local get_player_data = Public.get_player_data

local function debug_str(msg)
    local debug = WPT.get('debug')
    if not debug then
        return
    end
    print('Mtn: ' .. msg)
end

local function show_text(msg, pos, color, surface)
    if color == nil then
        surface.create_entity({name = 'flying-text', position = pos, text = msg})
    else
        surface.create_entity({name = 'flying-text', position = pos, text = msg, color = color})
    end
end

local function fast_remove(tbl, index)
    local count = #tbl
    if index > count then
        return
    elseif index < count then
        tbl[index] = tbl[count]
    end

    tbl[count] = nil
end

local function do_refill_turrets()
    local refill_turrets = this.refill_turrets
    local index = refill_turrets.index

    if index > #refill_turrets then
        refill_turrets.index = 1
        return
    end

    local turret_data = refill_turrets[index]
    local turret = turret_data.turret

    if not turret.valid then
        fast_remove(refill_turrets, index)
        return
    end

    refill_turrets.index = index + 1

    local data = turret_data.data
    if data.liquid then
        turret.fluidbox[1] = data
    elseif data then
        turret.insert(data)
    end
end

local function do_turret_energy()
    local power_sources = this.power_sources

    for index = 1, #power_sources do
        local ps_data = power_sources[index]
        if not (ps_data and ps_data.valid) then
            fast_remove(power_sources, index)
            return
        end

        ps_data.energy = 0xfffff
    end
end

local function do_magic_crafters()
    local magic_crafters = this.magic_crafters
    local limit = #magic_crafters
    if limit == 0 then
        return
    end

    local index = magic_crafters.index

    for i = 1, magic_crafters_per_tick do
        if index > limit then
            index = 1
        end

        local data = magic_crafters[index]

        local entity = data.entity
        if not entity.valid then
            fast_remove(magic_crafters, index)
            limit = limit - 1
            if limit == 0 then
                return
            end
        else
            index = index + 1

            local tick = game.tick
            local last_tick = data.last_tick
            local rate = data.rate

            local count = (tick - last_tick) * rate

            local fcount = floor(count)

            if fcount > 1 then
                fcount = 1
            end

            if fcount > 0 then
                entity.get_output_inventory().insert {name = data.item, count = fcount}
                data.last_tick = tick - (count - fcount) / rate
            end
        end
    end

    magic_crafters.index = index
end

local function do_magic_fluid_crafters()
    local magic_fluid_crafters = this.magic_fluid_crafters
    local limit = #magic_fluid_crafters

    if limit == 0 then
        return
    end

    local index = magic_fluid_crafters.index

    for i = 1, magic_fluid_crafters_per_tick do
        if index > limit then
            index = 1
        end

        local data = magic_fluid_crafters[index]

        local entity = data.entity
        if not entity.valid then
            fast_remove(magic_fluid_crafters, index)
            limit = limit - 1
            if limit == 0 then
                return
            end
        else
            index = index + 1

            local tick = game.tick
            local last_tick = data.last_tick
            local rate = data.rate

            local count = (tick - last_tick) * rate

            local fcount = floor(count)

            if fcount > 0 then
                local fluidbox_index = data.fluidbox_index
                local fb = entity.fluidbox

                local fb_data = fb[fluidbox_index] or {name = data.item, amount = 0}
                fb_data.amount = fb_data.amount + fcount
                fb[fluidbox_index] = fb_data

                data.last_tick = tick - (count - fcount) / rate
            end
        end
    end

    magic_fluid_crafters.index = index
end






local function tick()
    do_magic_crafters()
    do_magic_fluid_crafters()
end

Public.deactivate_callback =
    Token.register(
    function(entity)
        if entity and entity.valid then
            entity.active = false
            entity.operable = false
            entity.destructible = false
        end
    end
)

Public.neutral_force =
    Token.register(
    function(entity)
        if entity and entity.valid then
            entity.force = 'neutral'
        end
    end
)

Public.enemy_force =
    Token.register(
    function(entity)
        if entity and entity.valid then
            entity.force = 'enemy'
        end
    end
)

Public.active_not_destructible_callback =
    Token.register(
    function(entity)
        if entity and entity.valid then
            entity.active = true
            entity.operable = false
            entity.destructible = false
        end
    end
)

Public.disable_minable_callback =
    Token.register(
    function(entity)
        if entity and entity.valid then
            entity.minable = false
        end
    end
)

Public.disable_minable_and_ICW_callback =
    Token.register(
    function(entity)
        if entity and entity.valid then
            entity.minable = false
            ICW.register_wagon(entity, true)
        end
    end
)

Public.disable_destructible_callback =
    Token.register(
    function(entity)
        if entity and entity.valid then
            entity.destructible = false
            entity.minable = false
        end
    end
)
Public.disable_active_callback =
    Token.register(
    function(entity)
        if entity and entity.valid then
            entity.active = false
        end
    end
)

local disable_active_callback = Public.disable_active_callback


Public.power_source_callback =
    Token.register(
    function(turret)
        local power_sources = this.power_sources
        power_sources[#power_sources + 1] = turret
    end
)

Public.magic_item_crafting_callback =
    Token.register(
    function(entity, data)
        local callback_data = data.callback_data
        if not (entity and entity.valid) then
            return
        end

        entity.minable = false
        entity.destructible = false
        entity.operable = false

        local force = game.forces.player

        local tech = callback_data.tech
        if tech then
            if not force.technologies[tech].researched then
                entity.destroy()
                return
            end
        end

        local recipe = callback_data.recipe
        if recipe then
            entity.set_recipe(recipe)
        else
            local furance_item = callback_data.furance_item
            if furance_item then
                local inv = entity.get_inventory(defines.inventory.furnace_result)
                inv.insert(furance_item)
            end
        end

        local p = entity.position
        local x, y = p.x, p.y
        local distance = sqrt(x * x + y * y)

        local output = callback_data.output
        if #output == 0 then
            add_magic_crafter_output(entity, output, distance)
        else
            for i = 1, #output do
                local o = output[i]
                add_magic_crafter_output(entity, o, distance)
            end
        end

        if not callback_data.keep_active then
            Task.set_timeout_in_ticks(2, disable_active_callback, entity) -- causes problems with refineries.
        end
    end
)

Public.magic_item_crafting_callback_weighted =
    Token.register(
    function(entity, data)
        local callback_data = data.callback_data
        if not (entity and entity.valid) then
            return
        end

        entity.minable = false
        entity.destructible = false
        entity.operable = false

        local weights = callback_data.weights
        local loot = callback_data.loot

        local p = entity.position

        local i = random() * weights.total

        local index = table.binary_search(weights, i)
        if (index < 0) then
            index = bit32.bnot(index)
        end

        local stack = loot[index].stack
        if not stack then
            return
        end

        local force = game.forces.player

        local tech = stack.tech
        if tech then
            if force.technologies[tech] then
                if not force.technologies[tech].researched then
                    entity.destroy()
                    return
                end
            end
        end

        local recipe = stack.recipe
        if recipe then
            entity.set_recipe(recipe)
        else
            local furance_item = stack.furance_item
            if furance_item then
                local inv = entity.get_inventory(defines.inventory.furnace_result)
                inv.insert(furance_item)
            end
        end

        local x, y = p.x, p.y
        local distance = sqrt(x * x + y * y)

        local output = stack.output
        if #output == 0 then
            add_magic_crafter_output(entity, output, distance)
        else
            for o_i = 1, #output do
                local o = output[o_i]
                add_magic_crafter_output(entity, o, distance)
            end
        end

        if not callback_data.keep_active then
            Task.set_timeout_in_ticks(2, disable_active_callback, entity) -- causes problems with refineries.
        end
    end
)

function Public.prepare_weighted_loot(loot)
    local total = 0
    local weights = {}

    for i = 1, #loot do
        local v = loot[i]
        total = total + v.weight
        weights[#weights + 1] = total
    end

    weights.total = total

    return weights
end

function Public.do_random_loot(entity, weights, loot)
    if not entity.valid then
        return
    end

    entity.operable = false
    --entity.destructible = false

    local i = random() * weights.total

    local index = table.binary_search(weights, i)
    if (index < 0) then
        index = bit32.bnot(index)
    end

    local stack = loot[index].stack
    if not stack then
        return
    end

    local df = stack.distance_factor
    local count
    if df then
        local p = entity.position
        local x, y = p.x, p.y
        local d = sqrt(x * x + y * y)

        count = stack.count + d * df
    else
        count = stack.count
    end

    entity.insert {name = stack.name, count = count}
end

function Public.remove_offline_players()
    local offline_players_enabled = WPT.get('offline_players_enabled')
    if not offline_players_enabled then
        return
    end
    local offline_players = WPT.get('offline_players')
    local active_surface_index = WPT.get('active_surface_index')
    local surface = game.surfaces[active_surface_index]
    local player_inv = {}
    local items = {}
    if #offline_players > 0 then
        local later = {}
        for i = 1, #offline_players, 1 do
            if offline_players[i] and game.players[offline_players[i].index] and game.players[offline_players[i].index].connected then
                offline_players[i] = nil
            else
                if offline_players[i] and game.players[offline_players[i].index] and offline_players[i].tick < game.tick - 54000 then
                    local name = offline_players[i].name
                    player_inv[1] = game.players[offline_players[i].index].get_inventory(defines.inventory.character_main)
                    player_inv[2] = game.players[offline_players[i].index].get_inventory(defines.inventory.character_armor)
                    player_inv[3] = game.players[offline_players[i].index].get_inventory(defines.inventory.character_guns)
                    player_inv[4] = game.players[offline_players[i].index].get_inventory(defines.inventory.character_ammo)
                    player_inv[5] = game.players[offline_players[i].index].get_inventory(defines.inventory.character_trash)
                    local pos = game.forces.player.get_spawn_position(surface)
                    local e =
                        surface.create_entity(
                        {
                            name = 'character',
                            position = pos,
                            force = 'neutral'
                        }
                    )
                    local inv = e.get_inventory(defines.inventory.character_main)
                    e.character_inventory_slots_bonus = #player_inv[1]
                    for ii = 1, 5, 1 do
                        if player_inv[ii].valid then
                            for iii = 1, #player_inv[ii], 1 do
                                if player_inv[ii][iii].valid then
                                    items[#items + 1] = player_inv[ii][iii]
                                end
                            end
                        end
                    end
                    if #items > 0 then
                        for item = 1, #items, 1 do
                            if items[item].valid then
                                inv.insert(items[item])
                            end
                        end

                        local message = ({'main.cleaner', name})
                        local data = {
                            position = pos
                        }
                        Alert.alert_all_players_location(data, message)

                        e.die('neutral')
                    else
                        e.destroy()
                    end

                    for ii = 1, 5, 1 do
                        if player_inv[ii].valid then
                            player_inv[ii].clear()
                        end
                    end
                    offline_players[i] = nil
                else
                    later[#later + 1] = offline_players[i]
                end
            end
        end
        for k, _ in pairs(offline_players) do
            offline_players[k] = nil
        end
        if #later > 0 then
            for i = 1, #later, 1 do
                offline_players[#offline_players + 1] = later[i]
            end
        end
    end
end

local function calc_players()
    local players = game.connected_players
    local check_afk_players = WPT.get('check_afk_players')
    if not check_afk_players then
        return #players
    end
    local total = 0
    for i = 1, #players do
        local player = players[i]
        if player.afk_time < 36000 then
            total = total + 1
        end
    end
    if total <= 0 then
        total = 1
    end
    return total
end


function Public.on_player_joined_game(event)
    local active_surface_index = WPT.get('active_surface_index')
    local player = game.players[event.player_index]
    local surface = game.surfaces[active_surface_index]


	local reward = require 'maps.amap.main'.reward
    local player_data = get_player_data(player)
    if not player_data.first_join then

        for item, amount in pairs(starting_items) do
           player.insert({name = item, count = amount})
        end
        local rpg_t = RPG.get('rpg_t')
        local wave_number = WD.get('wave_number')
        local this = WPT.get()

        for i=0,this.science do
          local point = math.floor(math.random(1,5))
          local money = math.floor(math.random(1,100))
          	rpg_t[player.index].points_to_distribute = rpg_t[player.index].points_to_distribute+point
              player.insert{name='coin', count = money}
          	player.print({'amap.science',point,money}, {r = 0.22, g = 0.88, b = 0.22})
        end

        	rpg_t[player.index].xp = rpg_t[player.index].xp + wave_number*10



        player_data.first_join = true
        player.print({'amap.joingame'})
    end
    if player.surface.index ~= active_surface_index then
--player.teleport(surface.find_non_colliding_position("character", game.forces.player.get_spawn_position(surface), 20, 1, false) or {x=0,y=0}, surface)

  player.teleport(surface.find_non_colliding_position('character', game.forces.player.get_spawn_position(surface), 20, 1, false) or {x=0,y=0}, surface)
    else
        local p = {x = player.position.x, y = player.position.y}
        local get_tile = surface.get_tile(p)
        if get_tile.valid and get_tile.name == 'out-of-map' then
player.teleport(surface.find_non_colliding_position('character', game.forces.player.get_spawn_position(surface), 20, 1, false) or {x=0,y=0}, surface)
            --player.teleport({x=0,y=0}, surface)
        end
    end

end


function Public.is_creativity_mode_on()
    local creative_enabled = Commands.get('creative_enabled')
    if creative_enabled then
        WD.set('next_wave', 1000)
        Collapse.start_now(true)
        Public.set_difficulty()
    end
end
local function on_player_mined_entity(event)
  local name = event.entity.name
  local force = event.entity.force
  local entity = event.entity
  local this = WPT.get()
  if name == 'flamethrower-turret' and force.index == game.forces.player.index then
    this.flame = this.flame - 1

     if this.flame <= 0 then
       this.flame = 0
     end
  end
end
function Public.disable_creative()
    local creative_enabled = Commands.get('creative_enabled')
    if creative_enabled then
        Commands.set('creative_enabled', false)
    end
end

function Public.on_pre_player_left_game(event)
    local offline_players_enabled = WPT.get('offline_players_enabled')
    if not offline_players_enabled then
        return
    end

    local offline_players = WPT.get('offline_players')
    local player = game.players[event.player_index]
    local ticker = game.tick
    if player.character then
        offline_players[#offline_players + 1] = {
            index = event.player_index,
            name = player.name,
            tick = ticker
        }
    end
end
local on_player_or_robot_built_entity = function(event)
--change_pos  改变位置
local name = event.created_entity.name
local force = event.entity.force
local entity = event.created_entity
local this = WPT.get()
  if name == 'flamethrower-turret' and force.index == game.forces.player.index
  if this.flame >= 15 then
    game.print({'amap.too_many'})
    entity.destroy()
  else
    this.flame = this.flame + 1
    game.print({'amap.ok_many',this.flame})
  end
end
if name == "stone-wall" then
  local this = WPT.get()
  if not this.change then
   local wave_defense_table = WD.get_table()
   local dx = entity.position.x-this.pos.x
   local dy = entity.position.y-this.pos.y

   if dx < 0 then
      dx=-dx
   end
   if dy < 0 then
      dy=-dy
   end
   local d = dx+dy
   if d < 100 then
  this.change = true
  end
end

--game.print(dx)
--game.print(dy)
--game.print('差值为')
--game.print(d)
--game.print('出生地为')
--game.print(this.pos)
end

end

function Public.on_player_respawned(event)
    local player = game.get_player(event.player_index)
    if not (player and player.valid) then
        return
    end
    local player_data = get_player_data(player)
    if player_data.died then
        player_data.died = nil
    end
end

function Public.on_player_died(event)
    local player = game.get_player(event.player_index)
    if not (player and player.valid) then
        return
    end
    local player_data = get_player_data(player)
    player_data.died = true
end

function Public.on_player_changed_position(event)
    local active_surface_index = WPT.get('active_surface_index')
    if not active_surface_index then
        return
    end
    local player = game.players[event.player_index]
    local map_name = 'amap'

    if string.sub(player.surface.name, 0, #map_name) ~= map_name then
        return
    end

    local position = player.position
    local surface = game.surfaces[active_surface_index]

    local p = {x = player.position.x, y = player.position.y}
    local get_tile = surface.get_tile(p)
    local config_tile = WPT.get('void_or_tile')
    if config_tile == 'lab-dark-2' then
        if get_tile.valid and get_tile.name == 'lab-dark-2' then
            if random(1, 2) == 1 then
                if random(1, 2) == 1 then
                    show_text('This path is not for players!', p, {r = 0.98, g = 0.66, b = 0.22}, surface)
                end
                player.surface.create_entity({name = 'fire-flame', position = player.position})
                player.character.health = player.character.health - tile_damage
                if player.character.health == 0 then
                    player.character.die()
                    local message = ({'main.death_message_' .. random(1, 7), player.name})
                    game.print(message, {r = 0.98, g = 0.66, b = 0.22})
                end
            end
        end
    end

    if position.y >= 74 then
        player.teleport({position.x, position.y - 1}, surface)
        player.print(({'main.forcefield'}), {r = 0.98, g = 0.66, b = 0.22})
        if player.character then
            player.character.health = player.character.health - 5
            player.character.surface.create_entity({name = 'water-splash', position = position})
            if player.character.health <= 0 then
                player.character.die('enemy')
            end
        end
    end
end

local disable_recipes = function()
    local force = game.forces.player
    force.recipes['car'].enabled = false
    force.recipes['tank'].enabled = false
    force.recipes['pistol'].enabled = false
    force.recipes['land-mine'].enabled = false
    force.recipes['spidertron-remote'].enabled = false
  --  force.recipes['flamethrower-turret'].enabled = false
end

function Public.disable_tech()
    game.forces.player.technologies['landfill'].enabled = false
    game.forces.player.technologies['spidertron'].enabled = false
    game.forces.player.technologies['spidertron'].researched = false
    disable_recipes()
end

local disable_tech = Public.disable_tech
function Public.on_research_finished(event)
    disable_tech()
end

local function on_entity_died(event)

  local name = event.entity.name
local force = event.entity.force
  local entity = event.entity
  local this = WPT.get()
  if name == 'flamethrower-turret' and force.index == game.forces.player.index
    this.flame = this.flame - 1

     if this.flame <= 0 then
       this.flame = 0
     end
  end
end
Public.firearm_magazine_ammo = {name = 'firearm-magazine', count = 200}
Public.piercing_rounds_magazine_ammo = {name = 'piercing-rounds-magazine', count = 200}
Public.uranium_rounds_magazine_ammo = {name = 'uranium-rounds-magazine', count = 200}
Public.light_oil_ammo = {name = 'light-oil', amount = 100}
Public.artillery_shell_ammo = {name = 'artillery-shell', count = 15}
Public.laser_turrent_power_source = {buffer_size = 2400000, power_production = 40000}

function Public.reset_table()
    this.power_sources = {index = 1}
    this.refill_turrets = {index = 1}
    this.magic_crafters = {index = 1}
    this.magic_fluid_crafters = {index = 1}
end

local on_research_finished = Public.on_research_finished
local on_player_joined_game = Public.on_player_joined_game
local on_player_respawned = Public.on_player_respawned
local on_player_died = Public.on_player_died
local on_player_changed_position = Public.on_player_changed_position
local on_pre_player_left_game = Public.on_pre_player_left_game

Event.add(defines.events.on_built_entity, on_player_or_robot_built_entity)
Event.add(defines.events.on_robot_built_entity, on_player_or_robot_built_entity)
Event.add(defines.events.on_research_finished, on_research_finished)
Event.add(defines.events.on_player_joined_game, on_player_joined_game)
Event.add(defines.events.on_player_respawned, on_player_respawned)
Event.add(defines.events.on_player_died, on_player_died)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
Event.add(defines.events.on_robot_mined_entity, on_player_mined_entity)
--Event.add(defines.events.on_player_changed_position, on_player_changed_position)
Event.add(defines.events.on_pre_player_left_game, on_pre_player_left_game)
Event.on_nth_tick(10, tick)
--Event.on_nth_tick(5, do_turret_energy)

return Public
