--------------------------------------------------------
-- Active Players Panel (AC) v3.1 EXPANDED REAL+
-- Persistencia + Estadísticas + Historial + Rank Tops

local active_players = {}
local storage_file = minetest.get_worldpath() .. "/ac_data.mt"

-- Cargar datos guardados
local function load_data()
  local file = io.open(storage_file, "r")
  if not file then return {} end
  local data = minetest.deserialize(file:read("*all"))
  file:close()
  return data or {}
end

-- Guardar datos

local function save_data(data)
  local file = io.open(storage_file, "w")
  if file then
    file:write(minetest.serialize(data))
    file:close()
  end
end

local persistent = load_data()

-- Edad real server
local function get_server_age_days()
  local meta = io.open(minetest.get_worldpath() .. "/map_meta.txt", "r")

  if not meta then
    return 0
  end

  local content = meta:read("*all")
  meta:close()

  local created = content:match("created%s*=%s*(%d+)")

  if not created then return 0 end

  return math.floor( (os.time() - tonumber(created)) / 86400 )
end


-- Join
minetest.register_on_joinplayer(function(player)
  local name = player:get_player_name()

  if not persistent[name] then
    local pfile = io.open(minetest.get_worldpath() .. "/players/" .. name, "r")

    local first = os.time()

    if pfile then
      local content = pfile:read("*all")
      pfile:close()
      local t = content:match( "first_login%s*=%s*(%d+)" )
      if t then first = tonumber(t) end
    end

    persistent[name] = {
      first_join = first,
      total_hours = 0,
      sessions = 0,
      afk_time = 0
    }
  end

  persistent[name].sessions = persistent[name].sessions + 1

  active_players[name] = {
    session_time = 0,
    last_pos = player:get_pos(),
    afk_timer = 0
  }
end)


-- Leave

minetest.register_on_leaveplayer(function(player)
  local name = player:get_player_name()

  if active_players[name] then
    local hours = active_players[name].session_time / 3600
    persistent[name].total_hours = persistent[name].total_hours + hours
    persistent[name].afk_time = persistent[name].afk_time + active_players[name].afk_timer
    save_data(persistent)
    active_players[name] = nil
  end
end)


-- Globalstep

