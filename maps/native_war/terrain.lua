local math_abs = math.abs
local math_random = math.random
local Map_functions = require "tools.map_functions"
local simplex_noise = require 'utils.simplex_noise'.d2
local Public = {}

local hatchery_position = {x = 200, y = 0}
local table_tiles = {
	[1] = "concrete",
	[2] = "refined-concrete",
	[3] = "stone-path",
}
local function get_replacement_tile(surface, position)
	for i = 1, 128, 1 do
		local vectors = {{0, i}, {0, i * -1}, {i, 0}, {i * -1, 0}}
		table.shuffle_table(vectors)
		for k, v in pairs(vectors) do
			local tile = surface.get_tile(position.x + v[1], position.y + v[2])
			if not tile.collides_with("resource-layer") then return tile.name end
		end
	end
	return "grass-1"
end

local function place_market(surface, position, team_force)
	local market = surface.create_entity({name = "market", position = position, force = team_force})
	market.minable = false
	return market
end

local function kill_entities_combat_zone(surface, table_area)
	for _, ent in pairs(surface.find_entities_filtered{area = table_area, type = "resource"}) do ent.destroy() end
	for _, entity in ipairs(surface.find_entities_filtered{ area= table_area, type="tree"})  do entity.destroy() end
end

local function create_markets(surface)
	local wall = surface.create_entity({name = "stone-wall", position = {-15, -174}, force = "spectator"})
	wall.destructible=false
	wall.minable=false
	local wall = surface.create_entity({name = "stone-wall", position = {15, -174}, force = "spectator"})
	wall.destructible=false
	wall.minable=false
	local wall = surface.create_entity({name = "stone-wall", position = {-15, 174}, force = "spectator"})
	wall.destructible=false
	wall.minable=false
	local wall = surface.create_entity({name = "stone-wall", position = {15, 174}, force = "spectator"})
	wall.destructible=false
	wall.minable=false
	surface.create_entity({name = "electric-beam", position = {-15, -174}, source = {-15, -174}, target = {15,-174}})
	surface.create_entity({name = "electric-beam", position = {-15, 174}, source = {-15, 174}, target = {15,174}})
	local x = hatchery_position.x
	local y = hatchery_position.y
	for i=169, 200, 1 do
		for j=1, 100, 1 do
			if math.sqrt((i*-1+160)*(i*-1+160)+(j-50)*(j-50))>=38 and math.sqrt((i*-1+160)*(i*-1+160)+(j-50)*(j-50))<=40 then
				if j== 50 or j== 49 or j==51 then else
					local wall = surface.create_entity({name = "stone-wall", position = {i*-1, j-50}, force = "west"})
					wall.destructible=false
					wall.minable=false
				end
			end
		end
	end
	for i=169, 200, 1 do
		for j=1, 100, 1 do
			if math.sqrt((i-160)*(i-160)+(j-50)*(j-50))>=38 and math.sqrt((i-160)*(i-160)+(j-50)*(j-50))<=40 then
				if j== 50 or j== 49 or j==51 then else
					local wall = surface.create_entity({name = "stone-wall", position = {i, j-50}, force = "east"})
					wall.destructible=false
					wall.minable=false
				end
			end
		end
	end
	local position = {(x * -1)+2, 0}
	local e = place_market(surface, position, "west")
	global.market1=e

	local energy_source = {type = "electric", buffer_capacity = "10GJ", usage_priority = "tertiary", input_flow_limit = "1GW", output_flow_limit = "0W", drain="0W"}
	local eei = surface.create_entity({type = "electric-energy-interface", name = "electric-energy-interface", energy_source = energy_source, position = {-200,-2}, force = "west"})
	local ep = surface.create_entity({name = "small-electric-pole", position = {-200,-5}, force = "west"})

	ep.destructible=false
	ep.minable=false
	eei.operable = false
	eei.destructible=false
	eei.minable=false
	eei.electric_buffer_size  = 100000000
	eei.power_usage = 48000000
	eei.power_production = 1

	--surface.create_entity({name = "small-worm-turret", position = {x * -1 + 6, 0}, force = "west"})

	global.map_forces.west.hatchery = e
	global.map_forces.east.target = e

	local position = {x-2, 0}
	local f = place_market(surface, position, "east")
	global.market=f

	local energy_source = {type = "electric", buffer_capacity = "10GJ", usage_priority = "tertiary", input_flow_limit = "1GW", output_flow_limit = "0W", drain="0W"}
	local eei2 = surface.create_entity({type = "electric-energy-interface", name = "electric-energy-interface", energy_source = energy_source, position = {201,-2}, force = "east"})
	local ep2 = surface.create_entity({name = "small-electric-pole", position = {200,-5}, force = "east"})

	ep2.destructible=false
	ep2.minable=false
	eei2.operable = false
	eei2.destructible=false
	eei2.minable=false
	eei2.electric_buffer_size  = 100000000
	eei2.power_usage = 48000000
	eei2.power_production = 1
	--surface.create_entity({name = "small-worm-turret", position = {x - 6, 0}, force = "east"})
	global.map_forces.east.hatchery = f
	global.map_forces.west.target = f

	--global.map_forces.east.spawn = {x=137,y=0}
	--global.map_forces.west.spawn = {x=-137,y=0}

	local area ={{-174,-150},{174,150}}
	kill_entities_combat_zone(surface, area)

	local te = surface.create_entity({name = "tree-09-red", position = {137,0}, force = "neutral"})
	local tw = surface.create_entity({name = "tree-04", position = {-137,0}, force = "neutral"})
	te.minable =false
	tw.minable = false
	te.destructible = false
	tw.destructible = false
