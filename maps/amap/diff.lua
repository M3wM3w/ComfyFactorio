
local Event = require 'utils.event'
local WD = require 'modules.wave_defense.table'
local WPT = require 'maps.amap.table'
local Difficulty = require 'modules.difficulty_vote_by_amount'
local atry_talbe = require "maps.amap.enemy_arty"
local enemy_health = require 'maps.amap.enemy_health_booster_v2'
local BiterHealthBooster = require 'modules.biter_health_booster_v2'
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


local easy = function()
  local wave_defense_table = WD.get_table()
  local player_count = calc_players()

  wave_defense_table.max_active_biters = 768 + player_count * 180

  if wave_defense_table.max_active_biters >= 4000 then
    wave_defense_table.max_active_biters = 4000
  end
  local wave_number = WD.get('wave_number')
  if wave_number >= 1500 then
    wave_number = 1500
  end
  -- threat gain / wave
  local max_threat = 1 + player_count * 0.1
  if max_threat >= 4 then
    max_threat = 4
  end

    max_threat = max_threat + wave_number * 0.0013

    WD.set_biter_health_boost(wave_number * 0.0018+1)
    wave_defense_table.threat_gain_multiplier =  max_threat

  wave_defense_table.wave_interval = 4200 - player_count * 30
  if wave_defense_table.wave_interval < 1800 or wave_defense_table.threat <= 0 then
    wave_defense_table.wave_interval = 1800
  end
  local mintime = 7500 - player_count * 150
  if mintime <= 6000 then
    mintime = 6000
  end
  game.map_settings.enemy_expansion.min_expansion_cooldown = mintime
  --  game.map_settings.enemy_expansion.max_expansion_cooldown = 104000


end
local med = function()
  local wave_defense_table = WD.get_table()
  local player_count = calc_players()

  wave_defense_table.max_active_biters = 768 + player_count * 220

  if wave_defense_table.max_active_biters >= 4000 then
    wave_defense_table.max_active_biters = 4000
  end
  local wave_number = WD.get('wave_number')
  -- threat gain / wave
  if wave_number >= 1500 then
    wave_number = 1500
  end
  local max_threat = 1 + player_count * 0.1
  if max_threat >= 4 then
    max_threat = 4
  end

    max_threat = max_threat + wave_number * 0.0013
    WD.set_biter_health_boost(wave_number * 0.002+1)
    wave_defense_table.threat_gain_multiplier =  max_threat

  wave_defense_table.wave_interval = 4200 - player_count * 45
  if wave_defense_table.wave_interval < 1800 or wave_defense_table.threat <= 0 then
    wave_defense_table.wave_interval = 1800
  end
  local mintime = 7500 - player_count * 240
  if mintime <= 3600 then
    mintime = 3600
  end
  game.map_settings.enemy_expansion.min_expansion_cooldown = mintime
  --  game.map_settings.enemy_expansion.max_expansion_cooldown = 104000

end
local hard = function()
  local wave_defense_table = WD.get_table()
  local player_count = calc_players()

  wave_defense_table.max_active_biters = 768 + player_count * 280

  if wave_defense_table.max_active_biters >= 4000 then
    wave_defense_table.max_active_biters = 4000
  end

  local wave_number = WD.get('wave_number')
  -- threat gain / wave
  if wave_number >= 1500 then
    wave_number = 1500
  end
  local max_threat = 1 + player_count * 0.1
  if max_threat >= 4 then
    max_threat = 4
  end

    max_threat = max_threat + wave_number * 0.0013
    WD.set_biter_health_boost(wave_number * 0.0022+1)
    wave_defense_table.threat_gain_multiplier =  max_threat

  wave_defense_table.wave_interval = 3900 - player_count * 60
  if wave_defense_table.wave_interval < 1800 or wave_defense_table.threat <= 0 then
    wave_defense_table.wave_interval = 1800
  end
  local mintime = 7500 - player_count * 300
  if mintime <= 3000 then
    mintime = 3000
  end
  game.map_settings.enemy_expansion.min_expansion_cooldown = mintime
  --  game.map_settings.enemy_expansion.max_expansion_cooldown = 104000

end

local set_diff = function()

  local game_lost = WPT.get('game_lost')
  if game_lost then
    return
  end

  local diff= Difficulty.get()
  if diff.difficulty_vote_index == 1 then
    easy()
  end
  if diff.difficulty_vote_index == 2 then
    med()
  end
  if diff.difficulty_vote_index == 3 then
    hard()
  end

local health = BiterHealthBooster.get('biter_health_boost')
enemy_health.set('biter_health_boost_forces',{[game.forces.enemy.index]=health})
  --med()
  local wave_number = WD.get('wave_number')
  local damage_increase = 0
  -- local any=wave_number+150
  -- local k= math.floor(any/1000)
  -- if k <= 1 then
  --   k =1
  -- end
  -- if k >= 5 then
  --   k =5
  -- end
  local k = math.sqrt(diff.difficulty_vote_index)
  if k <= 1 then
    k =1
  end
  k=math.floor(k)
  damage_increase = wave_number * 0.001*k*1.2
  --game.forces.player.get_ammo_damage_modifier("beam")
--game.forces.enemy.set_ammo_damage_modifier("artillery-shell", damage_increase)
--game.forces.enemy.set_ammo_damage_modifier("rocket", damage_increase)
  game.forces.enemy.set_ammo_damage_modifier("melee", damage_increase)
  game.forces.enemy.set_ammo_damage_modifier("biological", damage_increase)

  local table = atry_talbe.get()
  local radius=math.floor(wave_number*0.15)*k
if radius >= 350 then
  radius = 350
end
table.radius=350+radius
local pace=wave_number*0.0002*k+1
--if pace >= 2 then
  pace = 1.5
--end
table.pace=pace

end
Event.on_nth_tick(600, set_diff)
