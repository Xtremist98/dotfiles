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
    weatherProc.running = true
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

  function parseReport(raw) {
    const text = String(raw || "").trim()
    if (!text) {
      unavailable = true
      scheduleRetry()
      return
    }

    try {
      const report = JSON.parse(text)
      const current = report.current
      if (!current) {
        unavailable = true
        scheduleRetry()
        return
      }

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
      loaded = true
      unavailable = false
    } catch (_error) {
      unavailable = true
      scheduleRetry()
    }
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
    command: ["curl", "-fsS", "--max-time", "15", "-A", "omarchy-weather",
      root.requestUrl]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseReport(text)
    }
    onRunningChanged: {
      if (running || !root.refreshPending) return
      root.refreshPending = false
      Qt.callLater(function() { root.refresh(false) })
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