end

local function draw_noise_ore_patch(position, name, surface, radius, richness)
	if not position then return end
	if not name then return end
	if not surface then return end
	if not radius then return end
	if not richness then return end
	local seed = game.surfaces[1].map_gen_settings.seed
	local noise_seed_add = 25000
	local richness_part = richness / radius
	for y = radius * -3, radius * 3, 1 do
		for x = radius * -3, radius * 3, 1 do
			local pos = {x = x + position.x + 0.5, y = y + position.y + 0.5}
			local noise_1 = simplex_noise(pos.x * 0.0125, pos.y * 0.0125, seed)
			local noise_2 = simplex_noise(pos.x * 0.1, pos.y * 0.1, seed + 25000)
			local noise = noise_1 + noise_2 * 0.12
			local distance_to_center = math.sqrt(x^2 + y^2)
			local a = richness - richness_part * distance_to_center
			if distance_to_center < radius - math.abs(noise * radius * 0.85) and a > 1 then
				if surface.can_place_entity({name = name, position = pos, amount = a}) then

					surface.create_entity{name = name, position = pos, amount = a}

					local mirror_pos = {x = pos.x * -1, y = pos.y }
					surface.create_entity{name = name, position = mirror_pos, amount = a}

					for _, e in pairs(surface.find_entities_filtered({position = pos, name = {"wooden-chest", "gun-turret"}})) do
						e.destroy()
					end
					for _, e in pairs(surface.find_entities_filtered({position = mirror_pos, name = {"wooden-chest", "gun-turret"}})) do
						e.destroy()
					end
				end
			end
		end
	end
end

local function first_ore_generate(surface)
	local area = {{250, -50}, {300, 50}}
	local ores = {}
	ores["iron-ore"] = surface.count_entities_filtered({name = "iron-ore", area = area})
	ores["copper-ore"] = surface.count_entities_filtered({name = "copper-ore", area = area})
	ores["coal"] = surface.count_entities_filtered({name = "coal", area = area})
	ores["stone"] = surface.count_entities_filtered({name = "stone", area = area})
	for ore, ore_count in pairs(ores) do
		if ore_count < 1000 or ore_count == nil then
			local pos = {}
			for a = 1, 32, 1 do
				pos = {x = math_random(250, 300), y = math_random(-50, 50)}
				if surface.can_place_entity({name = "coal", position = pos, amount = 1}) then
					break
				end
			end
			draw_noise_ore_patch(pos, ore, surface, math_random(18, 24), math_random(1500, 2000))
		end
	end
end

