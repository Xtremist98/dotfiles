-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Disable all Omarchy default bindings. Add your own in hypr/bindings.lua.
-- omarchy_default_bindings = false
--
-- Or disable only bindings for Omarchy's preinstalled apps/web apps while
-- keeping core window-manager bindings:
-- omarchy_preinstalled_bindings = false

-- Load Omarchy defaults.
-- Your own gestures replace Omarchy's defaults.
omarchy_default_gestures = false

require("default.hypr.omarchy")

-- Override the default environment (gtk3 platform theme etc.).
require("hypr.envs")

-- Put your personal overrides in these files. They're loaded after Omarchy's
-- defaults so package updates can improve the defaults without rewriting your
-- ~/.config/hypr files.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- Add any other personal Hyprland configuration below.
-- o.window("qemu", { workspace = "5" })

-- HyprMod managed settings
require("hyprland-gui")

-- Workaround for the v0.56.2 boot-time SEGV in CCursorBuffer/CCursorManager
-- (cairo NULL surface at CursorManager.cpp:220). Upstream fix is unreleased in
-- main only. Fall back to XCursor instead of hyprcursor.
hl.config({ cursor = { enable_hyprcursor = false } })

-- Hyprland 0.57.0 flipped quirks:skip_non_kms_dmabuf_formats to true (it was
-- false in 0.56.x). With "true" the zwp_linux_dmabuf_v1 format table is filtered
-- down to formats the monitor can also scan out, which drops EVERY alpha format
-- (AR24 and friends). Clients that ask for an alpha buffer (quickshell/EGL, and
-- anything else doing transparency) then get XR24 instead, so their alpha is
-- discarded: the bar strip and the notification layer paint solid black.
-- Verified with a wl_drm/dmabuf feedback dump: default -> no AR24, override ->
-- AR24 + 8 modifier variants. Restore the pre-0.57 behaviour until upstream
-- narrows the filter so it only hides formats the *renderer* cannot import.
hl.config({ quirks = { skip_non_kms_dmabuf_formats = false } })

-- Added by the Omarchy Workspace Layout plugin: registers its Lua tiling layouts.
do local path = (os.getenv("XDG_CONFIG_HOME") or os.getenv("HOME") .. "/.config") .. "/hypr/omarchy-workspace-layout.lua"; local file = io.open(path, "r"); if file then file:close(); dofile(path) end end
