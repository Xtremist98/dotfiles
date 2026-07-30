#!/usr/bin/env python3
import psutil
import json
import shutil
import os

def fmt(bytes_val):
    for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
        if bytes_val < 1024:
            return f"{bytes_val:.1f}{unit}"
        bytes_val /= 1024

def get_progress_bar(percent, length=10):
    filled = int(length * percent / 100)
    bar = "■" * filled + "□" * (length - filled)
    return bar

def get_sys_info():
    cpu_usage = psutil.cpu_percent(interval=1)
    cpu_percent = int(cpu_usage)

    mem = psutil.virtual_memory()
    swap = psutil.swap_memory()

    disk = shutil.disk_usage('/')
    disk_percent = (disk.used / disk.total) * 100

    processes = []
    for proc in psutil.process_iter(['name', 'memory_info']):
        try:
            processes.append((proc.info['name'], proc.info['memory_info'].rss))
        except:
            pass
    top_apps = sorted(processes, key=lambda x: x[1], reverse=True)[:8]

    tt = "<html><body><pre>\n"
    tt += "<font color='#cba6f7'>╔════════ SYSTEM DIAGNOSTICS ════════╗</font>\n"
    tt += f"<font color='#f38ba8'>║ CPU    </font><font color='#45475a'>[{get_progress_bar(cpu_percent)}]</font><font color='#cdd6f4'> {cpu_percent}%</font>\n"
    tt += f"<font color='#a6e3a1'>║ MEMORY </font><font color='#45475a'>[{get_progress_bar(mem.percent)}]</font><font color='#cdd6f4'> {int(mem.percent)}%</font>\n"
    tt += f"<font color='#a6e3a1'>║</font><font color='#cdd6f4'> Used: {fmt(mem.used):<8}</font><font color='#6c7086'> │</font><font color='#cdd6f4'> Free: {fmt(mem.available)}</font>\n"
    tt += f"<font color='#fab387'>║ SWAP   </font><font color='#45475a'>[{get_progress_bar(swap.percent)}]</font><font color='#cdd6f4'> {int(swap.percent)}%</font>\n"
    tt += f"<font color='#89b4fa'>║ DISK   </font><font color='#45475a'>[{get_progress_bar(disk_percent)}]</font><font color='#cdd6f4'> {int(disk_percent)}%</font>\n"
    tt += f"<font color='#89b4fa'>║</font><font color='#cdd6f4'> Used: {fmt(disk.used):<8}</font><font color='#6c7086'> │</font><font color='#cdd6f4'> Total: {fmt(disk.total)}</font>\n"
    tt += "<font color='#cba6f7'>╠════════════════════════════════════╣</font>\n"
    tt += "<font color='#f9e2af'>║ ACTIVE TASKS                       ║</font>\n"
    for name, rss in top_apps:
        dots = "." * (20 - len(name[:15]))
        tt += f"<font color='#cba6f7'>║</font><font color='#cdd6f4'> {name[:15].upper()}</font><font color='#45475a'> {dots}</font><font color='#f5c2e7'> {fmt(rss):>8}</font>\n"
    tt += "<font color='#cba6f7'>╚════════════════════════════════════╝</font>\n"
    uptime = os.popen("uptime -p").read().replace("up ", "").strip()
    tt += f"<font color='#94e2d5'><b>UPTIME:</b> {uptime}</font>\n"
    tt += "</pre></body></html>"

    bar_text = (
        f"<html><font color='#f38ba8'>󰻠</font> {cpu_percent}%  "
        f"<font color='#a6e3a1'>󰍛</font> {int(mem.percent)}%"
    )

    return json.dumps({"text": bar_text, "tooltip": tt})

if __name__ == "__main__":
    print(get_sys_info())