local function mirror_chunk(event, source_surface, x_modifier)
	local surface = event.surface
	local left_top = event.area.left_top
	local offset = 0
	if x_modifier == -1 then offset = 32 end
	local mirror_left_top = {x = left_top.x * x_modifier - offset, y = left_top.y}

	source_surface.request_to_generate_chunks(mirror_left_top, 1)
	source_surface.force_generate_chunk_requests()

	local mirror_area = {{mirror_left_top.x , mirror_left_top.y}, {mirror_left_top.x + 32, mirror_left_top.y + 32}}

	for _, tile in pairs(source_surface.find_tiles_filtered({area = mirror_area})) do
		surface.set_tiles({{name = tile.name, position = {x = tile.position.x * x_modifier, y = tile.position.y}}}, true)
	end
	for _, entity in pairs(source_surface.find_entities_filtered({area = mirror_area})) do
		if surface.can_place_entity({name = entity.name, position = {x = entity.position.x * x_modifier, y = entity.position.y}}) then
			entity.clone({position = {x = entity.position.x * x_modifier, y = entity.position.y}, surface = surface, force = "neutral"})
		end
	end
	for _, decorative in pairs(source_surface.find_decoratives_filtered{area = mirror_area}) do
		surface.create_decoratives{
			check_collision=false,
			decoratives={{name = decorative.decorative.name, position = {x = decorative.position.x * x_modifier, y = decorative.position.y}, amount = decorative.amount}}
		}
	end
end

local function combat_area(event)
	local surface = event.surface
	local left_top = event.area.left_top

	if left_top.y >= 15 then return end
	if left_top.y < -15 then return end

	local replacement_tile = "landfill"
	local tile = surface.get_tile({8,0})
	if tile then replacement_tile = tile.name end

	for _, tile in pairs(surface.find_tiles_filtered({area = event.area})) do
		-- if tile.name == "water" or tile.name == "deepwater" then
			-- surface.set_tiles({{name = replacement_tile, position = tile.position}}, true)
		-- end
		-- if tile.position.x >= -4 and tile.position.x < 4 then
			-- surface.set_tiles({{name = "water-shallow", position = tile.position}}, true)
		-- end
	end
	--[[
	for _, entity in pairs(surface.find_entities_filtered({type = {"resource", "cliff"}, area = event.area})) do
		entity.destroy()
	end
	]]
end

local function is_out_of_map(p)
	--if math.sqrt((p.x*p.x)+(p.y*p.y))<30 then return end
	--if math.sqrt((p.x*p.x)+(p.y*p.y))<30 then return end
	if math.sqrt((p.x+90)*(p.x+90)+(p.y+100)*(p.y+100))<15 then return true end
	if math.sqrt((p.x+90)*(p.x+90)+(p.y+100)*(p.y+100))<45 and p.y <=-100 then return end
	if math.sqrt((p.x-30)*(p.x-30)+(p.y+100)*(p.y+100))<15 then return true end
	if math.sqrt((p.x-30)*(p.x-30)+(p.y+100)*(p.y+100))<45 and p.y <=-100 then return end
	if math.sqrt((p.x-90)*(p.x-90)+(p.y-100)*(p.y-100))<15 then return true end
	if math.sqrt((p.x-90)*(p.x-90)+(p.y-100)*(p.y-100))<45 and p.y >=100 then return end
	if math.sqrt((p.x+30)*(p.x+30)+(p.y-100)*(p.y-100))<15 then return true end
	if math.sqrt((p.x+30)*(p.x+30)+(p.y-100)*(p.y-100))<45 and p.y >=100 then return end
	if math.sqrt((p.x+135)*(p.x+135)+(p.y)*(p.y))<30 and p.y >=0 and p.x >= -135 then return end
	if math.sqrt((p.x-135)*(p.x-135)+(p.y)*(p.y))<30 and p.y <=0 and p.x <= 135 then return end
	if p.x >= -15 and p.x <= 15 and ( p.y<=100 and p.y >= -100) then return end
	if p.x >= -75 and p.x <= -45 and ( p.y<=100 and p.y >= -100) then return end
	if p.x >= 45 and p.x <= 75 and ( p.y<=100 and p.y >= -100) then return end
	if p.x >= -135 and p.x <= -105 and ( p.y<=0 and p.y >= -100) then return end
	if p.x >= 105 and p.x <= 135 and ( p.y<=100 and p.y >= 0) then return end
	if p.x > -105 and p.x <= -75 and ( p.y>=-15 and p.y <= 15) then return true end
	if p.x >= 75 and p.x < 105 and ( p.y>=-15 and p.y <= 15) then return true end
	if p.y < 30 and p.y >= -30 and p.x >= 135  then return end
	if p.y < 30 and p.y >= -30 and p.x <= -135  then return end
	if p.x * 0.5 >= math_abs(p.y)+50 then return end
	if p.x * -0.5 > math_abs(p.y)+50 then return end
	return true
end

