-- help_controller.lua

local S = core.get_translator(core.get_current_modname())

core.register_chatcommand("guardian", {
  description = S("Shows Guardian rank requirements"),
  func = function(name)
    jc_help_view.show_guardian(name)
    return true
  end
})
