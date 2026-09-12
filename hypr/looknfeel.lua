-- Change the default Omarchy look'n'feel.

hl.config({
  general = {
    --gaps_in = 3,
   -- gaps_out = 10,
   -- border_size = 1,

    resize_on_border = true,
    allow_tearing = false,
    layout = "dwindle",
  },

  --decoration = {
    --rounding = 0,

    --shadow = {
      --enabled = false,
    --},

    --blur = {
      --enabled = false,
    --},
  --},

  group = {

    groupbar = {
      font_size = 15,
      font_family = "Slate For OnePlus",
      font_weight_active = "ultraheavy",
      font_weight_inactive = "normal",
      indicator_height = 2,
      indicator_gap = 4,
      height = 22,
      gaps_in = 4,
      gaps_out = 4,
      text_color = "rgb(cacccc)",
      text_color_inactive = "rgba(798186b0)",
      col = {
        active = "rgba(79818630)",
        inactive = "rgba(101315a0)",
      },
      gradients = false,
      gradient_rounding = 8,
      gradient_round_only_edges = true,
    },
  },

  animations = {
    enabled = true,
  },
})

-- Animations are owned by the active theme's hyprland.lua (required last,
-- after this user config), so the block that used to live here is removed to
-- let themes govern animation style. See ~/.local/state/omarchy/current/theme/hyprland.lua.

hl.config({
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
    initial_workspace_tracking = 0,
  },

  cursor = {
    hide_on_key_press = true,
    warp_on_change_workspace = 1,
  },

  binds = {
    hide_special_on_workspace_change = true,
  },
})


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
