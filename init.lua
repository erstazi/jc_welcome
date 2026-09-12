local modname = core.get_current_modname()
local S = core.get_translator(core.get_current_modname())
local modpath = core.get_modpath(core.get_current_modname())
local ESC = core.formspec_escape
--------------------------------------------------------
-- Luanti :: Welcome Splash Screen Mod v2.1
--------------------------------------------------------
jc_welcome = jc_welcome or {}

--------------------------------------------------
-- Welcome Config
--------------------------------------------------
dofile(modpath .. "/config.lua")

--------------------------------------------------
-- Welcome MVC
--------------------------------------------------
dofile(modpath .. "/welcome_model.lua")
dofile(modpath .. "/welcome_view.lua")
dofile(modpath .. "/welcome_controller.lua")

--------------------------------------------------
-- LOAD AC PANEL
-- CARGAR AC PANEL
--------------------------------------------------
dofile(modpath .. "/ac_model.lua")
dofile(modpath .. "/ac_view.lua")
dofile(modpath .. "/ac_controller.lua")

--------------------------------------------------
-- LOAD IF PANEL
-- CARGAR IF PANEL
--------------------------------------------------
dofile(modpath .. "/if_model.lua")
dofile(modpath .. "/if_view.lua")
dofile(modpath .. "/if_controller.lua")

--------------------------------------------------
-- HELP MVC
--------------------------------------------------
dofile(modpath .. "/help_model.lua")
dofile(modpath .. "/help_view.lua")
dofile(modpath .. "/help_controller.lua")

--------------------------------------------------
-- Server Rules
--------------------------------------------------
dofile(modpath .. "/rules_model.lua")
dofile(modpath .. "/rules_view.lua")
dofile(modpath .. "/rules_controller.lua")