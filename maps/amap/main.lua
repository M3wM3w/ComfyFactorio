require 'modules.rpg.main'
require 'maps.amap.relax'
require 'maps.amap.diff'
require 'maps.amap.biter_die'
local Functions = require 'maps.amap.functions'
local IC = require 'maps.amap.ic.table'
local CS = require 'maps.amap.surface'
local Event = require 'utils.event'
--local HS = require 'maps.amap.highscore'
local WD = require 'modules.wave_defense.table'
local wall_health = require 'maps.amap.wall_health_booster_v2'
local Balance = require 'maps.amap.balance'
--local enemy_health = require 'maps.amap.enemy_health_booster'.set_health_modifier
local spider_health =require 'maps.amap.spider_health_booster_v2'
local enemy_health = require 'maps.amap.enemy_health_booster_v2'
local Map = require 'modules.map_info'
local AntiGrief = require 'antigrief'
--local Explosives = require 'modules.explosives'
local WPT = require 'maps.amap.table'
local Autostash = require 'modules.autostash'
local BuriedEnemies = require 'maps.amap.buried_enemies'
local RPG_Settings = require 'modules.rpg.table'
local RPG_Func = require 'modules.rpg.functions'
local Commands = require 'commands.misc'
local Task = require 'utils.task'
local Token = require 'utils.token'
local Alert = require 'utils.alert'
local rock = require 'maps.amap.rock'
local Loot = require'maps.amap.loot'

local rpg_spells = RPG_Settings.get('rpg_spells')
 --rpg_spells[1].enabled = false
  --rpg_spells[17].enabled = true
  --for k=1,#rpg_spells do
    rpg_spells[16].enabled = true
    rpg_spells[17].enabled = true
  --end
  local RPG = require 'modules.rpg.table'
local Difficulty = require 'modules.difficulty_vote_by_amount'

local arty = require "maps.amap.enemy_arty"
--require 'maps.amap.burden'
require "modules.spawners_contain_biters"
require 'maps.amap.biters_yield_coins'
--require 'maps.amap.sort'
local Public = {}
local floor = math.floor
local remove = table.remove
--require 'modules.flamethrower_nerf'
--加载地形
require 'maps.amap.caves'
require 'modules.surrounded_by_worms'
require 'maps.amap.ic.main'
require 'modules.shotgun_buff'
require 'modules.no_deconstruction_of_neutral_entities'
require 'modules.wave_defense.main'
require 'modules.charging_station'
local BiterHealthBooster = require 'modules.biter_health_booster_v2'

local init_new_force = function()
  local new_force = game.forces.protectors
  local enemy = game.forces.enemy
  if not new_force then
    new_force = game.create_force('protectors')
  end
  new_force.set_friend('enemy', true)
  enemy.set_friend('protectors', true)
end
local setting = function()
  --game.map_settings.enemy_evolution.destroy_factor = 0.004
  --	game.map_settings.enemy_evolution.pollution_factor = 0.000003
  game.map_settings.enemy_expansion.enabled = true
  game.map_settings.enemy_expansion.min_expansion_cooldown = 6000
  game.map_settings.enemy_expansion.max_expansion_cooldown = 104000
  --game.map_settings.enemy_evolution.time_factor = 0.00004
  game.map_settings.enemy_expansion.max_expansion_distance = 20
  game.map_settings.enemy_expansion.settler_group_min_size = 5
  game.map_settings.enemy_expansion.settler_group_max_size = 50
  game.forces.enemy.friendly_fire = false
  game.forces.player.set_ammo_damage_modifier("artillery-shell", 0)
  game.forces.player.set_ammo_damage_modifier("melee", 0)
  game.forces.player.set_ammo_damage_modifier("biological", 0)

local this = WPT.get()
local surface = game.surfaces[this.active_surface_index]
--  local index = game.forces.player.index
  wall_health.set('biter_health_boost', 1)
  spider_health.set('biter_health_boost',1)
  enemy_health.set('biter_health_boost_forces',1)
  BiterHealthBooster.set('biter_health_boost_forces',{[game.forces.player.index]=1})
  wall_health.set_active_surface(tostring(surface.name))
  spider_health.set_active_surface(tostring(surface.name))
--  spider_health(index,1)
enemy_health.set_active_surface(tostring(surface.name))
--enemy_health(game.forces.enemy.index,1)
end

