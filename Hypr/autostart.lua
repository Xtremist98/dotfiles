-- Extra autostart processes.
-- o.launch_on_start("my-service")

hl.on("hyprland.start", function()
    hl.exec_cmd("hyprctl setcursor WinSur 16")
    hl.exec_cmd("bash -c 'sleep 3 && XDG_MENU_PREFIX=arch- kbuildsycoca6'")
end)
