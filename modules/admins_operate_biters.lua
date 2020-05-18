local event = require 'utils.event'
local math_random = math.random
local math_floor = math.floor
global.biter_command = {}
global.biter_command.active_unit_groups = {}
global.biter_command.enabled = true
global.biter_command.whitelist = {}
global.biter_command.admin_mode = true --if only admins can see and use the panel
global.biter_command.teleporting = false --if teleporting is allowed for non-admins
global.biter_command.buildings = true ---if player can trigger building nests and worms

local worm_raffle = {
  "small-worm-turret", "small-worm-turret", "medium-worm-turret", "small-worm-turret",
  "medium-worm-turret", "medium-worm-turret", "big-worm-turret", "medium-worm-turret",
  "big-worm-turret","big-worm-turret","behemoth-worm-turret", "big-worm-turret",
  "behemoth-worm-turret","behemoth-worm-turret","behemoth-worm-turret","big-worm-turret","behemoth-worm-turret"
}

local function shuffle(tbl)
	local size = #tbl
		for i = size, 1, -1 do
			local rand = math_random(size)
			tbl[i], tbl[rand] = tbl[rand], tbl[i]
		end
	return tbl
end

local function is_closer(pos1, pos2, pos)
  return ((pos1.x - pos.x)^2 + (pos1.y - pos.y)^2) < ((pos2.x - pos.x)^2 + (pos2.y - pos.y)^2)
end

local function shuffle_distance(tbl, position)
	local size = #tbl
		for i = size, 1, -1 do
			local rand = math_random(size)
      if is_closer(tbl[i].position, tbl[rand].position, position) and i > rand then
        tbl[i], tbl[rand] = tbl[rand], tbl[i]
      end
		end
	return tbl
end

local function get_evo(force)
  local evo = math_floor(game.forces["enemy"].evolution_factor * 20)
  local nests = math_random(1 + evo, 2 + evo * 2 )
end

local function place_nest_near_unit_group(group)
  if not global.biter_command.buildings then return false end
  if not group.members then return false end
	if #group.members < 5 then return false end
  local units = group.members
  shuffle(units)
  for i = 1, 5, 1 do
    if not units[i].valid then return false end
  end
	local name = "biter-spawner"
	if math_random(1, 3) == 1 then name = "spitter-spawner" end
	local position = group.surface.find_non_colliding_position(name, group.position, 16, 1)
	if not position then return false end
  group.surface.create_entity({name = name, position = position, force = group.force})
  group.surface.create_entity({name = "blood-explosion-huge", position = position})
  for i = 1, 5, 1 do
	   units[i].surface.create_entity({name = "blood-explosion-huge", position = units[i].position})
     units[i].destroy()
  end
  return true
end

local function build_worm(group)
  if not global.biter_command.buildings then return false end
	if not group.members then return false end
	if #group.members < 5 then return false end
  local units = group.members
  shuffle(units)
  for i = 1, 5, 1 do
    if not units[i].valid then return false end
  end
	local position = group.surface.find_non_colliding_position("assembling-machine-1", group.position, 8, 1)
	local worm = worm_raffle[math_random(1 + math_floor(group.force.evolution_factor * 8), math_floor(1 + group.force.evolution_factor * 16))]
	if not position then return false end
	group.surface.create_entity({name = worm, position = position, force = group.force})
  group.surface.create_entity({name = "blood-explosion-huge", position = position})
  for i = 1, 5, 1 do
	   units[i].surface.create_entity({name = "blood-explosion-huge", position = units[i].position})
     units[i].destroy()
  end
  return true
end