function Public.reset_map()

  local this = WPT.get()
  local wave_defense_table = WD.get_table()

  --创建一个地表
  this.active_surface_index = CS.create_surface()

  Autostash.insert_into_furnace(true)
  Autostash.bottom_button(true)
  BuriedEnemies.reset()
  Commands.reset()
  Commands.activate_custom_buttons(true)
  Commands.bottom_right(false)

  IC.reset()
  IC.allowed_surface('amap')

  game.reset_time_played()
  WPT.reset_table()
  arty.reset_table()

  --记得后面改为失去一半经验！并且修订技能！
  local xp = {}
  local rpg_t = RPG.get('rpg_t')
  for k, p in pairs(game.connected_players) do
    local player = game.connected_players[k]
    xp[player.index]={}
    xp[player.index] = rpg_t[player.index].xp / 3

    if xp[player.index] > 5000 then
      xp[player.index] = 5000
    end
  end

  RPG_Func.rpg_reset_all_players()

  for k, p in pairs(game.connected_players) do
    local player = game.connected_players[k]
    rpg_t[player.index].xp = xp[player.index]
    xp[player.index]={}
  end

  RPG_Settings.set_surface_name('amap')
  RPG_Settings.enable_health_and_mana_bars(true)
  RPG_Settings.enable_wave_defense(true)
  RPG_Settings.enable_mana(true)
  RPG_Settings.enable_flame_boots(true)
  RPG_Settings.enable_stone_path(true)
  RPG_Settings.enable_one_punch(true)
  RPG_Settings.enable_one_punch_globally(false)
  RPG_Settings.enable_auto_allocate(true)
  RPG_Settings.disable_cooldowns_on_spells()
--  RPG_Settings.enable_title(true)

  --初始化部队
  init_new_force()
  --难度设置
  local Diff = Difficulty.get()
  Difficulty.reset_difficulty_poll({difficulty_poll_closing_timeout = game.tick + 36000})
  Diff.gui_width = 20

  local surface = game.surfaces[this.active_surface_index]
  --Explosives.set_surface_whitelist({[surface.name] = true})
  game.forces.player.set_spawn_position({0, 0}, surface)



  local players = game.connected_players
  for i = 1, #players do
    local player = players[i]
    Commands.insert_all_items(player)
  end

  --生产火箭发射井
  rock.spawn(surface,{x=0,y=10})
  rock.market(surface)

  WD.reset_wave_defense()
  wave_defense_table.surface_index = this.active_surface_index
  --记得修改目标！
  wave_defense_table.target = this.rock
  wave_defense_table.nest_building_density = 32
  wave_defense_table.game_lost = false
  --  wave_defense_table.set_evolution_time = true
  --生成随机位置！
  local positions = {x = 200, y = 200}
  positions.x = math.random(-200,200)
  positions.y = math.random(-200,200)

  if positions.y < 75 and positions.y > -75 then

    if positions.y < 0 then
      positions.y = positions.y - 100
    else
      positions.y = positions.y + 100
    end
  end
  if positions.x < 75 and positions.x > -75 then
    if positions.x < 0 then
      positions.x = positions.x - 100
    else
      positions.x = positions.x + 100
    end
  end

  wave_defense_table.spawn_position = positions
  this.pos = positions
  this.change = false
  this.science = 0
  --game.print(positions)
  WD.alert_boss_wave(true)
  WD.clear_corpses(false)
  WD.remove_entities(true)
  WD.enable_threat_log(true)
  WD.increase_damage_per_wave(true)
  WD.increase_health_per_wave(true)
  WD.set_disable_threat_below_zero(true)
  WD.set_biter_health_boost(1.4)
  --  WD.set().wave_interval = 3300
  --  WD.set().threat_gain_multiplier = 4
  WD.set().next_wave = game.tick + 7200* 15
  --初始化虫子科技

  Functions.disable_tech()
  game.forces.player.set_spawn_position({0, 0}, surface)

  BiterHealthBooster.set_active_surface(tostring(surface.name))
     BiterHealthBooster.acid_nova(true)
     BiterHealthBooster.check_on_entity_died(true)
     BiterHealthBooster.boss_spawns_projectiles(true)
     BiterHealthBooster.enable_boss_loot(false)
Balance.init_enemy_weapon_damage()
  Task.start_queue()
  Task.set_queue_speed(16)

  this.chunk_load_tick = game.tick + 1200
  this.game_lost = false
  this.last = 0

  global.worm_distance = 210
  global.average_worm_amount_per_chunk = 5
