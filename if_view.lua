-- if_view.lua
local ESC = core.formspec_escape

jc_if_view = {}

function jc_if_view.show_panel(name)
  ----------------------------------------------------
  -- Global time
  ----------------------------------------------------
  local server_time = jc_if_model.get_server_time()
  local days, years = jc_if_model.get_world_age()

  ----------------------------------------------------
  -- Base formspec
  ----------------------------------------------------
  local formspec =
    "formspec_version[4]"
    .."size[13,9]"
    ..default.gui_bg
    ..default.gui_bg_img

    ------------------------------------------------
    -- Header
    ------------------------------------------------
    .."label[0.4,0.3;IF - Players Online]"
    .."label[9.5,0.3;Time: " .. ESC(server_time) .. "]"
    .."label[9.5,0.8;Day: " .. ESC(days) .. "]"
    .."label[9.5,1.3;Year: " .. ESC(years) .. "]"

    ------------------------------------------------
    -- Refresh button
    ------------------------------------------------
    .."button[5.2,0.25;2.5,0.8;refresh;Refresh]"

    ------------------------------------------------
    -- Bottom of the list
    ------------------------------------------------
    .."box[0.3,2.0;12.0,6.7;#00000066]"

    ------------------------------------------------
    -- Scroll container
    ------------------------------------------------
    .."scroll_container[0.4,2.2;11.8,6.3;scroll_players_activeornot;vertical]"

  ----------------------------------------------------
  -- Player list
  ----------------------------------------------------
  local online = jc_if_model.get_online_players()

  ----------------------------------------------------
  -- Draw list
  ----------------------------------------------------
  local y = 0.2

  for _,p in ipairs(online) do
    local minutes = math.floor(p.time/60)
    local seconds = math.floor(p.time%60)
    local player_obj = core.get_player_by_name(p.name)

    ------------------------------------------------
    -- Skin FIX
    ------------------------------------------------
    local head_texture = "character.png"

    if player_obj and skins and skins.get_player_skin then
      local skin_obj = skins.get_player_skin(player_obj)

      if skin_obj then
        head_texture = (skin_obj:get_preview() or head_texture) .. "^[resize:16x32"
      end
    end

    ------------------------------------------------
    -- Name + rank
    ------------------------------------------------
    local display_name = jc_if_model.get_rank_display(p.name)

    ------------------------------------------------
    -- Status
    ------------------------------------------------
    local status = jc_if_model.get_status(p.name)

    ------------------------------------------------
    -- Row draw
    ------------------------------------------------
    formspec = formspec
      ..string.format("image[0.3,%.2f;0.4,0.8;%s]", ESC(y-0.2), ESC(head_texture) )
      ..string.format("label[1.3,%.2f;%s]", ESC(y+0.15), ESC(display_name) )
      ..string.format("label[7.0,%.2f;%dm %ds]", ESC(y+0.15), ESC(minutes), ESC(seconds) )
      ..string.format("label[9.5,%.2f;%s]", ESC(y+0.15), ESC(status) )

    y = y + 0.9
  end

  ----------------------------------------------------
  -- Close scroll
  ----------------------------------------------------
  formspec = formspec .. "scroll_container_end[]"
  formspec = formspec .. "scrollbaroptions[max=1000;smallstep=10;largestep=10]"
  formspec = formspec .. "scrollbar[12.3,2.0;0.5,6.7;vertical;scroll_players_activeornot;0]"

  ----------------------------------------------------
  -- Show
  ----------------------------------------------------
  core.show_formspec(name, "if:panel", formspec)
end