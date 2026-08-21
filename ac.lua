local S = core.get_translator(core.get_current_modname())
local modpath = core.get_modpath(core.get_current_modname())
local storage = core.get_mod_storage()

--------------------------------------------------------
-- Active Players Panel (AC) v3.1 EXPANDED REAL+
-- Persistencia + Estadísticas + Historial + Rank Tops

local active_players = {}
local persistent = {}

--------------------------------------------------------
-- MOD STORAGE
--------------------------------------------------------

local function get_storage_key(name)
  return "player:" .. name
end

local function load_player_data(name)
  local value = storage:get_string(get_storage_key(name))

  if value == "" then
    return nil
  end

  return core.deserialize(value)
end

local function save_player_data(name, data)
  storage:set_string(
    get_storage_key(name),
    core.serialize(data)
  )
end

local function save_player_list()
  if type(persistent) ~= "table" then
    persistent = {}
  end

  local players = {}

  for name in pairs(persistent) do
    table.insert(players, name)
  end

  table.sort(players)

  storage:set_string(
    "players",
    core.serialize(players)
  )
end

--------------------------------------------------------
-- MIGRATE OLD ac_data.mt
--------------------------------------------------------

local function migrate_old_data()
  local old_file = core.get_worldpath() .. "/ac_data.mt"
  local migrated_file = core.get_worldpath() .. "/ac_data.mt.migrated"

  -- Check whether ModStorage already contains players.
  local players_raw = storage:get_string("players")

  if players_raw ~= "" then
    return false
  end

  -- Check for old data file.
  local file = io.open(old_file, "r")

  if not file then
    return false
  end

  core.log("action", "[jc_welcome] Migrating ac_data.mt to ModStorage...")

  local content = file:read("*all")
  file:close()

  if not content or content == "" then
    core.log("warning", "[jc_welcome] ac_data.mt is empty. Migration skipped.")
    return false
  end

  local old_data = core.deserialize(content)

  if type(old_data) ~= "table" then
    core.log("error", "[jc_welcome] Could not deserialize ac_data.mt. Migration aborted.")
    return false
  end

  local count = 0

  for name, data in pairs(old_data) do
    if type(name) == "string" and type(data) == "table" then
      save_player_data(name, data)
      count = count + 1
    end
  end

  -- Create player index.
  local players = {}

  for name in pairs(old_data) do
    table.insert(players, name)
  end

  table.sort(players)

  storage:set_string(
    "players",
    core.serialize(players)
  )

  -- Verify that ModStorage now contains the data.
  local verify = storage:get_string("players")

  if verify == "" then
    core.log(
      "error",
      "[jc_welcome] ModStorage verification failed. Original ac_data.mt was NOT changed."
    )

    return false
  end

  -- Keep a backup of the original file.
  local renamed = os.rename(old_file, migrated_file)

  if renamed then
    core.log(
      "action",
      "[jc_welcome] Migration complete: " ..
      count .. " players moved to ModStorage."
    )

    core.log(
      "action",
      "[jc_welcome] Original data saved as ac_data.mt.migrated."
    )
  else
    core.log(
      "warning",
      "[jc_welcome] Data migrated successfully, but ac_data.mt could not be renamed."
    )
  end

  return true
end

--------------------------------------------------------
-- LOAD DATA FROM MOD STORAGE
--------------------------------------------------------

local function load_data()
  local data = {}

  local players_raw = storage:get_string("players")

  if players_raw ~= "" then
    local players = core.deserialize(players_raw)

    if type(players) == "table" then
      for _, name in ipairs(players) do
        local player_data = load_player_data(name)

        if player_data then
          data[name] = player_data
        end
      end
    end
  end

  return data
end

--------------------------------------------------------
-- MIGRATE THEN LOAD
--------------------------------------------------------

migrate_old_data()

persistent = load_data()

if type(persistent) ~= "table" then
  persistent = {}
end

-- Edad real server
local function get_server_age_days()
  local created = storage:get_int("server_created")

  if created == 0 then
    -- Server creation: 2026-02-09 04:23:00
    created = os.time({
      year = 2026,
      month = 2,
      day = 9,
      hour = 4,
      min = 23,
      sec = 0
    })

    storage:set_int("server_created", created)
    storage:set_string("server_created_date", "2026-02-09 04:23:00")
  end

  return math.floor((os.time() - created) / 86400)
end


-- Join
core.register_on_joinplayer(function(player)
  local name = player:get_player_name()

  if not persistent[name] then
    persistent[name] = {
      first_join = os.time(),
      total_hours = 0,
      sessions = 0,
      afk_time = 0
    }

    save_player_list()
  end

  persistent[name].sessions =
    persistent[name].sessions + 1

  save_player_data(name, persistent[name])

  active_players[name] = {
    session_time = 0,
    last_pos = player:get_pos(),
    afk_timer = 0
  }
end)


-- Leave

