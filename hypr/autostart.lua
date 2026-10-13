-- Extra autostart processes.
-- o.launch_on_start("my-service")

hl.on("hyprland.start", function()
    -- Cursor theme is applied by the cursor-accent plugin's post-boot hook.
    hl.exec_cmd("bash -c 'sleep 3 && XDG_MENU_PREFIX=arch- kbuildsycoca6'")
end)
