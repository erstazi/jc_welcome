
local pending_rules = {}
local frozen_players = {}

local timeout_seconds = 120
local penalty_seconds = 120

local rules_text =
  "=== JUST-CRAFT SERVER RULES ===\n\n" ..
  "1) Do NOT steal from other players.\n" ..
  "2) Do NOT place lava or water on other players' areas.\n" ..
  "3) Do NOT build on someone else's claimed area.\n" ..
  "4) Do NOT steal protected areas or land.\n" ..
  "5) Do NOT use modified or hacked clients.\n" ..
  "6) No insults, swearing, or offensive language.\n" ..
  "7) Do NOT advertise other servers.\n" ..
  "8) Respect all players, especially Moderators and Staff.\n" ..
  "9) Do NOT ask for privileges or ranks (Moderator, Staff, Guardian).\n" ..
  "10) Moderator and Staff ranks are only given when applications are officially opened.\n" ..
  "11) Do NOT place lava or water at spawn.\n" ..
  "12) Dating or looking for relationships inside the server is strictly forbidden.\n" ..
  "13) Do NOT provoke fights or unnecessary arguments.\n" ..
  "14) Do NOT harass or annoy other players repeatedly.\n" ..
  "15) Do NOT spam in chat.\n" ..
  "16) Do NOT write everything in ALL CAPS.\n" ..
  "17) Do NOT spread false information to confuse others.\n" ..
  "18) Do NOT build inappropriate or offensive structures.\n" ..
  "19) Do NOT destroy abandoned constructions without staff permission.\n" ..
  "20) Do NOT make traps that harm other players unfairly.\n" ..
  "21) Do NOT create lag machines or mechanisms that affect server performance.\n" ..
  "22) Keep spawn and claimed areas tidy and aesthetically organized.\n" ..
  "23) Do NOT exploit server bugs.\n" ..
  "24) Do NOT duplicate items under any circumstances.\n" ..
  "25) Report bugs to Staff instead of exploiting them.\n" ..
  "26) Do NOT scam other players in trades.\n" ..
  "27) Owner decisions are final.\n" ..
  "28) Do NOT publicly argue against punishments in chat.\n" ..
  "29) Report Staff issues to the Owner.\n" ..
  "30) Impersonating Staff will result in immediate punishment.\n" ..
  "31) Do NOT share your account with others.\n" ..
  "32) Do NOT ask for others' passwords.\n" ..
  "33) Each player is responsible for their account security.\n" ..
  "34) Keep a friendly and safe environment for everyone.\n" ..
  "35) Do NOT post +18 or inappropriate content.\n" ..
  "36) Romantic or inappropriate roleplay is forbidden."

local mandatory_rules_text =
  rules_text ..
  "\n\nYou have 120 seconds to accept.\n" ..
  "Closing this window = 2 minute penalty."
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
      return "You are temporarily penalized. Wait " .. remaining .. " seconds."
    else
      temp_penalties[name] = nil
      save_penalties(temp_penalties)
    end
  end
end)



-- Command
core.register_chatcommand("rule", {
  params = "<player>",
  description = "Force player to accept rules",
  privs = { ban = true },

  func = function(name, param)
    if param == "" then
      return false, "Usage: /rule <player>"
    end

    local target = core.get_player_by_name(param)
    if not target then
      return false, "Player not found."
    end

    pending_rules[param] = {
      moderator = name,
      time = os.time()
    }

    frozen_players[param] = true

    local formspec =
      "formspec_version[4]" ..
      "size[10,8]" ..
      "label[0.5,0.3;SERVER RULES - MANDATORY]" ..
      "textarea[0.5,1;9,5.5;rules;;" ..
      core.formspec_escape(mandatory_rules_text) ..
      "]" ..
      "button[3.5,6.8;3,1;accept;I ACCEPT]"

    core.show_formspec(param, "rules:confirm", formspec)

    return true, "Rules sent to " .. param
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
    core.kick_player(name, "You closed the rules window. Penalized 2 minutes.")
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

    core.chat_send_player(mod_name, name .. " accepted the rules.")
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
      core.kick_player(name, "You did not accept the rules. Penalized 2 minutes.")

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
  description = "View panel OR register sanction report",
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
        return false, "Usage: /sanction <player> <reason> <time> <type>"
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

    return true, "Sanction report registered (no punishment applied)."
  end,
})

-- =========================
-- /h (historial)
-- =========================

core.register_chatcommand("h", {
  description = "View global sanction history",
  privs = {ban = true},
  func = function(name)
    local data = storage:get_string("history_global")

    if data == "" then
      return false, "No sanction history found."
    end

    local history = core.deserialize(data) or {}

    local text = table.concat(history, "\n")

    core.show_formspec(name, "justcraft:history",
      "formspec_version[4]" ..
      "size[12,9]" ..
      "textarea[0.5,0.5;11,8;;Global Sanction History:;" ..
      core.formspec_escape(text) .. "]"
    )

    return true
  end,
})

-----Rules
core.register_chatcommand("rules", {
  description = "Show rules",
  func = function(name)
    local formspec =
      "formspec_version[4]" ..
      "size[10,8]" ..
      "bgcolor[#00000000;true]" ..

      -- TEXTAREA CORREGIDO
      "textarea[0.5,0.5;9,6;rules;;" ..
      core.formspec_escape(rules_text) ..
      "]" ..

      "button_exit[3.5,7;3,1;exit;Close/Cerrar]"

    core.show_formspec(name, "rules:show", formspec)
  end
})


core.register_on_joinplayer(function(player)
  local name = player:get_player_name()
  local message = "Use /rules to view the server rules"
  -- lo manda 1 vez
  core.chat_send_player(name, message)
  -- lo vuelve a mandar cada 20s (3 veces total = 1 minuto aprox)
end)
