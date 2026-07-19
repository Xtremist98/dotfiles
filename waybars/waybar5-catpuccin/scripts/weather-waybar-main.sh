#!/usr/bin/env bash
# Waybar Weather Module Script
# Displays current weather and 3-day forecast
# Uses wttr.in JSON API for accurate forecast data

set -euo pipefail

################################################################################
# CONFIGURATION
################################################################################

# City name (leave empty "" for IP-based auto-detection)
CITY="Shabqadar"

# Language code (ko=Korean, en=English, ja=Japanese, etc.)
# See: https://github.com/chubin/wttr.in#supported-languages
LANG="en"

# Tooltip labels (customize for your language)
LABEL_NOW="Now"
LABEL_TEMP="Temp"
LABEL_FEELS="Feels"
LABEL_WIND="Wind"
LABEL_RAIN="Rain"
LABEL_HUMIDITY="Humidity"
LABEL_PRESSURE="Pressure"

################################################################################
# SCRIPT - No need to modify below this line
################################################################################

# Get day names using system locale
day_num_today=$(date +'%u')
day_num_tomorrow=$(date -d tomorrow +'%u')
day_num_after=$(date -d '+2 days' +'%u')

get_day_name() {
    case $1 in
        1) date -d "monday" +'%A' ;;
        2) date -d "tuesday" +'%A' ;;
        3) date -d "wednesday" +'%A' ;;
        4) date -d "thursday" +'%A' ;;
        5) date -d "friday" +'%A' ;;
        6) date -d "saturday" +'%A' ;;
        7) date -d "sunday" +'%A' ;;
    esac
}

TODAY="$(get_day_name $day_num_today)"
TOMORROW="$(get_day_name $day_num_tomorrow)"
DAYAFTER="$(get_day_name $day_num_after)"

# Fetch JSON data for accurate forecasts
json="$(curl -4 -fsS "https://wttr.in/${CITY}?format=j1&lang=${LANG}" 2>/dev/null)" || {
    echo '{"text":" --°C","tooltip":"Weather unavailable"}'
    exit 0
}

# Current conditions
current_temp="$(echo "$json" | jq -r '.current_condition[0].temp_C')"
current_feels="$(echo "$json" | jq -r '.current_condition[0].FeelsLikeC')"
current_desc="$(echo "$json" | jq -r ".current_condition[0].lang_${LANG}[0].value // .current_condition[0].weatherDesc[0].value")"
current_icon="$(echo "$json" | jq -r '.current_condition[0].weatherCode')"
wind="$(echo "$json" | jq -r '.current_condition[0].windspeedKmph')km/h"
wind_dir="$(echo "$json" | jq -r '.current_condition[0].winddir16Point')"
humidity="$(echo "$json" | jq -r '.current_condition[0].humidity')%"
pressure="$(echo "$json" | jq -r '.current_condition[0].pressure')hPa"
precip="$(echo "$json" | jq -r '.current_condition[0].precipMM')mm"
location="$(echo "$json" | jq -r '.nearest_area[0].areaName[0].value')"

# Forecast data
today_avg="$(echo "$json" | jq -r '.weather[0].avgtempC')"
today_icon="$(echo "$json" | jq -r '.weather[0].hourly[4].weatherCode')"
tomorrow_avg="$(echo "$json" | jq -r '.weather[1].avgtempC')"
tomorrow_icon="$(echo "$json" | jq -r '.weather[1].hourly[4].weatherCode')"
dayafter_avg="$(echo "$json" | jq -r '.weather[2].avgtempC')"
dayafter_icon="$(echo "$json" | jq -r '.weather[2].hourly[4].weatherCode')"

# Map weather codes to icons
get_icon() {
    case $1 in
        113) echo "☀️" ;;
        116) echo "⛅" ;;
        119|122) echo "☁️" ;;
        143|248|260) echo "🌫️" ;;
        176|263|266|293|296|353) echo "🌦️" ;;
        179|182|185|281|284|311|314|317|350|377) echo "🌨️" ;;
        200|386|389|392|395) echo "⛈️" ;;
        227|230) echo "❄️" ;;
        299|302|305|308|356|359) echo "🌧️" ;;
        320|323|326|329|332|335|338|368|371|374) echo "🌨️" ;;
        *) echo "🌡️" ;;
    esac
}

bar_icon="$(get_icon $current_icon)"
today_emoji="$(get_icon $today_icon)"
tomorrow_emoji="$(get_icon $tomorrow_icon)"
dayafter_emoji="$(get_icon $dayafter_icon)"

# Build bar text
bar="${bar_icon} ${current_temp}°C"

# Build tooltip
tip="$(cat <<EOF
$location
━━━━━━━━━━━━━━━━━━━━━━
${LABEL_NOW}: $current_desc
${LABEL_TEMP}: ${current_temp}°C | ${LABEL_FEELS}: ${current_feels}°C
${LABEL_WIND}: ${wind_dir} ${wind} | ${LABEL_RAIN}: ${precip}
${LABEL_HUMIDITY}: ${humidity} | ${LABEL_PRESSURE}: ${pressure}

━━━━━━━━━━━━━━━━━━━━━━
$TODAY     ${today_emoji}  ${today_avg}°C
$TOMORROW   ${tomorrow_emoji}  ${tomorrow_avg}°C
$DAYAFTER  ${dayafter_emoji}  ${dayafter_avg}°C
EOF
)"

jq -nc --arg text "$bar" --arg tooltip "$tip" '{text: $text, tooltip: $tooltip}'
