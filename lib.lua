
local dg_lib = {}

dg_lib.getNodeDefinition = function(player, altPos)
  --[[
    This function retrieves the node definition for a given player position.
    It checks if the node below the player (or at the specified alternative position)
    is registered in the core.registered_nodes table and returns the corresponding
    node definition if found.

    Args:
        player: The player object.
        altPos (optional): An alternative position table {x, y, z} to check instead of the player's current position.

    Returns:
        The node definition (table) if found, otherwise nil.
  ]]
	if player and type(player) == "userdata" and core.is_player(player) then
		local playerName = player:get_player_name()
    		local position = player:get_pos()
    		if altPos then
      			assert(
        			type(altPos) == "table" and
        			type(altPos.x) == "number" and
        			type(altPos.y) == "number" and
        			type(altPos.z) == "number", "[dg_lib.getNodeDefinition] Invalid alternative position"
      			)
      			position = altPos
    		end
  
    		local nodeBelow = core.get_node_or_nil(position)
  
    		if nodeBelow then
      			local nodeDefinition = core.registered_nodes[nodeBelow.name]
      			if nodeDefinition then
        			return nodeDefinition
      			end
    		end
	end
	return nil
end

dg_lib.NodeIsLiquid = function(player, altPos)
	local def = dg_lib.getNodeDefinition(player, altPos)
	if def and ( def.drawtype == "liquid" or def.drawtype == "flowingliquid" ) then
		return true
	end
	return false
end

dg_lib.NodeisWalkable = function(player, altPos)
	local def = dg_lib.getNodeDefinition(player, altPos)
	if def and def.walkable then
		return true
	end
	return false
end

dg_lib.NodeisClimbable = function(player, altPos)
	local def = dg_lib.getNodeDefinition(player, altPos)
	if def and def.climbable then
		return true
	end
	return false
end

dg_lib.NodeIsInSnowyGroup = function(player, altPos)
	local def = dg_lib.getNodeDefinition(player, altPos)
	if def and def.groups and def.groups and def.groups.snowy and def.groups.snowy > 0  then
		return true
	end
	return false
end

return dg_lib