local function out_of_map_area(event)
	local surface = event.surface
	local left_top = event.area.left_top

	for x = -1, 32, 1 do
		for y = -1, 32, 1 do
			local p = {x = left_top.x + x, y = left_top.y + y}
			if is_out_of_map(p) then
				if (p.x == -137 or p.x == -138 or p.x == -102 or p.x == -103 or p.x == -78 or p.x == -77 or p.x == -42 or p.x == -43 or p.x == -17 or p.x == -18 or p.x == 17 or p.x == 18 or p.x == 42 or p.x == 43 or p.x == 77 or p.x == 78) and (p.y == -32 or p.y == -33 or p.y == -95 or p.y == -96) then
					surface.set_tiles({{name = "hazard-concrete-right", position = p}}, true)
					if (p.x == -137 and p.y == -32) and surface.can_place_entity({name="substation", position = {p.x,p.y}, force = 'neutral'}) then
						local e = surface.create_entity({name="substation", position = {p.x,p.y}, force = 'neutral'})
						e.destructible=false
						e.minable=false
					end
					if (p.x == -137 and p.y == -95) then
						local e = surface.create_entity({name="substation", position = {p.x,p.y}, force = 'neutral'})
						e.destructible=false
						e.minable=false
					end
					if (p.x == -102 and p.y == -32) then
						local e = surface.create_entity({name="substation", position = {p.x,p.y}, force = 'neutral'})
						e.destructible=false
						e.minable=false
					end
					if (p.x == -102 and p.y == -95) then
						local e = surface.create_entity({name="substation", position = {p.x,p.y}, force = 'neutral'})
						e.destructible=false
						e.minable=false
					end
					if (p.x == -77 and p.y == -32) then
						local e = surface.create_entity({name="substation", position = {p.x,p.y}, force = 'neutral'})
						e.destructible=false
						e.minable=false
					end
					if (p.x == -77 and p.y == -95) then
						local e = surface.create_entity({name="substation", position = {p.x,p.y}, force = 'neutral'})
						e.destructible=false
						e.minable=false
					end
					if (p.x == -42 and p.y == -32) then
						local e = surface.create_entity({name="substation", position = {p.x,p.y}, force = 'neutral'})
						e.destructible=false
						e.minable=false
					end
					if (p.x == -42 and p.y == -95) then
						local e = surface.create_entity({name="substation", position = {p.x,p.y}, force = 'neutral'})
						e.destructible=false
						e.minable=false
					end
					if (p.x == -17 and p.y == -32) then
						local e = surface.create_entity({name="substation", position = {p.x,p.y}, force = 'neutral'})
						e.destructible=false
						e.minable=false
					end
					if (p.x == -17 and p.y == -95) then
						local e = surface.create_entity({name="substation", position = {p.x,p.y}, force = 'neutral'})
						e.destructible=false
						e.minable=false
					end
					if (p.x == 18 and p.y == -32) then
						local e = surface.create_entity({name="substation", position = {p.x,p.y}, force = 'neutral'})
						e.destructible=false
						e.minable=false
					end
					if (p.x == 18 and p.y == -95) then
						local e = surface.create_entity({name="substation", position = {p.x,p.y}, force = 'neutral'})
						e.destructible=false
						e.minable=false
					end
					if (p.x == 43 and p.y == -32) then
						local e = surface.create_entity({name="substation", position = {p.x,p.y}, force = 'neutral'})
						e.destructible=false
						e.minable=false
					end
					if (p.x == 43 and p.y == -95) then
						local e = surface.create_entity({name="substation", position = {p.x,p.y}, force = 'neutral'})
						e.destructible=false
						e.minable=false
					end
					if (p.x == 78 and p.y == -32) then
						local e = surface.create_entity({name="substation", position = {p.x,p.y}, force = 'neutral'})
						e.destructible=false
						e.minable=false
					end
					if (p.x == 78 and p.y == -95) then
						local e = surface.create_entity({name="substation", position = {p.x,p.y}, force = 'neutral'})
						e.destructible=false
						e.minable=false
					end
				elseif (p.x == 137 or p.x == 138 or p.x == 102 or p.x == 103 or p.x == 78 or p.x == 77 or p.x == 42 or p.x == 43 or p.x == 17 or p.x == 18 or p.x == -17 or p.x == -18 or p.x == -42 or p.x == -43 or p.x == -77 or p.x == -78) and (p.y == 32 or p.y == 33 or p.y == 95 or p.y == 96) then
					surface.set_tiles({{name = "hazard-concrete-right", position = p}}, true)
					if (p.x == 138 and p.y == 33)  then
						local e = surface.create_entity({name="substation", position = {p.x,p.y}, force = 'neutral'})
						e.destructible=false
						e.minable=false
					end
					if (p.x == 138 and p.y == 96) then
						local e = surface.create_entity({name="substation", position = {p.x,p.y}, force = 'neutral'})
						e.destructible=false
						e.minable=false
					end
					if (p.x == 103 and p.y == 33) then
						local e = surface.create_entity({name="substation", position = {p.x,p.y}, force = 'neutral'})
						e.destructible=false
						e.minable=false
					end
					if (p.x == 103 and p.y == 96) then
						local e = surface.create_entity({name="substation", position = {p.x,p.y}, force = 'neutral'})
						e.destructible=false
						e.minable=false
					end
					if (p.x == 78 and p.y == 33) then
						local e = surface.create_entity({name="substation", position = {p.x,p.y}, force = 'neutral'})
						e.destructible=false
						e.minable=false
					end
					if (p.x == 78 and p.y == 96) then
						local e = surface.create_entity({name="substation", position = {p.x,p.y}, force = 'neutral'})
						e.destructible=false
						e.minable=false
					end
					if (p.x == 43 and p.y == 33) then
						local e = surface.create_entity({name="substation", position = {p.x,p.y}, force = 'neutral'})
						e.destructible=false
						e.minable=false
					end
					if (p.x == 43 and p.y == 96) then
						local e = surface.create_entity({name="substation", position = {p.x,p.y}, force = 'neutral'})
						e.destructible=false
						e.minable=false
					end
					if (p.x == 18 and p.y == 33) then
						local e = surface.create_entity({name="substation", position = {p.x,p.y}, force = 'neutral'})
						e.destructible=false
						e.minable=false
					end
					if (p.x == 18 and p.y == 96) then
						local e = surface.create_entity({name="substation", position = {p.x,p.y}, force = 'neutral'})
						e.destructible=false
						e.minable=false
					end
					if (p.x == -17 and p.y == 33) then
						local e = surface.create_entity({name="substation", position = {p.x,p.y}, force = 'neutral'})
						e.destructible=false
						e.minable=false
					end
					if (p.x == -17 and p.y == 96) then
						local e = surface.create_entity({name="substation", position = {p.x,p.y}, force = 'neutral'})
						e.destructible=false
						e.minable=false
					end
					if (p.x == -42 and p.y == 33) then
						local e = surface.create_entity({name="substation", position = {p.x,p.y}, force = 'neutral'})
						e.destructible=false
						e.minable=false
					end
					if (p.x == -42 and p.y == 96) then
						local e = surface.create_entity({name="substation", position = {p.x,p.y}, force = 'neutral'})
						e.destructible=false
						e.minable=false
					end
					if (p.x == -77 and p.y == 33) then
						local e = surface.create_entity({name="substation", position = {p.x,p.y}, force = 'neutral'})
						e.destructible=false
						e.minable=false
					end
					if (p.x == -77 and p.y == 96) then
						local e = surface.create_entity({name="substation", position = {p.x,p.y}, force = 'neutral'})
						e.destructible=false
						e.minable=false
					end
				else
					surface.set_tiles({{name = "out-of-map", position = p}}, true)
				end
			else
				if p.x >=-210 and p.x <=210 then
					local this_tile = surface.get_tile(p)
					local replacement_tile = "landfill"
					if this_tile.name == "water" or this_tile.name == "deepwater" then
						surface.set_tiles({{name = replacement_tile, position = this_tile.position}}, true)
					end
				end
			end

			if( p.x ==-135 or p.x == 75 ) and (p.y >= -200 and p.y <= -175 ) then
				local this_tile = surface.get_tile(p)
				local replacement_tile = "hazard-concrete-right"
				surface.set_tiles({{name = replacement_tile, position = this_tile.position}}, true)
			end
			if( p.x >=-135 and p.x <= 75 ) and (p.y == -200 or p.y == -175 ) then
				local this_tile = surface.get_tile(p)
				local replacement_tile = "hazard-concrete-right"
				surface.set_tiles({{name = replacement_tile, position = this_tile.position}}, true)
			end
			if( p.x >=-15 and p.x <= 15 ) and p.y == -174 then
				local this_tile = surface.get_tile(p)
				local replacement_tile = "hazard-concrete-right"
				surface.set_tiles({{name = replacement_tile, position = this_tile.position}}, true)
			end
			if p.x >-135 and p.x < 75 and p.y>-200 and p.y<-175 then
				local this_tile = surface.get_tile(p)
				local nb_rand=math.random(3)
				local replacement_tile = table_tiles[nb_rand]
				surface.set_tiles({{name = replacement_tile, position = this_tile.position}}, true)
			end


			if( p.x == -75 or p.x == 135 ) and (p.y <= 200 and p.y >= 175 ) then
				local this_tile = surface.get_tile(p)
				local replacement_tile = "hazard-concrete-left"
				surface.set_tiles({{name = replacement_tile, position = this_tile.position}}, true)
			end
			if( p.x >=-75 and p.x <= 135 ) and (p.y == 200 or p.y == 175 ) then
				local this_tile = surface.get_tile(p)
				local replacement_tile = "hazard-concrete-left"
				surface.set_tiles({{name = replacement_tile, position = this_tile.position}}, true)
			end
			if( p.x >=-15 and p.x <= 15 ) and p.y == 174 then
				local this_tile = surface.get_tile(p)
				local replacement_tile = "hazard-concrete-left"
				surface.set_tiles({{name = replacement_tile, position = this_tile.position}}, true)
			end
			if p.x >-75 and p.x < 135 and p.y<200 and p.y>175 then
				local this_tile = surface.get_tile(p)
				local nb_rand=math.random(3)
				local replacement_tile = table_tiles[nb_rand]
				surface.set_tiles({{name = replacement_tile, position = this_tile.position}}, true)
			end
		end
	end
