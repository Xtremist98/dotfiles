#!/usr/bin/env python
import json
import requests
from datetime import datetime
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

# ==============================================================================
#  CONFIGURATION 
# ==============================================================================
CITY = "Dubai"
UNITS = "m" 
# "m" for Metric, "u" for US/Imperial
# ==============================================================================

WEATHER_CODES = {
    '113': '☀️', '116': '⛅', '119': '☁️', '122': '☁️', '143': '🌫', '176': '🌦', '179': '🌧', '182': '🌧', 
    '185': '🌧', '200': '⛈', '227': '🌨', '230': '❄️', '248': '🌫', '260': '🌫', '263': '🌦', '266': '🌦', 
    '281': '🌧', '284': '🌧', '293': '🌦', '296': '🌦', '299': '🌧', '302': '🌧', '305': '🌧', '308': '🌧', 
    '311': '🌧', '314': '🌧', '317': '🌧', '320': '🌨', '323': '🌨', '326': '🌨', '329': '❄️', '332': '❄️', 
    '335': '❄️', '338': '❄️', '350': '🌧', '353': '🌦', '356': '🌧', '359': '🌧', '362': '🌧', '365': '🌧', 
    '368': '🌨', '371': '❄️', '374': '🌧', '377': '🌧', '386': '⛈', '389': '🌩', '392': '⛈', '395': '❄️'
}

def get_progress_bar(percent, length=10):
    try:
        p = int(percent)
        filled = int(length * p / 100)
        bar = "■" * filled + "□" * (length - filled)
        return bar
    except:
        return "□" * length

def format_time(time_str):
    try:
        hour = int(time_str) // 100
        suffix = "AM" if hour < 12 else "PM"
        display_hour = hour % 12
        if display_hour == 0: display_hour = 12
        return f"{display_hour:02d}:00 {suffix}"
    except:
        return time_str

def get_weather():
    data = {}
    try:
        session = requests.Session()
        retry = Retry(total=3, backoff_factor=1, status_forcelist=[500, 502, 503, 504])
        session.mount('https://', HTTPAdapter(max_retries=retry))

        query_city = CITY.replace(" ", "+")
        # Increased timeout to 20s to prevent ReadTimeoutError
        response = session.get(f"https://wttr.in/{query_city}?format=j1&{UNITS}", timeout=20)
        weather = response.json()
        
        nearest_area = weather['nearest_area'][0]
        city_name = nearest_area['areaName'][0]['value']
        country_name = nearest_area['country'][0]['value']
        
        current = weather['current_condition'][0]
        temp = current['temp_C']
        desc = current['weatherDesc'][0]['value']
        code = current['weatherCode']
        humidity = current['humidity']
        unit_label = "°C"
        
        # UI Colors matched to your Waybar theme
        # Border: #788587, Text: #dcd6d6, Accent: #85abbc
        tt = "<b><span color='#85abbc'>╔════════ METEOROLOGICAL DATA ════════╗</span></b>\n"
        tt += f"<b><span color='#85abbc'>║ LOCATION</span></b>   <span color='#dcd6d6'>{city_name.upper()}, {country_name.upper()}</span>\n"
        tt += f"<b><span color='#85abbc'>║ STATUS</span></b>     <span color='#dcd6d6'>{desc}</span>\n"
        tt += f"<b><span color='#85abbc'>║ TEMP</span></b>       <span color='#85abbc'>{temp}{unit_label}</span> <span color='#788587'>(Feels: {current['FeelsLikeC']}{unit_label})</span>\n"
        tt += f"<b><span color='#85abbc'>║ HUMIDITY</span></b>   <span color='#39515A'>[{get_progress_bar(humidity)}]</span> <span color='#dcd6d6'>{humidity}%</span>\n"
        tt += "<b><span color='#788587'>╠═════════════════════════════════════╣</span></b>\n"
        
        tt += "<b><span color='#85abbc'>║ 24-HOUR TRAJECTORY                  ║</span></b>\n"
        hourly_data = []
        for day in weather['weather'][:2]: 
            for hour in day['hourly']:
                hourly_data.append(hour)
        
        for hour in hourly_data[:4]:
            h_time = format_time(hour['time'])
            h_icon = WEATHER_CODES.get(hour['weatherCode'], '✨')
            h_temp = f"{hour['tempC']}{unit_label}"
            h_rain = f"{hour['chanceofrain']}%"
            tt += f"<b><span color='#788587'>║</span></b> <span color='#dcd6d6'>{h_time:<9}</span> {h_icon} <span color='#85abbc'>{h_temp:<4}</span> <span color='#85abbc'>󰖗 {h_rain:>3}</span>\n"

        tt += "<b><span color='#788587'>╚═════════════════════════════════════╝</span></b>"

        data['text'] = f"{WEATHER_CODES.get(code, '✨')} {temp}{unit_label}"
        data['tooltip'] = tt
        
    except Exception as e:
        data['text'] = " "
        data['tooltip'] = f"<span color='#f38ba8'><b>Error:</b></span> {str(e)}"

    return data

if __name__ == "__main__":
    print(json.dumps(get_weather()))
