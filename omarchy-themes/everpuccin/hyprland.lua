-- Everpuccin's Hyprland appearance for Omarchy 4.
local active_border_color = { colors = { "rgba(A7C080ff)", "rgba(D699B6ff)" }, angle = 90 }
local inactive_border_color = "rgba(232A2Eaa)"

hl.config({
  general = {
    col = {
      active_border = active_border_color,
      inactive_border = inactive_border_color,
    },
  },
  group = {
    col = {
      border_active = active_border_color,
      border_inactive = inactive_border_color,
    },
  },
})

