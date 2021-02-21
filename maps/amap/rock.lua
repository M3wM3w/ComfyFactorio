local WPT = require 'maps.amap.table'
local Event = require 'utils.event'
local Public = {}
local Alert = require 'utils.alert'
local WD = require 'modules.wave_defense.table'
local BiterHealthBooster = require 'modules.biter_health_booster_v2'
local RPG = require 'modules.rpg.table'
--local HS = require 'maps.amap.highscore'
local wave_defense_table = WD.get_table()
local Task = require 'utils.task'
local Server = require 'utils.server'
local wall_health = require 'maps.amap.wall_health_booster_v2'
local spider_health =require 'maps.amap.spider_health_booster_v2'
local urgrade_item = function(market)
  local this = WPT.get()
  local pirce_wall=this.health*1000 + 10000
  local pirce_arty=this.arty*1000 +10000
  local biter_health=this.biter_health*1000 + 7000
  local spider_health=this.spider_health*1000 + 10000
  local pirce_biter_dam=this.biter_dam*1000 +7000
  if pirce_arty >= 50000 then
    pirce_arty = 50000
  end


  if pirce_wall >= 50000 then
    pirce_wall = 50000
  end


  if biter_health >= 50000 then
    biter_health = 50000
  end
  if spider_health >= 50000 then
    spider_health = 50000
  end
  if pirce_biter_dam >= 50000 then
    pirce_biter_dam = 50000
  end
  local health_wall = {price = {{"coin", pirce_wall}}, offer = {type = 'nothing', effect_description = {'amap.buy_health_wall'}}}
  local arty_dam = {price = {{"coin", pirce_arty}}, offer = {type = 'nothing', effect_description = {'amap.buy_arty_dam'}}}
  local player_biter_health={price = {{"coin", biter_health}}, offer = {type = 'nothing', effect_description = {'amap.player_biter_health'}}}
  local spider_buy={price = {{"coin", spider_health}}, offer = {type = 'nothing', effect_description = {'amap.player_spider_health'}}}
  local biter_dam={price = {{"coin", pirce_biter_dam}}, offer = {type = 'nothing', effect_description = {'amap.player_biter_dam'}}}
  local buy_cap={price = {{"coin", 50000}}, offer = {type = 'nothing', effect_description = {'amap.buy_cap'}}}
  market.add_market_item(health_wall)
  market.add_market_item(arty_dam)
  market.add_market_item(player_biter_health)
  market.add_market_item(spider_buy)
  market.add_market_item(biter_dam)
  market.add_market_item(buy_cap)
end

local market_items = {

  {price = {{"coin", 5}}, offer = {type = 'give-item', item = "raw-fish", count = 1}},
  {price = {{"coin", 2000}}, offer = {type = 'give-item', item = 'car', count = 1}},
  {price = {{"coin", 15000}}, offer = {type = 'give-item', item = 'tank', count = 1}},
  {price = {{"coin", 60000}}, offer = {type = 'give-item', item = 'spidertron', count = 1}},
  {price = {{"coin", 500}}, offer = {type = 'give-item', item = 'spidertron-remote', count = 1}},
  --{price = {{"coin", 5000}}, offer = {type = 'give-item', item = 'locomotive', count = 1}},
  --{price = {{"coin", 5000}}, offer = {type = 'give-item', item = 'cargo-wagon', count = 1}},
  --{price = {{"coin", 5000}}, offer = {type = 'give-item', item = 'fluid-wagon', count = 1}}
  {price = {{"coin", 25000}}, offer = {type = 'give-item', item = 'tank-cannon', count = 1}},
  {price = {{"coin", 128}}, offer = {type = 'give-item', item = 'loader', count = 1}},
  {price = {{"coin", 512}}, offer = {type = 'give-item', item = 'fast-loader', count = 1}},
  {price = {{"coin", 4096}}, offer = {type = 'give-item', item = 'express-loader', count = 1}},
  {price = {{"raw-fish", 1}}, offer = {type = 'give-item', item = 'coin', count = 5}},
  {price = {{"coin", 3000}}, offer = {type = 'give-item', item = 'flamethrower-turret', count = 1}},
  {price = {{"coin", 15}}, offer = {type = 'give-item', item = 'crude-oil-barrel', count = 1}},
}

function Public.spawn(surface, position)
  local this = WPT.get()
  this.rock = surface.create_entity{name = "rocket-silo", position = position, force=game.forces.player}

  this.rock.minable = false
  game.forces.player.set_spawn_position({0,0}, surface)
end

function Public.market(surface)
  local this = WPT.get()
  local market = surface.create_entity{name = "market", position = {x=0, y=-10}, force=game.forces.player}

  market.last_user = nil
  if market ~= nil then
    market.destructible = false
    if market ~= nil then
      game.print(1)
      urgrade_item(market)
      for _, item in pairs(market_items) do
        market.add_market_item(item)
      end
    end
  end
end



local function on_rocket_launched(Event)
  local this = WPT.get()
  --game.print({'amap.times',this.times})
  local rpg_t = RPG.get('rpg_t')
  --local money = 1000 + this.times*1000
  local money = 8000
  local point = 1
  -- if money >= 50000 then
  --   money = 50000
  -- end
  -- if point >= 100 then
  --   point = 100
  -- end
  for k, p in pairs(game.connected_players) do
    local player = game.connected_players[k]

    rpg_t[player.index].points_to_distribute = rpg_t[player.index].points_to_distribute+point
    player.insert{name='coin', count = money}
    player.print({'amap.reward',this.times,point,money}, {r = 0.22, g = 0.88, b = 0.22})

  end
  if not this.pass then
    local wave_number = WD.get('wave_number')
    local msg = {'amap.pass',wave_number}
    for k, p in pairs(game.connected_players) do
      local player = game.connected_players[k]
      Alert.alert_player(player, 25, msg)
    end
    Server.to_discord_embed(table.concat({'** we win the game ! Record is ', wave_number}))
    this.pass = true
  end
  this.times=this.times+1
