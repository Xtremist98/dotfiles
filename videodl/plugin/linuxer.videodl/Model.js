.pragma library

// Formatting and grouping for the Video Grabber bar widget.
//
// Everything here is pure: the panel hands in the job records the host wrote
// and gets back strings. No timers, no I/O — those live in Service.qml.

var GLYPH_DOWNLOAD = "\uf019"
var GLYPH_CHECK    = "\uf00c"
var GLYPH_ALERT    = "\uf071"
var GLYPH_CLOSE    = "\uf00d"
var GLYPH_FOLDER   = "\uf07c"
var GLYPH_COPY     = "\uf0c5"
var GLYPH_OPEN     = "\uf08e"
var GLYPH_TRASH    = "\uf1f8"
var GLYPH_RETRY    = "\uf01e"
var GLYPH_CLEAR    = "\uf12d"
var GLYPH_SWEEP    = "\uf0b0"
var GLYPH_REFRESH  = "\uf021"
var GLYPH_BACK     = "\uf060"

var ACTIVE_STATES = ["queued", "running", "processing"]
var TERMINAL_STATES = ["completed", "failed", "cancelled"]

function isActive(job) {
  return !!job && ACTIVE_STATES.indexOf(String(job.status)) >= 0
}

function isDone(job) {
  return !!job && TERMINAL_STATES.indexOf(String(job.status)) >= 0
}

// Newest first from the host; keep that order in both panes.
function split(jobs) {
  var active = []
  var done = []
  var list = jobs && jobs.length ? jobs : []
  for (var i = 0; i < list.length; i++) {
    var job = list[i]
    if (!job || !job.id) continue
    if (isActive(job)) active.push(job)
    else if (isDone(job)) done.push(job)
  }
  return { active: active, done: done }
}

function completedCount(done) {
  var n = 0
  for (var i = 0; i < done.length; i++) if (String(done[i].status) === "completed") n++
  return n
}

// --- sizes and rates -----------------------------------------------------
// 1024-based, but named the way people read file sizes. Values below a
// kilobyte stay in bytes because "0.4 KB" hides how little is left on a
// stalled transfer.

function bytes(value) {
  var n = Number(value) || 0
  if (n <= 0) return "0 B"
  if (n < 1024) return Math.round(n) + " B"
  var units = ["KB", "MB", "GB", "TB"]
  var v = n / 1024
  var i = 0
  while (v >= 1024 && i < units.length - 1) {
    v /= 1024
    i++
  }
  var digits = v >= 100 ? 0 : (v >= 10 ? 1 : 2)
  return v.toFixed(digits) + " " + units[i]
}

function speed(value) {
  var n = Number(value) || 0
  if (n <= 0) return ""
  return bytes(n) + "/s"
}

// --- time ----------------------------------------------------------------
// Remaining/elapsed use the largest unit that stays readable: 42s, 3m 05s,
// 1h 12m. Estimated completion is a clock time, which is what people
// actually want when they glance at the bar.

function duration(seconds) {
  var s = Math.round(Number(seconds) || 0)
  if (s <= 0) return ""
  if (s < 60) return s + "s"
  var m = Math.floor(s / 60)
  var rs = s % 60
  if (m < 60) return m + "m " + (rs < 10 ? "0" + rs : rs) + "s"
  var h = Math.floor(m / 60)
  var rm = m % 60
  return h + "h " + (rm < 10 ? "0" + rm : rm) + "m"
}

// "14:32" from a millisecond epoch, in the machine's own timezone.
function clock(ms) {
  var n = Number(ms) || 0
  if (n <= 0) return ""
  var d = new Date(n)
  var hh = d.getHours()
  var mm = d.getMinutes()
  return (hh < 10 ? "0" + hh : hh) + ":" + (mm < 10 ? "0" + mm : mm)
}

function elapsed(job, now) {
  if (!job) return ""
  var started = Number(job.started) || 0
  if (started <= 0) return ""
  var end = Number(job.finished) || 0
  if (end <= 0) end = Number(now) || Date.now()
  return duration(Math.max(0, (end - started) / 1000))
}

// --- progress ------------------------------------------------------------

