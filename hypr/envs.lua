-- Desktop menu prefix.
hl.env("XDG_MENU_PREFIX", "arch-")

-- Cursor: hyprcursor is DISABLED (see hyprland.lua — v0.56.2 boot-time SEGV
-- in CCursorBuffer/CCursorManager), so the compositor cursor is XCursor-only.
-- XCURSOR_THEME is needed here so Omarchy's startup-cursor.lua restores
-- Omarchy-Accent (the cursor-accent plugin's recolored Bibata) instead of the
-- "default" alias on every boot. HYPRCURSOR_THEME deliberately stays unset.

hl.env("HYPRCURSOR_SIZE", "16")
hl.env("XCURSOR_SIZE", "16")
hl.env("XCURSOR_THEME", "Omarchy-Accent")

-- Let user bin override Omarchy's stock commands. This is needed for the
-- ~/.local/bin/omarchy-font-list wrapper, which adds Noto Sans Mono to the
-- Appearance > Fonts menu (Omarchy's stock command filters it out because
-- the font files lack fontconfig's spacing=100 tag).
local omarchy_bin = (os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/bin"
local kept_path = {}
for entry in (os.getenv("PATH") or "/usr/local/bin:/usr/bin"):gmatch("[^:]+") do
  if entry ~= omarchy_bin then table.insert(kept_path, entry) end
end
table.insert(kept_path, 1, omarchy_bin)
table.insert(kept_path, 1, (os.getenv("HOME") or "/home/linuxer") .. "/.local/bin")
hl.env("PATH", table.concat(kept_path, ":"))
