-- rules_view.lua
local S = core.get_translator(core.get_current_modname())

jc_rules_view = {}

function jc_rules_view.show_confirm(name)
  local formspec =
    "formspec_version[4]" ..
    "size[10,8]" ..
    "label[0.5,0.3;" .. core.formspec_escape( S("SERVER RULES - MANDATORY") ) .. "]" ..
    "textarea[0.5,1;9,5.5;rules;;" .. core.formspec_escape(jc_rules_model.mandatory_rules_text) .. "]" ..
    "button[3.5,6.8;3,1;accept;" .. core.formspec_escape( S("I Accept") ) .. "]"

  core.show_formspec(name, "rules:confirm", formspec)
end

function jc_rules_view.show_rules(name)
  local formspec =
    "formspec_version[4]" ..
    "size[10,8]" ..
    "bgcolor[#00000000;true]" ..
    "textarea[0.5,0.5;9,6;rules;;" .. core.formspec_escape(jc_rules_model.rules_text) .. "]" ..
    "button_exit[3.5,7;3,1;exit;" .. core.formspec_escape( S("Close") ) .. "]"

  core.show_formspec(name, "rules:show", formspec)
end