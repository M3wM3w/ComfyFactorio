local math_abs = math.abs

local function is_out_of_map(p)
	if p.x < -512 then return true end
	if (p.x + 512) * 0.125 >= math_abs(p.y) then return end
	if (p.x + 512) * -0.125 > math_abs(p.y) then return end
	return true
end

local function on_chunk_generated(event)
	local surface = event.surface
	local left_top = event.area.left_top
	for x = -1, 32, 1 do
		for y = -1, 32, 1 do
			local p = {x = left_top.x + x, y = left_top.y + y}			
			if is_out_of_map(p) then
				surface.set_tiles({{name = "out-of-map", position = p}}, true) 
			end
		end
	end
end

local function on_init()
	local surface = game.surfaces[1]
	surface.request_to_generate_chunks({-256, 0}, 4)
	surface.force_generate_chunk_requests()
	game.forces.player.set_spawn_position({-256, 0}, surface)
end

local event = require 'utils.event'
event.on_init(on_init)
event.add(defines.events.on_chunk_generated, on_chunk_generated)