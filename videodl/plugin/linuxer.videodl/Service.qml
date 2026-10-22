import QtQuick
import Quickshell
import Quickshell.Io
import "Model.js" as Model

// Talks to the videodl native-messaging host over its command-line face.
//
// The host is the single source of truth for both settings and job state: the
// extension queues downloads into it, and every detached worker writes its own
// record under $XDG_STATE_HOME/videodl/jobs. This service only ever reads that
// state back (`--jobs`) or asks the host to change it (`--job-action`), so the
// panel never has to parse or write the host's files itself.
//
// A native-messaging host is normally spawned per browser message and exits
// immediately, which is why the host grew these two argv modes: they give us
// something to run from the shell. The process is short-lived — one python
// start per poll — and slow polls when nothing is in flight keep that cheap.
Item {
  id: root

  // Poll cadence. Fast while something is downloading (or the panel is open,
  // where the user is watching), slow otherwise so an idle bar is not starting
  // a python interpreter every couple of seconds forever.
  property int activeInterval: 1500
  property int idleInterval: 20000
  property bool open: false

  // Parsed job list, newest first, exactly as the host reports it.
  property var jobs: []
  property bool loaded: false
  property bool refreshing: false
  property string lastError: ""
  // Set right after an action so the panel can show a transient note.
  property string actionNote: ""

  // Ticks once a second while something is active, so elapsed/ETA readouts
  // advance without waiting for the next poll.
  property double now: Date.now()

  readonly property var split: Model.split(jobs)
  readonly property var activeJobs: split.active
  readonly property var doneJobs: split.done
  readonly property bool busy: activeJobs.length > 0
  readonly property int activeCount: activeJobs.length

  readonly property string hostPath: {
    var home = Quickshell.env("HOME") || ""
    return home + "/.local/share/videodl/host/videodl-host"
  }

  function refresh() {
    if (refreshing) return
    refreshing = true
    listProcess.command = ["python3", hostPath, "--jobs"]
    listProcess.running = true
  }

  function act(op, jobId) {
    if (busyAction.running) return
    var argv = ["python3", hostPath, "--job-action", String(op)]
    if (jobId !== undefined && jobId !== null && String(jobId) !== "") argv.push(String(jobId))
    actionNote = ""
    busyAction.command = argv
    busyAction.running = true
  }

  function clearCompleted() {
    act("clear-completed")
  }

  function applyJobs(text) {
    var raw = String(text || "").trim()
    if (raw === "") {
      lastError = "The download host returned nothing."
      return
    }
    var parsed
    try {
      parsed = JSON.parse(raw)
    } catch (err) {
      lastError = "Could not read the download host's reply."
      return
    }
    if (!parsed || parsed.ok !== true) {
      lastError = (parsed && parsed.error) ? String(parsed.error) : "The download host reported an error."
      return
    }
    lastError = ""
    var next = parsed.jobs && parsed.jobs.length !== undefined ? parsed.jobs : []
    jobs = next
    loaded = true
    now = Date.now()
  }

  function applyAction(text) {
    var raw = String(text || "").trim()
    if (raw === "") return
    var parsed
    try {
      parsed = JSON.parse(raw)
    } catch (err) {
      return
    }
    if (!parsed) return
    if (parsed.ok !== true) {
      lastError = parsed.error ? String(parsed.error) : "That action failed."
      return
    }
    lastError = ""
    if (parsed.status) actionNote = String(parsed.status)
    refresh()
  }

  onOpenChanged: if (open) refresh()

  Component.onCompleted: refresh()

  // One poll loop for both paces: interval reads the faster value whenever the
  // panel is open or a job is in flight, and the timer restarts when that flips
  // so the change takes effect immediately rather than after the slow interval.
  Timer {
    id: pollTimer
    interval: (root.open || root.busy) ? root.activeInterval : root.idleInterval
    repeat: true
    running: true
    triggeredOnStart: false
    onTriggered: root.refresh()
    onIntervalChanged: restart()
  }

  Timer {
    id: tickTimer
    interval: 1000
    repeat: true
    running: root.busy
    onTriggered: root.now = Date.now()
  }

  Process {
    id: listProcess
    running: false
    command: []

    stdout: StdioCollector {
      id: listOut
      waitForEnd: true
    }

    stderr: StdioCollector {
      id: listErr
      waitForEnd: true
    }

    onExited: function(exitCode) {
      root.refreshing = false
      var out = String(listOut.text || "")
      var err = String(listErr.text || "")
      if (exitCode === 0) {
        root.applyJobs(out)
      } else {
        // A missing or moved host is worth saying out loud: the bar icon would
        // otherwise sit there looking merely idle.
        var detail = err.trim()
        root.lastError = detail !== ""
          ? detail.split("\n").slice(-1)[0]
          : "The download host is not answering (exit " + exitCode + ")."
      }
    }
  }

  Process {
    id: busyAction
    running: false
    command: []

    stdout: StdioCollector {
      id: actionOut
      waitForEnd: true
    }

    stderr: StdioCollector {
      id: actionErr
      waitForEnd: true
    }

    onExited: function(exitCode) {
      var out = String(actionOut.text || "")
      var err = String(actionErr.text || "")
      if (exitCode === 0) {
        root.applyAction(out)
      } else {
        root.lastError = err.trim() !== ""
          ? err.trim().split("\n").slice(-1)[0]
          : "That action failed (exit " + exitCode + ")."
        root.refresh()
      }
    }
  }
}
