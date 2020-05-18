local Event = require "utils.event"
local Global = require "utils.global"

local function validate_player(player)
  if not player then return false end
  if not player.valid then return false end
  if not player.character then return false end
  if not player.connected then return false end
  if not game.players[player.name] then return false end
  return true
end

local cooldowns = {}
local chests = {}
local inventories = {}

Global.register({
  chests = chests,
  inventories = inventories
}, function(global) 
  chests = global.chests 
  inventories = global.inventories
end)

Global.register({
  cooldowns = cooldowns
}, function(global)
  cooldowns = global.cooldowns
end)



local function check_player_ports(event)
  for _, player in pairs(game.connected_players) do
    if not validate_player(player) then goto continue end
    
    if not cooldowns[player.name] then
      cooldowns[player.name] = game.tick
    end
    
    --if cooldowns[player.name] - game.tick > 0 then goto continue end

    if player.surface.find_entity("player-port", player.position) then
      if cooldowns[player.name] > game.tick then 
        player.play_sound{path="utility/armor_insert", volume_modifier=1} 
        if math.random(1,3) == 1 then
          player.surface.create_entity({
            name = "flying-text",
            position = player.position,
            text = math.ceil((cooldowns[tostring(player.name)] - game.tick)/60),
            color = {r = math.random(130, 170), g = math.random(130, 170), b = 130}
          })
        end
        goto continue end
      local surface_name = player.surface.name == "cave_miner" and "choppy" or "cave_miner"
      local pos = surface_name == "cave_miner" and global.surface_cave_elevator.position or {1, -4}
      local safe_pos = game.surfaces[surface_name].find_non_colliding_position("character", pos, 20, 1)
      if safe_pos then
        player.teleport(safe_pos, surface_name)
      else
        player.teleport({0, -3}, surface_name)
      end
      cooldowns[player.name] = game.tick + 900
    end
--[[
    if cooldowns[player.name] > game.tick then
    local text = rendering.draw_text{
      text = "Cooldown:" .. math.ceil((cooldowns[player.name] - game.tick)/60) .. " seconds",
      surface = "choppy",
      target = global.surface_choppy_elevator,
      target_offset = {0, 5},
      color = { r=0.98, g=0.66, b=0.22},
      alignment = "center"
    }
    else
      rendering.destroy(text)
    end
    if math.random(1, 2) == 1 then
    rendering.destroy(text)
]]--
    ::continue::
  end
end

local function built_entity(event)
  local entity = event.created_entity
  if not entity or not entity.valid then return end
  if entity.name ~= "player-port" then return end
  
  entity.minable = false
  entity.destructible = false
  entity.operable = false
  

  local surface = entity.surface
end

local function tick()

  if not chests["cave_miner"] then 
    chests["cave_miner"] = global.surface_cave_chest
  end

  if not chests["choppy"] then 
    chests["choppy"] = global.surface_choppy_chest
  end

  local cave = chests["cave_miner"]
  local tree = chests["choppy"]

  if not cave or not tree then return end
  if not cave.valid or not tree.valid then return end

  local civ = tree.get_inventory(defines.inventory.chest)
  local oiv = cave.get_inventory(defines.inventory.chest)

  local ci = civ.get_contents()
  local oi = oiv.get_contents()
  for item, count in pairs(ci) do
    local count2 = oi[item] or 0
    local diff = count-count2
    if diff > 1 then
      local count2 = oiv.insert{name = item, count = math.floor(diff/2)}
      if count2 > 0 then
        civ.remove{name = item, count = count2}
      end
    elseif diff < -1 then
      local count2 = civ.insert{name = item, count = math.floor(-diff/2)}
      if count2 > 0 then
        oiv.remove{name = item, count = count2}
      end
    end
  end
  for item, count in pairs(oi) do
    if count > 1 and not ci[item] then
      local count2 = civ.insert{name = item, count = math.floor(count/2)}
      if count2 > 0 then
        oiv.remove{name = item, count = count2}
      end
    end
  end
end

Event.add(defines.events.on_tick, tick)
Event.on_nth_tick(60, check_player_ports)
Event.add(defines.events.on_built_entity, built_entity)