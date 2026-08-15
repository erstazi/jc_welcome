-- Minetest :: Splash Screen Mod v2.0 (corregido para ranks, lista con fondo)
--------------------------------------------------------

minetest.register_on_joinplayer(function(player)
  if player:get_hp() > 0 then
    local pname = player:get_player_name()

    -- Datos registry
    local pdata = registry.connected_players[pname]
    local ptime = pdata and pdata.time

    --------------------------------------------------
    -- SKIN REAL DINÁMICA (skinsdb compatible)
    --------------------------------------------------
    local skin_texture = "character.png"
    if player and skins.get_player_skin then
      local skin_obj = skins.get_player_skin(player)
      if skin_obj then
        skin_texture = skin_obj:get_preview() or skin_texture
      end
    end

    --------------------------------------------------
    -- DATOS DEL SERVIDOR
    --------------------------------------------------
    local server_name = minetest.settings:get("server_name") or "Untitled Server"
    local server_address = minetest.settings:get("server_address") or "localhost"
    local port = minetest.settings:get("port") or "30000"

    --------------------------------------------------
    -- FUNCIONES AUXILIARES PARA RANK
    --------------------------------------------------
    local function get_ranked_name(name)
      local rank = ranks.get_rank(name) or "basic"
      local def = ranks.get_def(rank)
      if def and def.prefix then
        local colour = def.colour or "#ffffff"
        return minetest.colorize(colour, "[" .. def.prefix:upper() .. "]") .. " " .. name
      end
      return name
    end

    --------------------------------------------------
    local formspec = "size[17,10]"
      .. default.gui_bg
      .. default.gui_bg_img
     .. "box[0.0,0.0;12.5,2;#111111]"

     -- Nombre server
     .. string.format("label[3.0,0.3;%s]", server_name)

     -- IP + Puerto
     .. string.format("label[3.0,0.9;%s:%s]",      server_address, port)

      -- Logo izquierda (igual)
     .. "image[0.5,0.0;2,2;inventory_logo.png]"

     -- 🔵 LOGO PEQUEÑO DERECHA
     .. "image[11.9,0.2;0.9,0.9;discord_logo.png]"

      -- 🔗 BOTÓN DISCORD
     .. "button_url[12.6,0.2;3.8,0.9;discord_link;Join Discord;https://discord.gg/C8Ev9td5k]"
     -- 🔗 BOTÓN PÁGINA WEB
     .. "button_url[12.6,1.2;3.8,0.9;web_link;Visit Website;https://just-craft.servegame.com/]"
     ---boton Foro
     .. "button_url[12.6,2.2;3.8,0.9;web_link;Visit Forum;https://forum.luanti.org/viewtopic.php?t=32339/]"
     -- Botón play
     .. "button_exit[0.5,8.5;3,1;close;Let's Play!]"
    --------------------------------------------------
    -- AVATAR Y TEXTOS
    --------------------------------------------------
    local avatar_x = 0.5
    local avatar_y = 3.5
    local avatar_w = 3
    local avatar_h = 4.5

    local text_x = 4.0
    local text_y_start = 2.5
    local line_spacing = 0.7
    local local_time = os.date("%H:%M:%S")

    if ptime then
      formspec = formspec
        .. string.format("label[%f,%f;Welcome back, %s!]",
          text_x, text_y_start, pname)
        .. string.format("label[%f,%f;You logged in at %s]",
          text_x, text_y_start + line_spacing,
          os.date("%A, %B %d, %Y", ptime))
        .. string.format("label[%f,%f;Local Time: %s]",
          text_x, text_y_start + 2*line_spacing,
          local_time)
        .. string.format("image[%f,%f;%f,%f;%s]",
          avatar_x, avatar_y,
          avatar_w, avatar_h,
          skin_texture)
    else
      formspec = formspec
        .. string.format("label[%f,%f;Greetings, %s!]",
          text_x, text_y_start, pname)
        .. string.format("label[%f,%f;Before starting, please read the rules posted at spawn.]",
          text_x, text_y_start + line_spacing)
        .. string.format("image[%f,%f;%f,%f;%s]",
          avatar_x, avatar_y,
          avatar_w, avatar_h,
          skin_texture)
    end

    --------------------------------------------------
    -- LISTA JUGADORES (SOLO MOVIDA IZQUIERDA)
    --------------------------------------------------
    local list_x = 11.9 -- MOVIDA
    local list_y = 3.9
    local list_w = 4.8
    local list_h = 5.2

    formspec = formspec ..
      string.format("box[%f,%f;%f,%f;#111111]",
        list_x, list_y,
        list_w, list_h)

    formspec = formspec ..
      string.format("label[%f,%f;%d Players Online]",
        list_x, list_y - 0.5,
        #registry.player_list)

    formspec = formspec ..
      string.format("textlist[%f,%f;%f,%f;player_list;",
        list_x, list_y,
        list_w, list_h)

    for i, name in ipairs(registry.player_list) do
      local display_name = get_ranked_name(name)
      formspec =
        (i > 1 and formspec .. "," or formspec)
        .. minetest.formspec_escape(display_name)
    end

    formspec = formspec ..
      string.format(";%d;true]",
        #registry.player_list)

    --------------------------------------------------
    -- OWNER
    --------------------------------------------------
    local player_rank = ranks.get_rank(pname) or "basic"
    if player_rank == "owner" then
      formspec = formspec ..
        "label[0.0,6.0;Owner Section: Here you can monitor server activity]"
    end

    --------------------------------------------------
    -- GENERAL
    --------------------------------------------------
    formspec = formspec ..
      "label[0.0,8.1;General Section: Enjoy the server!]"

    --------------------------------------------------
    -- FOOTER
    --------------------------------------------------
    formspec = formspec ..
      "label[0.0,9.2;For a complete list of available commands, type /help into chat.]"


    --------------------------------------------------
    -- MOSTRAR
    --------------------------------------------------
    minetest.show_formspec(pname,
      "welcome:splash",
      formspec)
  end
end)

--------------------------------------------------
-- Cargar AC panel
--------------------------------------------------
local ac_file = minetest.get_modpath("jc_welcome") .. "/ac.lua"
dofile(ac_file)

--------------------------------------------------
-- Cargar IF panel
--------------------------------------------------
local if_file = minetest.get_modpath("jc_welcome") .. "/if.lua"
dofile(if_file)

dofile(minetest.get_modpath("jc_welcome") .. "/help.lua")
dofile(minetest.get_modpath("jc_welcome") .. "/a.lua")
