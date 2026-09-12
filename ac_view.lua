-- ac_view.lua
local S = core.get_translator(core.get_current_modname())
local ESC = core.formspec_escape

jc_ac_view = {}

--------------------------------------------------------
-- Function for Command /ac
--------------------------------------------------------
function jc_ac_view.show_panel(name)
  local age = jc_ac_model.get_server_age_days()
  local stats = jc_ac_model.get_global_stats()

  local formspec =
    "formspec_version[4]"
    .. "size[20,11.2]"
    .. default.gui_bg
    .. default.gui_bg_img

    .. "label[0.3,0.3;" ..
      ESC(S("Active Players Panel")) .. "]"
    .. "label[11,0.3;" ..
      ESC(S("Server Age: @1 days", age)) .. "]"

    .. "box[0.2,0.7;19.6,1.2;#00000088]"

    .. "label[0.4,1.2;" .. ESC(S("Players: @1", stats.players)) .. "]"

    .. "label[7.0,1.2;" .. ESC(S("Total Hours: @1", stats.hours)) .. "]"

    .. "label[13.0,1.2;" .. ESC(S("Most Active: @1", stats.top)) .. "]"

    .. "box[0.2,2.0;19.6,8;#00000066]"

    .. "scroll_container[0.3,2.2;19.4,8.4;scroll;vertical]"

  local y = 0.2

  for pname, sdata in pairs(jc_ac_model.active_players) do
    local pdata = jc_ac_model.persistent[pname]

    local skin = "character.png"

    local player_obj = core.get_player_by_name(pname)
    if player_obj and skins and skins.get_player_skin then
      local s = skins.get_player_skin(player_obj)

      if s then
        skin = (s:get_preview() or skin) .. "^[resize:16x32"
      end
    end

    formspec =
      formspec
      .. "image[0.3," .. y - 0.2 .. ";0.4,0.8;" .. skin .. "]"
      .. "label[1.1," .. y + 0.2 .. ";" .. ESC(jc_ac_model.get_rank_display(pname)) .. "]"
      .. "label[6.2," .. y + 0.2 .. ";S:" .. ESC(math.floor(sdata.session_time / 3600)) .. "h]"
      .. "label[8.0," .. y + 0.2 .. ";T:" .. ESC(math.floor(pdata.total_hours)) .. "h]"
      .. "label[9.8," .. y + 0.2 .. ";J:" .. ESC(pdata.sessions) .. "]"

    y = y + 0.8
  end

  formspec = formspec
    .. "scroll_container_end[]"

    ------------------------------------------------
    -- Bottom buttons
    ------------------------------------------------
    .. "button[6.5,10.3;3,0.8;top_players;" .. ESC(S("TOP PLAYERS")) .. "]"
    .. "button[10.5,10.3;3,0.8;guardian;" .. ESC(S("GUARDIAN")) .. "]"

  core.show_formspec(name, "ac:panel", formspec)
end

--------------------------------------------------------
-- TOP PLAYERS PANEL
--------------------------------------------------------
function jc_ac_view.show_top_players(player)
  local groups = jc_ac_model.build_top_players()

  local fs =
    "formspec_version[4]"
    .. "size[20,11.2]"
    .. default.gui_bg
    .. default.gui_bg_img
    .. "label[0.3,0.3;" .. ESC(S("Top Players Panel")) .. "]"

  local y = 0.3

  fs = fs ..
    "scroll_container[0.3,0.8;18.5,9.0;top_players_scroll;vertical;0.1;0.3]"

  local function draw(title, list)
    if #list == 0 then
      return
    end

    fs = fs ..
      "label[0.2," .. y .. ";--- " .. ESC(S(title)) .. " ---]"

    y = y + 0.5

    for i = 1, #list do
      local name = list[i][1]
      local data = list[i][2]

      fs = fs ..
        "label[0.5," .. y .. ";" .. i .. ". " .. ESC(name) .. " - " .. math.floor(data.total_hours) .. "h]"

      y = y + 0.5
    end

    y = y + 0.3
  end

  draw("OWNER", groups.owner)
  draw("MODERATOR", groups.moderator)
  draw("STAFF", groups.staff)
  draw("GUARDIAN", groups.guardian)
  draw("BUILDER", groups.builder)
  draw("PLAYER", groups.player)
  -- draw("PLAYER", groups.player)
  -- draw("PLAYER", groups.player)
  -- draw("PLAYER", groups.player)

  fs = fs .. "scroll_container_end[]"

  ----------------------------------------------------
  -- Scrollbar
  ----------------------------------------------------

  fs = fs
    .. "scrollbaroptions[max=1000;smallstep=10;largestep=10]"
    .. "scrollbar[19.0,0.8;0.5,9.0;vertical;top_players_scroll;0]"

  ----------------------------------------------------
  -- BACK button
  ----------------------------------------------------
  fs = fs ..
    "button[8.0,10.2;4.0,0.8;back;" .. ESC(S("BACK")) .. "]"

  core.show_formspec(
    player:get_player_name(),
    "ac:top_players",
    fs
  )
