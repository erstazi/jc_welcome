-- if_controller.lua

local session_times = jc_if_model.session_times
local player_activity = jc_if_model.player_activity

--------------------------------------------------------
-- Session time + activity
--------------------------------------------------------
core.register_globalstep(function(dtime)
  for _, player in ipairs(core.get_connected_players()) do
    local name = player:get_player_name()

    if session_times[name] then
      session_times[name] = session_times[name] + dtime
    end

    local ctrl = player:get_player_control()

    --[[
    get_player_control(): returns table with player input

    - The table contains the following boolean fields representing the pressed keys: up, down, left, right, jump, aux1, sneak, dig, place, LMB, RMB and zoom.
    - The fields LMB and RMB are equal to dig and place respectively, and exist only to preserve backwards compatibility.
    - The table also contains the fields movement_x and movement_y.
      - They represent the movement of the player. Values are numbers in the range [-1.0, +1.0].
      - They take both keyboard and joystick input into account.
      - You should prefer them over up, down, left and right to support different input methods correctly.
      - Returns an empty table {} if the object is not a player.
    OLD:
    if ctrl.up or ctrl.down or ctrl.left or ctrl.right or ctrl.jump or ctrl.LMB or ctrl.RMB then
    ]]
    if ctrl.movement_x ~= 0
        or ctrl.movement_y ~= 0
        or ctrl.jump
        or ctrl.aux1
        or ctrl.sneak
        or ctrl.dig
        or ctrl.place
        or ctrl.zoom then
      player_activity[name] = 0
    else
      player_activity[name] = (player_activity[name] or 0) + dtime
    end
  end
end)

core.register_on_chat_message(function(name, message)
  player_activity[name] = 0
end)

core.register_on_joinplayer(function(player)
  local pname = player:get_player_name()
  session_times[pname] = 0
  player_activity[pname] = 0
end)

core.register_on_leaveplayer(function(player)
  local pname = player:get_player_name()
  session_times[pname] = nil
  player_activity[pname] = nil
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

--------------------------------------------------------
-- Formspec buttons
--------------------------------------------------------
core.register_on_player_receive_fields(function(player, formname, fields)
  if formname ~= "if:panel" then
    return
  end

  local name = player:get_player_name()

  if fields.refresh then
    jc_if_view.show_panel(name)
  end
end)