--HS.get_scores()
  setting()
end



local on_init = function()

  Public.reset_map()

  local tooltip = {
    [1] = ({'amap.easy'}),
    [2] = ({'amap.med'}),
    [3] = ({'amap.hard'})
  }

  Difficulty.set_tooltip(tooltip)

  game.forces.player.research_queue_enabled = true
  local T = Map.Pop_info()
  T.localised_category = 'amap'
  T.main_caption_color = {r = 150, g = 150, b = 0}
  T.sub_caption_color = {r = 0, g = 150, b = 0}



  --Explosives.set_whitelist_entity('character')
  --Explosives.set_whitelist_entity('spidertron')
  --Explosives.set_whitelist_entity('car')
  --Explosives.set_whitelist_entity('tank')
  --地图设置

  --setting()
end
local is_player_valid = function()
  local players = game.connected_players
  for _, player in pairs(players) do
    if player.connected and not player.character or not player.character.valid then
      if not player.admin then
        local player_data = Functions.get_player_data(player)
        if player_data.died then
          return
        end
        player.set_controller {type = defines.controllers.god}
        player.create_character()
      end
    end
  end
end


local has_the_game_ended = function()
  local game_reset_tick = WPT.get('game_reset_tick')
  if game_reset_tick then
    if game_reset_tick < 0 then
      return
    end

    local this = WPT.get()

    this.game_reset_tick = this.game_reset_tick - 30
    if this.game_reset_tick % 1800 == 0 then
      if this.game_reset_tick > 0 then
        local cause_msg
        if this.restart then
          cause_msg = 'restart'

        end

        game.print(({'main.reset_in', cause_msg, this.game_reset_tick / 60}), {r = 0.22, g = 0.88, b = 0.22})
      end

      if this.soft_reset and this.game_reset_tick == 0 then
        this.game_reset_tick = nil
        Public.reset_map()
        return
      end


    end
  end
end

local chunk_load = function()
  local chunk_load_tick = WPT.get('chunk_load_tick')
  if chunk_load_tick then
    if chunk_load_tick < game.tick then
      WPT.get().chunk_load_tick = nil
      Task.set_queue_speed(2)
    end
  end
end

local rondom = function(player,many)
  if not player.character or not player.character.valid then return end
  if many >= 500 then
    many = 500
  end
  local rpg_t = RPG.get('rpg_t')
  local q = math.random(0,19)
  local k = math.floor(many/100)
  local get_point = k*5+5
 if get_point >= 25 then
   get_point = 25
 end
  if q == 16 then
    if rpg_t[player.index].magicka < (get_point+10) then
      q = 17
      --    player.print({'amap.nopoint'})
      --  player.remove_item{name='coin', count = '1000'}
    else

      rpg_t[player.index].magicka =rpg_t[player.index].magicka -get_point
      player.print({'amap.nb16',get_point+10})
      return
    end
  end
  if q == 17 then
    if rpg_t[player.index].dexterity < (get_point+10) then
      q = 18
      --    player.print({'amap.nopoint'})
      --    player.remove_item{name='coin', count = '1000'}
    else
      rpg_t[player.index].dexterity = rpg_t[player.index].dexterity - get_point
      player.print({'amap.nb17',get_point})
      return
    end
  end
  if q == 18 then
    if rpg_t[player.index].vitality < (get_point+10) then
      q = 15
      --  player.print({'amap.nopoint'})
      --  player.remove_item{name='coin', count = '1000'}
    else
      rpg_t[player.index].vitality = rpg_t[player.index].vitality -get_point
      player.print({'amap.nb18',get_point})
      return
    end
  end
  if q == 15 then
    if rpg_t[player.index].strength < (get_point+10) then
      local money = 1000+1000*k
      player.print({'amap.nopoint',money})
      player.remove_item{name='coin', count = money}
      return
    else
      rpg_t[player.index].strength = rpg_t[player.index].strength -get_point
      player.print({'amap.nb15',get_point})
      return
    end
  end
  if q == 14 then
    local luck = 50*k+50
    if luck >= 400 then
      luck = 400
    end
    Loot.cool(player.surface, player.surface.find_non_colliding_position("steel-chest", player.position, 20, 1, true) or player.position, 'steel-chest', luck)
    player.print({'amap.nb14',luck})
    return
  elseif q == 13 then
    local money = 10000+1000*k
    player.insert{name='coin', count =money}
    player.print({'amap.nb13',money})
    return
  elseif q == 12 then
    local get_xp = 100+k*50
    rpg_t[player.index].xp = rpg_t[player.index].xp +get_xp
    player.print({'amap.nb12',get_xp})
    return
  elseif q == 11 then
    local amount = 10+10*k
    player.insert{name='distractor-capsule', count = amount}
    player.print({'amap.nb11',amount})
    return
  elseif q == 10 then
    local amount = 100+100*k
    player.insert{name='raw-fish', count = amount}
    player.print({'amap.nb10',amount})
    return
  elseif q == 9 then
    player.insert{name='raw-fish', count = '1'}
    player.print({'amap.nb9'})
    return
  elseif q == 8 then
