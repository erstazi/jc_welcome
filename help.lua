-- help.lua

local S = core.get_translator(core.get_current_modname())
local modpath = core.get_modpath(core.get_current_modname())

core.register_chatcommand("guardian", {
  description = S("Shows Guardian rank requirements"),
  func = function(name)
    local text =
      "=== JUST-CRAFT RANK SYSTEM ===\n\n" ..

      "► HOW TO BECOME GUARDIAN:\n\n" ..

      "STEP 1:\n" ..
      "You MUST be Build10 first.\n" ..
      "(Only Build10 players are eligible)\n\n" ..

      "STEP 2: REQUIREMENTS\n" ..
      "- Minimum 90 total hours played.\n" ..
      "- Average of 12 hours per active day.\n" ..
      "- Good session ratio (no join/leave abuse).\n" ..
      "- Account must be at least 90 days old.\n" ..
      "- Must have played on at least 60 different days.\n\n" ..

      "STEP 3:\n" ..
      "Promotion to Guardian is AUTOMATIC\n" ..
      "when all requirements are met.\n\n" ..

      "► BUILD SYSTEM:\n" ..
      "Build ranks are earned through\n" ..
      "progress, activity and contribution."

    local formspec =
      "formspec_version[4]" ..
      "size[10,8]" ..
      "textarea[0.5,0.5;9,6.5;info;;" ..
      core.formspec_escape(text) ..
      "]" ..
      "button_exit[3.5,7.2;3,0.8;exit;" .. S("Close") .. "]"

    core.show_formspec(name, "welcome:help", formspec)

    return true
  end
})