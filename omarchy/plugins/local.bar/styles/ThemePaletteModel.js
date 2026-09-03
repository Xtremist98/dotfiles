.pragma library

var ColorPattern = /^#(?:[0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$/
var MaxInputLength = 65536
var MaxLines = 1024

function parse(raw) {
  var values = {}
  var lines = String(raw || "").slice(0, MaxInputLength).split("\n")
  for (var i = 0; i < lines.length && i < MaxLines; i++) {
    var match = lines[i].match(/^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*["']?(#[0-9A-Fa-f]{6}(?:[0-9A-Fa-f]{2})?)/)
    if (!match || !ColorPattern.test(match[2])) continue
    values[String(match[1]).toLowerCase()] = match[2]
  }
  // Extended palette: the 8 core slots + the full catpine blend palette
  // (rose-pine accent/neutrals + catppuccin mocha spectrum). Each additional
  // slot maps to a named color.toml key so every bar module can hold a
  // distinct color from the whole palette.
  return {
    color01: values.color1 || values.red || "",
    color02: values.color2 || values.green || "",
    color03: values.color3 || values.yellow || "",
    color04: values.color4 || values.blue || "",
    color05: values.color5 || values.magenta || "",
    color06: values.color6 || values.cyan || "",
    color07: values.color7 || values.bright_fg || values.light_fg || values.bright_foreground || values.light_foreground || "",
    color08: values.color8 || values.bright_black || values.muted || values.dark_foreground || "",
    color09: values.color9 || "",
    color10: values.red || "",
    color11: values.green || "",
    color12: values.yellow || "",
    color13: values.blue || "",
    color14: values.magenta || values.iris || "",
    color15: values.cyan || values.foam || "",
    color16: values.orange || values.peach || "",
    color17: values.maroon || values.brown || "",
    color18: values.teal || values.bright_green || "",
    color19: values.sky || values.bright_cyan || "",
    color20: values.sapphire || values.bright_blue || "",
    color21: values.lavender || "",
    color22: values.mauve || "",
    color23: values.pink || values.bright_magenta || "",
    color24: values.flamingo || "",
    color25: values.rosewater || "",
    color26: values.bright_yellow || values.gold || "",
    color27: values.love || values.bright_red || "",
    color28: values.rose || values.accent || "",
    color29: values.text || values.cdd6f4 || values.cdd6f4 || "",
    color30: values.subtext1 || "",
    color31: values.bright_fg || values.foreground || values.color7 || "",
    color32: values.pine || "",
    color33: values.lavender || values.iris || "",
    color34: values.subtext0 || "",
    color35: values.overlay2 || "",
    color36: values.light_fg || values.subtle || "",
    color37: values.overlay1 || ""
  }
}

function selection(value) {
  var candidate = String(value || "").toLowerCase()
  if (candidate === "red" || candidate === "accent"
      || candidate === "0" || candidate === "1"
      || candidate === "color1") return "color01"
  if (candidate === "green" || candidate === "color2") return "color02"
  if (candidate === "yellow" || candidate === "color3") return "color03"
  if (/^color(0[0-9]|1[0-9]|2[0-9]|3[0-7])$/.test(candidate)) return candidate
  return [
    "color01", "color02", "color03", "color04",
    "color05", "color06", "color07", "color08", "color09", "foreground",
    "color10", "color11", "color12", "color13", "color14", "color15",
    "color16", "color17", "color18", "color19", "color20", "color21",
    "color22", "color23", "color24", "color25", "color26", "color27",
    "color28", "color29", "color30", "color31", "color32", "color33",
    "color34", "color35", "color36", "color37"
  ].indexOf(candidate) >= 0 ? candidate : "color01"
}
