--rose-pine-dark

local activeBorderColor = {
  colors = { "rgba(ebbcbaff)", "rgba(e0def4cc)", "rgba(9ccfd8aa)",  },
  angle = 35,
}
local inactiveBorderColor = "rgba(ff403d52)"

hl.config({
  general = {
    col = {
      active_border = activeBorderColor,
      inactive_border = inactiveBorderColor,
    },
    border_size = 2,
    gaps_in = 3,
    gaps_out = 10,
  },
  group = {
    col = {
      border_active = activeBorderColor,
      border_inactive = inactiveBorderColor,
    },
  },
  decoration = {
    active_opacity = 0.97,
    inactive_opacity = 0.95,
    rounding = 10,
    blur = {
      enabled = true,
      size = 3,
      passes = 2,
      ignore_opacity = true,
      new_optimizations = true,
      xray = false,
      noise = 0.03,
      contrast = 0.87,
      vibrancy = 0.03,
      vibrancy_darkness = 0.7,
      brightness = 0.42,
      popups_ignorealpha = 0.5,
      input_methods_ignorealpha = 0.5,
    },
  },
 })
