local Event = require 'utils.event'
local WPT = require 'maps.amap.table'

local entity_types = {
    ['unit'] = true,
    ['turret'] = true,
    ['unit-spawner'] = true
}

local projectiles = {
    'slowdown-capsule',
    'defender-capsule',
    'destroyer-capsule',
    'laser',
    'distractor-capsule',
    'rocket',
    'explosive-rocket',
    'grenade',
    'rocket',
    'grenade'
}

local wepeon ={
  'gun-turret',
  'land-mine',
  'biter-spawner'
}


local function loaded_biters(event)
    local cause = event.cause
    local entity = event.entity
    if not entity or not entity.valid then
        return
    end
    local cause = event.cause
    if not cause then
        return
    end
    local position = false
    if cause then
        if cause.valid then
            position = cause.position
        end
    end
    if not position then
        position = {entity.position.x + (-20 + math.random(0, 40)), entity.position.y + (-20 + math.random(0, 40))}
    end

local abc = {
  projectiles[math.random(1, 10)],
  wepeon[math.random(1, 2)]
}
k=math.random(1, 14)
if k >= 3 then
  k=1
else
  k=2
end
  e =  entity.surface.create_entity(
        {
            name = abc[k],
            position = entity.position,
            force = 'enemy',
            source = entity.position,
            target = position,
            max_range = 16,
            speed = 0.01
        }

    )
    if e.name == 'gun-turret' then
      e.insert{name='firearm-magazine', count = 30}
    end
end

local on_entity_died = function(event)
  local entity = event.entity
  if not (entity and entity.valid) then
      return
  end
  local cause = event.cause
  if not cause then
      return
  end

  if entity.name == 'land-mine' then
    --body...
        loaded_biters(event)
  end

  if not entity_types[entity.type] then
      return
  end
  if math.random(1, 96) == 1 then
      loaded_biters(event)
  end
end
local function on_player_mined_entity(event)
  local entity = event.entity
	if not entity.valid then return end
	if entity.type ~= "simple-entity" then return end

  if math.random(1, 146) == 1 then
      loaded_biters(event)
  end
end

Event.add(defines.events.on_entity_died, on_entity_died)
Event.add(defines.events.on_entity_damaged, on_entity_damaged)
Event.add(defines.events.on_player_mined_entity, on_player_mined_entity)
