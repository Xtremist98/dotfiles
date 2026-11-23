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
