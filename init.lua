local S = core.get_translator(core.get_current_modname())
local modpath = core.get_modpath(core.get_current_modname())
--------------------------------------------------------
-- Luanti :: Welcome Splash Screen Mod v2.1
--------------------------------------------------------

--------------------------------------------------------
-- NEW PLAYER / FIRST JOIN DATA
--------------------------------------------------------

core.register_on_newplayer(function(player)
  local meta = player:get_meta()

  meta:set_int("welcome_new_player", 1)
  meta:set_int("welcome_first_join", os.time())
end)

--------------------------------------------------------
-- SHOW WELCOME SCREEN
--------------------------------------------------------

local function show_welcome(player)
  if not player or player:get_hp() <= 0 then
    return
  end

  local pname = player:get_player_name()
  local meta = player:get_meta()

  --------------------------------------------------
  -- NEW / EXISTING PLAYER
  --------------------------------------------------

  local is_new_player = meta:get_int("welcome_new_player") == 1
  local ptime = meta:get_int("welcome_first_join")

  -- Existing player from before this feature existed.
  -- Give them a timestamp, but still treat them as
  -- an existing player and show "Welcome back".
  if not is_new_player and ptime == 0 then
    ptime = os.time()
    meta:set_int("welcome_first_join", ptime)
  end

  --------------------------------------------------
  -- Dynamic Real Skin
  --------------------------------------------------

  local skin_texture = "character.png"

  if player and skins.get_player_skin then
    local skin_obj = skins.get_player_skin(player)

    if skin_obj then
      skin_texture = skin_obj:get_preview() or skin_texture
    end
  end

  --------------------------------------------------
  -- Server Details
  --------------------------------------------------

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


  --------------------------------------------------
  -- Rank
  --------------------------------------------------

  local function get_ranked_name(name)
    local rank = ranks.get_rank(name) or "basic"
    local def = ranks.get_def(rank)

    if def and def.prefix then
      local colour = def.colour or "#ffffff"

      return core.colorize(
        colour,
        "[" .. def.prefix:upper() .. "]"
      ) .. " " .. name
    end

    return name
  end

  --------------------------------------------------
  -- ONLINE PLAYER LIST
  --------------------------------------------------

  local player_list = {}

  for _, p in ipairs(core.get_connected_players()) do
    player_list[#player_list + 1] = p:get_player_name()
  end

  --------------------------------------------------
  -- FORMSPEC
  --------------------------------------------------

  local formspec = "formspec_version[4]"
    .. "size[20,11.3]"
    .. default.gui_bg
    .. default.gui_bg_img

    .. "box[0.0,0.0;15.3,2;#111111]"

    .. string.format("label[3.5,0.3;%s]", core.formspec_escape(server_name) )

    .. string.format("label[3.5,0.9;%s:%s]", core.formspec_escape(server_address), core.formspec_escape(port) )

    .. "image[0.97,0.0;2,2;welcome_screen_logo.png]"
    .. "image[14.7,0.2;0.9,0.9;discord_logo.png]"

    .. "button_url[15.6,0.2;4.1,0.9;discord_link;"
      .. core.formspec_escape(S("Join Discord"))
      .. ";https://discord.gg/C8Ev9td5k]"

    .. "button_url[15.6,1.2;4.1,0.9;web_link;"
      .. core.formspec_escape(S("Visit Website"))
      .. ";https://justcraft.dssapp.us/]"

    .. "button_url[15.6,2.2;4.1,0.9;forum_link;"
      .. core.formspec_escape(S("Visit Forum"))
      .. ";https://forum.luanti.org/viewtopic.php?t=32339]"


  --------------------------------------------------
  -- TEXTS AND AVATAR
  --------------------------------------------------

  local avatar_x = 0.92
  local avatar_y = 3.03
  local avatar_w = 2.16
  local avatar_h = 3.24

  local frame_x = 0.25
  local frame_y = 2.15
  local frame_w = 3.5
  local frame_h = 5.25

  local text_x = 4.0
  local text_y_start = 2.5
  local line_spacing = 0.7

  local local_time = os.date("%H:%M:%S")

  --------------------------------------------------
  -- NEW PLAYER / RETURNING PLAYER
  --------------------------------------------------
  if is_new_player then
    formspec = formspec
      .. string.format(
        "label[%f,%f;%s]",
        text_x,
        text_y_start,
        core.formspec_escape(S("Greetings, @1!", pname))
      )

      .. string.format(
        "label[%f,%f;%f,%f;%s]",
        text_x,
        text_y_start + line_spacing,
        10.5,
        2,
        core.formspec_escape(S("Before starting, please read the rules with the /rules command."))
      )
  else
    formspec = formspec
      .. string.format(
        "label[%f,%f;%s]",
        text_x,
        text_y_start,
        core.formspec_escape(S("Welcome back, @1!", pname))
      )

      .. string.format(
        "label[%f,%f;%f,%f;%s]",
        text_x,
        text_y_start + line_spacing,
        10.5,
        2,
        core.formspec_escape( S("You first joined on @1", os.date("%A, %B %d, %Y", ptime) ) )
      )

      .. string.format(
        "label[%f,%f;%s]",
        text_x,
        text_y_start + 4 * line_spacing,
        core.formspec_escape(S("Local Time: @1", local_time))
      )
  end

  formspec = formspec
    -- Dark background behind player
    .. string.format(
      "box[%f,%f;%f,%f;#111111]",
      frame_x + 0.40,
      frame_y + 0.40,
      frame_w - 0.55,
      frame_h - 0.95
    )
    .. string.format(
      "image[%f,%f;%f,%f;%s]",
      avatar_x,
      avatar_y,
      avatar_w,
      avatar_h,
      skin_texture
    )

    .. string.format(
      "image[%f,%f;%f,%f;player_frame.png]",
      frame_x,
      frame_y,
      frame_w,
      frame_h
    )

  --------------------------------------------------
  -- PLAYER LIST
  --------------------------------------------------

  local list_x = 14.5
  local list_y = 3.9
  local list_w = 5.2
  local list_h = 6.5

  formspec = formspec
    .. string.format(
      "box[%f,%f;%f,%f;#111111]",
      list_x,
      list_y,
      list_w,
      list_h
    )

    .. string.format(
      "label[%f,%f;%s]",
      list_x,
      list_y - 0.4,
      core.formspec_escape(S("@1 Players Online", #player_list))
    )

    .. string.format(
      "textlist[%f,%f;%f,%f;player_list;",
      list_x,
      list_y,
      list_w,
      list_h
    )

  for i, name in ipairs(player_list) do
    local display_name = get_ranked_name(name)

    formspec = (i > 1 and formspec .. "," or formspec) .. core.formspec_escape(display_name)
  end

  formspec = formspec
    .. string.format(
      ";%d;true]",
      #player_list
    )

  --------------------------------------------------
  -- OWNER
  --------------------------------------------------

  local player_rank = ranks.get_rank(pname) or "basic"

  if player_rank == "owner" then
    formspec = formspec
      .. "label[4.0,6.0;10.5,2;" .. core.formspec_escape(S("Owner Section: Here you can monitor server activity")) .. "]"
  end

  --------------------------------------------------
  -- GENERAL
  --------------------------------------------------

  formspec = formspec
    .. "label[0.2,8.0;14.2,1.5;" .. core.formspec_escape(S("General Section: Enjoy the server!")) .. "]"

  --------------------------------------------------
  -- FOOTER
  --------------------------------------------------

  formspec = formspec
    .. "label[0.2,8.6;14.2,1.5;" .. core.formspec_escape(S("For a complete list of available commands, type /help into chat.")) .. "]"

  --------------------------------------------------
  -- Let's Play Button
  --------------------------------------------------

  formspec = formspec
    .. "button_exit[0.2,10.1;3,1;close;" .. core.formspec_escape(S("Let's Play!")) .. "]"

  --------------------------------------------------
  -- SHOW
  --------------------------------------------------

  core.show_formspec(
    pname,
    "welcome:splash",
    formspec
  )
end
--------------------------------------------------------
-- SHOW ON JOIN
--------------------------------------------------------

core.register_on_joinplayer(function(player)
  show_welcome(player)

  local meta = player:get_meta()

  if meta:get_int("welcome_new_player") == 1 then
    meta:set_int("welcome_new_player", 0)
  end
end)

--------------------------------------------------------
-- /welcome
--------------------------------------------------------

core.register_chatcommand("welcome", {
  description = S("Show the welcome screen again"),

  func = function(name)
    local player = core.get_player_by_name(name)

    if not player then
      return false, S("Player not found.")
    end

    show_welcome(player)

    return true
  end
})

--------------------------------------------------
-- LOAD AC PANEL
-- CARGAR AC PANEL
--------------------------------------------------

dofile(core.get_modpath("jc_welcome") .. "/ac.lua")

--------------------------------------------------
-- LOAD IF PANEL
-- CARGAR IF PANEL
--------------------------------------------------

dofile(core.get_modpath("jc_welcome") .. "/if.lua")

--------------------------------------------------
-- HELP
--------------------------------------------------

dofile(core.get_modpath("jc_welcome") .. "/help.lua")

--------------------------------------------------
-- A
--------------------------------------------------

dofile(core.get_modpath("jc_welcome") .. "/a.lua")