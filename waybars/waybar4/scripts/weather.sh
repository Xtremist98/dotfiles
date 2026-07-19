#!/bin/bash

# Get your location (you can also hardcode a city name like "London" or "Mogoditshane")
CITY="Shabqadar"

# If CITY is empty, try to get location from IP
if [ -z "$CITY" ]; then
    CITY=$(curl -s "https://ipapi.co/city/" 2>/dev/null || echo "Mogoditshane")
fi

# Fetch weather data from wttr.in
weather_data=$(curl -s "wttr.in/${CITY}?format=j1" 2>/dev/null)

if [ -z "$weather_data" ]; then
    echo '{"text": "  ", "tooltip": "Unable to fetch weather data"}'
    exit 0
fi

# Parse current weather
current_temp=$(echo "$weather_data" | jq -r '.current_condition[0].temp_C')
current_desc=$(echo "$weather_data" | jq -r '.current_condition[0].weatherDesc[0].value')
current_code=$(echo "$weather_data" | jq -r '.current_condition[0].weatherCode')

# Parse tomorrow's weather
tomorrow_temp_max=$(echo "$weather_data" | jq -r '.weather[1].maxtempC')
tomorrow_temp_min=$(echo "$weather_data" | jq -r '.weather[1].mintempC')
tomorrow_desc=$(echo "$weather_data" | jq -r '.weather[1].hourly[4].weatherDesc[0].value')
tomorrow_code=$(echo "$weather_data" | jq -r '.weather[1].hourly[4].weatherCode')

# Function to get weather icon based on weather code
get_icon() {
    case $1 in
        113) echo "󰖙" ;;  # Sunny/Clear
        116) echo "󰖕" ;;  # Partly cloudy
        119) echo "󰖐" ;;  # Cloudy
        122) echo "󰖐" ;;  # Overcast
        143|248|260) echo "󰖑" ;;  # Fog
        176|263|266|293|296) echo "󰖗" ;;  # Light rain
        179|182|185|227|230|281|284|311|314|317|350|362|365|374|377) echo "󰼶" ;;  # Sleet/Ice
        200|386|389) echo "󰙾" ;;  # Thunder
        299|302|305|308|356|359) echo "󰖖" ;;  # Rain
        320|323|326|329|332|335|338|368|371) echo "󰼴" ;;  # Snow
        392|395) echo "󰼵" ;;  # Heavy snow
        *) echo "󰖙" ;;  # Default
    esac
}

current_icon=$(get_icon "$current_code")
tomorrow_icon=$(get_icon "$tomorrow_code")

# Format output
text=" ${current_icon} ${current_temp}°C"
tooltip="Today: ${current_desc}, ${current_temp}°C\nTomorrow: ${tomorrow_desc}, ${tomorrow_temp_min}-${tomorrow_temp_max}°C"

# Output JSON
echo "{\"text\": \"$text\", \"tooltip\": \"$tooltip\"}"
