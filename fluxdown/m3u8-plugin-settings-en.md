# M3U8 Plugin — English Settings Guide

Plugin: **M3U8 发现与变体解析器** (M3U8 Discovery & Variant Resolver) v3.0.0
Location: FluxDown → Settings → Extensions → Plugins → M3U8 → gear icon

The plugin ships only Chinese labels. This is a local English reference; it does not change the plugin.

---

## Most important settings (the ones visible at the top)

### Site · Effective scope — `站点 · 生效范围`
- **What it is:** Comma-separated hostnames where the plugin may parse **playback pages**.
- **Format:** `example.com` or `example.com, video.example.org`
- **Do not include:** `https://`, paths, or wildcards. A bare domain also covers its subdomains.
- **For playback pages this is required.** Direct `.m3u8` / `.mpd` links are always processed even when this is empty.
- **Important:** The Chinese helper text in the dialog says “leave blank = all sites”, but v3.0.0 actually treats blank as **no playback pages**. Use an explicit domain list for page URLs.

### Site · Login credentials — `站点 · 登录凭据`
- **What it is:** Cookie / token / headers for sites that require login.
- **When to use:** The site shows a login page or returns HTML/403 instead of an m3u8.
- **Supported formats:**
  - Raw Cookie: `SID=abc123; token=ef456`
  - `bearer:YOUR_TOKEN`
  - `basic:USERNAME:PASSWORD`
  - Multiple header lines: `Key: Value` (one per line)
- **Optional first line:** `@example.com` limits the credential to that exact host. Use `@*.example.com` to include subdomains. Without it, the “Site · Effective scope” list is used.
- **Easy way:** Click **“复制取 Cookie 的脚本”** (Copy Cookie script), paste it into the browser DevTools console on the site, then paste the result back here.
- **Safety:** Credentials are only sent to requests with the exact same origin as the task URL.

### Automatically pass “security check” pages — `自动过「安全检查」页`
- **Default:** ON
- **What it does:** If the site returns an anti-bot “security check” interstitial, the plugin tries to extract the Cookie and retries the same URL once.
- **Recommendation:** Leave ON. If it cannot solve the challenge, it falls back to the normal behavior.

### Follow embedded player — `跟随内嵌播放器`
- **Default:** ON
- **What it does:** If the page has no m3u8, follow an embedded `iframe` player and search there.
- **Recommendation:** Leave ON. If the player is nested several levels deep, increase **Max iframe depth** to 2 or 3.

### Detect DASH manifest — `识别 DASH 清单`
- **Default:** ON
- **What it does:** If the page has no m3u8 but has an `.mpd` DASH manifest, pass that URL to FluxDown's DASH engine.
- **Recommendation:** Leave ON. m3u8 is still preferred when both exist.

---

## Other switches (defaults are fine for most people)

| English | Chinese label | Default | Meaning / recommendation |
|---|---|---|---|
| Detect series pages | 识别剧集页 | ON | Multi-episode pages show an episode picker instead of downloading only the current episode. Leave ON unless it misdetects single videos. |
| Use yt-dlp fallback for HTML | 抓到网页时用 yt-dlp 兜底 | ON | If the plugin receives an HTML page instead of a playlist, try yt-dlp. Requires yt-dlp installed. |
| Auto-pick highest quality | 自动选最高画质 | OFF | ON = download immediately using the preferred quality/codec, no quality dialog. OFF = show the quality picker each time. |
| Hand complex sites to yt-dlp | 复杂站点交给 yt-dlp | OFF | Use only when the built-in parser fails. Requires yt-dlp installed. |
| Audio only | 只要音频 | OFF | Download only a separate audio track. Fails clearly if the source has no separate audio track. |
| Remux to MP4 | 转成 MP4 | ON | Losslessly remux when the container is non-standard. Slightly slower, usually safe. |
| Plugin fallback when muxing fails | 合并失败时插件兜底 | ON | If FluxDown fails to merge separate audio/video tracks, retry with ffmpeg. |
| Ephemeral signed URL | 一次性签名链接 | OFF | Skip metadata probing and download immediately. Use only for short-lived signed URLs. |
| Ad filtering mode | 去广告 · 模式 | OFF | OFF / markers only (conservative) / markers + heuristics (aggressive). Only affects HLS tasks parsed by this plugin. |

