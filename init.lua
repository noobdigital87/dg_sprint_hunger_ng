local your_mod_name = core.get_current_modname()

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
        drain_rate = get_settings_number(your_mod_name .. ".drain_rate", 5),
        starve_below = get_settings_number("hunger_ng_starve_below", 1),
        detection_step = get_settings_number(your_mod_name .. ".detection_step", 0.1),
        sprint_step = get_settings_number(your_mod_name .. ".sprint_step", 0.5),
        drain_step = get_settings_number(your_mod_name .. ".drain_step", 0.2),
        cancel_step = get_settings_number(your_mod_name .. ".cancel_step", 0.3),
}
local game_info = core.get_game_info()
dg_sprint_core.RegisterStep(your_mod_name, "DETECT", settings.detection_step, function(player, state, dtime)
	local detected = dg_sprint_core.IsSprintKeyDetected(player, settings.aux1, settings.double_tap, settings.tap_interval) and dg_sprint_core.IsMoving(player) and not player:get_attach()
	if detected ~= state.detected then
		state.detected = detected
	end

end)

dg_sprint_core.RegisterStep(your_mod_name, "SPRINT", settings.sprint_step, function(player, state, dtime)
			
	if state.detected and settings.particles then
		dg_sprint_core.ShowParticles(player:get_pos())
	end
			
	if game_info == "VoxeLibre" then
		dg_sprint_core.VoxeLibreSprint(player, sprint)
	else		
		dg_sprint_core.Sprint(your_mod_name, player, state.detected, {speed = 0.8, jump = 0.1})
	end
	
	if detected ~= state.is_sprinting then
		state.is_sprinting = detected
	end
end)

if settings.enable_sprint then
    dg_sprint_core.RegisterStep(your_mod_name, "DRAIN", settings.drain_step, function(player, state, dtime)
    	local is_sprinting = state.is_sprinting
        if is_sprinting then
    	    if dg_sprint_core.ExtraDrainCheck(player) then
                local player_name = player:get_player_name()
                hunger_ng.alter_hunger(player_name, -( settings.drain_rate * dtime), 'Sprinting')
    	    end
        end
    end)
end

dg_sprint_core.RegisterStep(your_mod_name , "SPRINT_CANCELLATIONS", settings.cancel_step, function(player, state, dtime)
    local pos = player:get_pos()
    local node_pos = { x = pos.x, y = pos.y + 0.5, z = pos.z }

    local cancel = false

	if settings.liquid and dg_sprint_core.IsNodeLiquid(player, node_pos) then
        cancel = true
    elseif settings.snow and dg_sprint_core.IsNodeSnow(player, node_pos) then
        cancel = true
    elseif settings.starve and settings.enable_sprint then
        if settings.starve_below == -1 then return end
        local info = hunger_ng.get_hunger_information(player:get_player_name())
        if info.hunger.exact <= settings.starve_below then
            cancel = true
        end
    end

    dg_sprint_core.prevent_detection(player, cancel, your_mod_name .. ":SPRINT_CANCELLATIONS")
end)
