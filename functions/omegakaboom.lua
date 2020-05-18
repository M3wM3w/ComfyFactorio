-------requires on_tick_schedule

local function create_projectile(surface, pos, projectile)	
	surface.create_entity({	
		name = projectile,
		position = pos,
		force = "enemy",
		target = pos,
		speed = 1
	})	
end

local function omegakaboom(surface, center_pos, projectile, radius, density)
	local positions = {}
	for x = radius * -1, radius, 1 do
		for y = radius * -1, radius, 1 do
			local pos = {x = center_pos.x + x, y = center_pos.y + y}
			local distance_to_center = math.ceil(math.sqrt((pos.x - center_pos.x)^2 + (pos.y - center_pos.y)^2))
			if distance_to_center < radius and math.random(1,100) < density then
				if not positions[distance_to_center] then positions[distance_to_center] = {} end
				positions[distance_to_center][#positions[distance_to_center] + 1] = pos
			end
		end
	end		
	if #positions == 0 then return end	
	local t = 1
	for i1, pos_list in pairs(positions) do
		for i2, pos in pairs(pos_list) do
			if not global.on_tick_schedule[game.tick + t] then global.on_tick_schedule[game.tick + t] = {} end			
			global.on_tick_schedule[game.tick + t][#global.on_tick_schedule[game.tick + t] + 1] = {
				func = create_projectile,
				args = {surface, pos, projectile}
			}			
		end
		t = t + 4
	end
end

return omegakaboom