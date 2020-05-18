local function is_position_inside_playfield(position)
	if position.x > playfield_area.right_bottom.x then return false end
	if position.y > playfield_area.right_bottom.y then return false end
	if position.x <= playfield_area.left_top.x then return false end
	if position.y < playfield_area.left_top.y then return false end
	return true
end