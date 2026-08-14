-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

-- Application bindings
hl.bind("SUPER + ALT + RETURN", hl.dsp.exec_cmd("uwsm-app -- xdg-terminal-exec --dir=\"$(omarchy-cmd-terminal-cwd)\" tmux new"), { description = "Tmux" })
hl.bind("SUPER + N", hl.dsp.exec_cmd("uwsm app -- nautilus --new-window"), { description = "File manager" })
hl.bind("SUPER + B", hl.dsp.exec_cmd("omarchy-launch-browser"), { description = "Browser" })
hl.bind("SUPER + SHIFT + B", hl.dsp.exec_cmd("$browser --private"), { description = "Browser (private)" })
hl.bind("SUPER + M", hl.dsp.exec_cmd("uwsm app -- /usr/bin/mpv --player-operation-mode=pseudo-gui --"), { description = "Mpv" })
hl.bind("SUPER + D", hl.dsp.exec_cmd("uwsm app -- /usr/lib/vesktop/vesktop"), { description = "Discord" })
hl.bind("SUPER + Y", hl.dsp.exec_cmd("omarchy-launch-tui nvtop"), { description = "Nvtop" })
hl.bind("SUPER + Q", hl.dsp.exec_cmd("uwsm app -- /usr/bin/qbittorrent"), { description = "Torrent" })
hl.bind("SUPER + Z", hl.dsp.exec_cmd("dolphin"), { description = "Dolphin" })
o.bind("SHIFT + TAB","Workspace overview","omarchy-shell shell summon mirador '{}'")
hl.bind("SUPER + SHIFT + T", hl.dsp.exec_cmd("uwsm app -- /usr/bin/Telegram"), { description = "Telegram" })

-- Brightness control with arrow keys
hl.bind("SUPER + Up", hl.dsp.exec_cmd("brightnessctl set +1%"))
hl.bind("SUPER + Down", hl.dsp.exec_cmd("brightnessctl set 1%-"))

-- Replace the existing togglefloating bind for Mpv
hl.bind("SUPER + E", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/togglefloating_resize.sh"))

-- Shell Settings panel
hl.bind("SUPER + I", hl.dsp.exec_cmd("omarchy-shell shell summon shell.settings"), { description = "Shell Settings" })

-- >>> omagrab keybind begin
hl.bind("SUPER + SHIFT + V", hl.dsp.exec_cmd("xdg-terminal-exec --app-id=omagrab -e omagrab --clip"), { description = "omagrab" })
-- <<< omagrab keybind end
