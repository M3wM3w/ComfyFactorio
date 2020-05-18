local function coord_string(x, y)
	local str = tostring(x) .. "_"
	str = str .. tostring(y)
	return str
end

local function draw_cell(surface, cell, cell_size, wall_entity_name, force_name)
	local r = math.floor(cell_size * 0.5)
	local entities = {}
	if cell.north then
		for x = r * -1, r, 1 do
			entities[#entities + 1] = {position = {cell.position.x + x, cell.position.y - r}, name = wall_entity_name, force = force_name}
		end
	end
	if cell.south then
		for x = r * -1, r, 1 do
			entities[#entities + 1] = {position = {cell.position.x + x, cell.position.y + r}, name = wall_entity_name, force = force_name}
		end
	end
	if cell.east then
		for y = r * -1, r, 1 do
			entities[#entities + 1] = {position = {cell.position.x + r, cell.position.y + y}, name = wall_entity_name, force = force_name}
		end
	end
	if cell.west then
		for y = r * -1, r, 1 do
			entities[#entities + 1] = {position = {cell.position.x - r, cell.position.y - y}, name = wall_entity_name, force = force_name}
		end
	end
	for _, e in pairs(entities) do
		if surface.can_place_entity(e) then surface.create_entity(e) end
	end
end

local function draw_maze(surface, position, size, cell_size, wall_entity_name, force_name)
	for _, cell in pairs(maze_cells) do
		draw_cell(surface, cell, cell_size, wall_entity_name, force_name)
	end
end

local function get_random_occupied_cell()
	local occupied_cells = {}
	for c, cell in pairs(maze_cells) do
		if cell.occupied then
			if not cell.dead then
				occupied_cells[#occupied_cells + 1] = c
			end
		end
	end
	if not occupied_cells[1] then return end
	return occupied_cells[math.random(1, #occupied_cells)]
end

local function set_dead_cells()
	local directions = {
		{0, -1},
		{0, 1},
		{1, 0},
		{-1, 0}
	}
	
	for c, cell in pairs(maze_cells) do
		if not cell.dead then
			maze_cells[c].dead = true
			for i = 1, 4, 1 do
				local cell_string = coord_string(cell.cell_position.x + directions[i][1], cell.cell_position.y + directions[i][2])
				if maze_cells[cell_string] then
					if not maze_cells[cell_string].occupied then
						maze_cells[c].dead = false
						break
					end
				end		
			end
		end
	end
end

local function expand_cell(current_cell)
	local expansion_raffle = {
			{0, -1, "north", "south"},
			{0, 1, "south", "north"},
			{1, 0, "east", "west"},
			{-1, 0, "west", "east"}
		}
	table.shuffle_table(expansion_raffle)
	for i = 1, 4, 1 do
		local direction = expansion_raffle[i]
		local cell_canditate = coord_string(current_cell.cell_position.x + direction[1], current_cell.cell_position.y + direction[2])
		if maze_cells[cell_canditate] then
			if not maze_cells[cell_canditate].occupied then
				maze_cells[cell_canditate].occupied = true
				current_cell[direction[3]] = false
				maze_cells[cell_canditate][direction[4]] = false
				return maze_cells[cell_canditate]
			end
		end
	end
	return false
end

local function expand(size)
	local current_cell = maze_cells[get_random_occupied_cell()]
	while true do
		current_cell = expand_cell(current_cell)
		if not current_cell then
			set_dead_cells()
			current_cell = maze_cells[get_random_occupied_cell()] 
		end
		if not current_cell then break end
	end
end

local function disable_borders(size)
	for s = size * -1, size, 1 do
		maze_cells[coord_string(s, size * -1)].north = false
		maze_cells[coord_string(s, size)].south = false
		maze_cells[coord_string(size, s)].east = false
		maze_cells[coord_string(size * -1, s)].west = false
	end
end

function create_maze(surface, position, size, cell_size, wall_entity_name, force_name, borderless)
	if not surface then game.print("No surface given.") return end
	if not position then game.print("No position given.") return end
	if not size then game.print("No size given.") return end
	if not cell_size then game.print("No cell_size given.") return end
	if not wall_entity_name then game.print("No wall_entity_name given.") return end
	
	maze_cells = {}
	
	for x = size * -1, size, 1 do
		for y = size * -1, size, 1 do
			maze_cells[coord_string(x, y)] = {
				position = {x = position.x + x * (cell_size - 1), y = position.y + y * (cell_size - 1)},
				cell_position = {x = x , y = y},
				occupied = false,
				dead = false,
				north = true,
				south = true,
				east = true,
				west = true
			}
		end
	end
	
	maze_cells[coord_string(size * -1, 0)].occupied = true
	maze_cells[coord_string(size * -1, 0)].west = false
	maze_cells[coord_string(size, 0)].east = false
	
	if borderless then disable_borders(size) end
	
	expand(size)
	
	draw_maze(surface, position, size, cell_size, wall_entity_name, force_name)
end