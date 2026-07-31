#!/bin/bash
# Omarchy weather module backend.
# Ported from the waybar weather.sh script. Emits structured JSON for the
# quickshell module; subcommands handle unit toggle / location management.

for cmd in curl jq notify-send; do
    command -v "$cmd" >/dev/null 2>&1 || {
        jq -n -c '{"text": "⚠️", "desc": "Missing dependency: '"$cmd"'"}'
        exit 1
    }
done

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/weather_module"
CACHE_FILE_LOC="$CACHE_DIR/location.json"
CACHE_FILE_WTTR="$CACHE_DIR/wttr.json"
CACHE_FILE_AQI="$CACHE_DIR/aqi.json"
FILE_UNIT="$CACHE_DIR/unit"
FILE_OVERRIDE="$CACHE_DIR/loc_override"
CACHE_AGE=900
mkdir -p "$CACHE_DIR"
CURRENT_TIME=$(date +%s)

WEATHER_CODES='{"113":"☀️","116":"⛅","119":"☁️","122":"☁️","143":"🌫","176":"🌦","179":"🌧","182":"🌧","185":"🌧","200":"🌩","227":"🌨","230":"❄️","248":"🌫","260":"🌫","263":"🌦","266":"🌦","281":"🌧","284":"🌧","293":"🌦","296":"🌧","299":"🌦","302":"🌧","305":"🌧","308":"🌧","311":"🌧","314":"🌧","317":"🌧","320":"🌨","323":"🌨","326":"🌨","329":"❄️","332":"❄️","335":"❄️","338":"❄️","350":"🌧","353":"🌦","356":"🌧","359":"🌧","362":"🌧","365":"🌧","368":"🌨","371":"❄️","374":"🌧","377":"🌧","386":"🌩","389":"🌩","392":"🌩","395":"❄️"}'

case "$1" in
    --toggle-unit)
        CURRENT_UNIT=$(cat "$FILE_UNIT" 2>/dev/null || echo "C")
        if [ "$CURRENT_UNIT" == "C" ]; then
            echo "F" > "$FILE_UNIT"
            notify-send -a "Weather" -i "weather-clear" "Weather" "Switched to Fahrenheit (°F)"
        else
            echo "C" > "$FILE_UNIT"
            notify-send -a "Weather" -i "weather-clear" "Weather" "Switched to Celsius (°C)"
        fi
        exit 0
        ;;
    --set-location)
        if [ $# -ge 2 ]; then
            echo "$2" > "$FILE_OVERRIDE"
            rm -f "$CACHE_FILE_WTTR" "$CACHE_FILE_AQI"
            notify-send -a "Weather" -i "mark-location" "Location Updated" "Now tracking: $2"
        fi
        exit 0
        ;;
    --clear-location)
        rm -f "$FILE_OVERRIDE"
        rm -f "$CACHE_FILE_WTTR" "$CACHE_FILE_AQI"
        notify-send -a "Weather" -i "mark-location" "Location Reset" "Switched to Automatic IP tracking."
        exit 0
        ;;
    --clear-cache)
        rm -f "$CACHE_FILE_WTTR" "$CACHE_FILE_AQI"
        exit 0
        ;;
esac

COLOR_ACCENT="#c4a0f0"
COLOR_MUTED="#8c92a3"
COLOR_TEXT="#dcd6d6"
COLOR_HI="#f9e2af"

UNIT_SYM=$(cat "$FILE_UNIT" 2>/dev/null || echo "C")
MANUAL_LOC=$(cat "$FILE_OVERRIDE" 2>/dev/null)

if [ -n "$MANUAL_LOC" ]; then
    CITY="$MANUAL_LOC"
    LOC_STR="${CITY}"
    LOC=""
    CITY_ENCODED=$(echo "$CITY" | sed 's/ /%20/g')