core.register_on_leaveplayer(function(player)
  local name = player:get_player_name()

  if active_players[name] and persistent[name] then
    local hours = active_players[name].session_time / 3600

    persistent[name].total_hours =
      (persistent[name].total_hours or 0) + hours

    persistent[name].afk_time =
      (persistent[name].afk_time or 0) + active_players[name].afk_timer

    save_player_data(name, persistent[name])

    active_players[name] = nil
  end
end)


-- Globalstep

core.register_globalstep(function(dtime)
  for name, data in pairs(active_players) do
    data.session_time = data.session_time + dtime
    local player = core.get_player_by_name(name)
    if player then
      local pos = player:get_pos()
      if vector.distance(pos, data.last_pos) < 0.1 then
        data.afk_timer = data.afk_timer + dtime
      else
        data.afk_timer = 0
      end
      data.last_pos = pos
    end
  end
end)


-- Rango display
local function get_rank_display(name)
  if not ranks or not ranks.get_rank then
    return name
  end

  local rank = ranks.get_rank(name)
  local def = ranks.get_def(rank)

  if def and def.prefix then
    return core.colorize(def.colour or "#fff", "[" .. def.prefix:upper() .. "] ") .. name
  end

  return name
end

-- Estadísticas globales

local function get_global_stats()
  local total_players = 0
  local total_hours = 0
  local most_active = "None"
  local max_hours = 0

  for name, data in pairs(persistent) do

    total_players = total_players + 1
    total_hours = total_hours + data.total_hours

    if data.total_hours > max_hours then
      max_hours = data.total_hours
      most_active = name
    end
  end

  return {
    players = total_players,
    hours = math.floor(total_hours),
    top = most_active
  }
end

-- TOPS POR RANGO (DATA)

local function get_rank(name)
  if ranks and ranks.get_rank then
    return ranks.get_rank(name) or "player"
  end
  return "player"
end

local function build_rank_tops()

  local groups = {
    owner = {},
    moderator = {},
    staff = {},
    guardian = {},
    builder = {},
    player = {}
  }

  for name, data in pairs(persistent) do
    local rank = get_rank(name)
    if rank == "owner" then
      table.insert(groups.owner, {name,data})
    elseif rank == "moderator" then
      table.insert(groups.moderator, {name,data})
    elseif rank == "staff" then
      table.insert(groups.staff, {name,data})
    elseif rank == "guardian" then
      table.insert(groups.guardian, {name,data})
    elseif rank:find("build") then
      table.insert(groups.builder, {name,data})
    else
      table.insert(groups.player, {name,data})
    end
  end

  for _, list in pairs(groups) do
    table.sort(list, function(a,b)
      return a[2].total_hours > b[2].total_hours
    end)
  end

  return groups
end

-- Function for Command /ac
local function show_ac_panel(name)
  local age = get_server_age_days()
  local stats = get_global_stats()

  local formspec =
    "formspec_version[4]"
    .. "size[20,11.2]"
    .. default.gui_bg
    .. default.gui_bg_img

    .. "label[0.3,0.3;" ..
      core.formspec_escape(S("Active Players Panel")) .. "]"
    .. "label[11,0.3;" ..
      core.formspec_escape(S("Server Age: @1 days", age)) .. "]"

    .. "box[0.2,0.7;19.6,1.2;#00000088]"

    .. "label[0.4,1.2;" .. core.formspec_escape(S("Players: @1", stats.players)) .. "]"

    .. "label[7.0,1.2;" .. core.formspec_escape(S("Total Hours: @1", stats.hours)) .. "]"

    .. "label[13.0,1.2;" .. core.formspec_escape(S("Most Active: @1", stats.top)) .. "]"

    .. "box[0.2,2.0;19.6,8;#00000066]"

    .. "scroll_container[0.3,2.2;19.4,8.4;scroll;vertical]"

  local y = 0.2

  for pname, sdata in pairs(active_players) do
    local pdata = persistent[pname]

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
      .. "image[0.3," .. y - 0.2 .. ";0.7,0.7;" .. skin .. "]"
      .. "label[1.1," .. y .. ";" .. core.formspec_escape(get_rank_display(pname)) .. "]"
      .. "label[6.2," .. y .. ";S:" .. math.floor(sdata.session_time / 3600) .. "h]"
      .. "label[8.0," .. y .. ";T:" .. math.floor(pdata.total_hours) .. "h]"
      .. "label[9.8," .. y .. ";J:" .. pdata.sessions .. "]"

    y = y + 0.8
  end

  formspec = formspec
    .. "scroll_container_end[]"

    ------------------------------------------------
    -- Bottom buttons
    ------------------------------------------------
    .. "button[6.5,10.3;3,0.8;ranktops;" .. core.formspec_escape(S("RANK TOPS")) .. "]"
    .. "button[10.5,10.3;3,0.8;guardian;" .. core.formspec_escape(S("GUARDIAN")) .. "]"

  core.show_formspec(name, "ac:panel", formspec)
end

-- For Command /ac
core.register_chatcommand("ac", {
  description = S("Active Players Panel v3"),

  func = function(name)
    if not core.check_player_privs(name, {server=true}) then
      return false, S("No permission.")
    end

    show_ac_panel(name)

    return true
  end
})



