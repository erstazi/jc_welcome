-- guardian_model.lua
local S = core.get_translator(core.get_current_modname())
local ESC = core.formspec_escape

jc_guardian_model = {}

function jc_guardian_model.get_guardian_text()
  return "" ..
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
    "progress, activity and contribution." ..
    ""
end