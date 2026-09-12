-- welcome/welcome_model.lua
local modname = core.get_current_modname()
local S = core.get_translator(modname)

jc_welcome_model = {}

local DAYS = {
  S("Sunday"),
  S("Monday"),
  S("Tuesday"),
  S("Wednesday"),
  S("Thursday"),
  S("Friday"),
  S("Saturday")
}

local MONTHS = {
  S("January"),
  S("February"),
  S("March"),
  S("April"),
  S("May"),
  S("June"),
  S("July"),
  S("August"),
  S("September"),
  S("October"),
  S("November"),
  S("December")
}

function jc_welcome_model.format_date(timestamp)
  local t = os.date("*t", timestamp)

  return S("@1, @2 @3, @4",
    DAYS[t.wday],
    MONTHS[t.month],
    t.day,
    t.year
  )
end

function jc_welcome_model.format_datetime(timestamp)
  local t = os.date("*t", timestamp)

  return S("@1, @2 @3, @4 at @5:@6",
    DAYS[t.wday],
    MONTHS[t.month],
    t.day,
    t.year,
    string.format("%02d", t.hour),
    string.format("%02d", t.min)
  )
end

function jc_welcome_model.get_data(player)
  if not player or player:get_hp() <= 0 then
    return nil
  end

  local pname = player:get_player_name()
  local meta = player:get_meta()

  local is_new_player = meta:get_int("welcome_new_player") == 1
  local ptime = meta:get_int("welcome_first_join")
  local ltime = meta:get_int("welcome_previous_join")

  -- Existing player from before this feature existed.
  -- Give them a timestamp, but still treat them as
  -- an existing player and show "Welcome back".
  if not is_new_player and ptime == 0 then
    ptime = os.time()
    meta:set_int("welcome_first_join", ptime)
  end

  local skin_texture = "character.png"

  if skins.get_player_skin then
    local skin_obj = skins.get_player_skin(player)

    if skin_obj then
      skin_texture = skin_obj:get_preview() or skin_texture
    end
  end

  local server_name = core.settings:get("server_name")

  if server_name == "" then
    server_name = "Untitled Server"
  end

  local server_address = core.settings:get("server_address")

  if server_address == "" then
    server_address = "localhost"
  end

  local port = core.settings:get("port")

  if port == "" then
    port = "30000"
  end

  local player_list = {}

  for _, p in ipairs(core.get_connected_players()) do
    player_list[#player_list + 1] = p:get_player_name()
  end

  return {
    player = player,
    player_name = pname,
    is_new_player = is_new_player,
    first_join = ptime,
    previous_join = ltime,
    skin_texture = skin_texture,
    server_name = server_name,
    server_address = server_address,
    port = port,
    local_time = os.date("%H:%M:%S"),
    player_list = player_list,

    link_server_website = jc_welcome_config.link_server_website,
    link_discord = jc_welcome_config.link_discord,
    link_luanti_forum_post = jc_welcome_config.link_luanti_forum_post,
  }
end