local function flying_text(message, action, position, player)
  local texts = {
    {"roger", "acknowledged", "aye aye", "confirmed", "will do"},
    {"negative", "no", "not really", "we are not your critters", "go away"},
    {"fooood", "nom nom", "we hunger", "killllll"},
    {"WTF", "we wanted ACTION", "why you hate us", "we were good soldiers", "go to hell"}
  }
  colors = {{r=0,g=220,b=0},{r=220,g=0,b=0},{r=0,g=100,b=220}, {r=200,g=200,b=0}, {r=255, g = 255, b = 255}}
  if message then
    player.create_local_flying_text{text = message, position = position, color = colors[5]}
  else
    player.create_local_flying_text{text = texts[action][math_random(1,#texts[action])], position = position, color = colors[action]}
  end
end


-----------commands-----------

local function move_to(position, distraction)
  local command = {
    type = defines.command.go_to_location,
    destination = position,
    distraction = distraction,
    pathfind_flags = {allow_destroy_friendly_entities = true}
  }
  return command
end

-- local function attackmaincommand(target)
--   local wave_defense_table = WD.get_table()
--   if not wave_defense_table.target then return end
--   if not wave_defense_table.target.valid then return end
--   local command = {
-- 		type = defines.command.attack,
-- 		target = target,
-- 		distraction = defines.distraction.by_enemy,
-- 	}
--   return command
-- end

local function attackareacommand(position)
  local command = {
    type = defines.command.attack_area,
    destination = position,
    radius = 25,
    distraction = defines.distraction.by_enemy
   }
   return command
end

local function attackobstaclescommand(surface, position)
  local commands = {}
  local obstacles = surface.find_entities_filtered{position = position, radius = 20, type = {"simple-entity", "tree"}, limit = 100}
  if obstacles then
    shuffle(obstacles)
    shuffle_distance(obstacles, position)
    for i = 1, #obstacles, 1 do
      if obstacles[i].valid then
        commands[#commands + 1] = {
          type = defines.command.attack,
          target = obstacles[i],
          distraction = defines.distraction.by_enemy
        }
      end
    end
  end
  return commands
end

local function get_coords(group, source_player)
  local position
  if source_player.gui.screen["biter_panel"] then
    local x = tonumber(source_player.gui.screen["biter_panel"]["coords"]["coord_x"].text)
    local y = tonumber(source_player.gui.screen["biter_panel"]["coords"]["coord_y"].text)
    if x == nil or x == "nil" then
      x = group.position.x
      source_player.gui.screen["biter_panel"]["coords"]["coord_x"].text = group.position.x
    end
    if y == nil or y == "nil" then
      y = group.position.y
      source_player.gui.screen["biter_panel"]["coords"]["coord_y"].text = group.position.y
    end
    position = {x = x, y = y}
  end
  return position
end

-------button functions-------------

local function pan(group, source_player)
	source_player.open_map(group.position, 0.5)
end

local function teleport(group, source_player)
  if source_player.admin or global.biter_command.teleporting  then
	   source_player.teleport(group.position, group.surface)
   else
     flying_text("Teleporting is disabled", nil, source_player.position, source_player)
   end
end

local function disband(group, source_player)
  flying_text(nil, 4, group.position, source_player)
  group.destroy()
end

local function movetome(group, source_player)
  group.set_command(move_to(source_player.position, defines.distraction.none))
  flying_text(nil, 1, group.position, source_player)
end

local function movetoposition(group, source_player)
  local position = get_coords(group, source_player)
  if position then
    group.set_command(move_to(position, defines.distraction.none))
    flying_text(nil, 1, group.position, source_player)
  else
    flying_text(nil, 2, group.position, source_player)
  end
end

local function patroltome(group, source_player)
  group.set_command(move_to(source_player.position, defines.distraction.by_enemy))
  flying_text(nil, 1, group.position, source_player)
end

local function patroltoposition(group, source_player)
  local position = get_coords(group, source_player)
  if position then
    group.set_command(move_to(position, defines.distraction.by_enemy))
    flying_text(nil, 1, group.position, source_player)
  else
    flying_text(nil, 2, group.position, source_player)
  end
end

local function settle(group, source_player)
  local success = place_nest_near_unit_group(group)
  if success then
    flying_text(nil, 1, group.position, source_player)
  else
    flying_text(nil, 2, group.position, source_player)
    source_player.print("Settling new nest failed. Check if group has enough members(5+) and there is empty space (or nests are disabled).")
  end
end

local function siege(group, source_player)
  local success = build_worm(group)
  if success then
    flying_text(nil, 1, group.position, source_player)
  else
    flying_text(nil, 2, group.position, source_player)
    source_player.print("Making worm failed. Check if group has enough members(5+) and there is empty space (or worms are disabled).")
  end
end

local function report(group, source_player)
  local status = group.state
  local states = {"gathering", "moving", "attacking distraction", "attacking target", "finished", "pathfinding", "wander in group"}
  flying_text(states[status + 1], nil, group.position, source_player)
end

local function attackenemiesaround(group, source_player)
  flying_text(nil, 3, group.position, source_player)
  group.set_command(attackareacommand(group.position))
end

local function attackobstaclesaround(group, source_player)
  local commands = attackobstaclescommand(group.surface, group.position)
  if #commands > 1 then
  group.set_command({
    type = defines.command.compound,
    structure_type = defines.compound_command.return_last,
    commands = commands
  })
  flying_text(nil, 3, group.position, source_player)
  else
    source_player.print("No obstacles found around unit group.")
    flying_text(nil, 2, group.position, source_player)
  end
end

local function attackenemiesaroundme(group, source_player)
  group.set_command(attackareacommand(source_player.position))
  flying_text(nil, 3, group.position, source_player)
end

local function attackobstaclesaroundme(group, source_player)
  local commands = attackobstaclescommand(source_player.surface, source_player.position)
  if #commands > 1 then
  group.set_command({
    type = defines.command.compound,
    structure_type = defines.compound_command.return_last,
    commands = commands
  })
  flying_text(nil, 3, group.position, source_player)
  else
    source_player.print("No obstacles found around player.")
    flying_text(nil, 2, group.position, source_player)
  end
end

local function addunitsaroundme(group, source_player)
  local units = source_player.surface.find_entities_filtered{position = source_player.position, radius = 50,type = "unit", force = group.force}
  for i = 1, #units, 1 do
    group.add_member(units[i])
  end
end

local function addunits(group, source_player)
  local units = source_player.surface.find_entities_filtered{position = group.position, radius = 50,type = "unit", force = group.force}
  for i = 1, #units, 1 do
    group.add_member(units[i])
  end
end

local function forcemove(group, source_player)
  group.start_moving()
  flying_text(nil, 1, group.position, source_player)
end

local function creategroup(source_player)
  source_player.surface.create_unit_group{position = source_player.position, force = source_player.force}
  flying_text("Unit group created", nil, source_player.position, source_player)
end
----------------------direction panel-----------------
local function set_directions(changedx, changedy, source_player)
  if source_player.gui.screen["biter_panel"] then
    local x = tonumber(source_player.gui.screen["biter_panel"]["coords"]["coord_x"].text)
    local y = tonumber(source_player.gui.screen["biter_panel"]["coords"]["coord_y"].text)
    if x == nil or x == "nil" then x = 0 end
    if y == nil or y == "nil" then y = 0 end
    x = x + changedx
    y = y + changedy
    source_player.gui.screen["biter_panel"]["coords"]["coord_x"].text = x
    source_player.gui.screen["biter_panel"]["coords"]["coord_y"].text = y
  end
end


local function nw(source_player)
  set_directions(-25, -25, source_player)
end

local function n(source_player)
  set_directions(0, -25, source_player)
end

local function ne(source_player)
  set_directions(25, -25, source_player)
end

local function w(source_player)
  set_directions(-25, 0, source_player)
end

local function e(source_player)
  set_directions(25, 0, source_player)
end

local function sw(source_player)
  set_directions(-25, 25, source_player)
end

local function s(source_player)
  set_directions(0, 25, source_player)
end

local function se(source_player)
  set_directions(25, 25, source_player)
end

local function center(group, source_player)
  if source_player.gui.screen["biter_panel"] then
    source_player.gui.screen["biter_panel"]["coords"]["coord_x"].text = group.position.x
    source_player.gui.screen["biter_panel"]["coords"]["coord_y"].text = group.position.y
  end
end

----------------------------gui-----------------------

local function top_button(player)
	if player.gui.top["biter_commands"] then
    if global.biter_command.enabled or global.biter_command.whitelist[player.name] == true then
      player.gui.top["biter_commands"].visible = true
      return
    else
      --player.gui.top["biter_commands"].destroy()
      player.gui.top["biter_commands"].visible = false
      return
    end
  end
  if player.admin or not global.biter_command.admin_mode then
    if global.biter_command.enabled or global.biter_command.whitelist[player.name] == true then
    	local button = player.gui.top.add({type = "sprite-button", name = "biter_commands", sprite = "entity/medium-spitter"})
    	button.style.minimal_height = 38
    	button.style.minimal_width = 38
    	button.style.padding = -2
    end
  end
end

local function show_info(player)
  if player.gui.screen["biter_comm_info"] then player.gui.screen["biter_comm_info"].destroy() return end
  local frame = player.gui.screen.add{type = "frame", name = "biter_comm_info", caption = "Biter Commander needs halp", direction = "vertical"}
  frame.location = {x = 350, y = 45}
  frame.style.minimal_height = 300
  frame.style.maximal_height = 300
  frame.style.minimal_width = 330
  frame.style.maximal_width = 630
  frame.add({type = "label", caption = "Create new group first, then add biters to it."})
  frame.add({type = "label", caption = "You can use directionpad to navigate them, or do it in person."})
  frame.add({type = "label", caption = "If you input invalid coordinates, they get rewritten to current group's position."})
  frame.add({type = "label", caption = "You can operate only biters and create groups of your own force."})
  frame.add({type = "label", caption = "If group is stuck at gathering state, use 'force move' button."})
  frame.add({type = "label", caption = "Empty groups get autodeleted by game after a while."})
  frame.add({type = "button", name = "close_info", caption = "Close"})
end

local function build_groups(player)
  local groups = {}
  for _, g in pairs(global.biter_command.active_unit_groups) do
		if g.group.valid then
      if player.admin and global.biter_command.admin_mode then
			   table.insert(groups, tostring(g.id))
      else
        if player.force == g.group.force then
          table.insert(groups, tostring(g.id))
        end
      end
		else
      g = nil
    end
	end
	table.insert(groups, "Select Group")
  return groups
end

local function biter_panel(player)
	if player.gui.screen["biter_panel"] then player.gui.screen["biter_panel"].destroy() return end

	local frame = player.gui.screen.add { type = "frame", caption = "Biter Commander", name = "biter_panel", direction = "vertical" }
  frame.location = {x = 5, y = 45}
  frame.style.minimal_height = 680
  frame.style.maximal_height = 680
  frame.style.minimal_width = 330
  frame.style.maximal_width = 330

  local groups = build_groups(player)
	local selected_index = #groups
	if global.panel_group_index then
		if global.panel_group_index[player.name] then
			if groups[global.panel_group_index[player.name]] then
				selected_index = global.paneld_group_index[player.name]
			end
		end
	end
  local t0 = frame.add({type = "table", name = "top", column_count = 3})
  local drop_down = t0.add({type = "drop-down", name = "group_select", items = groups, selected_index = selected_index})
	drop_down.style.minimal_width = 150
	drop_down.style.right_padding = 12
	drop_down.style.left_padding = 12
  t0.add({type = "sprite-button", name = "info", sprite = "virtual-signal/signal-info"})
  t0.add({type = "sprite-button", name = "close_biters", sprite = "virtual-signal/signal-X"})

  local l1 = frame.add({type = "label", caption = "Camera"})
  local t1 = frame.add({type = "table", name = "camera", column_count = 2})
  local l2 = frame.add({type = "label", caption = "Movement"})
  local t2 = frame.add({type = "table", name = "movement", column_count = 2})
  local l3 = frame.add({type = "label", caption = "Build"})
  local t3 = frame.add({type = "table", name = "build", column_count = 2})
  local l4 = frame.add({type = "label", caption = "Attack"})
  local t4 = frame.add({type = "table", name = "attack", column_count = 2})
  local l5 = frame.add({type = "label", caption = "Group Management"})
  local t5 = frame.add({type = "table", name = "management", column_count = 2})
  local line = frame.add { type = "line"}
	line.style.top_margin = 8
	line.style.bottom_margin = 8
  local t6 = frame.add({type = "table", name = "directions", column_count = 3})
	local buttons = {
		t1.add({type = "button", caption = "Pan to group", name = "pan", tooltip = "Moves camera to group position."}),
		t1.add({type = "button", caption = "TP to group", name = "teleport", tooltip = "Teleports to group."}),
		t2.add({type = "button", caption = "Move to me", name = "movetome", tooltip = "Gives group order to move to your position."}),
    t2.add({type = "button", caption = "Move to position", name = "movetoposition", tooltip = "Sends group to position with coordinates entered below."}),
    t2.add({type = "button", caption = "Patrol to me ", name = "patroltome", tooltip = "Gives group order to move to your position and engage any enemy during movement."}),
    t2.add({type = "button", caption = "Patrol to position", name = "patroltoposition", tooltip = "Sends group to position with coordinates entered below and engage any enemy during movement."}),
		t3.add({type = "button", caption = "Settle nest", name = "settle", tooltip = "Group creates base. Costs 5 units."}),
		t3.add({type = "button", caption = "Build worm", name = "siege", tooltip = "Group builds worm turret. Costs 5 units."}),
		t4.add({type = "button", caption = "Attack area", name = "attackenemiesaround", tooltip = "Group attacks enemy things around self."}),
		t4.add({type = "button", caption = "Attack obstacles", name = "attackobstaclesaround", tooltip = "Group attacks obstacles around self."}),
    t4.add({type = "button", caption = "Attack my area", name = "attackenemiesaroundme", tooltip = "Group attacks enemy things around your position."}),
		t4.add({type = "button", caption = "Attack my obstacles", name = "attackobstaclesaroundme", tooltip = "Group attacks obstacles around your position."}),
    t5.add({type = "button", caption = "Report", name = "report", tooltip = "Reports group status."}),
    t5.add({type = "button", caption = "Force Move", name = "forcemove", tooltip = "Makes group to start moving even if gathering is not done (unstuck)."}),
    t5.add({type = "button", caption = "Add units around me", name = "addunitsaroundme", tooltip = "Adds units around you to selected unit group."}),
    t5.add({type = "button", caption = "Add units", name = "addunits", tooltip = "Adds units around group to it."}),
    t5.add({type = "button", caption = "Create group", name = "creategroup", tooltip = "Creates new group on player position"}),
    t5.add({type = "button", caption = "Disband group", name = "disband", tooltip = "Disbands group."}),
	}
  local buttons2 = {
    t6.add({type = "button", caption = "25 NW", name = "nw", tooltip = "Changes remote position"}),
    t6.add({type = "button", caption = "25 N", name = "n", tooltip = "Changes remote position"}),
    t6.add({type = "button", caption = "25 NE", name = "ne", tooltip = "Changes remote position"}),
    t6.add({type = "button", caption = "25 W", name = "w", tooltip = "Changes remote position"}),
    t6.add({type = "button", caption = "Center", name = "center", tooltip = "Centers remote position to group"}),
    t6.add({type = "button", caption = "25 E", name = "e", tooltip = "Changes remote position"}),
    t6.add({type = "button", caption = "25 SW", name = "sw", tooltip = "Changes remote position"}),
    t6.add({type = "button", caption = "25 S", name = "s", tooltip = "Changes remote position"}),
    t6.add({type = "button", caption = "25 SE", name = "se", tooltip = "Changes remote position"}),
	}
	for _, button in pairs(buttons) do
		button.style.font = "default-bold"
		button.style.font_color = { r=0.99, g=0.99, b=0.99}
		button.style.minimal_width = 150
	end
  for _, button in pairs(buttons2) do
		button.style.font = "default-bold"
		button.style.font_color = { r=0.99, g=0.99, b=0.99}
		button.style.minimal_width = 70
	end
  local t7 = frame.add({type = "table", name = "coords", column_count = 2})
  t7.add({type = "label", caption = "X: "})
  t7.add({type = "textfield", name = "coord_x"})
  t7.add({type = "label", caption = "Y: "})
  t7.add({type = "textfield", name = "coord_y"})
end

local comm_functions = {
		["pan"] = pan,
		["teleport"] = teleport,
		["disband"] = disband,
		["movetome"] = movetome,
    ["movetoposition"] = movetoposition,
    ["patroltome"] = patroltome,
    ["patroltoposition"] = patroltoposition,
		["settle"] = settle,
		["siege"] = siege,
		["report"] = report,
		["attackenemiesaround"] = attackenemiesaround,
		["attackobstaclesaround"] = attackobstaclesaround,
    ["attackenemiesaroundme"] = attackenemiesaroundme,
		["attackobstaclesaroundme"] = attackobstaclesaroundme,
    ["addunits"] = addunits,
    ["addunitsaroundme"] = addunitsaroundme,
    ["forcemove"] = forcemove,
    ["center"] = center,
	}

local comm_global_functions = {
		["creategroup"] = creategroup,
    ["nw"] = nw,
    ["n"] = n,
    ["ne"] = ne,
    ["w"] = w,
    ["e"] = e,
    ["sw"] = sw,
    ["s"] = s,
    ["se"] = se,
	}

local function refresh_groups(player)
  local groups = build_groups(player)
  player.gui.screen["biter_panel"]["top"]["group_select"].items = groups
end

local function on_gui_click(event)
	if not event then return end
	if not event.element then return end
	if not event.element.valid then return end
	local player = game.players[event.element.player_index]
	if event.element.name == "biter_commands" then --top button press
    if global.biter_command.enabled or global.biter_command.whitelist[player.name] == true then
      biter_panel(player)
		  return
    else
      top_button(player)
      player.print("Biter commander module is disabled.")
      return
    end
  else
    if global.biter_command.enabled or global.biter_command.whitelist[player.name] == true then
      top_button(player)
    end
	end
	if event.element.type ~= "button" and event.element.type ~= "sprite-button" then return end
	--if event.frame.name ~= "biter_panel" then return end
  local name = event.element.name
	if name == "close_biters" then biter_panel(player) return end
  if name == "info" then show_info(player) return end
  if name == "close_info" then show_info(player) return end
  if comm_functions[name] then
    local target_group_id = event.element.parent.parent["top"]["group_select"].items[event.element.parent.parent["top"]["group_select"].selected_index]
    if not target_group_id then return end
    if target_group_id == "Select Group" then
      player.print("No target group selected.", {r=0.88, g=0.88, b=0.88})
      return
    end
    -- local index = index(tonumber(target_group_id))
    -- if not index then
    --   player.print("Selected group is no longer valid.", {r=0.88, g=0.88, b=0.88})
    --   return
    -- end
    local group = global.biter_command.active_unit_groups[tonumber(target_group_id)]
    if group and group.group.valid then
      comm_functions[name](group.group, player)
    else
      refresh_groups(player)
    end
    return
  end

  if comm_global_functions[name] then
    comm_global_functions[name](player)
    return
  end
end

local function refresh_panel()
  for _, player in pairs(game.connected_players) do
		if player.gui.screen["biter_panel"] then
      refresh_groups(player)
		end
	end
end

local function on_player_joined_game(event)
	top_button(game.players[event.player_index])
end

local function on_unit_group_created(event)
  if event and event.group then
    global.biter_command.active_unit_groups[event.group.group_number] = {id = event.group.group_number, group = event.group}
    refresh_panel()
  end
end

local function on_unit_removed_from_group(event)
  if event and event.group then
    if #event.group.members == 1 then
      global.biter_command.active_unit_groups[event.group.group_number] = nil
      refresh_panel()
    end
  end
end

event.add(defines.events.on_unit_removed_from_group, on_unit_removed_from_group)
event.add(defines.events.on_unit_group_created, on_unit_group_created)
event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_gui_click, on_gui_click)