--------------------------------------------------------
-- EVENTOS BOTONES PANEL AC (UNIFICADO)
--------------------------------------------------------
core.register_on_player_receive_fields(function(player, formname, fields)
  local name = player:get_player_name()

  ----------------------------------------------------
  -- BACK FROM RANK TOPS
  ----------------------------------------------------
  if formname == "ac:ranktops" then
    if fields.back then
      show_ac_panel(name)
    end

    return
  end


  ----------------------------------------------------
  -- BACK FROM GUARDIAN
  ----------------------------------------------------
  if formname == "ac:guardian" then
    if fields.back then
      show_ac_panel(name)
    end

    return
  end


  if formname ~= "ac:panel" then return end
  ----------------------------------------------------
  -- PANEL RANK TOPS
  ----------------------------------------------------
  if fields.ranktops then
    local groups = build_rank_tops()

    local fs =
      "formspec_version[4]"
      .. "size[20,11.2]"
      .. default.gui_bg
      .. default.gui_bg_img
      .. "label[0.3,0.3;" .. core.formspec_escape(S("Rank Tops Panel")) .. "]"

    local y = 0.3

    fs = fs ..
      "scroll_container[0.3,0.8;18.5,9.0;ranktops_scroll;vertical;0.1;0.3]"

    local function draw(title, list)
      if #list == 0 then
        return
      end

      fs = fs ..
        "label[0.2," .. y .. ";--- " .. core.formspec_escape(S(title)) .. " ---]"

      y = y + 0.5

      for i = 1, #list do
        local name = list[i][1]
        local data = list[i][2]

        fs = fs ..
          "label[0.5," .. y .. ";" .. i .. ". " .. core.formspec_escape(name) .. " - " .. math.floor(data.total_hours) .. "h]"

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
    draw("PLAYER", groups.player)
    draw("PLAYER", groups.player)
    draw("PLAYER", groups.player)

    fs = fs .. "scroll_container_end[]"

    ----------------------------------------------------
    -- Scrollbar
    ----------------------------------------------------

    fs = fs
      .. "scrollbaroptions[max=1000;smallstep=10;largestep=10]"
      .. "scrollbar[19.0,0.8;0.5,9.0;vertical;ranktops_scroll;0]"

    ----------------------------------------------------
    -- BACK button
    ----------------------------------------------------
    fs = fs ..
      "button[8.0,10.2;4.0,0.8;back;" .. core.formspec_escape(S("BACK")) .. "]"

    core.show_formspec(
      player:get_player_name(),
      "ac:ranktops",
      fs
    )

    return
  end

  ----------------------------------------------------
  -- PANEL GUARDIAN PROGRESS
  ----------------------------------------------------
  if fields.guardian then
    local list = {}
    for name, data in pairs(persistent) do
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

        ------------------------------------------------
        -- AUTO ASCENSO
        ------------------------------------------------
        if hours_ok and activity_ok and join_ok and age_ok and days_played >= 60 and rank ~= "guardian" then
          core.chat_send_all("💚 " .. S("@1 promoted to Guardian!", name) )
          core.run_server_chatcommand("rank", name .. " guardian")
        end

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
      .. "label[0.3,0.5;" .. core.formspec_escape(S("Guardian Progress Panel")) .. "]"

      -- Header background
      .. "box[0.3,1.0;19.4,0.8;#00000088]"

      -- Header
      .. "label[0.5,1.5;" .. core.formspec_escape(S("Player")) .. "]"
      .. "label[6.0,1.5;" .. core.formspec_escape(S("Hours")) .. "]"
      .. "label[8.3,1.5;" .. core.formspec_escape(S("Activity %")) .. "]"
      .. "label[10.9,1.5;" .. core.formspec_escape(S("Join %")) .. "]"
      .. "label[14.1,1.5;" .. core.formspec_escape(S("Days")) .. "]"
      .. "label[16.3,1.5;" .. core.formspec_escape(S("Status")) .. "]"

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
        .. "label[0.2," .. y .. ";" .. core.formspec_escape(p.name) .. "]"

        -- Hours
        .. "label[5.7," .. y .. ";" .. core.formspec_escape(math.floor(p.hours) .. "/90") .. "]"

        -- Activity
        .. "label[8.2," .. y .. ";" .. core.formspec_escape(math.floor(p.a) .. "%") .. "]"

        -- Join Ratio
        .. "label[11.0," .. y .. ";" .. core.formspec_escape(math.floor(p.j) .. "%") .. "]"

        -- Days
        .. "label[13.8," .. y .. ";" .. core.formspec_escape(p.days) .. "]"

        -- Status
        .. "label[16.0," .. y .. ";" .. core.formspec_escape(status) .. "]"

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
      "button[8.0,10.2;4.0,0.8;back;" .. core.formspec_escape(S("BACK")) .. "]"

    core.show_formspec(player:get_player_name(), "ac:guardian", fs)

    return
  end
end)