else
    if [ -f "$CACHE_FILE_LOC" ] && [ $((CURRENT_TIME - $(stat -c %Y "$CACHE_FILE_LOC" 2>/dev/null || echo 0))) -lt 86400 ]; then
        LOC_DATA=$(cat "$CACHE_FILE_LOC")
    else
        LOC_DATA=$(curl --max-time 5 -s "https://ipinfo.io/json")
        [ -n "$LOC_DATA" ] && echo "$LOC_DATA" > "$CACHE_FILE_LOC"
    fi
    CITY=$(echo "$LOC_DATA" | jq -r '.city // "Unknown"')
    REGION=$(echo "$LOC_DATA" | jq -r '.region // ""')
    LOC=$(echo "$LOC_DATA" | jq -r '.loc // ""')
    CITY_ENCODED=$(echo "$CITY" | sed 's/ /%20/g')
    LOC_STR="${CITY}"
    [ -n "$REGION" ] && LOC_STR="${CITY}, ${REGION}"
fi

RESPONSE=""
if [ -f "$CACHE_FILE_WTTR" ]; then
    CACHED_AGE=$((CURRENT_TIME - $(stat -c %Y "$CACHE_FILE_WTTR" 2>/dev/null || echo 0)))
    if [ $CACHED_AGE -lt $CACHE_AGE ]; then
        CACHED=$(cat "$CACHE_FILE_WTTR")
        echo "$CACHED" | jq -e '.current_condition[0]' >/dev/null 2>&1 && RESPONSE="$CACHED"
    fi
fi

fetch_wttr() {
    local url="$1"
    local out
    out=$(curl --max-time 15 -s "$url")
    if echo "$out" | jq -e '.current_condition[0]' >/dev/null 2>&1; then
        RESPONSE="$out"
        return 0
    fi
    return 1
}

if [ -z "$RESPONSE" ]; then
    # City name first — the most reliable lookup. If it fails, fall back to
    # coordinates from ipinfo, rounded to 2 decimals (wttr.in rejects the
    # 4-decimal form ipinfo serves).
    if ! fetch_wttr "https://wttr.in/${CITY_ENCODED}?format=j1&m" && [ -n "$LOC" ]; then
        ROUNDED=$(echo "$LOC" | awk -F, '{printf "%.2f,%.2f", $1, $2}')
        fetch_wttr "https://wttr.in/@${ROUNDED}?format=j1&m"
    fi
fi

# wttr.in occasionally returns an error body ("location not found: upstream
# error: ..."). Treat anything that isn't valid JSON as unavailable and never
# cache it, so a bad reply can't linger and poison the next run.
if ! echo "$RESPONSE" | jq -e '.current_condition[0]' >/dev/null 2>&1; then
    jq -n -c '{"text": "🌫️", "desc": "Weather Unavailable"}'
    exit 1
fi

echo "$RESPONSE" > "$CACHE_FILE_WTTR"

if [ -f "$CACHE_FILE_AQI" ] && [ $((CURRENT_TIME - $(stat -c %Y "$CACHE_FILE_AQI" 2>/dev/null || echo 0))) -lt $CACHE_AGE ]; then
    AQI_DATA=$(cat "$CACHE_FILE_AQI")
else
    AQI_CITY=$(echo "$CITY" | sed 's/ /%20/g')
    AQI_DATA=$(curl --max-time 5 -s "https://api.waqi.info/feed/${AQI_CITY}/?token=demo")
    [ -n "$AQI_DATA" ] && echo "$AQI_DATA" > "$CACHE_FILE_AQI"
fi
AQI_VAL=$(echo "$AQI_DATA" | jq -r '.data.aqi // "N/A"' 2>/dev/null || echo "N/A")

DESC=$(echo "$RESPONSE" | jq -r '.current_condition[0].weatherDesc[0].value')
CODE=$(echo "$RESPONSE" | jq -r '.current_condition[0].weatherCode')
HUM=$(echo "$RESPONSE" | jq -r '.current_condition[0].humidity')
UV=$(echo "$RESPONSE" | jq -r '.current_condition[0].uvIndex // "0"')
WIND=$(echo "$RESPONSE" | jq -r '.current_condition[0].windspeedKmph // "0"')
PRESS=$(echo "$RESPONSE" | jq -r '.current_condition[0].pressure // "0"')
VIS=$(echo "$RESPONSE" | jq -r '.current_condition[0].visibility // "0"')
SUNRISE=$(echo "$RESPONSE" | jq -r '.weather[0].astronomy[0].sunrise')
SUNSET=$(echo "$RESPONSE" | jq -r '.weather[0].astronomy[0].sunset')

