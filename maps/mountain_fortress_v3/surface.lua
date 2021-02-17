local Global = require 'utils.global'
local surface_name = 'mountain_fortress_v3'
local WPT = require 'maps.mountain_fortress_v3.table'
local Reset = require 'maps.mountain_fortress_v3.soft_reset'

local Public = {}

local this = {
    active_surface_index = nil,
    surface_name = surface_name
}

Global.register(
    this,
    function(tbl)
        this = tbl
    end
)

local starting_items = {['pistol'] = 1, ['firearm-magazine'] = 16, ['rail'] = 16, ['wood'] = 16, ['explosives'] = 32}

function Public.create_surface()
    local map_gen_settings = {
        ['seed'] = math.random(10000, 99999),
        ['width'] = WPT.level_width,
        ['water'] = 0.001,
        ['starting_area'] = 1,
        ['cliff_settings'] = {cliff_elevation_interval = 0, cliff_elevation_0 = 0},
        ['default_enable_all_autoplace_controls'] = true,
        ['autoplace_settings'] = {
            ['entity'] = {treat_missing_as_default = false},
            ['tile'] = {
                settings = {
                    ['deepwater'] = {frequency = 1, size = 0, richness = 1},
                    ['deepwater-green'] = {frequency = 1, size = 0, richness = 1},
                    ['water'] = {frequency = 1, size = 0, richness = 1},
                    ['water-green'] = {frequency = 1, size = 0, richness = 1},
                    ['water-mud'] = {frequency = 1, size = 0, richness = 1},
                    ['water-shallow'] = {frequency = 1, size = 0, richness = 1}
                },
                treat_missing_as_default = true
            },
            ['decorative'] = {treat_missing_as_default = true}
        },
        property_expression_names = {
            cliffiness = 0,
            ['tile:water:probability'] = -10000,
            ['tile:deep-water:probability'] = -10000
        }
    }
    local modded = is_game_modded()
    if modded then
        map_gen_settings.autoplace_controls = {}
        if game.active_mods['Krastorio2'] then
            map_gen_settings.autoplace_controls.imersite = {
                frequency = 1,
                richness = 1,
                size = 1
            }
            map_gen_settings.autoplace_controls['mineral-water'] = {
                frequency = 1,
                richness = 1,
                size = 1
            }
            map_gen_settings.autoplace_controls['rare-metals'] = {
                frequency = 1,
                richness = 1,
                size = 1
            }
        end
        if game.active_mods['Factorio-Tiberium'] then
            map_gen_settings.autoplace_controls.tibGrowthNode = {
                frequency = 1,
                richness = 1,
                size = 1
            }
        end
    end

    local mine = {}
    mine['control-setting:moisture:bias'] = 0.33
    mine['control-setting:moisture:frequency:multiplier'] = 1

    map_gen_settings.property_expression_names = mine

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
