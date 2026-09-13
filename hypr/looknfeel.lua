-- Change the default Omarchy look'n'feel.

-- Make mpv always tile (overrides default floating-window tag).
o.window("mpv", { tag = "-floating-window", tile = true })

-- Make Windscribe always floating and centered.
o.window("^Windscribe$", { float = true, center = true, {size =  350, 741} })

-- Omagrab Windowsrules
o.window("^omagrab$", {float = true, center = true, {size = 520, 260} })

-- GTK
hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme 'rose-pine-dark'")
hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'")
hl.exec_cmd("gsettings set org.gnome.desktop.interface font-name 'Noto Sans 11'")
hl.exec_cmd("gsettings set org.gnome.desktop.interface document-font-name 'Noto Sans 11'")
