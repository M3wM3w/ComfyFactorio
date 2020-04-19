local function create_particles(surface, position, amount)
	if not surface.valid then return end
	local math_random = math.random
	for i = 1, amount, 1 do 
		local m = math_random(6, 12)
		local m2 = m * 0.005
		
		surface.create_particle({
			name = "stone-particle",
			position = position,
			frame_speed = 0.1,
			vertical_speed = 0.1,
			height = 0.1,
			movement = {m2 - (math_random(0, m) * 0.01), m2 - (math_random(0, m) * 0.01)}
		})
	end	
end

local function spawn_biter(surface, position, evolution)
	if not surface.valid then return end
	local evo = math.floor(evolution * 1000)
	
	local biter_chances = {
		{name = "small-biter", chance = math.floor(1000 - (evo * 1.6))},
		{name = "small-spitter", chance = math.floor(500 - evo * 0.8)},
		{name = "medium-biter", chance = -150 + evo},
		{name = "medium-spitter", chance = -75 + math.floor(evo * 0.5)},
		{name = "big-biter", chance = math.floor((evo - 500) * 3)},
		{name = "big-spitter", chance = math.floor((evo - 500) * 2)},
		{name = "behemoth-biter", chance = math.floor((evo - 800) * 6)},
		{name = "behemoth-spitter", chance = math.floor((evo - 800) * 4)}
	}
	
	local max_chance = 0	
	for i = 1, 8, 1 do
		if biter_chances[i].chance < 0 then biter_chances[i].chance = 0 end
		max_chance = max_chance + biter_chances[i].chance
	end
	local r = math.random(1, max_chance)	
	local current_chance = 0
	for i = 1, 8, 1 do
		current_chance = current_chance + biter_chances[i].chance
		if r <= current_chance then
			local biter_name = biter_chances[i].name
			local p = surface.find_non_colliding_position(biter_name, position, 10, 1)
			if not p then return end
			surface.create_entity({name = biter_name, position = p, force = "enemy"})
			return
		end
	end
end

local function unearthing_biters(surface, position, amount)
	if not surface then return end
    	if not surface.valid then return end
	if not position then return end
	if not position.x then return end
	if not position.y then return end	
	
	local evolution = game.forces.enemy.evolution_factor
	
	local ticks = amount * 30
	ticks = ticks + 90
	for t = 1, ticks, 1 do
		if not global.on_tick_schedule[game.tick + t] then global.on_tick_schedule[game.tick + t] = {} end
				
		global.on_tick_schedule[game.tick + t][#global.on_tick_schedule[game.tick + t] + 1] = {
			func = create_particles,
			args = {surface, {x = position.x, y = position.y}, 4}
		}										
		
		if t > 90 then
			if t % 30 == 29 then			
				global.on_tick_schedule[game.tick + t][#global.on_tick_schedule[game.tick + t] + 1] = {
					func = spawn_biter,
					args = {surface, {x = position.x, y = position.y}, evolution}
				}
			end
		end
	end		
end

return unearthing_biters