if [ "$UNIT_SYM" == "F" ]; then
    TEMP=$(echo "$RESPONSE" | jq -r '.current_condition[0].temp_F')
    FEELS=$(echo "$RESPONSE" | jq -r '.current_condition[0].FeelsLikeF')
    TMAX=$(echo "$RESPONSE" | jq -r '.weather[0].maxtempF')
    TMIN=$(echo "$RESPONSE" | jq -r '.weather[0].mintempF')
else
    TEMP=$(echo "$RESPONSE" | jq -r '.current_condition[0].temp_C')
    FEELS=$(echo "$RESPONSE" | jq -r '.current_condition[0].FeelsLikeC')
    TMAX=$(echo "$RESPONSE" | jq -r '.weather[0].maxtempC')
    TMIN=$(echo "$RESPONSE" | jq -r '.weather[0].mintempC')
fi

ICON=$(echo "$WEATHER_CODES" | jq -r --arg code "$CODE" '.[$code] // "☀️"')

get_uv() {
    local u=$(echo "${1%.*}" | tr -d '[:space:]')
    [[ -z "$u" || ! "$u" =~ ^[0-9]+$ ]] && u=0
    if [ "$u" -le 2 ]; then echo "Low"
    elif [ "$u" -le 5 ]; then echo "Mod"
    elif [ "$u" -le 7 ]; then echo "High"
    else echo "Ext"; fi
}

get_aqi() {
    local a=$(echo "$1" | tr -d '[:space:]')
    [[ -z "$a" || ! "$a" =~ ^[0-9]+$ ]] && a=0
    if [ "$a" -le 50 ]; then echo "Good"
    elif [ "$a" -le 100 ]; then echo "Mod"
    elif [ "$a" -le 150 ]; then echo "Unhealth"
    elif [ "$a" -le 200 ]; then echo "Poor"
    else echo "Bad"; fi
}
AQI_LABEL=$(get_aqi "$AQI_VAL")
UV_LABEL=$(get_uv "$UV")

