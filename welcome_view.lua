-- welcome/welcome_view.lua
local modname = core.get_current_modname()
local S = core.get_translator(modname)
local ESC = core.formspec_escape

jc_welcome_view = {}

function jc_welcome_view.get_ranked_name(name)
  local rank = ranks.get_rank(name) or "basic"
  local def = ranks.get_def(rank)

  if def and def.prefix then
    local colour = def.colour or "#ffffff"

    return core.colorize(colour, "[" .. def.prefix:upper() .. "]" ) .. " " .. name
  end

  return name
end

function jc_welcome_view.build(data)
  local pname = data.player_name

  local formspec = "" ..
    "formspec_version[4]" ..
    "size[20,11.3]" ..
    default.gui_bg ..
    default.gui_bg_img ..

    "box[0.0,0.0;15.3,2;#111111]" ..
    string.format("label[3.5,0.3;%s]", ESC(data.server_name)) ..
    string.format("label[3.5,0.9;%s:%s]", ESC(data.server_address), ESC(data.port)) ..
    string.format("label[3.5,1.5;%s]", ESC(S("Local Time: @1", data.local_time))) ..
    "image[0.97,0.0;2,2;welcome_screen_logo.png]" ..
    "image[14.7,0.2;0.9,0.9;discord_logo.png]" ..
    "button_url[15.6,0.2;4.1,0.9;discord_link;" .. ESC( S("Join Discord") ) .. ";" .. ESC(data.link_discord) .. "]" ..
    "button_url[15.6,1.2;4.1,0.9;web_link;" .. ESC( S("Visit Website") ) .. ";" .. ESC(data.link_server_website) .. "]" ..
    "button_url[15.6,2.2;4.1,0.9;forum_link;" .. ESC( S("Visit Forum") ) .. ";" .. ESC(data.link_luanti_forum_post) .. "]" ..
    ""

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
  local line_spacing = 1.2

  if data.is_new_player then
    formspec = formspec ..
      string.format(
        "label[%f,%f;%f,%f;%s]",
        text_x,
        text_y_start,
        10.5,
        2,
        ESC( S("Greetings, @1!", core.colorize("#00FF00", pname) ) )
      )

    formspec = formspec ..
      string.format(
        "label[%f,%f;%f,%f;%s]",
        text_x,
        text_y_start + line_spacing,
        10.5,
        2,
        ESC( S("Before starting, please read the rules with the @1 command.", core.colorize("#FFFF00", "/rules") ) )
      )
  else
    formspec = formspec ..
      string.format(
        "label[%f,%f;%f,%f;%s]",
        text_x,
        text_y_start,
        10.5,
        2,
        ESC( S("Welcome back, @1!", core.colorize("#00FF00", pname) ) )
      )

    formspec = formspec ..
      string.format(
        "label[%f,%f;%f,%f;%s]",
        text_x,
        text_y_start + 1 * line_spacing,
        10.5,
        2,
        ESC( S("You first joined on @1", jc_welcome_model.format_date(data.first_join) ) )
      )

    if data.previous_join > 0 then
      formspec = formspec ..
        string.format(
          "label[%f,%f;%f,%f;%s]",
          text_x,
          text_y_start + 2 * line_spacing,
          10.5,
          2,
          ESC( S("You last logged on @1", jc_welcome_model.format_datetime(data.previous_join) ) )
        )
    end
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
      data.skin_texture
    )
    .. string.format(
      "image[%f,%f;%f,%f;player_frame.png]",
      frame_x,
      frame_y,
      frame_w,
      frame_h
    )

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
      ESC(S("@1 Players Online", #data.player_list))
    )
    .. string.format(
      "textlist[%f,%f;%f,%f;player_list;",
      list_x,
      list_y,
      list_w,
      list_h
    )

  for i, name in ipairs(data.player_list) do
    local display_name = jc_welcome_view.get_ranked_name(name)

    formspec = (i > 1 and formspec .. "," or formspec) .. ESC(display_name)
  end

  formspec = formspec .. string.format(";%d;true]", #data.player_list)

  local player_rank = ranks.get_rank(pname) or "basic"

  if player_rank == "owner" then
    formspec = formspec .. "label[4.0,6.0;10.5,2;" .. ESC( S("Owner Section: Here you can monitor server activity") ) .. "]"
  end

  formspec = formspec .. "label[0.2,8.0;14.2,1.5;" .. ESC( S("General Section: Enjoy the server!") ) .. "]"

  formspec = formspec .. "label[0.2,8.6;14.2,1.5;" .. ESC( S("For a complete list of available commands, type @1 into chat.", core.colorize("#FFFF00", "/help") ) ) .. "]"

  formspec = formspec .. "button_exit[0.2,10.1;3,1;close;" .. ESC( S("Let's Play!") ) .. "]"

  formspec = formspec .. "button[3.4,10.1;3,1;show_places;" .. ESC( S("Show Places") ) .. "]"

  formspec = formspec .. "button[6.6,10.1;3,1;show_sounds;" .. ESC( S("Sounds") ) .. "]"

  return formspec
end

function jc_welcome_view.show(player_name, data)
  core.show_formspec(player_name, "welcome:splash", jc_welcome_view.build(data) )
end