---

## Quality and audio

| English | Chinese label | Default | Meaning |
|---|---|---|---|
| Preferred quality | 画质 · 档位 | `best` | Default quality: best / 1080p / 720p / 480p / 360p. It only preselects; it does not hide other qualities. |
| Preferred codec | 画质 · 编码偏好 | `auto` | auto / H.264 (AVC) / H.265 (HEVC) / AV1 / VP9. Preference only; falls back if unavailable. |
| Separate audio track | 音轨 · 独立音轨 | `auto` | auto / always separate / off. `auto` separates only when the source clearly has a separate audio track. |
| Audio language | 音轨 · 语言 | empty | e.g. `zh`, `zh-CN`, `ja`, `en`. Empty = use the source's default/autoselect track. |

---

## Naming, network, parsing

| English | Chinese label | Default | Meaning |
|---|---|---|---|
| File name template | 命名 · 文件名模板 | `{title} {host}` | Placeholders: `{title}`, `{res}`, `{lang}`, `{host}`, `{date}`. Use `{title}` alone to omit the domain suffix. |
| User-Agent | 网络 · User-Agent | empty | Empty = FluxDown default. Some sites return different qualities based on UA. |
| Extra request headers | 网络 · 额外请求头 | empty | One `Key: Value` per line. `#` starts a comment. Overrides the plugin's automatic Referer/Origin if the name matches. |
| Max iframe depth | 解析 · 内嵌最多跟进几层 | 1 | 1–3. Increase only when the player is nested in multiple iframes. |
| Series · minimum items | 剧集 · 最少条目 | 3 | Minimum link-cluster size before a page is treated as a series. 2–50. |
| Series · picker limit | 剧集 · 选集上限 | 200 | Maximum episodes listed in the picker. 1–1000. |
| Series · link regex | 剧集 · 链接正则 | empty | Optional custom regex (no surrounding slashes) for what counts as an episode. Empty = built-in rules. |
| Download · Range cap | 下载 · Range 上限 | 0 | KiB per request. 0 = unlimited. Set e.g. `4096` only for CDNs that return 403 when a single request is too large. |

---

## Ads (leave off unless needed)

| English | Chinese label | Default | Meaning |
|---|---|---|---|
| Ad filtering mode | 去广告 · 模式 | OFF | OFF / markers only / markers + heuristics. Applies only to HLS tasks parsed by this plugin. |
| Ad filtering custom rules | 去广告 · 自定义规则 | empty | JSON, e.g. `{"dropPath":["/ads/","/preroll/"],"dropHosts":["ads.example.com"]}`. Usually leave empty. |

---

## Recommended setup

1. Put the domain(s) of the site you download from into **Site · Effective scope**.
2. Leave all other settings at their defaults.
3. If the site requires login, fill **Site · Login credentials** using the “Copy Cookie script” button.
4. If you do not want a quality popup for every download, turn ON **Auto-pick highest quality**.
5. If a specific site fails with the built-in parser, try **Hand complex sites to yt-dlp** (after installing yt-dlp).
6. For series, the defaults are fine; the episode picker appears only when the page has strong multi-episode signals.

---

## Quick troubleshooting

- **Pasted a playback page but nothing happens:** Add that site's domain to **Site · Effective scope**. Blank only works for direct `.m3u8`/`.mpd` links.
- **Login page / HTML downloaded instead of video:** Fill **Site · Login credentials**; optionally set a desktop **User-Agent**.
- **Quality popup every time:** Turn ON **Auto-pick highest quality**.
- **No audio after downloading:** Leave **Separate audio track** on `auto`; for sources with separate tracks, the core should merge them.
- **403 from a CDN:** Set **Download · Range cap** to e.g. `4096` (KiB).
- **Anti-bot check page:** Keep **Automatically pass “security check” pages** ON. CAPTCHA/fingerprint pages cannot be solved by the plugin.
