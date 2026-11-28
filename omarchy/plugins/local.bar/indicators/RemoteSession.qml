import QtQuick
import qs.Commons as Commons
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
    color: root.active && root.useActiveColor ? root.activeColor : root.foreground
  }

  readonly property var remoteSessionService: bar?.shell?.firstPartyServiceFor("omarchy.remote-session")
  readonly property var peers: remoteSessionService && Array.isArray(remoteSessionService.peers) ? remoteSessionService.peers : []

  active: remoteSessionService ? remoteSessionService.active : false
  activeText: "󰢹"
  activeTooltipText: peers.length > 0 ? Commons.I18n.t("bar.remoteSessionFrom").arg(peers.join(", ")) : Commons.I18n.t("bar.remoteSession")
  useActiveColor: true
  activeColor: Commons.Color.urgent
  revealWhenInactive: false

  Connections {
    target: root.indicatorHost
    ignoreUnknownSignals: true
    function onRefreshRequested() {
      if (root.remoteSessionService) root.remoteSessionService.refresh()
    }
  }
}
