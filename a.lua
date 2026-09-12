-- a.lua
local S = core.get_translator(core.get_current_modname())
local modpath = core.get_modpath(core.get_current_modname())

local storage = core.get_mod_storage()

local pending_rules = {}
local frozen_players = {}

local timeout_seconds = 120
local penalty_seconds = 120
local penalty_minutes = penalty_seconds / 60

jc_welcome = jc_welcome or {}

-------------------------------------------------------------------------------
-- Raw server rules
--
-- These are NOT translated. This allows other mods, such as jc_special
-- website.lua, to access the original English text.
-------------------------------------------------------------------------------
jc_welcome.rules_raw = {
  [1] = "Do NOT steal from other players.",
  [2] = "Do NOT place lava or water on other players' areas.",
  [3] = "Do NOT build on someone else's claimed area.",
  [4] = "Do NOT steal protected areas or land.",
  [5] = "Do NOT use modified or hacked clients.",
  [6] = "No insults, swearing, or offensive language.",
  [7] = "Do NOT advertise other servers.",
  [8] = "Respect all players, especially Moderators and Staff.",
  [9] = "Do NOT ask for privileges or ranks (Moderator, Staff, Guardian).",
  [10] = "Moderator and Staff ranks are only given when applications are officially opened.",
  [11] = "Do NOT place lava or water at spawn.",
  [12] = "Dating or looking for relationships inside the server is strictly forbidden.",
  [13] = "Do NOT provoke fights or unnecessary arguments.",
  [14] = "Do NOT harass or annoy other players repeatedly.",
  [15] = "Do NOT spam in chat.",
  [16] = "Do NOT write everything in ALL CAPS.",
  [17] = "Do NOT spread false information to confuse others.",
  [18] = "Do NOT build inappropriate or offensive structures.",
  [19] = "Do NOT destroy abandoned constructions without staff permission.",
  [20] = "Do NOT make traps that harm other players unfairly.",
  [21] = "Do NOT create lag machines or mechanisms that affect server performance.",
  [22] = "Keep spawn and claimed areas tidy and aesthetically organized.",
  [23] = "Do NOT exploit server bugs.",
  [24] = "Do NOT duplicate items under any circumstances.",
  [25] = "Report bugs to Staff instead of exploiting them.",
  [26] = "Do NOT scam other players in trades.",
  [27] = "Owner decisions are final.",
  [28] = "Do NOT publicly argue against punishments in chat.",
  [29] = "Report Staff issues to the Owner.",
  [30] = "Impersonating Staff will result in immediate punishment.",
  [31] = "Do NOT share your account with others.",
  [32] = "Do NOT ask for others' passwords.",
  [33] = "Each player is responsible for their account security.",
  [34] = "Do NOT post +18 or inappropriate content.",
  [35] = "Keep a friendly and safe environment for everyone.",
  [36] = "Romantic or inappropriate roleplay is forbidden.",
}

-------------------------------------------------------------------------------
-- Raw server rules in Spanish
--
-- These are NOT translated. This allows other mods, such as jc_special
-- website.lua, to access the original Spanish text.
-------------------------------------------------------------------------------
jc_welcome.rules_es_raw = {
  [1] = "No robes a otros jugadores.",
  [2] = "No coloques lava ni agua en las zonas de otros jugadores.",
  [3] = "No construyas en la zona reclamada de otra persona.",
  [4] = "No robes zonas o terrenos protegidos.",
  [5] = "No uses clientes modificados o hackeados.",
  [6] = "No se permiten insultos, palabrotas ni lenguaje ofensivo.",
  [7] = "No hagas publicidad de otros servidores.",
  [8] = "Respeta a todos los jugadores, especialmente a los Moderadores y al Staff.",
  [9] = "No pidas privilegios ni rangos (Moderador, Staff, Guardián).",
  [10] = "Los rangos de Moderador y Staff solo se otorgan cuando las solicitudes se abren oficialmente.",
  [11] = "No coloques lava ni agua en el spawn.",
  [12] = "Está estrictamente prohibido tener citas o buscar relaciones dentro del servidor.",
  [13] = "No provoques peleas ni discusiones innecesarias.",
  [14] = "No acoses ni molestes repetidamente a otros jugadores.",
  [15] = "No hagas spam en el chat.",
  [16] = "No escribas todo en MAYÚSCULAS.",
  [17] = "No difundas información falsa para confundir a los demás.",
  [18] = "No construyas estructuras inapropiadas u ofensivas.",
  [19] = "No destruyas construcciones abandonadas sin permiso del Staff.",
  [20] = "No hagas trampas que perjudiquen injustamente a otros jugadores.",
  [21] = "No crees máquinas de lag ni mecanismos que afecten al rendimiento del servidor.",
  [22] = "Mantén el spawn y las zonas reclamadas limpios y organizados estéticamente.",
  [23] = "No aproveches los errores (bugs) del servidor.",
  [24] = "No dupliques objetos bajo ninguna circunstancia.",
  [25] = "Informa de los errores al Staff en lugar de aprovecharte de ellos.",
  [26] = "No estafes a otros jugadores en los intercambios.",
  [27] = "Las decisiones del propietario son definitivas.",
  [28] = "No discutas públicamente las sanciones en el chat.",
  [29] = "Informa de los problemas relacionados con el Staff al propietario.",
  [30] = "Hacerse pasar por un miembro del Staff resultará en un castigo inmediato.",
  [31] = "No compartas tu cuenta con otras personas.",
  [32] = "No pidas las contraseñas de otras personas.",
  [33] = "Cada jugador es responsable de la seguridad de su cuenta.",
  [34] = "No publiques contenido +18 o inapropiado.",
  [35] = "Mantén un ambiente amistoso y seguro para todos.",
  [36] = "El juego de rol romántico o inapropiado está prohibido.",
}

-------------------------------------------------------------------------------
-- Translated server rules
-------------------------------------------------------------------------------
jc_welcome.rules_table = {}

for i, rule in ipairs(jc_welcome.rules_raw) do
  jc_welcome.rules_table[i] = S(rule)
end

local rules_parts = {}
for i = 1, #jc_welcome.rules_table do
  rules_parts[i] = i .. ") " .. jc_welcome.rules_table[i]
end

local rules_text =
  "=== " .. S("@1 SERVER RULES", "JUST-CRAFT") .. " ===\n\n" ..
  table.concat(rules_parts, "\n")

local mandatory_rules_text =
  rules_text ..
  "\n\n" ..
  S("You have @1 seconds to accept.", timeout_seconds) ..
  "\n" ..
  S("If you close this window without accepting, then you will have a @1 minute penalty.", penalty_minutes) ..
  ""

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
      "textarea[0.5,1;9,5.5;rules;;" .. core.formspec_escape(mandatory_rules_text) .. "]" ..
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
  local message = S("Use @1 to view the server rules", core.colorize("#FFFF00", "/rules"))
  core.chat_send_player(name, message)
end)
