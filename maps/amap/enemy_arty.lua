local Event = require 'utils.event'
local Global = require 'utils.global'
local Task = require 'utils.task'
local arty_count = {}
local Public = {}
local Token = require 'utils.token'
local WPT = require 'maps.amap.table'
local Loot = require'maps.amap.loot'

local turret_worth ={
  [1]={name='stone-wall',worth=0},
  [2]={name='land-mine',worth=1},
  [3]={name='laser-turret',worth=2},
  [4]={name='gun-turret',worth=1},
  [5]={name='medium-worm-turret',worth=2},
  [6]={name='flamethrower-turret',worth=3},
  [7]={name='big-worm-turret',worth=7},
  [8]={name='behemoth-worm-turret',worth=20},
  [9]={name='artillery-turret',worth=30}

}
local ammo={
  [1]={name='firearm-magazine'},
  [2]={name='piercing-rounds-magazine'},
  [3]={name='uranium-rounds-magazine'},
}
local direction={
  [1]={'north'},
  [2]={'east'},
  [3]={'south'},
  [4]={'west'},
}
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
  arty_count.max = 100

  arty_count.pace = 1
  arty_count.radius = 350
  arty_count.distance = 1050
  arty_count.surface = {}
arty_count.index=1
  arty_count.fire = {}

  arty_count.all = {}
  arty_count.gun={}
  arty_count.laser={}
  arty_count.flame={}

  arty_count.last=145
arty_count.ammo_index=1
  arty_count.count=0
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
function Public.get_ammo()
  local index = arty_count.ammo_index
local ammo_name =ammo[index].name
return ammo_name
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

local function gun_bullet ()
  for index = 1, #arty_count.gun do
    local turret = arty_count.gun[index]
    if not (turret and turret.valid) then
      fast_remove(arty_count.gun, index)
      return
    end
    local index = arty_count.ammo_index
local ammo_name =ammo[index].name
  turret.insert{name=ammo_name, count = 200}
  end
end

local function flame_bullet ()
  for index = 1, #arty_count.flame do
    local turret = arty_count.flame[index]
    if not (turret and turret.valid) then
      fast_remove(arty_count.flame, index)
      return
    end

    turret.fluidbox[1]={name = 'light-oil', amount = 100}
    -- {name = 'light-oil', amount = 100}
    --     local data = turret_data.data
    --     if data.liquid then
    --         turret.fluidbox[1] = data
    --     elseif data then
    --         turret.insert(data)
    --     end
    --turret.fluidbox[1]={name='light-oil', count = 100}

  end
end

local function energy_bullet ()
  for index = 1, #arty_count.laser do
    local turret = arty_count.laser[index]
    if not (turret and turret.valid) then
      fast_remove(arty_count.laser, index)
      return
    end

    turret.energy = 0xfffff

  end
end

local function on_chunk_generated(event)
  local surface = event.surface
  local area = event.area
  local this = WPT.get()
  if	not(surface.index == game.surfaces[this.active_surface_index].index) then return end
  local resource=game.surfaces[this.active_surface_index].find_entities_filtered{area = event.area,type = "resource"}
  --

  if not resource[1] then
    return
  end
  if not resource[1].valid then
    return
  end

  local pos = resource[1].position

  local a = math.abs(pos.x)
  local b = math.abs(pos.y)


  local dis = math.sqrt(a^2+b^2)
  if dis <145 then
    return
  end
if dis > 450 and arty_count.ammo_index==1 then
arty_count.ammo_index=2
end

if dis > 1200 and arty_count.ammo_index==2 then
arty_count.ammo_index=3
end


