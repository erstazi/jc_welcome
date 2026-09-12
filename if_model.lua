-- if_model.lua
jc_if_model = {}

jc_if_model.session_times = {}
jc_if_model.player_activity = {}

function jc_if_model.get_status(name)
  if (jc_if_model.player_activity[name] or 0) > 80 then
    return core.colorize("#ff5555","AFK")
  else
    return core.colorize("#55ff55","Active")
  end
end

function jc_if_model.get_rank_display(name)
  if not ranks or not ranks.get_rank then
    return name
  end

  local rank = ranks.get_rank(name) or "player"
  local def = ranks.get_def(rank)

  if def and def.prefix then
    local colour = def.colour or "#ffffff"
    return core.colorize( colour, "["..def.prefix:upper().."] " ) .. name
  end

  return name
end

function jc_if_model.get_server_time()
  local time = core.get_timeofday()*24
  local hour = math.floor(time)
  local minute = math.floor((time-hour)*60)
  return string.format("%02d:%02d",hour,minute)
end

function jc_if_model.get_world_age()
  local total = core.get_gametime()
  local days = math.floor(total/86400)
  local years = math.floor(days/365)
  return days, years
end

function jc_if_model.get_online_players()
  local online = {}

  for pname,time in pairs(jc_if_model.session_times) do
    if core.get_player_by_name(pname) then
      table.insert(online,{ name=pname, time=time })
    end
  end

  table.sort(online,function(a,b)
    return a.time > b.time
  end)

  return online
end