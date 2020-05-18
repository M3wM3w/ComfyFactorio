local Event = require 'utils.event'
local Power = require "maps.scrapyard.power"
local ICW = require "maps.scrapyard.icw.main"
local Scrap_table = require "maps.scrapyard.table"

local Public = {}

function Public.render_train_hp()
	local this = Scrap_table.get_table()
	local surface = game.surfaces[this.active_surface_index]
	this.health_text = rendering.draw_text{
		text = "HP: " .. this.locomotive_health .. " / " .. this.locomotive_max_health,
		surface = surface,
		target = this.locomotive,
		target_offset = {0, -2.5},
		color = this.locomotive.color,
		scale = 1.40,
		font = "default-game",
		alignment = "center",
		scale_with_zoom = false
	}
	this.caption = rendering.draw_text{
		text = "Grandmasters Train",
		surface = surface,
		target = this.locomotive,
		target_offset = {0, -4.25},
		color = this.locomotive.color,
		scale = 1.80,
		font = "default-game",
		alignment = "center",
		scale_with_zoom = false
	}
end

function Public.locomotive_spawn(surface, position)
	local this = Scrap_table.get_table()
	for y = -6, 6, 2 do
		surface.create_entity({name = "straight-rail", position = {position.x, position.y + y}, force = "player", direction = 0})
	end
	this.locomotive = surface.create_entity({name = "locomotive", position = {position.x, position.y + -3}, force = "player"})
	this.locomotive.get_inventory(defines.inventory.fuel).insert({name = "wood", count = 100})

	this.locomotive_cargo = surface.create_entity({name = "cargo-wagon", position = {position.x, position.y + 3}, force = "player"})
	this.locomotive_cargo.get_inventory(defines.inventory.cargo_wagon).insert({name = "raw-fish", count = 8})

	rendering.draw_light({
		sprite = "utility/light_medium", scale = 5.5, intensity = 1, minimum_darkness = 0,
		oriented = true, color = {255,255,255}, target = this.locomotive,
		surface = surface, visible = true, only_in_alt_mode = false,
	})

	this.locomotive.color = {0, 255, 0}
	this.locomotive.minable = false
	this.locomotive_cargo.minable = false
	this.locomotive_cargo.operable = true

	ICW.register_wagon(this.locomotive)
	ICW.register_wagon(this.locomotive_cargo)
end

function Public.inside(pos, area)
    local lt = area.left_top
    local rb = area.right_bottom

    return pos.x >= lt.x and pos.y >= lt.y and pos.x <= rb.x and pos.y <= rb.y
end
function Public.contains_positions(pos, area)
    if Public.inside(pos, area) then
        return true
    end
    return false
end

local function rebuild_energy_overworld(data)
	local this = data.this
	local surface = data.surface
	if not this.locomotive then return end
	if not this.locomotive.valid then return end
	if not this.locomotive.surface then return end
	if not this.locomotive.surface.valid then return end
	if this.ow_energy then
		if this.ow_energy.valid then
			local position = this.ow_energy.position
			local area = {
	            left_top = {x = position.x - 2, y = position.y - 2},
	            right_bottom = {x = position.x + 2, y = position.y + 2}
	            }
			if Public.contains_positions(this.locomotive.position, area) then return end
			this.old_ow_energy = this.ow_energy.energy
			this.ow_energy.destroy()
			this.energy["scrapyard"] = nil
		end
	end
	this.ow_energy = surface.create_entity{
		name = "electric-energy-interface",
		position = {
			x=this.locomotive.position.x,
			y=this.locomotive.position.y+1
		},
		create_build_effect_smoke = false,
		force = game.forces.neutral
	}

	rendering.draw_text{
	  text = "Power to locomotive",
	  surface = surface,
	  target = this.ow_energy,
	  target_offset = {0, -1.5},
	  color = { r = 0, g = 1, b = 0},
	  alignment = "center"
	}

	this.ow_energy.minable = false
	this.ow_energy.destructible = false
	this.ow_energy.operable = false
	this.ow_energy.power_production = 0
	this.ow_energy.electric_buffer_size = 10000000
	if this.old_ow_energy then
		this.ow_energy.energy = this.old_ow_energy
	end
