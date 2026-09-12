-- rules_controller.lua
local S = core.get_translator(core.get_current_modname())

local pending_rules = jc_rules_model.pending_rules
local frozen_players = jc_rules_model.frozen_players
local timeout_seconds = jc_rules_model.timeout_seconds
local penalty_seconds = jc_rules_model.penalty_seconds
local penalty_minutes = jc_rules_model.penalty_minutes
local temp_penalties = jc_rules_model.temp_penalties
local save_penalties = jc_rules_model.save_penalties

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

    jc_rules_view.show_confirm(param)

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

-- Rules
core.register_chatcommand("rules", {
  description = S("Show rules"),
  func = function(name)
    jc_rules_view.show_rules(name)
  end
})

core.register_on_joinplayer(function(player)
  local name = player:get_player_name()
  local message = S("Use @1 to view the server rules", core.colorize("#FFFF00", "/rules") )
  core.chat_send_player(name, message)
end)