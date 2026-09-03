pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons as Commons
import "ThemePaletteModel.js" as ThemePaletteModel

// Quattro owns the foundational background/foreground roles. Read the seven
// terminal swatches that its public Commons palette does not expose so the
// V1 bar-color contract can be reproduced without duplicating theme ownership.
Item {
  id: root

  required property var config

  readonly property string home: Quickshell.env("HOME")
  readonly property string colorsPath:
    home + "/.local/state/omarchy/current/theme/colors.toml"
  readonly property string themeNamePath:
    home + "/.local/state/omarchy/current/theme.name"
  readonly property string selectedId: ThemePaletteModel.selection(
    config && config.presentation ? config.presentation.accent : "color01")
  property color color01: Commons.Color.urgent
  property color color02: Commons.Color.accent
  property color color03: Commons.Color.accent
  property color color04: Commons.Color.accent
  property color color05: Commons.Color.accent
  property color color06: Commons.Color.accent
  property color color07: Commons.Color.foreground
  property color color08: Commons.Color.muted
  property color color09: "#8a9296"
  property color color10: Commons.Color.accent
  property color color11: Commons.Color.accent
  property color color12: Commons.Color.accent
  property color color13: Commons.Color.accent
  property color color14: Commons.Color.accent
  property color color15: Commons.Color.accent
  property color color16: Commons.Color.accent
  property color color17: Commons.Color.accent
  property color color18: Commons.Color.accent
  property color color19: Commons.Color.accent
  property color color20: Commons.Color.accent
  property color color21: Commons.Color.accent
  property color color22: Commons.Color.accent
  property color color23: Commons.Color.accent
  property color color24: Commons.Color.accent
  property color color25: Commons.Color.accent
  property color color26: Commons.Color.accent
  property color color27: Commons.Color.accent
  property color color28: Commons.Color.accent
  property color color29: Commons.Color.accent
  property color color30: Commons.Color.accent
  property color color31: Commons.Color.foreground
  property color color32: Commons.Color.accent
  property color color33: Commons.Color.accent
  property color color34: Commons.Color.accent
  property color color35: Commons.Color.accent
  property color color36: Commons.Color.accent
  property color color37: Commons.Color.accent
  readonly property color foregroundSoft: Qt.rgba(
    Commons.Color.foreground.r * 0.88 + Commons.Color.background.r * 0.12,
    Commons.Color.foreground.g * 0.88 + Commons.Color.background.g * 0.12,
    Commons.Color.foreground.b * 0.88 + Commons.Color.background.b * 0.12,
    1.0)
  readonly property color selectedColor: colorFor(selectedId)

  visible: false
  width: 0
  height: 0

  function apply(raw) {
    const palette = ThemePaletteModel.parse(raw)
    color01 = palette.color01 || Commons.Color.urgent
    color02 = palette.color02 || Commons.Color.accent
    color03 = palette.color03 || Commons.Color.accent
    color04 = palette.color04 || Commons.Color.accent
    color05 = palette.color05 || Commons.Color.accent
    color06 = palette.color06 || Commons.Color.accent
    color07 = palette.color07 || Commons.Color.foreground
    color08 = palette.color08 || Commons.Color.muted
    color09 = palette.color09 || "#8a9296"
    color10 = palette.color10 || Commons.Color.accent
    color11 = palette.color11 || Commons.Color.accent
    color12 = palette.color12 || Commons.Color.accent
    color13 = palette.color13 || Commons.Color.accent
    color14 = palette.color14 || Commons.Color.accent
    color15 = palette.color15 || Commons.Color.accent
    color16 = palette.color16 || Commons.Color.accent
    color17 = palette.color17 || Commons.Color.accent
    color18 = palette.color18 || Commons.Color.accent
    color19 = palette.color19 || Commons.Color.accent
    color20 = palette.color20 || Commons.Color.accent
    color21 = palette.color21 || Commons.Color.accent
    color22 = palette.color22 || Commons.Color.accent
    color23 = palette.color23 || Commons.Color.accent
    color24 = palette.color24 || Commons.Color.accent
    color25 = palette.color25 || Commons.Color.accent
    color26 = palette.color26 || Commons.Color.accent
    color27 = palette.color27 || Commons.Color.accent
    color28 = palette.color28 || Commons.Color.accent
    color29 = palette.color29 || Commons.Color.accent
    color30 = palette.color30 || Commons.Color.accent
    color31 = palette.color31 || Commons.Color.foreground
    color32 = palette.color32 || Commons.Color.accent
    color33 = palette.color33 || Commons.Color.accent
    color34 = palette.color34 || Commons.Color.accent
    color35 = palette.color35 || Commons.Color.accent
    color36 = palette.color36 || Commons.Color.accent
    color37 = palette.color37 || Commons.Color.accent
  }

  function colorFor(value) {
    const id = ThemePaletteModel.selection(value)
    if (id === "color02") return color02
    if (id === "color03") return color03
    if (id === "color04") return color04
    if (id === "color05") return color05
    if (id === "color06") return color06
    if (id === "color07") return color07
    if (id === "color08") return color08
    if (id === "color09") return color09
    if (id === "color10") return color10
    if (id === "color11") return color11
    if (id === "color12") return color12
    if (id === "color13") return color13
    if (id === "color14") return color14
    if (id === "color15") return color15
    if (id === "color16") return color16
    if (id === "color17") return color17
    if (id === "color18") return color18
    if (id === "color19") return color19
    if (id === "color20") return color20
    if (id === "color21") return color21
    if (id === "color22") return color22
    if (id === "color23") return color23
    if (id === "color24") return color24
    if (id === "color25") return color25
    if (id === "color26") return color26
    if (id === "color27") return color27
    if (id === "color28") return color28
    if (id === "color29") return color29
    if (id === "color30") return color30
    if (id === "color31") return color31
    if (id === "color32") return color32
    if (id === "color33") return color33
    if (id === "color34") return color34
    if (id === "color35") return color35
    if (id === "color36") return color36
    if (id === "color37") return color37
    if (id === "foreground") return foregroundSoft
    return color01
  }

  function linearChannel(value) {
    return value <= 0.04045
      ? value / 12.92 : Math.pow((value + 0.055) / 1.055, 2.4)
  }

  function relativeLuminance(value) {
    return 0.2126 * linearChannel(value.r)
      + 0.7152 * linearChannel(value.g)
      + 0.0722 * linearChannel(value.b)
  }

  function contrastRatio(left, right) {
    const leftLuminance = relativeLuminance(left)
    const rightLuminance = relativeLuminance(right)
    return (Math.max(leftLuminance, rightLuminance) + 0.05)
      / (Math.min(leftLuminance, rightLuminance) + 0.05)
  }

  function contrastColor(value) {
    const fill = colorFor(value)
    return contrastRatio(fill, Commons.Color.background)
      >= contrastRatio(fill, Commons.Color.foreground)
      ? Commons.Color.background : Commons.Color.foreground
  }

  function refresh() {
    colorsFile.reload()
  }

  // Quattro replaces the complete current/theme directory before rewriting
  // theme.name. Watching that stable sibling guarantees a reload after the
  // atomic swap, including a reapply whose theme name and base colors did not
  // change.
  FileView {
    id: themeNameFile
    path: root.themeNamePath
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: colorsFile.reload()
  }

  FileView {
    id: colorsFile
    path: root.colorsPath
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.apply(text())
    onLoadFailed: root.apply("")
  }

  Connections {
    target: Commons.Color
    function onBackgroundChanged() { root.refresh() }
    function onForegroundChanged() { root.refresh() }
    function onAccentChanged() { root.refresh() }
    function onUrgentChanged() { root.refresh() }
  }
}