local lost_xp = 2000+k*200
    if rpg_t[player.index].xp < lost_xp then
      rpg_t[player.index].xp = 0
      return
    else
      rpg_t[player.index].xp = rpg_t[player.index].xp - lost_xp
      player.print({'amap.nb8',lost_xp})
      return
    end
  elseif q == 7 then
    player.print({'amap.nb7'})
    return
  elseif q == 6 then
    rpg_t[player.index].strength = rpg_t[player.index].strength + get_point
    player.print({'amap.nb6',get_point})
    return
  elseif q == 5 then
    player.print({'amap.nb5',get_point})
    rpg_t[player.index].magicka =rpg_t[player.index].magicka +get_point
    return
  elseif q == 4 then
    player.print({'amap.nb4',get_point})
    rpg_t[player.index].dexterity = rpg_t[player.index].dexterity+get_point
    return
  elseif q == 3 then
    player.print({'amap.nb3',get_point})
    rpg_t[player.index].vitality = rpg_t[player.index].vitality+get_point
    return
  elseif q == 2 then
    player.print({'amap.nb2',get_point})
    rpg_t[player.index].points_to_distribute = rpg_t[player.index].points_to_distribute+get_point
    return
  elseif q == 1 then
    local money = 1000+1000*k
    player.print({'amap.nbone',money})
    player.insert{name='coin', count = money}
    return
  elseif q == 0 then
    local money = 1000+1000*k
    player.print({'amap.sorry',money})
    player.remove_item{name='coin', count = money}
    return
  elseif q == 19 then
    player.print({'amap.what'})
    return
  end
end
local timereward = function()
  local game_lost = WPT.get('game_lost')
  if game_lost then
    return
  end
  local this = WPT.get()
  local last = this.last
  local wave_number = WD.get('wave_number')
  if last < wave_number then
    if wave_number % 25 == 0 then
      game.print({'amap.roll'},{r = 0.22, g = 0.88, b = 0.22})
      --biterbuff()
      for k, p in pairs(game.connected_players) do
        local player = game.connected_players[k]
        rondom(player,wave_number)
        k=k+1
      end
      this.last = wave_number
   end

  end
end


local getrawrad = function()
  local game_lost = WPT.get('game_lost')
  if game_lost then
    return
  end
  local this = WPT.get()
  local wave_number = WD.get('wave_number')
  if wave_number > this.number then

    local rpg_t = RPG.get('rpg_t')
    for k, p in pairs(game.connected_players) do
      local player = game.connected_players[k]
      rpg_t[player.index].xp = rpg_t[player.index].xp + 10
    end
    this.number = wave_number
    --  game.print({'amap.getxpfromwave'})
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
local change = function()
  local this = WPT.get()
  local roll = this.roll
  if this.change then
    this.change = false
    this.change_dist = false
    if roll == 1 then
      if this.pos.x < 0 then
        this.pos.x = this.pos.x - 75
      else
        this.pos.x = this.pos.x + 75
      end
    elseif roll == 2 then
      if this.pos.y < 0 then
        this.pos.y = this.pos.y - 75
      else
        this.pos.y = this.pos.y + 75
      end
    elseif roll == 3 then
      if this.pos.y < 0 then
        this.pos.y = -this.pos.y + 75
      else
        this.pos.y = -this.pos.y - 75
      end
    elseif roll == 4 then
      if this.pos.x < 0 then
        this.pos.x = -this.pos.x + 75
      else
        this.pos.x = -this.pos.x - 75
      end
    elseif roll == 5 then
      if this.pos.x < 0 then
        this.pos.x = this.pos.x - 75
      else
        this.pos.x = this.pos.x + 75
      end
      if this.pos.y < 0 then
        this.pos.y = this.pos.y - 75
      else
        this.pos.y = this.pos.y + 75
      end
    elseif roll == 6 then
      if this.pos.y < 0 then
        this.pos.y = -this.pos.y + 75
      else
        this.pos.y = -this.pos.y - 75
      end

      if this.pos.x < 0 then
        this.pos.x = -this.pos.x + 75
      else
        this.pos.x = -this.pos.x - 75
      end
    end

  end
  if this.change_dist then
    this.change_dist = false
    local k = roll
    if k == 1 then
      this.pos.y = -this.pos.y
      this.pos.x = -this.pos.x
    elseif k == 2 then
      this.pos.y = -this.pos.y
    elseif k == 3 then
      this.pos.x = -this.pos.x
    elseif k == 4 then
      this.pos.y = -this.pos.y
    elseif k == 5 then
      this.pos.y = -this.pos.y
      this.pos.x = -this.pos.x
    elseif k == 6 then
      this.pos.x = -this.pos.x
    end

  end
