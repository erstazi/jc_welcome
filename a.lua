-- a.lua
local S = core.get_translator(core.get_current_modname())
local modpath = core.get_modpath(core.get_current_modname())

local pending_rules = {}
local frozen_players = {}

local timeout_seconds = 120
local penalty_seconds = 120
local penalty_minutes = penalty_seconds / 60

local rules_table = {
  [1] = S("Do NOT steal from other players."),
  [2] = S("Do NOT place lava or water on other players' areas."),
  [3] = S("Do NOT build on someone else's claimed area."),
  [4] = S("Do NOT steal protected areas or land."),
  [5] = S("Do NOT use modified or hacked clients."),
  [6] = S("No insults, swearing, or offensive language."),
  [7] = S("Do NOT advertise other servers."),
  [8] = S("Respect all players, especially Moderators and Staff."),
  [9] = S("Do NOT ask for privileges or ranks (Moderator, Staff, Guardian)."),
  [10] = S("Moderator and Staff ranks are only given when applications are officially opened."),
  [11] = S("Do NOT place lava or water at spawn."),
  [12] = S("Dating or looking for relationships inside the server is strictly forbidden."),
  [13] = S("Do NOT provoke fights or unnecessary arguments."),
  [14] = S("Do NOT harass or annoy other players repeatedly."),
  [15] = S("Do NOT spam in chat."),
  [16] = S("Do NOT write everything in ALL CAPS."),
  [17] = S("Do NOT spread false information to confuse others."),
  [18] = S("Do NOT build inappropriate or offensive structures."),
  [19] = S("Do NOT destroy abandoned constructions without staff permission."),
  [20] = S("Do NOT make traps that harm other players unfairly."),
  [21] = S("Do NOT create lag machines or mechanisms that affect server performance."),
  [22] = S("Keep spawn and claimed areas tidy and aesthetically organized."),
  [23] = S("Do NOT exploit server bugs."),
  [24] = S("Do NOT duplicate items under any circumstances."),
  [25] = S("Report bugs to Staff instead of exploiting them."),
  [26] = S("Do NOT scam other players in trades."),
  [27] = S("Owner decisions are final."),
  [28] = S("Do NOT publicly argue against punishments in chat."),
  [29] = S("Report Staff issues to the Owner."),
  [30] = S("Impersonating Staff will result in immediate punishment."),
  [31] = S("Do NOT share your account with others."),
  [32] = S("Do NOT ask for others' passwords."),
  [33] = S("Each player is responsible for their account security."),
  [34] = S("Keep a friendly and safe environment for everyone."),
  [35] = S("Do NOT post +18 or inappropriate content."),
  [36] = S("Romantic or inappropriate roleplay is forbidden."),
}

local rules_parts = {}
for i = 1, #rules_table do
  rules_parts[i] = i .. ") " .. rules_table[i]
end

local rules_text =
  "=== JUST-CRAFT " .. S("SERVER RULES") .. " ===\n\n" ..
  table.concat(rules_parts, "\n")

local mandatory_rules_text =
  rules_text ..
  "\n\n" ..
  S("You have @1 seconds to accept.", timeout_seconds) ..
  "\n" ..
  S("If you close this window without accepting, then you will have a @1 minute penalty.", penalty_minutes)
---

-- SISTEMA DE PENALIZACIÓN PERSISTENTE

local penalty_file = core.get_worldpath() .. "/rule_penalties.txt"

local function load_penalties()
  local t = {}
  local file = io.open(penalty_file, "r")
  if file then
    for line in file:lines() do
      local name, time = line:match("([^|]+)|([^|]+)")
      if name and time then
        t[name] = tonumber(time)
      end
    end
    file:close()
  end
  return t
end

local function save_penalties(t)
  local file = io.open(penalty_file, "w")
  if file then
    for name, time in pairs(t) do
      file:write(name .. "|" .. time .. "\n")
    end
    file:close()
  end
end

local temp_penalties = load_penalties()

-- Freeze system

core.register_globalstep(function()
  for name,_ in pairs(frozen_players) do
    local player = core.get_player_by_name(name)
    if player then
      player:set_physics_override({
        speed = 0,
        jump = 0
      })
    end
  end
end)



-- Block chat
core.register_on_chat_message(function(name)
  if frozen_players[name] then
    return true
  end
end)


-- Block login if penalized

core.register_on_prejoinplayer(function(name)
  local expire = temp_penalties[name]
  if expire then
    if os.time() < expire then
      local remaining = expire - os.time()
      return S("You are temporarily penalized. Wait @1 seconds.", remaining)
    else
      temp_penalties[name] = nil
      save_penalties(temp_penalties)
    end
  end
end)



-- Command
core.register_chatcommand("rule", {
  params = "<player>",
  description = S("Force player to accept rules"),
  privs = { ban = true },

  func = function(name, param)
    if param == "" then
      return false, S("Usage: /rule <player>")
    end

    local target = core.get_player_by_name(param)
    if not target then
      return false, S("Player not found.")
    end

    pending_rules[param] = {
      moderator = name,
      time = os.time()
    }

    frozen_players[param] = true

    local formspec =
      "formspec_version[4]" ..
      "size[10,8]" ..
      "label[0.5,0.3;" .. core.formspec_escape(S("SERVER RULES - MANDATORY")) .. "]" ..
      "textarea[0.5,1;9,5.5;rules;;" ..
      core.formspec_escape(mandatory_rules_text) ..
      "]" ..
      "button[3.5,6.8;3,1;accept;" .. core.formspec_escape(S("I Accept")) .. "]"

    core.show_formspec(param, "rules:confirm", formspec)

    return true, S("Rules sent to @1", param)
  end
})


