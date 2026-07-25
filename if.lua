--------------------------------------------------------
-- IF Active Players Panel v1.6 (Scroll + UI + Skins Fix)
--------------------------------------------------------

local session_times = {}
local player_activity = {}

--------------------------------------------------------
-- Session time + activity
--------------------------------------------------------
minetest.register_globalstep(function(dtime)
  for _, player in ipairs(minetest.get_connected_players()) do
    local name = player:get_player_name()

    if session_times[name] then
      session_times[name] = session_times[name] + dtime
    end

    local ctrl = player:get_player_control()

    if ctrl.up or ctrl.down or ctrl.left or ctrl.right or ctrl.jump or ctrl.LMB or ctrl.RMB then
      player_activity[name] = 0
    else
      player_activity[name] = (player_activity[name] or 0) + dtime
    end
  end
end)

minetest.register_on_joinplayer(function(player)
  local pname = player:get_player_name()
  session_times[pname] = 0
  player_activity[pname] = 0
end)

minetest.register_on_leaveplayer(function(player)
  local pname = player:get_player_name()
  session_times[pname] = nil
  player_activity[pname] = nil
end)

--------------------------------------------------------
-- AFK status
--------------------------------------------------------
local function get_status(name)
  if (player_activity[name] or 0) > 80 then
    return minetest.colorize("#ff5555","AFK")
  else
    return minetest.colorize("#55ff55","Active")
  end
end

--------------------------------------------------------
-- Rank display
--------------------------------------------------------
local function get_rank_display(name)
  if not ranks or not ranks.get_rank then
    return name
  end

  local rank = ranks.get_rank(name) or "player"
  local def = ranks.get_def(rank)

  if def and def.prefix then
    local colour = def.colour or "#ffffff"
    return minetest.colorize( colour, "["..def.prefix:upper().."] " ) .. name
  end

  return name
end

--------------------------------------------------------
-- Server time
--------------------------------------------------------
local function get_server_time()
  local time = minetest.get_timeofday()*24
  local hour = math.floor(time)
  local minute = math.floor((time-hour)*60)
  return string.format("%02d:%02d",hour,minute)
end

--------------------------------------------------------
-- World age
--------------------------------------------------------
local function get_world_age()
  local total = minetest.get_gametime()
  local days = math.floor(total/86400)
  local years = math.floor(days/365)
  return days, years
end

--------------------------------------------------------
-- Command /if
--------------------------------------------------------
minetest.register_chatcommand("if", {
  func = function(name)

    ----------------------------------------------------
    -- Global time
    ----------------------------------------------------
    local server_time = get_server_time()
    local days, years = get_world_age()

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
      .."label[9.5,0.3;Time: "..server_time.."]"
      .."label[9.5,0.8;Day: "..days.."]"
      .."label[9.5,1.3;Year: "..years.."]"

      ------------------------------------------------
      -- Fondo lista
      ------------------------------------------------
      .."box[0.3,2.0;12.4,6.7;#00000066]"

      ------------------------------------------------
      -- Scroll container
      ------------------------------------------------
      .."scroll_container[0.4,2.2;12.2,6.3;scroll;vertical]"

    ----------------------------------------------------
    -- Player list
    ----------------------------------------------------
    local online = {}

    for pname,time in pairs(session_times) do
      if minetest.get_player_by_name(pname) then
        table.insert(online,{ name=pname, time=time })
      end
    end

    table.sort(online,function(a,b)
      return a.time > b.time
    end)

    ----------------------------------------------------
    -- Draw list
    ----------------------------------------------------
    local y = 0.2

    for _,p in ipairs(online) do
      local minutes = math.floor(p.time/60)
      local seconds = math.floor(p.time%60)
      local player_obj = minetest.get_player_by_name(p.name)

      ------------------------------------------------
      -- Skin FIX (no aplastada)
      ------------------------------------------------
      local head_texture = "character.png"

      if player_obj and skins and skins.get_player_skin then
        local skin_obj = skins.get_player_skin(player_obj)

        if skin_obj then
          head_texture = (skin_obj:get_preview() or head_texture) .. "^[resize:32x32"
        end
      end

      ------------------------------------------------
      -- Name + rank
      ------------------------------------------------
      local display_name = get_rank_display(p.name)

      ------------------------------------------------
      -- Status
      ------------------------------------------------
      local status = get_status(p.name)

      ------------------------------------------------
      -- Row draw
      ------------------------------------------------
      formspec = formspec
        ..string.format(
          "image[0.3,%.2f;0.8,0.8;%s]",
          y,
          head_texture
        )
        ..string.format(
          "label[1.3,%.2f;%s]",
          y+0.1,
          minetest.formspec_escape(
            display_name
          )
        )
        ..string.format(
          "label[7.0,%.2f;%dm %ds]",
          y+0.1,
          minutes,
          seconds
        )
        ..string.format(
          "label[9.5,%.2f;%s]",
          y+0.1,
          status
        )

      y = y + 0.9
    end

    ----------------------------------------------------
    -- Close scroll
    ----------------------------------------------------
    formspec = formspec .. "scroll_container_end[]"

    ----------------------------------------------------
    -- Show
    ----------------------------------------------------
    minetest.show_formspec(name, "if:panel", formspec )

    return true
  end
})