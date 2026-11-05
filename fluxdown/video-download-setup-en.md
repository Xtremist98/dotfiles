# FluxDown Video Download Setup — English Guide

Configured: 2026-11-05

This file explains the video-download setup in plain English. It does not change anything; it is a reference.

---

## What is configured

### YouTube Down plugin (enabled)

- **Quality:** Best available — no quality popup for normal videos.
- **Codec:** Compatibility first — H.264 video + AAC audio in MP4 when the source offers them. Higher resolutions may fall back to VP9/AV1 because YouTube does not always provide H.264 there.
- **Browser cookies:** ON. Downloads started from the FluxDown browser extension automatically carry your YouTube cookies.
- **Fallback cookie:** empty. Fill this only if you need app-pasted links to work for age-restricted / members-only / bot-checked videos.
- **Playlist limit:** 200 entries.
- **Player clients:** `web_embedded, tv_downgraded, tv, tv_samsung, visionos` — this combination passed the YouTube bot check in testing.

### M3U8 plugin (enabled)

- **Auto-pick highest quality:** ON — no quality popup.
- **Preferred quality:** Best.
- **Preferred codec:** H.264 / AVC — falls back to HEVC/AV1/VP9 if H.264 is not offered.
- **Site scope:** a broad list of common video, social, news, learning, Chinese video, anime, sports, and HLS-player domains. Direct `.m3u8` / `.mpd` links work even if the site is not in the list.
- **yt-dlp fallback for HTML pages:** ON — used only when the plugin receives a web page instead of a playlist.
- **Hand complex sites to yt-dlp:** OFF — the native parser is used first because it respects quality/codec settings better.
- **DASH detection, embedded-player following, security-check handling, remux, merge fallback:** ON.
- **Ad filtering:** OFF.

### Resolver preference

YouTube URLs (including Shorts, live replays, playlists, `youtu.be`, YouTube Music, and embedded YouTube) are routed to the **YouTube Down** plugin first. Other sites use the **M3U8** plugin. This prevents the plugin-choice popup on YouTube links.

---

## How to download

### YouTube

Paste the YouTube URL into FluxDown, or use the FluxDown browser extension while the video is playing.

- Best quality is selected automatically.
- MP4 / H.264 is preferred for compatibility.
- Playlists are limited to 200 entries.
- If YouTube shows “Sign in to confirm you’re not a bot”, use the browser extension on the YouTube page — it carries your login cookies. App-pasted links can also work if you fill the fallback cookie in the plugin settings.

### Direct HLS / DASH links

Paste a `.m3u8` or `.mpd` URL. The M3U8 plugin always handles direct manifest links, even when the host is not in the site list.

### Other video sites

1. If the site is in the M3U8 site list, paste the video page URL.
2. If it is not in the list, open the page in Chromium, start the video, and use the FluxDown extension’s **“Download the playing video or audio”** command or the side panel. The extension captures the actual media URL, so the M3U8 site list does not limit it.

### Browser extension

The FluxDown extension is installed in Chromium and its native messaging host is connected. It can:

- Intercept normal browser downloads and send them to FluxDown.
- Detect the video/audio currently playing on a page.
- Send YouTube pages to the YouTube Down plugin with your cookies.

---

## Important limits

- **DRM-protected services cannot be downloaded.** This includes Netflix, Disney+, Prime Video, HBO Max, Apple TV+, Spotify, and similar services. The plugin cannot and will not bypass DRM.
- **Paid or login-only content requires your own authorized cookie.** Use only accounts and content you have permission to access.
- **Age-restricted, members-only, and private videos** need a logged-in cookie with access.
- **Live streams that have not ended** cannot be downloaded. Post-live replays may work after YouTube finishes processing them.
- **Some sites use blob/MSE or proprietary players.** Use the browser extension’s “playing video” capture for those.
- **“Every video on the web” is not technically achievable.** This setup covers YouTube, direct HLS/DASH, and many common video sites, but site-specific extraction and DRM set hard limits.
- Only download content you have the right to download.

---

## YouTube plugin settings — English names

Location: FluxDown → Settings → Extensions → Plugins → YouTube Down → gear icon.

| Chinese label | English | Current value |
|---|---|---|
| 清晰度 | Quality | 最高画质 (Best) |
| 编码偏好 | Codec preference | 兼容优先 (Compatibility / H.264 MP4) |
| 使用浏览器传来的 Cookie | Use cookies from the browser | ON |
| 备用 Cookie | Fallback cookie | Empty |
| 播放列表最多条目 | Playlist item limit | 200 |
| 播放器客户端（高级） | Player clients (advanced) | `web_embedded,tv_downgraded,tv,tv_samsung,visionos` |

To change quality later, choose one of:

- 每次询问 = Ask every time (quality popup)
- 最高画质 = Best
- ≤ 2160p / 1440p / 1080p / 720p / 480p / 360p = cap at that height
- 仅音频 = Audio only

---

## M3U8 plugin settings — English reference

The full 27-setting translation is here:

`~/.config/fluxdown/m3u8-plugin-settings-en.md`

Key current values:

| Chinese label | English | Current value |
|---|---|---|
| 站点 · 生效范围 | Site · Effective scope | Broad site list (see plugin settings) |
| 自动选最高画质 | Auto-pick highest quality | ON |
| 画质 · 档位 | Preferred quality | 最高码率 (Best) |
| 画质 · 编码偏好 | Preferred codec | H.264 / AVC |
| 抓到网页时用 yt-dlp 兜底 | yt-dlp fallback for HTML | ON |
| 复杂站点交给 yt-dlp | Hand complex sites to yt-dlp | OFF |
| 只要音频 | Audio only | OFF |
| 转成 MP4 | Remux to MP4 | ON |
| 合并失败时插件兜底 | Plugin fallback when muxing fails | ON |
| 去广告 · 模式 | Ad filtering mode | OFF |

**Site · Effective scope:** add domains as a comma-separated list, for example:

```text
example.com, video.example.org
```

A bare domain also covers its subdomains. Do not include `https://`, paths, or wildcards. Direct `.m3u8` / `.mpd` links do not need to be added.

---

## Verification performed

- **YouTube:** `Me at the zoo` resolved through `fluxdown@youtube-down`, produced `Me at the zoo.mp4`, selected 240p H.264 (the source maximum), and started downloading. The test task was deleted afterwards.
- **HLS:** `https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8` resolved through `m3u8-resolver@cocolight`, found 5 quality variants, selected FHD H.264, and started downloading 64 segments. The test task was deleted afterwards.
- Existing downloads were not paused, deleted, or modified.
