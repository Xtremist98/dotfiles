import QtQuick
import Quickshell.Io

// No UI: the actual work happens in recolor.py, run by the theme-set and
// post-boot hooks (see tools/install-cursor-hook.sh). This service only
// re-applies the current settings once when the shell (re)loads the plugin,
// so a fresh `omarchy plugin add --enable` or `omarchy-restart-shell` shows
// the right cursor immediately instead of waiting for the next theme switch.
// It only runs while the plugin is enabled in the shell, so the post-boot
// hook, not this file, is what keeps the cursor right across reboots.
Item {
  id: root

  readonly property string pluginDir: Qt.resolvedUrl(".").toString().replace("file://", "")

  Component.onCompleted: applyProcess.running = true

  Process {
    id: applyProcess
    running: false
    command: ["bash", "-c",
      "exec python3 '" + root.pluginDir + "recolor.py' \"$(omarchy-theme-current 2>/dev/null || echo unknown)\""
    ]
    stdout: StdioCollector { onStreamFinished: if (text) console.log("cursor-accent:", text.trim()) }
    stderr: StdioCollector { onStreamFinished: if (text) console.warn("cursor-accent:", text.trim()) }
  }
}
