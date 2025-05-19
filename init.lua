local api = dg_sprint_core

local mod_name = core.get_current_modname()
local player_data  = {}
local dg_lib = dofile(core.get_modpath(mod_name) .. "/lib.lua")

local settings = {
	enable_hunger_bar = core.settings:get_bool("hunger_ng_use_hunger_bar", true),
    	starve_threshold = tonumber(core.settings:get("hunger_ng_starve_below")) or 1,
    	drain_rate = tonumber(core.settings:get(mod_name .. ".drain_rate")) or 5,
    	cancel_sprint_on_starve = core.settings:get_bool(mod_name .. ".starve_cancel_sprint", false),
    	cancel_sprint_on_snow = core.settings:get_bool(mod_name .. ".snow_cancel_sprint", false),
    	cancel_sprint_in_liquid = core.settings:get_bool(mod_name .. ".liquid_cancel_sprint", false),
}

-- Create a new player data table
local function create_pdata()
	return {
        	on_ground = true,
        	in_liquid = false,
        	on_snow = false,
		is_sprinting = false,
   	}
end

-- Register the player data when they join the game
-- Enable or disable features based on the mod's settings
core.register_on_joinplayer(function(player, last_login)
    	local name = player:get_player_name()
    	player_data[name] = create_pdata()
    	api.enable_aux1(player, core.settings:get_bool(mod_name .. ".aux1", true))
    	api.enable_double_tap(player, core.settings:get_bool(mod_name .. ".double_tap", true))
    	api.enable_particles(player, core.settings:get_bool(mod_name .. ".particles", true))
    	api.enable_drain(player, settings.enable_hunger_bar)
end)

core.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
    	player_data[name] = nil
end)

api.register_step(mod_name.. ":SPRINT", (0.3), function(player, dtime)
    local key_detected = api.is_key_detected(player) and not player:get_attach()
    local name = player:get_player_name()

    -- Only call sprint when state changes
    if key_detected and not player_data[name].is_sprinting then
        player_data[name].is_sprinting = true
        api.sprint(player, true) -- Start sprinting
    elseif not key_detected and player_data[name].is_sprinting then
        player_data[name].is_sprinting = false
        api.sprint(player, false) -- Stop sprinting
    end
end)

if settings.enable_hunger_bar then
    	-- Drain hunger when sprinting on ground or in liquid.
    	api.register_step(mod_name.. ":DRAIN", (0.2), function(player, dtime)

        	local control = player:get_player_control()

        	-- Check if player is draining and on ground or in liquid.
        	local draining = api.is_draining(player) and (player_data[player:get_player_name()].on_ground or player_data[player:get_player_name()].in_liquid)

        	-- Check for jump to start draining even when not on ground or in liquid
        	if not player_data[player:get_player_name()].in_liquid and control.jump and not draining then
            		draining = true
        	end

        	-- Drain hunger when sprinting and conditions are met.
        	if draining then
            		local player_name = player:get_player_name()
            		hunger_ng.alter_hunger(player_name, -( settings.drain_rate * dtime), 'Sprinting')
        	end
    	end)
end

if settings.enable_hunger_bar then
    	-- Check if the player is in a liquid (Water or Lava)
    	api.register_step(mod_name.. ":IN_LIQUID", (0.3), function(player, dtime)
		local def = dg_lib.getNodeDefinition(player)
            	local name = player:get_player_name()
            	local is_liquid = def and def.drawtype == "liquid" or def.drawtype == "flowingliquid"

            	if is_liquid and not player_data[name].in_liquid then
                	player_data[name].in_liquid = true
            	elseif not is_liquid and player_data[name].in_liquid then
                	player_data[name].in_liquid = false
            	end
    	end)
end

if settings.cancel_sprint_in_liquid or settings.cancel_sprint_on_snow or settings.cancel_sprint_on_starve then
        api.register_step(mod_name.. ":SPRINT_CANCELLATIONS", (0.3), function(player, dtime)
                local pos = player:get_pos()
                local def = dg_lib.getNodeDefinition(player,{ x = pos.x, y = pos.y + 0.5, z = pos.z })

                local cancel = false

		if settings.cancel_sprint_in_liquid and def and (def.drawtype == "liquid" or def.drawtype == "flowingliquid") then
                    	cancel = true
                elseif settings.cancel_sprint_on_snow and def and def.groups and def.groups and def.groups.snowy and def.groups.snowy > 0 then
                    	cancel = true
                elseif settings.cancel_sprint_on_starve and settings.enable_hunger_bar then
	                local p_name = player:get_player_name()
                	local info = hunger_ng.get_hunger_information(p_name)

			if info.hunger.exact <= settings.starve_threshold then
                        	cancel = true
                    	end
                end
                api.cancel_sprint(player, cancel, mod_name .. ":SPRINT_CANCELLATIONS")
        end)
end

-- Prevent key detection when going backwards
local NAME_CANCEL = ":CANCEL_BACKWARDS"

api.register_step(mod_name.. ":" .. NAME_CANCEL, 0.1, function(player, dtime)
	local control = player:get_player_control()
    	if not control.down then
        	api.prevent_detection(player, false, mod_name .. ":" .. NAME_CANCEL)
    	else
        	api.prevent_detection(player, true, mod_name .. ":" .. NAME_CANCEL)
    	end
end)

if settings.enable_hunger_bar then
	-- Check if the player is on the ground.
    	api.register_step(mod_name.. ":GROUND", 1, function(player, dtime)
		local name = player:get_player_name()
        	local pos = player:get_pos()
        	local def = dg_lib.getNodeDefinition(player, {x = pos.x, y = pos.y - 1, z = pos.z})
        	if def then
			if def.walkable and not player_data[name].on_ground then
				player_data[name].on_ground = true
        		elseif not def.walkable and player_data[name].on_ground then
            			player_data[name].on_ground = false
			end
        	end
    	end)
end