-- Form handler

core.register_on_player_receive_fields(function(player, formname, fields)
  if formname ~= "rules:confirm" then return end

  local name = player:get_player_name()

  -- Closed without accepting
  if fields.quit and pending_rules[name] then
    temp_penalties[name] = os.time() + penalty_seconds
    save_penalties(temp_penalties)
    core.kick_player(name, S("You closed the rules window. You are penalized for @1 minutes.", penalty_minutes) )
    pending_rules[name] = nil
    frozen_players[name] = nil
    return
  end

  -- Accepted
  if fields.accept and pending_rules[name] then
    local mod_name = pending_rules[name].moderator
    frozen_players[name] = nil
    player:set_physics_override({ speed = 1, jump = 1 })
    core.close_formspec(name, "rules:confirm")

    core.chat_send_player(mod_name, S("@1 accepted the rules.", name) )
    pending_rules[name] = nil
  end
end)


---

-- Timeout auto kick

core.register_globalstep(function()
  for name,data in pairs(pending_rules) do
    if os.time() - data.time > timeout_seconds then
      temp_penalties[name] = os.time() + penalty_seconds
      save_penalties(temp_penalties)
      core.kick_player(name, S("You did not accept the rules. You are penalized for @1 minutes.", penalty_minutes) )

      pending_rules[name] = nil
      frozen_players[name] = nil
    end
  end
end)

local storage = core.get_mod_storage()

-- =========================
-- /sanction
-- =========================

core.register_chatcommand("sanction", {
  params = "[player reason time type]",
  description = S("View panel or register sanction report"),
  privs = {ban = true},
  func = function(name, param)
    -- Si no hay parámetros → abrir panel
    if param == "" then
      local formspec =
        "formspec_version[4]" ..
        "size[12,10]" ..

        "label[0.5,0.5;=== JUST-CRAFT SANCTION SYSTEM ===]" ..

        "textarea[0.5,1.2;11,8;;SANCTION CATEGORIES:;" ..

        "WARNING (Rules: 13,14,15,16,17,28)\n" ..
        "- Minor arguments\n" ..
        "- Spam / CAPS\n" ..
        "- Public punishment discussion\n\n" ..

        "MUTE (Rules: 6,12,35,36)\n" ..
        "- Insults / Offensive language\n" ..
        "- Dating / +18 content\n\n" ..

        "REMOVE PRIVS (Rules: 9,30)\n" ..
        "- Asking for ranks\n" ..
        "- Impersonating Staff\n\n" ..

        "TEMP BAN (Rules: 1,2,3,4,19,20,26)\n" ..
        "- Stealing / Griefing\n" ..
        "- Traps / Scams\n\n" ..

        "PERMANENT BAN (Rules: 5,23,24)\n" ..
        "- Hacked client\n" ..
        "- Exploits / Duplication\n" ..
        "]"

      core.show_formspec(name,       "justcraft:sanction_panel", formspec)
      return true
    end

    -- Si tiene parámetros → registrar informe
    local args = param:split(" ")

    if #args < 4 then
        return false, S("Usage: /sanction <player> <reason> <time> <type>")
    end

    local target = args[1]
    local reason = args[2]
    local time = args[3]
    local stype = args[4]

    local date = os.date("%Y-%m-%d %H:%M:%S")

    local entry = "[" .. date .. "] Staff: " .. name ..
                  " | Player: " .. target ..
                  " | Type: " .. stype ..
                  " | Time: " .. time ..
                  " | Reason: " .. reason

    local key = "history_global"
    local data = storage:get_string(key)

    local history = {}

    if data ~= "" then
      history = core.deserialize(data) or {}
    end

    table.insert(history, entry)

    storage:set_string("history_global", core.serialize(history))

    return true, S("Sanction report registered (no punishment applied).")
  end,
})

-- =========================
-- /h (historial)
-- =========================

core.register_chatcommand("h", {
  description = S("View global sanction history"),
  privs = {ban = true},
  func = function(name)
    local data = storage:get_string("history_global")

    if data == "" then
      return false, S("No sanction history found.")
    end

    local history = core.deserialize(data) or {}

    local text = table.concat(history, "\n")

    core.show_formspec(name, "justcraft:history",
      "formspec_version[4]" ..
      "size[12,9]" ..
      "textarea[0.5,0.5;11,8;;" .. core.formspec_escape(S("Global Sanction History")) .. ":;" ..
      core.formspec_escape(text) .. "]"
    )

    return true
  end,
})

-----Rules
core.register_chatcommand("rules", {
  description = S("Show rules"),
  func = function(name)
    local formspec =
      "formspec_version[4]" ..
      "size[10,8]" ..
      "bgcolor[#00000000;true]" ..
      "textarea[0.5,0.5;9,6;rules;;" .. core.formspec_escape(rules_text) .. "]" ..
      "button_exit[3.5,7;3,1;exit;" .. core.formspec_escape(S("Close")) .. "]"

    core.show_formspec(name, "rules:show", formspec)
  end
})


core.register_on_joinplayer(function(player)
  local name = player:get_player_name()
  local message = S("Use /rules to view the server rules")
  core.chat_send_player(name, message)
end)
