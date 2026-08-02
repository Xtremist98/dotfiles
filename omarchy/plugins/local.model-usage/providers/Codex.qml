import QtQuick

LocalScanner {
  providerId: "codex"
  providerName: "Codex"
  scannerPath: String(Qt.resolvedUrl("../scripts/codex_usage_scanner.py")).replace("file://", "")
  backgroundRefreshIntervalMs: 5 * 60 * 1000
  defaultHelpText: "Run `codex login` to authenticate."
}