minetest.register_globalstep(function(dtime)
  for name, data in pairs(active_players) do
    data.session_time = data.session_time + dtime
    local player = minetest.get_player_by_name(name)
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
    return minetest.colorize(def.colour or "#fff", "[" .. def.prefix:upper() .. "] ") .. name
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


-- COMANDO /ac

minetest.register_chatcommand("ac", {
  description = "Active Players Panel v3",
  func = function(name)
    if not minetest.check_player_privs(name, {server=true}) then
      return false, "No permission."
    end

    local age = get_server_age_days()
    local stats = get_global_stats()

    local formspec =
        "formspec_version[4]"
        .. "size[15,10]"
        .. default.gui_bg
        .. default.gui_bg_img

        ------------------------------------------------
        -- Header
        ------------------------------------------------
        .. "label[0.3,0.2;Active Players Panel]"
        .. "label[11,0.2;Server Age: "
        .. age .. " days]"

        ------------------------------------------------
        -- Stats bar
        ------------------------------------------------
        .. "box[0.2,0.7;14.6,1.2;#00000088]"

        .. "label[0.4,0.9;Players: "
        .. stats.players .. "]"

        .. "label[3.0,0.9;Total Hours: "
        .. stats.hours .. "]"

        .. "label[7.0,0.9;Most Active: "
        .. stats.top .. "]"
       ------------------------------------------------
       -- Botones Footer
       ------------------------------------------------
        .. "button[8.5,9.2;3,0.8;ranktops;RANK TOPS]"
        .. "button[11.8,9.2;3,0.8;guardian;GUARDIAN]"
        ------------------------------------------------
        -- Fondo lista
        ------------------------------------------------
        .. "box[0.2,2.0;14.6,7.6;#00000066]"

        ------------------------------------------------
        -- Scroll más abajo
        ------------------------------------------------
        .. "scroll_container[0.3,2.2;14.4,7.2;scroll;vertical]"

    local y = 0.2

    for pname, sdata in pairs(active_players) do
      local pdata = persistent[pname]

      ------------------------------------------------
      -- Skin compacta
      ------------------------------------------------
      local skin = "character.png"

      local player_obj = minetest.get_player_by_name(pname)
      if player_obj and skins and skins.get_player_skin then
        local s = skins.get_player_skin(player_obj)
        if s then
          skin = (s:get_preview() or skin) .. "^[resize:28x28"
        end
      end

      ------------------------------------------------
      -- Fila compacta
      ------------------------------------------------
      formspec =
          formspec

          .. "image[0.3,"..y..";0.7,0.7;"
          .. skin .. "]"

          .. "label[1.1,"..y..";"
          .. minetest.formspec_escape(
              get_rank_display(pname)
          ) .. "]"

          .. "label[6.2,"..y..";S:"
          .. math.floor(
              sdata.session_time / 3600
          ) .. "h]"

          .. "label[8.0,"..y..";T:"
          .. math.floor(
              pdata.total_hours
          ) .. "h]"

          .. "label[9.8,"..y..";J:"
          .. pdata.sessions .. "]"

      y = y + 0.8
    end

    formspec = formspec .. "scroll_container_end[]"

    minetest.show_formspec( name, "ac:panel", formspec )

    return true
  end
})



--------------------------------------------------------
-- EVENTOS BOTONES PANEL AC (UNIFICADO)
--------------------------------------------------------
minetest.register_on_player_receive_fields(function(player, formname, fields)
  if formname ~= "ac:panel" then return end

    ----------------------------------------------------
    -- PANEL RANK TOPS
    ----------------------------------------------------
    if fields.ranktops then
      local groups = build_rank_tops()

      local fs =
        "formspec_version[4]"
        .. "size[14,10]"
        .. default.gui_bg
        .. default.gui_bg_img
        .. "label[0.3,0.3;Rank Tops Panel]"

      local y = 0

      fs = fs .. "scroll_container[0.3,0.8;12.8,8.8;scroll;vertical]"

      local function draw(title,list)
        if #list == 0 then return end
        fs = fs .. "label[0.2,"..y..";--- " .. title .. " ---]"
        y = y + 0.5
        for i=1, #list do
          local name = list[i][1]
          local data = list[i][2]

          fs = fs ..
            "label[0.5,"..y..";"
            .. i .. ". "
            .. name
            .. " - "
            .. math.floor(data.total_hours)
            .. "h]"

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

      fs = fs .. "scroll_container_end[]"

      local content_height = y

      fs = fs ..
        "scrollbar[13.2,0.8;0.5,8.8;vertical;scroll;"
        .. content_height .. "]"

      minetest.show_formspec(player:get_player_name(), "ac:ranktops", fs)
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
            minetest.chat_send_all("💚 " .. name .. " promoted to Guardian!")
            minetest.run_server_chatcommand("rank", name .. " guardian")
          end

          table.insert(list, {name = name, hours = total_hours, h = hours_prog, a = activity_prog, j = join_prog, ok =hours_ok and activity_ok and join_ok, days = days_played })
        end
      end

      ------------------------------------------------
      -- FORMSPEC
      ------------------------------------------------
      ------------------------------------------------
      -- FORMSPEC LOG NUMÉRICO
      ------------------------------------------------
      local fs =
        "formspec_version[4]"
        .. "size[14,10]"
        .. default.gui_bg
        .. default.gui_bg_img

        -- Título más abajo
        .. "label[0.3,0.5;Guardian Progress Panel]"

        -- Cabecera tabla
        .. "box[0.3,1.0;13.4,0.8;#00000088]"
        .. "label[0.5,1.2;Player]"
        .. "label[4.0,1.2;Hours]"
        .. "label[6.5,1.2;Activity %]"
        .. "label[9.5,1.2;Join Ratio]"
        .. "label[11.0,1.2;Days]"  -- NUEVO
        .. "label[12.0,1.2;Status]"


        -- Scroll más abajo
        .. "scroll_container[0.3,2.0;13.4,7.5;scroll;vertical]"

      local y = 0.2

      for _, p in ipairs(list) do
        local status = p.ok and "💚 READY" or "❌ NOT READY"

        fs = fs ..
          -- Fondo fila
          "box[0.0,"..y..";13.0,0.6;#11111166]"

          -- Nombre
          .. "label[0.2,"..y..";"..p.name.."]"

          -- Horas reales (no %)
          .. "label[4.0,"..y..";"
          .. math.floor(p.hours)
          .. " / 90]"

          -- Actividad %
          .. "label[6.5,"..y..";"
          .. math.floor(p.a)
          .. "%]"

          -- Join ratio %
          .. "label[9.5,"..y..";"
          .. math.floor(p.j)
          .. "%]"

          -- Días jugados
          .. "label[11.0,"..y..";"..p.days.."]"

          -- Estado
          .. "label[12.0,"..y..";"
          .. status .. "]"

        y = y + 0.7
    end

    fs = fs .. "scroll_container_end[]"

    minetest.show_formspec(player:get_player_name(), "ac:guardian", fs)
  end
end)
