-- ac_controller.lua
local S = core.get_translator(core.get_current_modname())

local active_players = jc_ac_model.active_players
local persistent = jc_ac_model.persistent

--------------------------------------------------------
-- Join
--------------------------------------------------------
core.register_on_joinplayer(function(player)
  local name = player:get_player_name()

  if not persistent[name] then
    persistent[name] = {
      first_join = os.time(),
      total_hours = 0,
      sessions = 0,
      afk_time = 0
    }

    jc_ac_model.save_player_list()
  end

  persistent[name].sessions =
    persistent[name].sessions + 1

  jc_ac_model.save_player_data(name, persistent[name])

  active_players[name] = {
    session_time = 0,
    last_pos = player:get_pos(),
    afk_timer = 0
  }
end)

--------------------------------------------------------
-- Leave
--------------------------------------------------------
core.register_on_leaveplayer(function(player)
  local name = player:get_player_name()

  if active_players[name] and persistent[name] then
    local hours = active_players[name].session_time / 3600

    persistent[name].total_hours =
      (persistent[name].total_hours or 0) + hours

    persistent[name].afk_time =
      (persistent[name].afk_time or 0) + active_players[name].afk_timer

    jc_ac_model.save_player_data(name, persistent[name])

    active_players[name] = nil
  end
end)

--------------------------------------------------------
-- Globalstep
--------------------------------------------------------
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

--------------------------------------------------------
-- /ac
--------------------------------------------------------
core.register_chatcommand("ac", {
  description = S("Active Players Panel v3"),

  func = function(name)
    if not core.check_player_privs(name, {server=true}) then
      return false, S("No permission.")
    end

    jc_ac_view.show_panel(name)

    return true
  end
})

--------------------------------------------------------
-- EVENTOS BOTONES PANEL AC (UNIFICADO)
-- EVENTS BUTTONS AC PANEL (UNIFIED)
--------------------------------------------------------
core.register_on_player_receive_fields(function(player, formname, fields)
  local name = player:get_player_name()

  ----------------------------------------------------
  -- BACK FROM TOP PLAYERS
  ----------------------------------------------------
  if formname == "ac:top_players" then
    if fields.back then
      jc_ac_view.show_panel(name)
    end

    return
  end

  ----------------------------------------------------
  -- BACK FROM GUARDIAN
  ----------------------------------------------------
  if formname == "ac:guardian" then
    if fields.back then
      jc_ac_view.show_panel(name)
    end

    return
  end

  if formname ~= "ac:panel" then return end
  ----------------------------------------------------
  -- PANEL TOP PLAYERS
  ----------------------------------------------------
  if fields.top_players then
    jc_ac_view.show_top_players(player)

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
        -- Total days played
        local join_day = math.floor(data.first_join / 86400)
        local today = math.floor(os.time() / 86400)
        local days_played = math.min(today - join_day, data.sessions)

        -- Antigüedad mínima de la cuenta (3 meses = 90 días)
        -- Minimum account age (3 months = 90 days)
        local account_age_days = today - join_day
        local age_ok = account_age_days >= 90

        ------------------------------------------------
        -- PROGRESOS
        -- PROGRESS
        ------------------------------------------------
        local hours_prog = math.min(100, (total_hours / 90) * 100)

        local avg_day = total_hours / days

        local activity_prog = math.min(100, (avg_day / 12) * 100)

        local join_ratio = sessions / math.max(1,total_hours)

        local join_prog = math.min(100, (0.5 / join_ratio) * 100)

        ------------------------------------------------
        -- CONDICIONES
        -- CONDITIONS
        ------------------------------------------------
        local hours_ok = total_hours >= 90

        local activity_ok = avg_day >= 12

        local join_ok = join_ratio <= 0.5

        ------------------------------------------------
        -- AUTO ASCENSO
        -- AUTOMATIC ASSIGNING RANK
        ------------------------------------------------
        if hours_ok and activity_ok and join_ok and age_ok and days_played >= 60 and rank ~= "guardian" then
          core.chat_send_all("💚 " .. S("@1 promoted to Guardian!", name) )
          core.run_server_chatcommand("rank", name .. " guardian")
        end

        table.insert(list, {name = name, hours = total_hours, h = hours_prog, a = activity_prog, j = join_prog, ok = hours_ok and activity_ok and join_ok, days = days_played })
      end
    end

    jc_ac_view.show_guardian(player)

    return
  end
end)