-- one table to rule them all!
local Global = require 'utils.global'
local Event = require 'utils.event'

local dungeontable = {}
local arenatable = {}
local Public = {}

Global.register(
    dungeontable,
    function(tbl)
        dungeontable = tbl
    end
)
Global.register(
    arenatable,
    function(tbl)
        arenatable = tbl
    end
)

function Public.reset_arenatable()
  for k, _ in pairs(arenatable) do
    arenatable[k] = nil
  end
  arenatable.bosses = {}
  arenatable.created = {[1] = false, [2] = false, [3] = false, [4] = false}
  arenatable.active_player = {[1] = nil, [2] = nil, [3] = nil, [4] = nil}
  arenatable.active_boss = {[1] = nil, [2] = nil, [3] = nil, [4] = nil}
  arenatable.enemies = {[1] = nil, [2] = nil, [3] = nil, [4] = nil}
  arenatable.timer = {[1] = -100, [2] = -100, [3] = -100, [4] = -100}
  arenatable.won = {[1] = false, [2] = false, [3] = false, [4] = false}
  arenatable.previous_position = {
      [1] = {position = nil, surface = nil},
      [2] = {position = nil, surface = nil},
      [3] = {position = nil, surface = nil},
      [4] = {position = nil, surface = nil}
  }
end

function Public.reset_dungeontable()
  for k, _ in pairs(dungeontable) do
    dungeontable[k] = nil
  end
	dungeontable.tiered = false
	dungeontable.depth = {}
	dungeontable.spawn_size = 42
	dungeontable.spawner_tier = {}
	dungeontable.transport_chests_inputs = {}
	dungeontable.transport_chests_outputs = {}
	dungeontable.transport_poles_inputs = {}
	dungeontable.transport_poles_outputs = {}
	dungeontable.transport_surfaces = {}
	dungeontable.surface_size = {}
	dungeontable.treasures = {}
  dungeontable.mage_towers = {0, 0, 0, 0, 0, 0, 0, 0}
	dungeontable.item_blacklist = false
	dungeontable.original_surface_index = 1
	dungeontable.enemy_forces = {}
end

function Public.get_arenatable()
    return arenatable
end

function Public.get_dungeontable()
    return dungeontable
end

local function on_init()
    Public.reset_arenatable()
    Public.reset_dungeontable()
end

Event.on_init(on_init)

return Public