end

--------------------------------------------------------
-- PANEL GUARDIAN PROGRESS
--------------------------------------------------------
function jc_ac_view.show_guardian(player)
  local list = {}

  for name, data in pairs(jc_ac_model.persistent) do
    local rank = ranks and ranks.get_rank and ranks.get_rank(name) or ""
    rank = tostring(rank):lower()

    if rank:find("build10") or rank:find("builder10") then
      local total_hours = data.total_hours or 0

      local sessions = data.sessions or 0

      local days = math.max(1, (os.time() - data.first_join) / 86400)
      -- Días jugados totales
      local join_day = math.floor(data.first_join / 86400)
      local today = math.floor(os.time() / 86400)
      local days_played = math.min(today - join_day, data.sessions)

      -- Antigüedad mínima de la cuenta (3 meses = 90 días)
      local account_age_days = today - join_day
      local age_ok = account_age_days >= 90

      ------------------------------------------------
      -- PROGRESOS
      ------------------------------------------------
      local hours_prog = math.min(100, (total_hours / 90) * 100)

      local avg_day = total_hours / days

      local activity_prog = math.min(100, (avg_day / 12) * 100)

      local join_ratio = sessions / math.max(1,total_hours)

      local join_prog = math.min(100, (0.5 / join_ratio) * 100)

      ------------------------------------------------
      -- CONDICIONES
      ------------------------------------------------
      local hours_ok = total_hours >= 90

      local activity_ok = avg_day >= 12

      local join_ok = join_ratio <= 0.5

      table.insert(list, {name = name, hours = total_hours, h = hours_prog, a = activity_prog, j = join_prog, ok = hours_ok and activity_ok and join_ok, days = days_played })
    end
  end

  ------------------------------------------------
  -- FORMSPEC
  ------------------------------------------------
  local fs =
    "formspec_version[4]"
    .. "size[21.0,11.2]"
    .. default.gui_bg
    .. default.gui_bg_img

    -- Title
    .. "label[0.3,0.5;" .. ESC(S("Guardian Progress Panel")) .. "]"

    -- Header background
    .. "box[0.3,1.0;19.4,0.8;#00000088]"

    -- Header
    .. "label[0.5,1.5;" .. ESC(S("Player")) .. "]"
    .. "label[6.0,1.5;" .. ESC(S("Hours")) .. "]"
    .. "label[8.3,1.5;" .. ESC(S("Activity %")) .. "]"
    .. "label[10.9,1.5;" .. ESC(S("Join %")) .. "]"
    .. "label[14.1,1.5;" .. ESC(S("Days")) .. "]"
    .. "label[16.3,1.5;" .. ESC(S("Status")) .. "]"

    -- Column separators
    .. "box[5.5,1.0;0.02,7.5;#ffffff22]"
    .. "box[8.0,1.0;0.02,7.5;#ffffff22]"
    .. "box[10.8,1.0;0.02,7.5;#ffffff22]"
    .. "box[13.6,1.0;0.02,7.5;#ffffff22]"
    .. "box[15.8,1.0;0.02,7.5;#ffffff22]"

    -- Scroll area
    .. "scroll_container[0.3,2.0;19.4,7.8;scroll_guardian;vertical]"

  local y = 0.2

  for _, p in ipairs(list) do
    local status = S("NOT READY")

    if p.ok then
      status = S("READY")
    end

    fs = fs
      -- Row separator
      .. "box[0.3," .. (y + 0.3) .. ";19.4,0.02;#ffffff22]"

      -- Player
      .. "label[0.2," .. y .. ";" .. ESC(p.name) .. "]"

      -- Hours
      .. "label[5.7," .. y .. ";" .. ESC(math.floor(p.hours) .. "/90") .. "]"

      -- Activity
      .. "label[8.2," .. y .. ";" .. ESC(math.floor(p.a) .. "%") .. "]"

      -- Join Ratio
      .. "label[11.0," .. y .. ";" .. ESC(math.floor(p.j) .. "%") .. "]"

      -- Days
      .. "label[13.8," .. y .. ";" .. ESC(p.days) .. "]"

      -- Status
      .. "label[16.0," .. y .. ";" .. ESC(status) .. "]"

    y = y + 0.7
  end

  fs = fs ..
    "scroll_container_end[]"
  ----------------------------------------------------
  -- Scrollbar
  ----------------------------------------------------

  fs = fs
    .. "scrollbaroptions[max=1000;smallstep=10;largestep=10]"
    .. "scrollbar[19.8,1.8;0.5,8.2;vertical;scroll_guardian;0]"

  ----------------------------------------------------
  -- BACK button
  ----------------------------------------------------
  fs = fs ..
    "button[8.0,10.2;4.0,0.8;back;" .. ESC(S("BACK")) .. "]"

  core.show_formspec(player:get_player_name(), "ac:guardian", fs)
end