end

local function rebuild_energy_loco(data, destroy)
	local this = data.this
	local icw_table = data.icw_table
	if not this.locomotive.valid then return end
	local unit_surface = this.locomotive.unit_number
	local loco_surface = game.surfaces[icw_table.wagons[unit_surface].surface.index]
	local pos = {x=-19, y=3}

	if destroy then
		local radius = 1024
		local area = {{x = -radius, y = -radius}, {x = radius, y = radius}}
		for _, entity in pairs(loco_surface.find_entities_filtered{area = area, name = "electric-energy-interface"}) do
			entity.destroy()
		end
		this.energy.loco = nil
		this.lo_energy = nil
	end

	this.lo_energy = loco_surface.create_entity{
		name = "electric-energy-interface",
		position = pos,
		create_build_effect_smoke = false,
		force = game.forces.neutral
	}

	rendering.draw_text{
	  text = "Power to overworld",
	  surface = loco_surface,
	  target = this.lo_energy,
	  target_offset = {0, -1.5},
	  color = { r = 0, g = 1, b = 0},
	  alignment = "center"
	}

	this.lo_energy.minable = false
	this.lo_energy.destructible = false
	this.lo_energy.operable = false
	this.lo_energy.power_production = 0
	this.lo_energy.electric_buffer_size = 10000000
end

function Public.power_source_overworld()
	local this = Scrap_table.get_table()
	local surface = game.surfaces[this.active_surface_index]

	local data = {
		this = this,
		surface = surface
	}

	rebuild_energy_overworld(data)
end

function Public.power_source_locomotive()
	local this = Scrap_table.get_table()
	local icw_table = ICW.get_table()

	local data = {
		this = this,
		icw_table = icw_table
	}

	if not this.lo_energy then
		rebuild_energy_loco(data)

	elseif not this.lo_energy.valid then
		rebuild_energy_loco(data, true)
	end
end

local function fish_tag()
	local this = Scrap_table.get_table()
	if not this.locomotive_cargo then return end
	if not this.locomotive_cargo.valid then return end
	if not this.locomotive_cargo.surface then return end
	if not this.locomotive_cargo.surface.valid then return end
	if this.locomotive_tag then
		if this.locomotive_tag.valid then
			if this.locomotive_tag.position.x == this.locomotive_cargo.position.x and this.locomotive_tag.position.y == this.locomotive_cargo.position.y then return end
			this.locomotive_tag.destroy()
		end
	end
	this.locomotive_tag = this.locomotive_cargo.force.add_chart_tag(
		this.locomotive_cargo.surface,
		{icon = {type = 'item', name = 'raw-fish'},
		position = this.locomotive_cargo.position,
		text = " "
	})
end

local function set_player_spawn_and_refill_fish()
	local this = Scrap_table.get_table()
	if not this.locomotive_cargo then return end
	if not this.locomotive_cargo.valid then return end
	this.locomotive_cargo.get_inventory(defines.inventory.cargo_wagon).insert({name = "raw-fish", count = math.random(2, 5)})
	local position = this.locomotive_cargo.surface.find_non_colliding_position("stone-furnace", this.locomotive_cargo.position, 16, 2)
	if not position then return end
	game.forces.player.set_spawn_position({x = position.x, y = position.y}, this.locomotive_cargo.surface)
end

local function tick()
	Public.power_source_overworld()
	Public.power_source_locomotive()
	if game.tick % 30 == 0 then
		if game.tick % 1800 == 0 then
			set_player_spawn_and_refill_fish()
		end
		fish_tag()
	end
end

Event.on_nth_tick(5, tick)

return Public