end
local single_rewrad = function()
  local game_lost = WPT.get('game_lost')
  if game_lost then
    return
  end
  local wave_number = WD.get('wave_number')
  if wave_number >= 10 then
    return
  end
  local rpg_t = RPG.get('rpg_t')

  local this = WPT.get()
  local player_count = calc_players()
  if this.single and player_count <= 2 and not this.first then
    for k, p in pairs(game.connected_players) do
      local player = game.connected_players[k]
      rpg_t[player.index].points_to_distribute = rpg_t[player.index].points_to_distribute + 200
      rpg_t[player.index].xp=  rpg_t[player.index].xp+5000
      player.insert{name='coin', count = 10000}
      player.insert{name='tank', count = 1}
      game.print({'amap.single'})
      this.single = false

    end
  end
  this.first = false
end



local on_tick = function()
  local tick = game.tick

  if tick % 40 == 0 then
    --	pos()

    --bigermap()


    --  has_the_game_ended()
is_player_valid()
    chunk_load()
    timereward()
    getrawrad()
    --	biterup()
  end
  if tick % 500 == 0 then
change()
  end

  if tick % 600 == 0 then
    local this = WPT.get()
    local wave_defense_table = WD.get_table()
    local roll = this.roll
    wave_defense_table.spawn_position = this.pos
    if this.roll == 6 then
      this.roll = 1
    end
    this.roll=this.roll+1


  end
end

  function on_research_finished(Event)
    if Event.research.force.index==game.forces.enemy.index then return end
    local this = WPT.get()
    this.science=this.science+1
    local rpg_t = RPG.get('rpg_t')
    for k, p in pairs(game.connected_players) do
      local player = game.connected_players[k]
      local point = math.floor(math.random(1,5))
      local money = math.floor(math.random(1,100))
      rpg_t[player.index].points_to_distribute = rpg_t[player.index].points_to_distribute+point
      player.insert{name='coin', count = money}
      --	player.print({'amap.science',point,money}, {r = 0.22, g = 0.88, b = 0.22})
      Alert.alert_player(player, 5, {'amap.science',point,money})
      k=k+1
    end
  end

  local on_player_joined_game = function()
    local player_count = calc_players()
    if player_count <= 4 then
      RPG_Settings.points_per_level = 10
    else
      RPG_Settings.points_per_level = 5
    end
  end

  local on_player_left_game = function()
    local player_count = calc_players()
    if player_count <= 4 then
      RPG_Settings.points_per_level = 10
    else
      RPG_Settings.points_per_level = 5
    end
  end

  local change_dis = function()
    local this = WPT.get()
    this.change_dist=true
  end
  Event.add_event_filter(defines.events.on_entity_damaged, {filter = 'final-damage-amount', comparison = '>', value = 0})
  Event.on_init(on_init)
  Event.on_nth_tick(10, on_tick)
  Event.on_nth_tick(7200, single_rewrad)
  Event.on_nth_tick(60, change_dis)
  --Event.add(defines.events.on_player_joined_game, on_player_joined_game)
  --Event.add(defines.events.on_pre_player_left_game, on_player_left_game)
  Event.add(defines.events.on_research_finished, on_research_finished)
  return Public
