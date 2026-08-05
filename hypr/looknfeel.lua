-- Change the default Omarchy look'n'feel.

hl.config({
    general = {
        ["col.active_border"] = {
            colors = {
                "rgba(101315ee)",
                "rgba(101315ee)",
                "rgba(101315ee)",
                "rgba(798186ee)",
                "rgba(798186ee)",
                "rgba(798186ee)",
                "rgba(798186ee)",
                "rgba(798186ee)",
            },
            deg = 30,
        },
        ["col.inactive_border"] = {
            colors = {
                "rgb(1e1e1e)",
            },
            deg = 90,
        },
        gaps_in = 4,
        gaps_out = 5,
        border_size = 2,
    },

    decoration = {
        rounding = 6,
        rounding_power = 3,
        shadow = {
            enabled = true,
            range = 16,
            color = "rgba(00000052)",
        },
        blur = {
            enabled = true,
            size = 2,
            passes = 2,
            special = true,
            brightness = 0.60,
            contrast = 0.75,
        },
    },

    group = {
        ["col.border_active"] = {
            colors = {
                "rgba(798186ee)",
                "rgba(101315ee)",
                "rgba(101315ee)",
                "rgba(798186ee)",
            },
            deg = 5,
        },
        ["col.border_inactive"] = "rgb(101315)",
        groupbar = {
            ["col.active"] = "rgba(79818688)",
            ["col.inactive"] = "rgba(101315aa)",
            text_color = "rgb(101315)",
            text_color_inactive = "rgba(798186aa)",
        },
    },

    animations = {
        enabled = true,
        bezier = {
            "easeOutQuint, 0.23, 1, 0.32, 1",
            "easeInOutCubic, 0.65, 0.05, 0.36, 1",
            "linear, 0, 0, 1, 1",
            "almostLinear, 0.5, 0.5, 0.75, 1.0",
            "quick, 0.15, 0, 0.1, 1",
        },
        animation = {
            "global, 1, 8, default",
            "border, 1, 5.39, easeOutQuint",
            "windows, 1, 3.79, easeOutQuint",
            "windowsIn, 1, 4.1, easeOutQuint, popin 87%",
            "windowsOut, 1, 1.49, linear, popin 87%",
            "fadeIn, 1, 1.73, almostLinear",
            "fadeOut, 1, 1.46, almostLinear",
            "fade, 1, 3.03, quick",
            "layers, 1, 3.81, easeOutQuint",
            "layersIn, 1, 4, easeOutQuint, fade",
            "layersOut, 1, 1.5, linear, fade",
            "fadeLayersIn, 1, 1.79, almostLinear",
            "fadeLayersOut, 1, 1.39, almostLinear",
            "workspaces, 0, 0, ease",
            "specialWorkspace, 1, 3, easeOutQuint, slidevert",
        },
    },

    dwindle = {
        preserve_split = true,
        force_split = 2,
    },

    scrolling = {
        column_width = 0.49,
    },

    master = {
        new_status = "master",
    },

    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        disable_scale_notification = true,
        focus_on_activate = true,
        anr_missed_pings = 3,
        on_focus_under_fullscreen = 1,
    },

    cursor = {
        hide_on_key_press = true,
        warp_on_change_workspace = 1,
    },

    binds = {
        hide_special_on_workspace_change = true,
    },

    gestures = {
        gesture = {
            "3, horizontal, workspace",
            "3, up, close",
            "4, horizontal, move",
            "4, up, fullscreen",
            "4, down, float",
        },
    },
})

-- Make mpv always tile (overrides default floating-window tag).
o.window("mpv", { tag = "-floating-window", tile = true })

-- Make Windscribe always floating and centered.
o.window("^Windscribe$", { float = true, center = true })

-- GTK Theme Settings
hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'")
hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'")
