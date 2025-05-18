local api = dg_sprint_core

local mod_name = core.get_current_modname()
local player_data  = {}


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
    player_data[player:get_player_name()] = nil
end)

-- Sprint when key is detected and not attached to an object.
api.register_step(mod_name.. ":SPRINT", (0.3), function(player, dtime)
    local key_detected = api.is_key_detected(player) and not player:get_attach()
    api.sprint(player, key_detected)
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
        local name = player:get_player_name()
        local pos = player:get_pos()
        local node_below = core.get_node_or_nil(pos)
        if node_below then
            local def = minetest.registered_nodes[node_below.name] or {}
            local drawtype = def.drawtype
            local is_liquid = drawtype == "liquid" or drawtype == "flowingliquid"
            if is_liquid and not player_data[name].in_liquid then
                player_data[name].in_liquid = true
            else
                player_data[name].in_liquid = false
            end
        end
    end)
end

if settings.cancel_sprint_in_liquid then
    -- Check if the player is in a liquid (Water or Lava)
    api.register_step(mod_name.. ":IN_LIQUID", (0.3), function(player, dtime)
        local name = player:get_player_name()
        local pos = player:get_pos()
        local node_below = core.get_node_or_nil(pos)
        if node_below then
            local def = minetest.registered_nodes[node_below.name] or {}
            local drawtype = def.drawtype
            local is_liquid = drawtype == "liquid" or drawtype == "flowingliquid"
            if is_liquid and not player_data[name].in_liquid then
                api.cancel_sprint(player, true, mod_name .. ":IN_LIQUID")
            else
                api.cancel_sprint(player, false, mod_name .. ":IN_LIQUID")
            end
        end
    end)
end

if settings.cancel_sprint_on_snow then
    -- Check if the player is on snow
    api.register_step(mod_name.. ":ON_SNOW", (0.3), function(player, dtime)
        local pos = player:get_pos()
        local check_pos = { x = pos.x, y = pos.y + 0.5, z = pos.z }
        local node = core.get_node_or_nil(check_pos)
        if node then
            local def = core.registered_nodes[node.name]
            if def and def.groups and def.groups.snowy and def.groups.snowy > 0 then
                api.cancel_sprint(player, true, mod_name .. ":ON_SNOW")
            else
                api.cancel_sprint(player, false, mod_name .. ":ON_SNOW")
            end
        end
    end)
end

if settings.cancel_sprint_on_starve then 
    -- Cancel sprinting if the player is starving and settings are enabled
    api.register_step(mod_name.. ":CANCEL", 0.4, function(player, dtime)
        if settings.cancel_sprint_on_starve then
            local p_name = player:get_player_name()
            local info = hunger_ng.get_hunger_information(p_name)
            if info.hunger.exact <= settings.starve_threshold then
                api.cancel_sprint(player, true, mod_name .. ":CANCEL")
            else
                api.cancel_sprint(player, false, mod_name .. ":CANCEL")
            end
        end
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

-- Check if the player is on the ground.
api.register_step(mod_name.. ":GROUND", 0.4, function(player, dtime)
    local pos = player:get_pos()
    local node_below = core.get_node_or_nil({x = pos.x, y = pos.y - 1, z = pos.z})
    if node_below then
        local def = core.registered_nodes[node_below.name]
        if def and def.walkable then
            player_data[player:get_player_name()].on_ground = true
        else
            player_data[player:get_player_name()].on_ground = false
        end
    end
end)