end

local function on_entity_died(Event)
  local this = WPT.get()
  if Event.entity == this.rock then

    --game.print({'amap.lost',wave_number}),{r = 1, g = 0, b = 0, a = 0.5})
    local wave_number = WD.get('wave_number')
    local msg = {'amap.lost',wave_number}
    for _, p in pairs(game.connected_players) do

      Alert.alert_player(p, 25, msg)

    end
    Server.to_discord_embed(table.concat({'** we lost the game ! Record is ', wave_number}))
   local Reset_map = require 'maps.amap.main'.reset_map
    wave_defense_table.game_lost = true
    wave_defense_table.target = nil
    --  game.forces.enemy.set_friend('player', true)
    --game.print('设置右军友好')
  --  game.forces.player.set_friend('enemy', true)
    --game.print('设置敌军友好')
    --local game_reset_tick = WPT.get('game_reset_tick')
  --  game.print('GG,游戏结束，稍后自动重启',{r = 0.99, g = 0.00, b = 0.22})
  --  this.game_reset_tick = 5400
  --local diff_name = Difficulty.get('name')
  Reset_map()
  for _, player in pairs(game.connected_players) do
      player.play_sound {path = 'utility/game_lost', volume_modifier = 0.75}
  end
    --abc()
  end
end

local function on_market_item_purchased(event)
  local player = game.players[event.player_index]
  local market = event.market
  local offer_index = event.offer_index
  local count = event.count
  local offers = market.get_market_items()
  local bought_offer = offers[offer_index].offer
  local this = WPT.get()
  local index = game.forces.player.index
  if bought_offer.type ~= "nothing" then return end

  if offer_index == 1 then
    local wave_number = WD.get('wave_number')
    local times = math.floor(wave_number/100)+this.cap
    if this.health >= times then
      player.print({'amap.cap_upgrad'})
      local pirce_wall=this.health*1000 + 10000
      if pirce_wall >= 50000 then
        pirce_wall = 50000
      end
      player.insert{name='coin',count = pirce_wall}
      return
    end
    this.health=this.health+1
    wall_health.set('biter_health_boost',this.health*0.1+1)

    game.print({'amap.buy_wall_over',player.name,this.health*0.1+1})

  end

  if offer_index == 2 then

    this.arty=this.arty+1
    game.forces.player.set_ammo_damage_modifier("artillery-shell", this.arty*0.1)
    game.print({'amap.buy_arty_over',player.name,this.arty*0.1+1})
  end
  if offer_index == 3 then
    local wave_number = WD.get('wave_number')
    local times = math.floor(wave_number/50)+this.cap
  if times >= 30 then
      times = 30
    end
if this.biter_health >= times then
      player.print({'amap.cap_upgrad'})
      local pirce_biter_health=this.biter_health*1000 +7000
      if pirce_biter_health >= 50000 then
        pirce_biter_health = 50000
      end
      player.insert{name='coin',count =pirce_biter_health}
      return
    end
    this.biter_health=this.biter_health+1
    local health = this.biter_health*0.1+1
BiterHealthBooster.set('biter_health_boost_forces',{[game.forces.player.index]=health})
    game.print({'amap.buy_player_biter_over',player.name,this.biter_health*0.1+1})
  end
  if offer_index == 4 then

    local wave_number = WD.get('wave_number')
    local times = math.floor(wave_number/100)+this.cap
    if this.spider_health >= times then
      player.print({'amap.cap_upgrad'})
      local spider_health=this.spider_health*1000 + 10000
      if spider_health >= 50000 then
        spider_health = 50000
      end
      player.insert{name='coin',count = spider_health}
      return
    end
    this.spider_health=this.spider_health+1
    spider_health.set('biter_health_boost',this.health*0.1+1)
  --  spider_health(index,this.spider_health*0.1+1.1)
    game.print({'amap.buy_spider_health_over',player.name,this.spider_health*0.1+1})
  end
  if offer_index == 5 then
    local wave_number = WD.get('wave_number')
    local times = math.floor(wave_number/100)+this.cap+1
    if times >= 30 then
      times = 30
    end
    if this.biter_dam >= times then
      player.print({'amap.cap_upgrad'})
      local pirce_biter_dam=this.biter_dam*1000 +7000
      if pirce_biter_dam >= 50000 then
        pirce_biter_dam = 50000
      end
      player.insert{name='coin',count = pirce_biter_dam}
      return
    end
    this.biter_dam=this.biter_dam+1
    local damage_increase = this.biter_dam*0.1
    game.forces.player.set_ammo_damage_modifier("melee", damage_increase)
    game.forces.player.set_ammo_damage_modifier("biological", damage_increase)
    game.print({'amap.buy_biter_dam',player.name,this.biter_dam*0.1+1})
  end

  if offer_index == 6 then

this.cap=this.cap+1
    game.print({'amap.buy_cap_over',player.name,this.cap})
  end
  market.force.play_sound({path = 'utility/new_objective', volume_modifier = 0.75})
  market.clear_market_items()
  urgrade_item(market)
  for k, item in pairs(market_items) do
    market.add_market_item(item)
  end

end
Event.add(defines.events.on_rocket_launched, on_rocket_launched)
Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_market_item_purchased,on_market_item_purchased)
return Public
