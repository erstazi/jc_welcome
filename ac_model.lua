-- ac_model.lua
local storage = core.get_mod_storage()

jc_ac_model = {}

jc_ac_model.active_players = {}
jc_ac_model.persistent = {}

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
  storage:set_string( get_storage_key(name), core.serialize(data) )
end

local function save_player_list()
  if type(jc_ac_model.persistent) ~= "table" then
    jc_ac_model.persistent = {}
  end

  local players = {}

  for name in pairs(jc_ac_model.persistent) do
    table.insert(players, name)
  end

  table.sort(players)

  storage:set_string("players", core.serialize(players) )
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

  storage:set_string("players", core.serialize(players) )

  -- Verify that ModStorage now contains the data.
  local verify = storage:get_string("players")

  if verify == "" then
    core.log("error", "[jc_welcome] ModStorage verification failed. Original ac_data.mt was NOT changed." )
    return false
  end

  -- Keep a backup of the original file.
  local renamed = os.rename(old_file, migrated_file)

  if renamed then
    core.log("action", "[jc_welcome] Migration complete: " .. count .. " players moved to ModStorage." )
    core.log("action", "[jc_welcome] Original data saved as ac_data.mt.migrated.")
  else
    core.log("warning", "[jc_welcome] Data migrated successfully, but ac_data.mt could not be renamed.")
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

jc_ac_model.persistent = load_data()

if type(jc_ac_model.persistent) ~= "table" then
  jc_ac_model.persistent = {}
end

-- Actual server age
function jc_ac_model.get_server_age_days()
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

function jc_ac_model.save_player_data(name, data)
  save_player_data(name, data)
end

function jc_ac_model.save_player_list()
  save_player_list()
end

-- Rank display
function jc_ac_model.get_rank_display(name)
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

-- Global Statistics
function jc_ac_model.get_global_stats()
  local total_players = 0
  local total_hours = 0
  local most_active = "None"
  local max_hours = 0

  for name, data in pairs(jc_ac_model.persistent) do

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

-- Get ranks from the ranks mod
local function get_rank(name)
  if ranks and ranks.get_rank then
    return ranks.get_rank(name) or "player"
  end
  return "player"
end

-- Top player results sorted by Rank (DATA)
function jc_ac_model.build_top_players()

  local groups = {
    owner = {},
    moderator = {},
    staff = {},
    guardian = {},
    builder = {},
    player = {}
  }

  for name, data in pairs(jc_ac_model.persistent) do
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