end

local scrap_vectors = {}
for x = -5, 5, 1 do
	for y = -5, 5, 1 do
		if math.sqrt(x^2 + y^2) <= 5 then
			scrap_vectors[#scrap_vectors + 1] = {x, y}
		end
	end
end

local function generate_scrap(event)
	local distance_to_center = math.sqrt(event.area.left_top.x ^ 2 + event.area.left_top.y ^ 2)

	local worms = event.surface.find_entities_filtered({area = event.area, type = "turret"})
	if #worms == 0 then return end

	for _, e in pairs(worms) do
		if math_random(1,2) == 1 then
			for c = 1, math_random(2,12), 1 do
				local vector = scrap_vectors[math_random(1, #scrap_vectors)]
				local position = {e.position.x + vector[1], e.position.y + vector[2]}
				if e.surface.can_place_entity({name = "mineable-wreckage", position = position, force = "neutral"}) then
					e.surface.create_entity({name = "mineable-wreckage", position = position, force = "neutral"})
				end
			end
		end
	end
end


local function on_chunk_generated(event)
	local source_surface = game.surfaces["mirror_terrain"]
	if not source_surface then return end
	if not source_surface.valid then return end
	if event.surface.index == source_surface.index then return end
	local left_top = event.area.left_top
	if left_top.x >= 0 then
		mirror_chunk(event, source_surface, 1)
	else
		mirror_chunk(event, source_surface, -1)
	end

	out_of_map_area(event)

	if left_top.x >= -150 and left_top.x < 150 then combat_area(event) end
	if left_top.x == 256 and left_top.y == 256 then
		create_markets(event.surface)
		first_ore_generate(event.surface)
	end
	if left_top.x <= -500  and left_top.x >= -1500 then
		local density = -0.003 * left_top.x -0.5
		local floor_density = math.floor(density)
		for i = 0, floor_density, 1 do
			if math.random(100)<=10 then
				local rand_x = math.random(33)-1
				local rand_y = math.random(33)-1
				local pos = {x =left_top.x + rand_x, y = left_top.y + rand_y}
				--local position = envent.surface.find_non_colliding_position("big-worm-turret", pos, 8, 1)
				if pos.x * -0.5 > math_abs(pos.y)+50 and event.surface.can_place_entity({name = "small-worm-turret", position = pos, force = "east"}) then
					event.surface.create_entity({name = "small-worm-turret", position = pos, force = "east"})
					generate_scrap(event)
				end
			end
		end
	end

	if left_top.x <= -1500  and left_top.x >= -2500 then
		local density = -0.003 * left_top.x -2.5
		local floor_density = math.floor(density)
		for i = 0, floor_density, 1 do
			if math.random(100)<=10 then
				local rand_x = math.random(33)-1
				local rand_y = math.random(33)-1
				local pos = {x =left_top.x + rand_x, y = left_top.y + rand_y}
				--local position = envent.surface.find_non_colliding_position("big-worm-turret", pos, 8, 1)
				if pos.x * -0.5 > math_abs(pos.y)+50 and event.surface.can_place_entity({name = "medium-worm-turret", position = pos, force = "east"}) then
					event.surface.create_entity({name = "medium-worm-turret", position = pos, force = "east"})
					generate_scrap(event)
				end
			end
		end
	end
	if left_top.x <= -2500 then
		local density = -0.003 * left_top.x -5.5
		local floor_density = math.floor(density)
		if floor_density > 4 then floor_density = 4 end
		for i = 0, floor_density, 1 do
			if math.random(100)<=10 then
				local rand_x = math.random(33)-1
				local rand_y = math.random(33)-1
				local pos = {x =left_top.x + rand_x, y = left_top.y + rand_y}
				--local position = envent.surface.find_non_colliding_position("big-worm-turret", pos, 8, 1)
				if  pos.x * -0.5 > math_abs(pos.y)+50 and event.surface.can_place_entity({name = "big-worm-turret", position = pos, force = "east"}) then
					event.surface.create_entity({name = "big-worm-turret", position = pos, force = "east"})
					generate_scrap(event)
				end
			end
		end
	end
	if left_top.x >= 500  and left_top.x <= 1500 then
		local density = 0.003 * left_top.x -0.5
		local floor_density = math.floor(density)
		for i = 0, floor_density, 1 do
			if math.random(100)<=10 then
				local rand_x = math.random(33)-1
				local rand_y = math.random(33)-1
				local pos = {x =left_top.x + rand_x, y = left_top.y + rand_y}
				--local position = envent.surface.find_non_colliding_position("big-worm-turret", pos, 8, 1)
				if pos.x * 0.5 > math_abs(pos.y)+50 and event.surface.can_place_entity({name = "small-worm-turret", position = pos, force = "west"}) then
					event.surface.create_entity({name = "small-worm-turret", position = pos, force = "west"})
					generate_scrap(event)
				end
			end
		end
	end

	if left_top.x >= 1500  and left_top.x <= 2500 then
		local density = 0.003 * left_top.x -2.5
		local floor_density = math.floor(density)
		for i = 0, floor_density, 1 do
			if math.random(100)<=10 then
				local rand_x = math.random(33)-1
				local rand_y = math.random(33)-1
				local pos = {x =left_top.x + rand_x, y = left_top.y + rand_y}
				--local position = envent.surface.find_non_colliding_position("big-worm-turret", pos, 8, 1)
				if pos.x * 0.5 > math_abs(pos.y)+50 and event.surface.can_place_entity({name = "medium-worm-turret", position = pos, force = "west"}) then
					event.surface.create_entity({name = "medium-worm-turret", position = pos, force = "west"})
					generate_scrap(event)
				end
			end
		end
	end
	if left_top.x >= 2500 then
		local density = 0.003 * left_top.x -5.5
		local floor_density = math.floor(density)
		if floor_density > 4 then floor_density=4 end
		for i = 0, floor_density, 1 do
			if math.random(100)<=10 then
				local rand_x = math.random(33)-1
				local rand_y = math.random(33)-1
				local pos = {x =left_top.x + rand_x, y = left_top.y + rand_y}
				--local position = envent.surface.find_non_colliding_position("big-worm-turret", pos, 8, 1)
				if pos.x * 0.5 > math_abs(pos.y)+50 and event.surface.can_place_entity({name = "big-worm-turret", position = pos, force = "west"}) then
					event.surface.create_entity({name = "big-worm-turret", position = pos, force = "west"})
					generate_scrap(event)
				end
			end
		end
	end


	if left_top.x > 320 then return end
	if left_top.x < -320 then return end
	if left_top.y > 320 then return end
	if left_top.y < -320 then return end

	game.forces.west.chart(event.surface, {{left_top.x, left_top.y},{left_top.x + 31, left_top.y + 31}})
	game.forces.east.chart(event.surface, {{left_top.x, left_top.y},{left_top.x + 31, left_top.y + 31}})
end


local event = require 'utils.event'
event.add(defines.events.on_chunk_generated, on_chunk_generated)

return Public