--  local q = dis - arty_count.last -5

  if  arty_count.last== event.area.left_top.x then
     return
   end
  arty_count.last= event.area.left_top.x
  local many_turret = math.floor(dis*0.05)
  if many_turret<=20 then many_turret=20 end
  if many_turret>=1000 then many_turret=1000 end
  local radius =math.floor(dis*0.03)
  if radius > 50 then radius = 50 end
  while many_turret > 0 do
    local roll_k =math.floor(many_turret/6)
    if roll_k < 6 then roll_k = 6 end
    if roll_k > 9 then roll_k = 9 end
    local roll_turret = math.random(1,roll_k)
    local turret_name = turret_worth[roll_turret].name

    local n = math.random(-100,100)
    local t = math.random(-100,100)
    if n>=0 then n=1 else n = -1 end
    if t>=0 then t=1 else t = -1 end
    local rand_x = pos.x + math.random(1,radius+10)*n
    local rand_y = pos.y + math.random(1,radius+10)*t


      local e = surface.create_entity{name = turret_name, position = {x=rand_x,y=rand_y},
      force=game.forces.enemy,
      direction= math.random(1,7)}
      many_turret=many_turret-turret_worth[roll_turret].worth
      --  game.print(e.direction)
      if e.valid and e.name then
      if e.name == 'gun-turret' then arty_count.gun[#arty_count.gun+1]=e end
      if e.name == 'laser-turret' then arty_count.laser[#arty_count.laser+1]=e end
      if e.name == 'flamethrower-turret' then arty_count.flame[#arty_count.flame+1]=e end
      if e.name == 'artillery-turret' then
     arty_count.all[e.unit_number]=e
     --game.print(e.position)
      arty_count.count = arty_count.count + 1
      end
    end
  end


  for i=1,200 do
    local n = math.random(-100,100)
    local t = math.random(-100,100)
    if n>=0 then n=1 else n = -1 end
    if t>=0 then t=1 else t = -1 end
    local rand_x = pos.x + math.random(1,radius+10)*n
    local rand_y = pos.y + math.random(1,radius+10)*t

    if surface.can_place_entity{name = "stone-wall", position = {x=rand_x,y=rand_y}, force=game.forces.enemy} then
    surface.create_entity{name = "stone-wall", position ={x=rand_x,y=rand_y}, force=game.forces.enemy}
    end
  end
  for i=1,13 do
    local n = math.random(-100,100)
    local t = math.random(-100,100)
    if n>=0 then n=1 else n = -1 end
    if t>=0 then t=1 else t = -1 end
    local rand_x = pos.x + math.random(1,radius+15)*n
    local rand_y = pos.y + math.random(1,radius+15)*t

    surface.create_entity{name = "land-mine", position ={x=rand_x,y=rand_y}, force=game.forces.enemy}
  end

 local many_baozhang =math.random(2, 5)

dis =math.floor(dis)
if dis > 1500 then dis = 1500 end
--game.print(dis)
  while many_baozhang>=0 do
    local n = math.random(-100,100)
    local t = math.random(-100,100)
    if n>=0 then n=1 else n = -1 end
    if t>=0 then t=1 else t = -1 end
    local rand_x = pos.x + math.random(1,5)*n
    local rand_y = pos.y + math.random(1,5)*t
local bz_position={x=rand_x,y=rand_y}
local magic = math.random(1+dis*0.05, dis*0.25)
    Loot.cool(surface, surface.find_non_colliding_position("steel-chest", bz_position, 20, 1, true) or bz_position, 'steel-chest', magic)
     many_baozhang= many_baozhang-1
  end

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

local function add_bullet()
  gun_bullet()
  flame_bullet()
  energy_bullet()
end



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
if not arty_count.fire[arty_count.index] then
arty_count.fire[arty_count.index] = 0
end
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
Event.add(defines.events.on_chunk_generated, on_chunk_generated)
Event.add(defines.events.on_entity_died, on_entity_died)
--Event.add(defines.events.on_player_changed_position, on_player_changed_position)
Event.on_nth_tick(10, add_bullet)
Event.on_nth_tick(10, do_artillery_turrets_targets)
Event.on_init(on_init)


return Public
