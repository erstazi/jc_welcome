-- help_view.lua
local S = core.get_translator(core.get_current_modname())
local ESC = core.formspec_escape

jc_help_view = {}

function jc_help_view.show_guardian(name)
  local text = jc_help_model.get_guardian_text()

  local formspec =
    "formspec_version[4]" ..
    "size[10,8]" ..
    "textarea[0.5,0.5;9,6.5;info;;" .. ESC(text) .. "]" ..
    "button_exit[3.5,7.2;3,0.8;exit;" .. ESC( S("Close") ) .. "]"

  core.show_formspec(name, "welcome:help", formspec)
end