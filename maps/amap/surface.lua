local Global = require 'utils.global'
local surface_name = 'amap'
local WPT = require 'maps.amap.table'
local Reset = require 'maps.amap.soft_reset'

local Public = {}

local this = {
    active_surface_index = nil,
    surface_name = surface_name,
}

Global.register(
    this,
    function(tbl)
        this = tbl
    end
)

local starting_items = {['pistol'] = 1, ['firearm-magazine'] = 16,  ['wood'] = 16}

function Public.create_surface()
        local map_gen_settings = {
        ['seed'] = math.random(10000, 99999),
        ['starting_area'] = 1.2,
        ['default_enable_all_autoplace_controls'] = true,
        ['water'] = 0.65

    }
	map_gen_settings.autoplace_controls = {
			["coal"] = {frequency = "1.4", size = "1", richness = "0.7"},
			["stone"] = {frequency = "1.4", size = "1", richness = "0.7"},
			["copper-ore"] = {frequency = "1.4", size = "2", richness = "0.7"},
			["iron-ore"] = {frequency ="1.4", size = "2", richness = "0.7"},
			["crude-oil"] = {frequency = "2", size = "2", richness = "1"},
			["trees"] = {frequency = "1", size = "0.7", richness = "0.7"},
			["enemy-base"] = {frequency = "4", size = "2", richness = "1"},
			--["starting_area"] = 1.2,
		}
    if not this.active_surface_index then
        this.active_surface_index = game.create_surface(surface_name, map_gen_settings).index
    else
        this.active_surface_index = Reset.soft_reset_map(game.surfaces[this.active_surface_index], map_gen_settings, starting_items).index
    end




    if not this.cleared_nauvis then
        local mgs = game.surfaces['nauvis'].map_gen_settings
        mgs.width = 16
        mgs.height = 16
        game.surfaces['nauvis'].map_gen_settings = mgs
        game.surfaces['nauvis'].clear()
        this.cleared_nauvis = true
    end
--local size = game.surfaces[this.active_surface_index].map_gen_settings
  --  size.width = 512
   -- size.height = 512
    --game.surfaces[this.active_surface_index].map_gen_settings = size
    return this.active_surface_index
end

function Public.get_active_surface()
    return this.active_surface
end

function Public.get_surface_name()
    return this.surface_name
end

function Public.get(key)
    if key then
        return this[key]
    else
        return this
    end
end

return Public
