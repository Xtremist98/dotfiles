--rose-pine-dark

local activeBorderColor = {
  colors = { "rgba(ebbcbaff)", "rgba(c4a7e7ff)" },
  angle = 45,
}
local inactiveBorderColor = "rgba(403d52ff)"

hl.config({
  general = {
    col = {
      active_border = activeBorderColor,
      inactive_border = inactiveBorderColor,
    },
  },
  group = {
    col = {
      border_active = activeBorderColor,
      border_inactive = inactiveBorderColor,
    },
  },
})
