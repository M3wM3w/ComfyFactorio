local Event = require 'utils.event'
local Global = require 'utils.global'
local Task = require 'utils.task'
local arty_count = {}
local Public = {}
local Token = require 'utils.token'
local WPT = require 'maps.amap.table'
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
  --  'silo',
    'spidertron'
}

Global.register(
    arty_count,
    function(tbl)
        arty_count = tbl
    end
)

function Public.reset_table()
  arty_count.max = 50
  arty_count.all = {}
  arty_count.count = 0
  arty_count.pace = 1
  arty_count.radius = 350
  arty_count.distance = 1400
  arty_count.surface = {}
  arty_count.index = 1
  arty_count.fire = {}
end


function Public.get(key)
    if key then
        return arty_count[key]
    else
        return arty_count
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

local on_init = function()
    Public.reset_table()
end

local function add_bullet ()
  for k, p in pairs(arty_count.all) do
      if arty_count.all[k].valid then
        arty_count.all[k].insert{name='artillery-shell', count = '5'}
      end
  end
end
local function on_chunk_generated(event)
   local surface = event.surface
   local this = WPT.get()
   if	not(surface.index == game.surfaces[this.active_surface_index].index) then return end
	
   local left_top_x = event.area.left_top.x
   local left_top_y = event.area.left_top.y

  local position
   for x = 0, 31, 1 do
 		for y = 0, 31, 1 do
    	position = {x = left_top_x + x, y = left_top_y + y}
      local q =position.x*position.x
      local w =position.y*position.y
      local distance =math.sqrt(q+w)

      if distance >= arty_count.distance then

        if arty_count.count >= arty_count.max then
          return
        else
        local roll = math.random(1, 8024)
        if roll == 1 then
          local arty = surface.create_entity{name = "artillery-turret", position = position, force='enemy'}
        --  arty.insert{name='artillery-shell', count = '5'}
          --local k = #arty_count.all
    --      game.print(k)
         arty_count.all[arty.unit_number]=arty
        -- game.print(arty_count.all[1].name)
          arty_count.count = arty_count.count + 1
      --    game.print(arty_count.count)
      -- game.print(position)
        end
      end
    end
  end
  end

end

local function on_entity_died(event)


  local entity = event.entity

if not entity or not entity.valid then return end


 if arty_count.all[entity.unit_number] then
 arty_count.all[entity.unit_number] = nil
 arty_count.count = arty_count.count - 1
 end
-- local force = entity.force
--  local name = entity.name
--   if name == 'artillery-turret' and force.name == 'enemy' then
-- arty_count.all[entity.unit_number] = nil
--     arty_count.count = arty_count.count -1
--
--      if arty_count.count <= 0 then
--        arty_count.count = 0
--      end

end

function on_player_changed_position(event)
local player = game.players[event.player_index]
local surface = player.surface
if not surface.valid then
    return
end

local position = player.position

local q =position.x*position.x
local w =position.y*position.y
local distance =math.sqrt(q+w)
--artillery-targeting-remote
game.print("123")
surface.create_entity(
    {
        name = 'artillery-targeting-remote',
        position = position,
        force = 'enemy',
      --  target = position,
      --  speed = 0.001
    }
  )
  game.print("logging")
end
local artillery_target_callback =
    Token.register(
    function(data)
        local position = data.position
        local entity = data.entity

        if not entity.valid then
            return
        end

        local tx, ty = position.x, position.y
        local pos = entity.position
        local x, y = pos.x, pos.y
        local dx, dy = tx - x, ty - y
        local d = dx * dx + dy * dy
        if d >= 1024 and d <= 441398 then -- 704 in depth~
            if entity.name == 'character' then
                entity.surface.create_entity {
                    name = 'artillery-projectile',
                    position = position,
                    target = entity,
                    force = 'enemy',
                    speed = arty_count.pace
                }
            elseif entity.name ~= 'character' then
                entity.surface.create_entity {
                    name = 'rocket',
                    position = position,
                    target = entity,
                    force = 'enemy',
                    speed = arty_count.pace
                }
            end
        end
    end
)

local function do_artillery_turrets_targets()
--local surface = arty_count.surface
  local this = WPT.get()
local surface = game.surfaces[this.active_surface_index]
if arty_count.count <= 0 then return end
--选取重炮
  local roll_table = {}
  for index, arty in pairs(arty_count.all) do
    if arty.valid then
      roll_table[#roll_table + 1] = arty
    else
      arty_count.all[index] = nil   -- <- if not valid, remove from table
      arty_count.count = arty_count.count - 1
    end
  end
  if #roll_table <= 0 then return end
  --local roll = math.random(1, #roll_table)
--if arty_count.index > #roll_table then arty_count.index=1 end
if arty_count.index and roll_table and arty_count.index > #roll_table then
  arty_count.index = 1
end

local now =game.tick

if (now - arty_count.fire[arty_count.index]) < 480 then return end
arty_count.fire[arty_count.index] = now
  local position = roll_table[arty_count.index].position
arty_count.index=arty_count.index+1
  --扫描区域
--   local normal_area = {left_top = {-480, -480}, right_bottom = {480, 480}}
-- game.print(123)
-- normal_area=  roll_table[roll].artillery_area
-- game.print(12)
local entities = surface.find_entities_filtered{position = position, radius = arty_count.radius, name = artillery_target_entities, force = game.forces.player}

    -- local entities = surface.find_entities_filtered {area = normal_area, name = artillery_target_entities, force = 'player'}
    if #entities == 0 then
        return
    end


--开火
  for i = 1, arty_count.count do
      local entity = entities[math.random(#entities)]
--game.print(entity.position)
      if entity and entity.valid then
          local data = {position = position, entity = entity}
          Task.set_timeout_in_ticks(i * 60, artillery_target_callback, data)
      end
  end
end
Event.add(defines.events.on_chunk_generated, on_chunk_generated)
Event.add(defines.events.on_entity_died, on_entity_died)
--Event.add(defines.events.on_player_changed_position, on_player_changed_position)
--Event.on_nth_tick(600, add_bullet)
Event.on_nth_tick(10, do_artillery_turrets_targets)
Event.on_init(on_init)


return Public
