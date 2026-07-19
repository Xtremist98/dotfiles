#!/bin/bash

# Weather script for Hyprlock
# Requires curl and jq for JSON parsing

# Configuration
CITY="London"  # Change this to your city
API_KEY=""     # Add your OpenWeatherMap API key here or leave empty for wttr.in
UNITS="metric" # metric, imperial, or kelvin
CACHE_FILE="/tmp/hyprlock_weather.cache"
CACHE_DURATION=1800 # 30 minutes in seconds

# Function to get weather using wttr.in (no API key needed)
get_weather_wttr() {
    local response=$(curl -s "wttr.in/$CITY?format=j1" 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$response" ]; then
        # Extract current weather using simple text parsing
        local temp=$(echo "$response" | grep -o '"temp_C":"[^"]*"' | head -1 | cut -d'"' -f4 | sed 's/°C//')
        local condition=$(echo "$response" | grep -o '"weatherDesc":\[{"value":"[^"]*"' | head -1 | cut -d'"' -f6)
        local humidity=$(echo "$response" | grep -o '"humidity":"[^"]*"' | head -1 | cut -d'"' -f4)
        
        if [ -n "$temp" ] && [ -n "$condition" ]; then
            echo "${temp}°C · ${condition}"
            return 0
        fi
    fi
    return 1
}

# Function to get weather using OpenWeatherMap API (requires API key)
get_weather_openweather() {
    if [ -z "$API_KEY" ]; then
        return 1
    fi
    
    local response=$(curl -s "http://api.openweathermap.org/data/2.5/weather?q=$CITY&units=$UNITS&appid=$API_KEY" 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$response" ]; then
        local temp=$(echo "$response" | jq -r '.main.temp' 2>/dev/null)
        local condition=$(echo "$response" | jq -r '.weather[0].description' 2>/dev/null)
        local humidity=$(echo "$response" | jq -r '.main.humidity' 2>/dev/null)
        
        if [ "$temp" != "null" ] && [ "$condition" != "null" ]; then
            if [ "$UNITS" = "metric" ]; then
                echo "${temp}°C · ${condition}"
            elif [ "$UNITS" = "imperial" ]; then
                echo "${temp}°F · ${condition}"
            else
                echo "${temp}K · ${condition}"
            fi
            return 0
        fi
    fi
    return 1
}

# Function to get weather icon
get_weather_icon() {
    local condition=$(echo "$1" | tr '[:upper:]' '[:lower:]')
    
    case "$condition" in
        *clear*|*sunny*) echo "󰖙" ;;
        *cloud*|*overcast*) echo "󰖐" ;;
        *rain*|*drizzle*) echo "󰖖" ;;
        *snow*) echo "󰖘" ;;
        *thunder*|*storm*) echo "󰖓" ;;
        *mist*|*fog*) echo "󰖑" ;;
        *wind*) echo "󰖝" ;;
        *) echo "󰖙" ;;
    esac
}

# Function to check cache
is_cache_valid() {
    if [ -f "$CACHE_FILE" ]; then
        local cache_time=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)
        local current_time=$(date +%s)
        local age=$((current_time - cache_time))
        [ $age -lt $CACHE_DURATION ]
    else
        return 1
    fi
}

# Main function
get_weather() {
    # Check cache first
    if is_cache_valid; then
        cat "$CACHE_FILE"
        return 0
    fi
    
    # Try to get fresh weather data
    local weather_data=""
    
    # Try OpenWeatherMap first if API key is available
    if [ -n "$API_KEY" ]; then
        weather_data=$(get_weather_openweather)
    fi
    
    # Fallback to wttr.in
    if [ -z "$weather_data" ]; then
        weather_data=$(get_weather_wttr)
    fi
    
    # Cache the result if successful
    if [ -n "$weather_data" ]; then
        echo "$weather_data" > "$CACHE_FILE"
        echo "$weather_data"
    else
        # Return cached data if available, even if expired
        if [ -f "$CACHE_FILE" ]; then
            cat "$CACHE_FILE"
        else
            echo "Weather unavailable"
        fi
    fi
}

# Parse arguments
case "$1" in
    --weather)
        get_weather
        ;;
    --icon)
        weather=$(get_weather)
        get_weather_icon "$weather"
        ;;
    --cache-clear)
        rm -f "$CACHE_FILE"
        echo "Weather cache cleared"
        ;;
    *)
        echo "Usage: $0 --weather | --icon | --cache-clear"
        exit 1
        ;;
esac