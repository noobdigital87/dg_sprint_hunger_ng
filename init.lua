local your_mod_name = core.get_current_modname()

local api = dg_sprint_core

local function get_settings_boolean(setting_name, default)
	return core.settings:get_bool(setting_name, default)
end

local function get_settings_number(setting_name, default)
	return tonumber(core.settings:get(setting_name)) or default
end

local settings = {
        enable_sprint = get_settings_boolean("hunger_ng_use_hunger_bar", true),
    	aux1 = get_settings_boolean(your_mod_name .. ".aux1", true),
    	double_tap = get_settings_boolean(your_mod_name .. ".double_tap", true),
    	particles = get_settings_boolean(your_mod_name .. ".particles", true),
    	tap_interval = get_settings_number(your_mod_name .. ".tap_interval", 0.5),
        liquid = get_settings_boolean(your_mod_name .. ".liquid", false),
        snow = get_settings_boolean(your_mod_name .. ".snow", false),
        starve = get_settings_boolean(your_mod_name .. ".starve", false),
        drain_rate = get_settings_number(your_mod_name .. ".drain_rate", 2),
        starve_below = get_settings_number("hunger_ng_starve_below", 1),
        detection_step = get_settings_number(your_mod_name .. ".detection_step", 0.1),
        sprint_step = get_settings_number(your_mod_name .. ".sprint_step", 0.5),
        drain_step = get_settings_number(your_mod_name .. ".drain_step", 0.2),
        cancel_step = get_settings_number(your_mod_name .. ".cancel_step", 0.3),
        speed = get_settings_number(your_mod_name .. ".speed", 0.8),
        jump = get_settings_number(your_mod_name .. ".jump", 0.1),
        fov = get_settings_boolean(your_mod_name .. ".fov", true),
        fov_value = get_settings_number(your_mod_name .. ".fov_value", 15),
        fov_time_stop = get_settings_number(your_mod_name .. ".fov_time_stop", 0.4),
	fov_time_start = get_settings_number(your_mod_name..".fov_time_start", 0.2),
}

api.register_server_step(your_mod_name, "DETECT", settings.detection_step, function(player, state, dtime)
	local control = player:get_player_control()
	local detected = api.sprint_key_detected(player, (settings.aux1 and control.aux1), (settings.double_tap and control.up), settings.tap_interval)
	if detected ~= state.detected then
		state.detected = detected
	end
end)

api.register_server_step(your_mod_name, "SPRINT", settings.sprint_step, function(player, state, dtime)
	if not settings.fov then
		settings.fov_value = 0
    	end

    	if state.detected then
        	local sprint_settings = {speed = settings.speed, jump = settings.jump, particles = settings.particles, fov = settings.fov_value, transition = settings.fov_time_start}
		api.set_sprint(your_mod_name, player, state.detected, sprint_settings)
    	else
        	local sprint_settings = {speed = settings.speed, jump = settings.jump, particles = settings.particles, fov = settings.fov_value, transition = settings.fov_time_stop}
        	api.set_sprint(your_mod_name, player, state.detected, sprint_settings)
    	end
end)

if settings.enable_sprint then
	api.register_server_step(your_mod_name, "DRAIN", settings.drain_step, function(player, state, dtime)
        	if state.detected and api.is_player_draining(player) then
            		local player_name = player:get_player_name()
            		hunger_ng.alter_hunger(player_name, -( settings.drain_rate * dtime), 'Sprinting')
        	end
    	end)
end

api.register_server_step(your_mod_name , "SPRINT_CANCELLATIONS", settings.cancel_step, function(player, state, dtime)
    
	local pos = player:get_pos()
		
    	local node_pos = { x = pos.x, y = pos.y + 0.5, z = pos.z }

    	local cancel = false

	local control = player:get_player_control()
		
	if control.down then
		cancel = true	
	elseif settings.liquid and api.tools.node_is_liquid(player, node_pos) then
        	cancel = true
    	elseif settings.snow and api.tools.node_is_snowy_group(player, node_pos) then
        	cancel = true
    	elseif settings.starve and settings.enable_sprint then
        	if settings.starve_below == -1 then return end
        	local info = hunger_ng.get_hunger_information(player:get_player_name())
        	if info.hunger.exact <= settings.starve_below then	
            		cancel = true	
		end
	end
    	api.set_sprint_cancel(player, cancel, your_mod_name .. ":SPRINT_CANCELLATIONS")
end)

