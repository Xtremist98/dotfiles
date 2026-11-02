pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property string icon: "·"
  property string place: ""
  property string tempC: ""
  property string tempF: ""
  property string feelsC: ""
  property string feelsF: ""
  property string description: ""
  property string country: ""
  property string humidity: ""
  property string windKmh: ""
  property string windMph: ""
  property var forecastDays: []
  property var configuredLocation: ({
    name: "",
    latitude: null,
    longitude: null
  })
  property bool loaded: false
  property bool unavailable: false
  property bool refreshPending: false
  property bool geocodeAttempted: false
  readonly property bool refreshing: weatherProc.running

  // Provider state. Open-Meteo is preferred (richest payload, real is_day),
  // but it answers 503 "service is overloaded" for hours at a time, which used
  // to leave the bar showing a stale temperature forever. Whichever provider
  // answered last is tried first on the next fetch.
  property string preferredProvider: "open-meteo"
  property string activeProvider: ""
  property string activeUrl: ""
  property var providerQueue: []
  property bool fallbackPending: false

  readonly property string locationQuery: {
    const latitude = parseFloat(String(configuredLocation.latitude))
    const longitude = parseFloat(String(configuredLocation.longitude))
    if (!isNaN(latitude) && !isNaN(longitude))
      return latitude + "," + longitude
    const name = String(configuredLocation.name || "").trim()
    return name ? encodeURIComponent(name) : ""
  }

  readonly property string requestUrl: {
    const latitude = parseFloat(String(configuredLocation.latitude))
    const longitude = parseFloat(String(configuredLocation.longitude))
    if (isNaN(latitude) || isNaN(longitude)) return ""
    return "https://api.open-meteo.com/v1/forecast"
      + "?latitude=" + latitude + "&longitude=" + longitude
      + "&current=temperature_2m,relative_humidity_2m,apparent_temperature,"
      + "weather_code,wind_speed_10m,is_day"
      + "&daily=weather_code,temperature_2m_max,temperature_2m_min,"
      + "precipitation_probability_max"
      + "&timezone=auto&forecast_days=3&wind_speed_unit=kmh"
  }

  readonly property string wttrUrl: {
    const latitude = parseFloat(String(configuredLocation.latitude))
    const longitude = parseFloat(String(configuredLocation.longitude))
    if (isNaN(latitude) || isNaN(longitude)) return ""
    return "https://wttr.in/" + latitude + "," + longitude + "?format=j1"
  }

  readonly property string geocodeUrl: {
    const name = String(configuredLocation.name || "").trim()
    if (!name) return ""
    return "https://geocoding-api.open-meteo.com/v1/search?name="
      + encodeURIComponent(name) + "&count=1&language=en&format=json"
  }

  function parseLocation(raw) {
    try {
      const value = JSON.parse(String(raw || ""))
      const latitude = parseFloat(value && value.latitude)
      const longitude = parseFloat(value && value.longitude)
      configuredLocation = {
        name: value && typeof value.name === "string"
          ? value.name.trim() : "",
        latitude: !isNaN(latitude) ? latitude : null,
        longitude: !isNaN(longitude) ? longitude : null
      }
    } catch (_error) {
      configuredLocation = { name: "", latitude: null, longitude: null }
    }
    geocodeAttempted = false
  }

  function descriptionForCode(code) {
    const value = parseInt(code)
    const map = {
      0: "Clear sky", 1: "Mainly clear", 2: "Partly cloudy", 3: "Overcast",
      45: "Fog", 48: "Rime fog",
      51: "Light drizzle", 53: "Drizzle", 55: "Dense drizzle",
      56: "Light freezing drizzle", 57: "Freezing drizzle",
      61: "Light rain", 63: "Rain", 65: "Heavy rain",
      66: "Light freezing rain", 67: "Freezing rain",
      71: "Light snow", 73: "Snow", 75: "Heavy snow", 77: "Snow grains",
      80: "Light rain showers", 81: "Rain showers", 82: "Violent rain showers",
      85: "Light snow showers", 86: "Snow showers",
      95: "Thunderstorm", 96: "Thunderstorm with hail",
      99: "Thunderstorm with heavy hail"
    }
    return map[value] !== undefined ? map[value] : ""
  }

  function glyphForCode(code, isDay) {
    const value = parseInt(code) || 0
    switch (value) {
      case 0: case 1: return isDay ? "\ue430" : "\uef5e"
      case 2: return isDay ? "\uf172" : "\uf174"
      case 3: return "\ue2bd"
      case 45: case 48: return "\ue818"
      case 51: case 53: case 55: case 56: case 57: return "\uf176"
      case 61: case 63: case 65: case 66: case 67: return "\uf61f"
      case 71: case 73: case 75: case 77: case 85: case 86: return "\ue80f"
      case 80: case 81: case 82: return "\uf61e"
      case 95: case 96: case 99: return "\uebdb"
      default: return "\ue2bd"
    }
  }

  function cToF(c) {
    const n = parseFloat(c)
    return isNaN(n) ? "" : String(Math.round(n * 9 / 5 + 32))
  }

  function roundC(c) {
    const n = parseFloat(c)
    return isNaN(n) ? "" : String(Math.round(n))
  }

  function refresh(force) {
    if (!enabled) return
    if (!root.requestUrl) {
      if (root.geocodeUrl && !geocodeProc.running && !root.geocodeAttempted) {
        root.geocodeAttempted = true
        geocodeProc.running = true
      }
      return
    }
    if (weatherProc.running) {
      if (force === true) refreshPending = true
      return
    }
    const first = root.preferredProvider === "wttr" ? "wttr" : "open-meteo"
    const second = first === "wttr" ? "open-meteo" : "wttr"
    root.fallbackPending = false
    root.providerQueue = [first, second]
    root.startNextProvider()
  }

  // Retry the fetch with backoff after a failed/empty result so the widget
  // recovers from the boot network race and from transient provider failures,
  // instead of staying offline until the next 15-minute periodic check.
  function scheduleRetry() {
    if (retryTimer.running) return
    retryTimer.attempt = 0
    retryTimer.interval = 15000
    retryTimer.running = true
  }

  function reloadLocation() {
    locationFile.reload()
  }

  // Single place that decides what happens once the shell is idle: either the
  // next provider in the queue or a queued forced refresh. Idempotent and safe
  // to call from both the stream collector and onRunningChanged, because those
  // two can fire in either order.
  function maybeAdvance() {
    if (weatherProc.running) return
    if (root.fallbackPending) {
      root.fallbackPending = false
      root.startNextProvider()
      return
    }
    if (!root.refreshPending) return
    root.refreshPending = false
    root.refresh(false)
  }

  function providerUrl(name) {
    if (name === "wttr") return root.wttrUrl
    if (name === "open-meteo") return root.requestUrl
    return ""
  }

  function startNextProvider() {
    if (weatherProc.running) return
    const queue = root.providerQueue
    if (!queue || !queue.length) {
      root.activeProvider = ""
      root.activeUrl = ""
      root.unavailable = true
      root.scheduleRetry()
      return
    }
    root.activeProvider = queue[0]
    root.activeUrl = root.providerUrl(queue[0])
    root.providerQueue = queue.slice(1)
    if (!root.activeUrl) {
      root.startNextProvider()
      return
    }
    weatherProc.running = true
  }

  // WorldWeatherOnline codes (wttr.in) collapsed onto the WMO codes this widget
  // already renders and describes. Unknown codes return -1 and are skipped.
  function wwoToWmo(code) {
    const value = parseInt(code)
    if (isNaN(value)) return -1
    const map = {
      113: 0, 116: 2, 119: 3, 122: 3,
      143: 45, 149: 45, 248: 45, 260: 48,
      176: 80, 179: 71, 182: 77, 185: 56, 200: 95,
      227: 71, 230: 75,
      263: 51, 266: 53, 281: 56, 284: 57,
      293: 61, 296: 61, 299: 63, 302: 63, 305: 65, 308: 65,
      311: 66, 314: 67, 317: 77, 320: 75,
      323: 71, 326: 71, 329: 73, 332: 73, 335: 75, 338: 75,
      350: 77, 353: 80, 356: 81, 359: 82,
      362: 85, 365: 86, 368: 85, 371: 86, 374: 77, 377: 77,
      386: 95, 389: 95, 392: 96, 395: 96
    }
    return map[value] !== undefined ? map[value] : -1
  }

  // wttr.in has no per-day code: pick the worst (highest WMO) daylight hour so a
  // rainy afternoon is not advertised as a sunny day, falling back to any hour.
  function wttrDayCode(day) {
    if (!day || !day.hourly || !day.hourly.length) return ""
    const daylight = [600, 900, 1200, 1500, 1800]
    let best = -1
    let any = -1
    for (let index = 0; index < day.hourly.length; index++) {
      const hour = day.hourly[index]
      if (!hour) continue
      const code = wwoToWmo(hour.weatherCode)
      if (code < 0) continue
      if (any < 0) any = code
      if (daylight.indexOf(parseInt(hour.time)) === -1) continue
      if (code > best) best = code
    }
    const chosen = best >= 0 ? best : any
    return chosen >= 0 ? String(chosen) : ""
  }

  function applyOpenMeteo(raw) {
    try {
      const report = JSON.parse(String(raw || ""))
      const current = report && report.current
      if (!current) return false

      const code = parseInt(current.weather_code)
      const isDay = current.is_day === 1
      icon = glyphForCode(code, isDay)
      tempC = roundC(current.temperature_2m)
      tempF = cToF(current.temperature_2m)
      feelsC = roundC(current.apparent_temperature)
      feelsF = cToF(current.apparent_temperature)
      description = descriptionForCode(code)
      place = String(configuredLocation.name || "")
      country = ""
      humidity = current.relative_humidity_2m !== undefined
        ? String(Math.round(current.relative_humidity_2m)) : ""
      windKmh = current.wind_speed_10m !== undefined
        ? String(Math.round(current.wind_speed_10m)) : ""
      windMph = current.wind_speed_10m !== undefined
        ? String(Math.round(current.wind_speed_10m * 0.621371)) : ""

      const days = []
      const daily = report.daily
      if (daily && daily.time && daily.time.length) {
        const count = Math.min(daily.time.length, 3)
        for (let index = 0; index < count; index++) {
          const minC = daily.temperature_2m_min
            ? daily.temperature_2m_min[index] : undefined
          const maxC = daily.temperature_2m_max
            ? daily.temperature_2m_max[index] : undefined
          const dayCode = daily.weather_code
            ? daily.weather_code[index] : undefined
          const rain = daily.precipitation_probability_max
            && daily.precipitation_probability_max[index] !== undefined
            ? parseFloat(daily.precipitation_probability_max[index]) : 0
          days.push({
            date: String(daily.time[index] || ""),
            minC: roundC(minC),
            maxC: roundC(maxC),
            minF: cToF(minC),
            maxF: cToF(maxC),
            code: dayCode !== undefined ? String(dayCode) : "",
            rain: isNaN(rain) ? 0 : rain
          })
        }
      }
      forecastDays = days
      return true
    } catch (_error) {
      return false
    }
  }

  function applyWttr(raw) {
    try {
      const report = JSON.parse(String(raw || ""))
      const current = report && report.current_condition
        && report.current_condition[0]
      if (!current) return false

      const code = wwoToWmo(current.weatherCode)
      const hour = new Date().getHours()
      const isDay = hour >= 6 && hour < 18
      icon = glyphForCode(code, isDay)

      tempC = roundC(current.temp_C)
      tempF = cToF(current.temp_C)
      feelsC = roundC(current.FeelsLikeC)
      feelsF = cToF(current.FeelsLikeC)

      const desc = current.weatherDesc && current.weatherDesc[0]
        ? String(current.weatherDesc[0].value || "").trim() : ""
      description = desc || descriptionForCode(code)

      const area = report.nearest_area && report.nearest_area[0]
      const areaName = area && area.areaName && area.areaName[0]
        ? String(area.areaName[0].value || "") : ""
      place = String(configuredLocation.name || areaName || "")
      country = area && area.country && area.country[0]
        ? String(area.country[0].value || "") : ""

      humidity = current.humidity !== undefined
        ? String(Math.round(parseFloat(current.humidity))) : ""
      windKmh = current.windspeedKmph !== undefined
        ? String(Math.round(parseFloat(current.windspeedKmph))) : ""
      windMph = current.windspeedMiles !== undefined
        ? String(Math.round(parseFloat(current.windspeedMiles)))
        : (windKmh ? String(Math.round(parseFloat(windKmh) * 0.621371)) : "")

      const days = []
      const list = report.weather || []
      const count = Math.min(list.length, 3)
      for (let index = 0; index < count; index++) {
        const day = list[index] || {}
        let rain = 0
        const hourly = day.hourly || []
        for (let slot = 0; slot < hourly.length; slot++) {
          const chance = hourly[slot] ? parseFloat(hourly[slot].chanceofrain) : NaN
          if (!isNaN(chance) && chance > rain) rain = chance
        }
        days.push({
          date: String(day.date || ""),
          minC: roundC(day.mintempC),
          maxC: roundC(day.maxtempC),
          minF: cToF(day.mintempC),
          maxF: cToF(day.maxtempC),
          code: wttrDayCode(day),
          rain: rain
        })
      }
      forecastDays = days
      return true
    } catch (_error) {
      return false
    }
  }

  // The process appends "\n<http status>" so a 5xx body stays visible for the
  // log instead of being swallowed by curl -f.
  function handleResponse(provider, payload) {
    const text = String(payload || "")
    const tail = text.match(/\n(\d{3})\s*$/)
    const status = tail ? parseInt(tail[1]) : 0
    const body = tail ? text.slice(0, tail.index) : text

    const ok = status === 200
      && (provider === "wttr" ? applyWttr(body) : applyOpenMeteo(body))

    if (ok) {
      preferredProvider = provider
      loaded = true
      unavailable = false
      if (provider !== "open-meteo")
        console.log("weather: served by " + provider)
      return
    }

    const next = root.providerQueue.length ? root.providerQueue[0] : ""
    console.warn("weather: " + provider + " failed (http " + status + ")"
      + (next ? " - trying " + next : ""))
    fallbackPending = true
    Qt.callLater(function() { root.maybeAdvance() })
  }

  function parseGeocode(raw) {
    try {
      const data = JSON.parse(String(raw || "{}"))
      const result = data && data.results && data.results[0]
      if (!result || result.latitude === undefined
          || result.longitude === undefined) return
      configuredLocation = {
        name: String(result.name || configuredLocation.name),
        latitude: result.latitude,
        longitude: result.longitude
      }
    } catch (_error) { }
  }

  Process {
    id: weatherProc
    command: ["curl", "-sS", "--max-time", "20", "-A", "omarchy-weather",
      "-w", "\n%{http_code}", root.activeUrl]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.handleResponse(root.activeProvider, text)
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        const message = String(text || "").trim()
        if (message) console.warn("weather: curl: " + message)
      }
    }
    onRunningChanged: {
      if (running) return
      // Never re-enter a running Process: hand the next provider / pending
      // refresh back to the event loop instead of starting it from here.
      Qt.callLater(function() { root.maybeAdvance() })
    }
  }

  Process {
    id: geocodeProc
    command: ["curl", "-fsS", "--max-time", "10", "-A", "omarchy-weather",
      root.geocodeUrl]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseGeocode(text)
    }
  }

  FileView {
    id: locationFile
    path: Quickshell.env("HOME")
      + "/.local/state/omarchy/settings/weather.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.parseLocation(text())
    onLoadFailed: root.parseLocation("")
  }

  Timer {
    interval: 1500
    running: root.enabled
    onTriggered: locationFile.reload()
  }

  onLocationQueryChanged: refresh(true)

  Timer {
    interval: 15 * 60 * 1000
    running: root.enabled
    repeat: true
    triggeredOnStart: false
    onTriggered: root.refresh(false)
  }

  // Backoff retry after a failed fetch (see scheduleRetry). Stops as soon as a
  // successful report arrives; otherwise keeps trying for roughly 20 minutes.
  Timer {
    id: retryTimer
    property int attempt: 0
    interval: 15000
    running: false
    repeat: false
    onTriggered: {
      if (root.loaded && !root.unavailable) return
      root.refresh(false)
      attempt++
      if (attempt < 10) {
        interval = Math.min(600000, 15000 * Math.pow(2, attempt))
        running = true
      }
    }
  }
}
