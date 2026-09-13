--rose-pine-dark

local activeBorderColor = {
    colors = { "rgba(ebbcbaff)", "rgba(31748fff)", "rgba(eb6f92ff)", "rgba(ebbcbaff)" },
  angle = 41.8,
}
local inactiveBorderColor = "rgba(403d52ff)"

hl.config({
  general = {
    col = {
      active_border = activeBorderColor,
      inactive_border = inactiveBorderColor,
    },
    border_size = 1,
    gaps_in = 2,
    gaps_out = 6,
  },
  group = {
    col = {
      border_active = activeBorderColor,
      border_inactive = inactiveBorderColor,
    },
  },
  decoration = {
    active_opacity = 0.96,
    inactive_opacity = 0.93,
    rounding = 0,
    blur = {
      enabled = true,
      size = 6,
      passes = 3,
      ignore_opacity = true,
      new_optimizations = true,
      xray = false,
      noise = 0.03,
      contrast = 0.9,
      vibrancy = 0.04,
      vibrancy_darkness = 0.7,
      brightness = 0.45,
      popups_ignorealpha = 0.5,
      input_methods_ignorealpha = 0.5,
    },
    shadow = {
      enabled = false,
    },
  },
})