function percent(job) {
  if (!job) return 0
  var p = Number(job.percent) || 0
  if (p > 0) return Math.min(100, p)
  var done = Number(job.done) || 0
  var total = Number(job.total) || 0
  if (done > 0 && total > 0) return Math.min(100, (done / total) * 100)
  if (String(job.status) === "completed") return 100
  return 0
}

// "0.46/1.20 GB" — both sides in the size of the total, so the pair stays short
// enough for the narrow two-pane column. One number and no "of" saves ~10px.
function pair(done, total) {
  if (!(done > 0) || !(total > 0)) return ""
  var units = ["B", "KB", "MB", "GB", "TB"]
  var i = 0
  var t = total
  while (t >= 1024 && i < units.length - 1) {
    t /= 1024
    i++
  }
  var d = done / Math.pow(1024, i)
  var digits = t >= 100 ? 0 : (t >= 10 ? 1 : 2)
  if (d < 1) digits = Math.max(digits, 2)
  return d.toFixed(digits) + "/" + t.toFixed(digits) + " " + units[i]
}

// "0.46/1.20 GB", "1.20 GB", or "" when nothing is known yet.
function transferred(job) {
  if (!job) return ""
  var done = Number(job.done) || 0
  var total = Number(job.total) || 0
  if (done > 0 && total > 0) return pair(done, total)
  if (total > 0) return bytes(total)
  if (done > 0) return bytes(done)
  if (String(job.status) === "completed") return bytes(job.size)
  return ""
}

// --- labels --------------------------------------------------------------

function statusLabel(job) {
  if (!job) return ""
  var status = String(job.status)
  if (status === "queued") return "Queued"
  if (status === "running") return "Downloading"
  if (status === "processing") return "Converting"
  if (status === "completed") return "Done"
  if (status === "cancelled") return "Cancelled"
  if (status === "failed") return "Failed"
  return status
}

// The quality/codec badge: "1080p · vp9 · mkv", "audio · mp3 · 320k".
function spec(job) {
  if (!job) return ""
  var parts = []
  if (job.mode === "audio") {
    parts.push("audio")
    if (job.convert) parts.push(String(job.convert))
  } else {
    if (job.height) parts.push(Number(job.height) + "p")
    if (job.codec) parts.push(String(job.codec))
    if (job.convert) parts.push(String(job.convert))
  }
  var embed = []
  if (job.embed_thumbnail) embed.push("thumb")
  if (job.embed_metadata) embed.push("meta")
  var text = parts.join(" · ")
  if (embed.length) text += (text !== "" ? " · " : "") + embed.join("+")
  return text
}

// Title falls back to the URL host so a queued job is never a blank row.
function title(job) {
  if (!job) return ""
  var t = String(job.title || "").trim()
  if (t !== "") return t
  var url = String(job.url || "")
  var m = url.match(/^[a-z]+:\/\/([^/]+)/i)
  return m ? m[1] : url
}

function fileName(job) {
  if (!job) return ""
  return String(job.name || (job.file ? String(job.file).split("/").pop() : "") || "")
}

// Panel meta line: what the widget is doing right now in one phrase.
function summary(jobs) {
  var split1 = split(jobs)
  var active = split1.active.length
  if (active > 0) {
    var totals = 0
    var totalBytes = 0
    for (var i = 0; i < split1.active.length; i++) {
      var s = Number(split1.active[i].speed) || 0
      if (s > 0) {
        totals += s
        totalBytes++
      }
    }
    if (totalBytes > 0) return "Downloading — " + speed(totals)
    return active === 1 ? "One download in flight" : active + " downloads in flight"
  }
  var done = split1.done.length
  if (done > 0) {
    var completed = completedCount(split1.done)
    return completed + " finished"
  }
  return "No downloads yet"
}

// Aggregate progress for the bar icon's ring: the mean of the active jobs, so
// two parallel grabs move the arc half as far as one.
function activeProgress(jobs) {
  var list = split(jobs).active
  if (list.length === 0) return 0
  var sum = 0
  for (var i = 0; i < list.length; i++) sum += percent(list[i])
  return sum / list.length
}

function hasActive(jobs) {
  return split(jobs).active.length > 0
}
