-- Change the default Omarchy look'n'feel.

hl.config({
  general = {
    gaps_in = 4,
    gaps_out = 10,
    border_size = 1,
  },
    --decoration = {
    --rounding = 10,
    --rounding_power = 5,
  --},
})

-- Make mpv always tile (overrides default floating-window tag). 
o.window("mpv", { tag = "-floating-window", tile = true })

-- Make Windscribe always floating and centered.
o.window("^Windscribe$", { float = true, center = true, {size =  350, 741} })

-- FluxDown: keep auxiliary windows wide and short (IDM-style), main window tiled.
-- The complete-window title is the file name, so float every com.fluxdown.app window,
-- then force the main window back to tiling.
o.window("com.fluxdown.app", { float = true, center = true, size = { 600, 220 } })
o.window({ class = "com.fluxdown.app", title = "New Download" }, { float = true, center = true, size = { 640, 280 } })
o.window({ class = "com.fluxdown.app", title = "Download progress" }, { float = true, center = true, size = { 640, 360 } })
o.window({ class = "com.fluxdown.app", title = "Settings" }, { float = true, center = true, size = { 948, 505 } })
o.window({ class = "com.fluxdown.app", title = "FluxDown" }, { tile = true, float = false })

-- GTK (follows the active Omarchy theme; falls back to Adwaita-dark)
hl.exec_cmd("theme=$(cat ~/.local/state/omarchy/current/theme.name 2>/dev/null | tr -cd 'A-Za-z0-9-_'); if [ -z \"$theme\" ] || { [ ! -d /usr/share/themes/$theme ] && [ ! -d ~/.local/share/themes/$theme ]; }; then theme=Adwaita-dark; fi; gsettings set org.gnome.desktop.interface gtk-theme \"$theme\"")
hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'")

--GtK ( Font System )
hl.exec_cmd("gsettings set org.gnome.desktop.interface font-name 'Inter 10'")
hl.exec_cmd("gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 11'")
hl.exec_cmd("gsettings set org.gnome.desktop.interface document-font-name 'Inter 11'")

-- Opt another application in to Omarchy's standard transparency.
-- Find its class with: hyprctl clients
-- o.transparent_window("my-app")
-- o.transparent_window("my-app", "0.9 0.85") -- Custom active/inactive opacity.
--o.transparent_window("(org.kde.dolphin|org.kde.ark|btrfs-assistant|ca.desrt.dconf-editor|org.gnome.DiskUtility|disktree|fdm|gpartedbin|org.kde.konsole|org.localsend.localsend_app| com.linuxer.NordvpnGui|org.pulseaudio.pavucontrol|vesktop|xed|org.telegram.desktop|com.tmog.taskmanager|io.github.lgse.Strata|qt5ct|qt6ct|org.rncbc.qpwgraph)")
