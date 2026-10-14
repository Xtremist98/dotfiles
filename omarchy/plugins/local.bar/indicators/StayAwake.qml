import QtQuick
import qs.Commons
import qs.Ui

BarIndicator {
  id: root

  fontSize: 12
  fixedWidth: Style.bar.statusSlot

  // Draw the mark at pixelSize instead of the 12px global cap. See
  // IndicatorGlyph.qml for why `fontSize` alone cannot do this.
  iconComponent: Component { Item {} }

  IndicatorGlyph {
    text: root.text
    font.family: root.fontFamily
  }
  transform: Translate { x: -Style.spaceReal(1) }

  readonly property var idleService: bar?.shell?.firstPartyServiceFor("omarchy.idle")

  active: idleService ? idleService.stayAwake : false
  activeText: ""
  inactiveText: ""
  activeTooltipText: "Allow Idle Lock & Screensaver"
  inactiveTooltipText: "Stay Awake"

  function toggle() {
    if (root.idleService) root.idleService.setIdleEnabled(root.active)
  }

  onPressed: function() { root.toggle() }
}
