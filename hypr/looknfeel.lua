-- Change the default Omarchy look'n'feel.

hl.config({
  general = {
    gaps_in = 3,
    gaps_out = 8,
    border_size = 2,
  },
})

-- Make mpv always tile (overrides default floating-window tag).
o.window("mpv", { tag = "-floating-window", tile = true })

-- Make Windscribe always floating and centered.
o.window("^Windscribe$", { float = true, center = true, {size =  350, 741} })

-- Omagrab Windowsrules
o.window("^omagrab$", {float = true, center = true, {size = 520, 260} })

-- GTK (follows the active Omarchy theme; falls back to Adwaita-dark)
hl.exec_cmd("theme=$(cat ~/.local/state/omarchy/current/theme.name 2>/dev/null | tr -cd 'A-Za-z0-9-_'); if [ -z \"$theme\" ] || { [ ! -d /usr/share/themes/$theme ] && [ ! -d ~/.local/share/themes/$theme ]; }; then theme=Adwaita-dark; fi; gsettings set org.gnome.desktop.interface gtk-theme \"$theme\"")
hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'")
hl.exec_cmd("gsettings set org.gnome.desktop.interface font-name 'Noto Sans 11'")
hl.exec_cmd("gsettings set org.gnome.desktop.interface document-font-name 'Noto Sans 11'")