NOW_HHMM=$(( $(date +%-H) * 100 ))
HOURS=$(echo "$RESPONSE" | jq -c --argjson now "$NOW_HHMM" '
  ([.weather[0].hourly[] | select((.time | tonumber) >= $now)]) + .weather[1].hourly | .[:8]
')

HOURLY_ARR="[]"
while read -r h; do
    [ "$h" = "null" ] || [ -z "$h" ] && continue
    HT=$(echo "$h" | jq -r '.time | tonumber | . / 100 | floor')

    if [ "$HT" -eq 0 ]; then HTFMT="12 AM"
    elif [ "$HT" -eq 12 ]; then HTFMT="12 PM"
    elif [ "$HT" -gt 12 ]; then HTFMT=$(printf "%02d PM" $((HT - 12)))
    else HTFMT=$(printf "%02d AM" $HT); fi

    HCODE=$(echo "$h" | jq -r '.weatherCode')
    HRAIN=$(echo "$h" | jq -r '.chanceofrain')
    HICON=$(echo "$WEATHER_CODES" | jq -r --arg code "$HCODE" '.[$code] // "☀️"')

    [ "$UNIT_SYM" == "F" ] && HTEMP=$(echo "$h" | jq -r '.tempF') || HTEMP=$(echo "$h" | jq -r '.tempC')

    HOURLY_ARR=$(echo "$HOURLY_ARR" | jq -c --arg t "$HTFMT" --arg i "$HICON" --arg tmp "$HTEMP" --arg r "$HRAIN" \
        '. + [{"time": $t, "icon": $i, "temp": $tmp, "rain": $r}]')
done <<< "$(echo "$HOURS" | jq -c '.[]')"

DAY1_DATE=$(echo "$RESPONSE" | jq -r '.weather[1].date')
DAY2_DATE=$(echo "$RESPONSE" | jq -r '.weather[2].date')
DAY1_NAME=$(date -d "$DAY1_DATE" "+%A" 2>/dev/null || echo "Tomorrow")
DAY2_NAME=$(date -d "$DAY2_DATE" "+%A" 2>/dev/null || echo "Next Day")

DAY1_CODE=$(echo "$RESPONSE" | jq -r '.weather[1].hourly[4].weatherCode // .weather[1].hourly[0].weatherCode')
DAY2_CODE=$(echo "$RESPONSE" | jq -r '.weather[2].hourly[4].weatherCode // .weather[2].hourly[0].weatherCode')
DAY1_ICON=$(echo "$WEATHER_CODES" | jq -r --arg code "$DAY1_CODE" '.[$code] // "☀️"')
DAY2_ICON=$(echo "$WEATHER_CODES" | jq -r --arg code "$DAY2_CODE" '.[$code] // "☀️"')

if [ "$UNIT_SYM" == "F" ]; then
    D1_MAX=$(echo "$RESPONSE" | jq -r '.weather[1].maxtempF'); D1_MIN=$(echo "$RESPONSE" | jq -r '.weather[1].mintempF')
    D2_MAX=$(echo "$RESPONSE" | jq -r '.weather[2].maxtempF'); D2_MIN=$(echo "$RESPONSE" | jq -r '.weather[2].mintempF')
else
    D1_MAX=$(echo "$RESPONSE" | jq -r '.weather[1].maxtempC'); D1_MIN=$(echo "$RESPONSE" | jq -r '.weather[1].mintempC')
    D2_MAX=$(echo "$RESPONSE" | jq -r '.weather[2].maxtempC'); D2_MIN=$(echo "$RESPONSE" | jq -r '.weather[2].mintempC')
fi

DAILY_ARR=$(jq -n -c \
    --arg d1 "$DAY1_NAME" --arg i1 "$DAY1_ICON" --arg x1 "$D1_MAX" --arg n1 "$D1_MIN" \
    --arg d2 "$DAY2_NAME" --arg i2 "$DAY2_ICON" --arg x2 "$D2_MAX" --arg n2 "$D2_MIN" \
    '[{"day": $d1, "icon": $i1, "max": $x1, "min": $n1}, {"day": $d2, "icon": $i2, "max": $x2, "min": $n2}]')

jq -n -c \
    --arg text "$ICON ${TEMP}°${UNIT_SYM}" \
    --arg icon "$ICON" \
    --arg temp "$TEMP" \
    --arg unit "$UNIT_SYM" \
    --arg desc "$DESC" \
    --arg loc "$LOC_STR" \
    --arg feels "$FEELS" \
    --arg tmax "$TMAX" \
    --arg tmin "$TMIN" \
    --arg humidity "$HUM" \
    --arg wind "$WIND" \
    --arg vis "$VIS" \
    --arg aqi "$AQI_VAL" \
    --arg aqiLabel "$AQI_LABEL" \
    --arg uv "$UV" \
    --arg uvLabel "$UV_LABEL" \
    --arg pressure "$PRESS" \
    --arg sunrise "$SUNRISE" \
    --arg sunset "$SUNSET" \
    --argjson hourly "$HOURLY_ARR" \
    --argjson daily "$DAILY_ARR" \
    '{text: $text, icon: $icon, temp: $temp, unit: $unit, desc: $desc, loc: $loc, feels: $feels, tmax: $tmax, tmin: $tmin, humidity: $humidity, wind: $wind, vis: $vis, aqi: $aqi, aqiLabel: $aqiLabel, uv: $uv, uvLabel: $uvLabel, pressure: $pressure, sunrise: $sunrise, sunset: $sunset, hourly: $hourly, daily: $daily}'
