-- welcome/welcome_controller.lua
local modname = core.get_current_modname()
local S = core.get_translator(modname)

jc_welcome_controller = {}

function jc_welcome_controller.show_welcome(player)
  local data = jc_welcome_model.get_data(player)

  if not data then
    return
  end

  jc_welcome_view.show(player:get_player_name(), data)
end

core.register_on_newplayer(function(player)
  local meta = player:get_meta()

  meta:set_int("welcome_new_player", 1)
  meta:set_int("welcome_first_join", os.time())
end)

core.register_on_player_receive_fields(function(player, formname, fields)
  if formname ~= "welcome:splash" then
    return false
  end

  if fields.show_places then
    if not player then
      return false, S("Player not found.")
    end

    local player_name = player:get_player_name()

    core.close_formspec(player_name, "welcome:splash")

    if jc_places and jc_places.show_places then
      jc_places.show_places(player_name)
    end

    return true
  end

  if fields.show_sounds then
    if not player then
      return false, S("Player not found.")
    end

    local player_name = player:get_player_name()

    core.close_formspec(player_name, "welcome:splash")

    if jc_special_sounds and jc_special_sounds.show_sounds_formspec then
      jc_special_sounds.show_sounds_formspec(player)
    end

    return true
  end

  return false
end)

core.register_on_joinplayer(function(player)
  local meta = player:get_meta()
  local now = os.time()

  -- Save the previous join time BEFORE updating it.
  local last_join = meta:get_int("welcome_last_join")

  if last_join > 0 then
    meta:set_int("welcome_previous_join", last_join)
  end

  -- Show welcome screen.
  -- This now displays the previous join time.
  jc_welcome_controller.show_welcome(player)

  -- Record this join as the current last join.
  meta:set_int("welcome_last_join", now)

  -- Existing player after their first join.
  if meta:get_int("welcome_new_player") == 1 then
    meta:set_int("welcome_new_player", 0)
  end
end)

core.register_chatcommand("welcome", {
  description = S("Show the welcome screen again"),

  func = function(name)
    local player = core.get_player_by_name(name)

    if not player then
      return false, S("Player not found.")
    end

    jc_welcome_controller.show_welcome(player)

    return true
  end
})
