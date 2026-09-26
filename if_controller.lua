-- if_controller.lua

local session_times = jc_if_model.session_times
local player_activity = jc_if_model.player_activity
local player_dead = jc_if_model.player_dead

local last_look = {}
local last_wield_index = {}

local LOOK_THRESHOLD = 0.01

local function set_active(name)
  if not player_dead[name] then
    player_activity[name] = 0
  end
end

local function angle_difference(a, b)
  local difference = math.abs(a - b)

  if difference > math.pi then
    difference = (math.pi * 2) - difference
  end

  return difference
end

--------------------------------------------------------
-- Session time + activity
--------------------------------------------------------
core.register_globalstep(function(dtime)
  for _, player in ipairs(core.get_connected_players()) do
    local name = player:get_player_name()

    if session_times[name] then
      session_times[name] = session_times[name] + dtime
    end

    if player_dead[name] then
      goto continue
    end

    local active = false
    local ctrl = player:get_player_control()

    if ctrl.movement_x ~= 0
        or ctrl.movement_y ~= 0
        or ctrl.jump
        or ctrl.aux1
        or ctrl.sneak
        or ctrl.dig
        or ctrl.place
        or ctrl.zoom then
      active = true
    end

    ----------------------------------------------------
    -- Mouse / camera movement
    ----------------------------------------------------
    local look_horizontal = player:get_look_horizontal()
    local look_vertical = player:get_look_vertical()

    if last_look[name] then
      if angle_difference(look_horizontal, last_look[name].horizontal) > LOOK_THRESHOLD
          or math.abs(look_vertical - last_look[name].vertical) > LOOK_THRESHOLD then
        active = true
      end
    end

    last_look[name] = {
      horizontal = look_horizontal,
      vertical = look_vertical,
    }

    ----------------------------------------------------
    -- Hotbar selection
    ----------------------------------------------------
    local wield_index = player:get_wield_index()

    if last_wield_index[name] and wield_index ~= last_wield_index[name] then
      active = true
    end

    last_wield_index[name] = wield_index

    if active then
      player_activity[name] = 0
    else
      player_activity[name] = (player_activity[name] or 0) + dtime
    end

    ::continue::
  end
end)

--------------------------------------------------------
-- Chat
--------------------------------------------------------
core.register_on_chat_message(function(name, message)
  set_active(name)
end)

--------------------------------------------------------
-- Chat commands
--------------------------------------------------------
core.register_on_chatcommand(function(name, command, params)
  set_active(name)
end)

--------------------------------------------------------
-- Forms / inventory formspec
--------------------------------------------------------
core.register_on_player_receive_fields(function(player, formname, fields)
  local name = player:get_player_name()

  set_active(name)

  if formname ~= "if:panel" then
    return
  end

  if fields.refresh then
    jc_if_view.show_panel(name)
  end
end)

--------------------------------------------------------
-- Node placement
--------------------------------------------------------
core.register_on_placenode(function(pos, newnode, placer, oldnode, itemstack, pointed_thing)
  if placer and placer:is_player() then
    set_active(placer:get_player_name())
  end
end)

--------------------------------------------------------
-- Node digging
--------------------------------------------------------
core.register_on_dignode(function(pos, oldnode, digger)
  if digger and digger:is_player() then
    set_active(digger:get_player_name())
  end
end)

--------------------------------------------------------
-- Node punching
--------------------------------------------------------
core.register_on_punchnode(function(pos, node, puncher, pointed_thing)
  if puncher and puncher:is_player() then
    set_active(puncher:get_player_name())
  end
end)

--------------------------------------------------------
-- Punching players
--------------------------------------------------------
core.register_on_punchplayer(function(player, hitter, time_from_last_punch, tool_capabilities, dir, damage)
  if hitter and hitter:is_player() then
    set_active(hitter:get_player_name())
  end
end)

--------------------------------------------------------
-- Right-clicking players
--------------------------------------------------------
core.register_on_rightclickplayer(function(player, clicker)
  if clicker and clicker:is_player() then
    set_active(clicker:get_player_name())
  end
end)

--------------------------------------------------------
-- Crafting
--------------------------------------------------------
core.register_on_craft(function(itemstack, player, old_craft_grid, craft_inv)
  if player and player:is_player() then
    set_active(player:get_player_name())
  end
end)

--------------------------------------------------------
-- Inventory actions
--------------------------------------------------------
core.register_on_player_inventory_action(function(player, action, inventory, inventory_info)
  if player and player:is_player() then
    set_active(player:get_player_name())
  end
end)

--------------------------------------------------------
-- Eating
--------------------------------------------------------
core.register_on_item_eat(function(hp_change, replace_with_item, itemstack, user, pointed_thing)
  if user and user:is_player() then
    set_active(user:get_player_name())
  end
end)

--------------------------------------------------------
-- Picking up dropped items
--------------------------------------------------------
core.register_on_item_pickup(function(itemstack, picker, pointed_thing, time_from_last_punch, ...)
  if picker and picker:is_player() then
    set_active(picker:get_player_name())
  end
end)

--------------------------------------------------------
-- Death
--------------------------------------------------------
core.register_on_dieplayer(function(player, reason)
  local name = player:get_player_name()

  player_dead[name] = true
  player_activity[name] = 0
end)

--------------------------------------------------------
-- Respawn
--------------------------------------------------------
core.register_on_respawnplayer(function(player)
  local name = player:get_player_name()

  player_dead[name] = false
  player_activity[name] = 0

  local wield_index = player:get_wield_index()

  last_wield_index[name] = wield_index

  local look_horizontal = player:get_look_horizontal()
  local look_vertical = player:get_look_vertical()

  last_look[name] = {
    horizontal = look_horizontal,
    vertical = look_vertical,
  }
end)

--------------------------------------------------------
-- Join
--------------------------------------------------------
core.register_on_joinplayer(function(player)
  local pname = player:get_player_name()

  session_times[pname] = 0
  player_activity[pname] = 0
  player_dead[pname] = false

  last_wield_index[pname] = player:get_wield_index()

  last_look[pname] = {
    horizontal = player:get_look_horizontal(),
    vertical = player:get_look_vertical(),
  }
end)

--------------------------------------------------------
-- Leave
--------------------------------------------------------
core.register_on_leaveplayer(function(player)
  local pname = player:get_player_name()

  session_times[pname] = nil
  player_activity[pname] = nil
  player_dead[pname] = nil
  last_look[pname] = nil
  last_wield_index[pname] = nil
end)

--------------------------------------------------------
-- /if
--------------------------------------------------------
core.register_chatcommand("if", {
  func = function(name)
    jc_if_view.show_panel(name)
    return true
  end
})