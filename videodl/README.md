# Video Grabber (videodl)

A Chromium/Brave extension that puts an IDM-style floating download button on
every `<video>` on the page, with real quality selection: **height + codec** for
video, and **stream + format conversion** for audio — plus an Omarchy bar
widget that shows the transfers live.

Downloads are performed by `yt-dlp`, driven by a local native-messaging host.
Nothing is uploaded anywhere; the host only spawns `yt-dlp` on your machine.
**There are no desktop notifications and no OSD popups** — the in-page panel and
the bar panel are the only feedback surfaces.

## Layout

| Path | What it is |
|---|---|
| `extension/` | The unpacked MV3 extension (loaded via `--load-extension`). |
| `host/videodl-host` | Native messaging host. Handles `formats`, `download`, `config`, `setdir`, `pick-dir`, `jobs`, `job-action`, and `--worker <payload.json>`. |
| `native-messaging/com.linuxer.videodl.json` | Host manifest template; `install.sh` rewrites `path` and `allowed_origins` and copies it into every browser profile. |
| `key/` | Signing key + derived extension ID (**`ckoadpikjppjggoenpjgiaoodfhjnclo`**). |
| `install.sh` / `uninstall.sh` | Install / remove. |
| `~/.config/omarchy/plugins/linuxer.videodl/` | The bar widget (`Panel.qml`, `Service.qml`, `JobList.qml`, `JobRow.qml`, `ProgressLine.qml`, `Model.js`). Kept outside this tree so `omarchy` plugin tooling owns it. |
| `~/.local/state/videodl/jobs/*.json` | One JSON file per download — the live state the panel polls. |

The extension ID is pinned by the `"key"` field in `extension/manifest.json`, so
the directory can be moved without breaking `allowed_origins`.

## Install / update

```sh
bash ~/.local/share/videodl/install.sh
```

It is idempotent and does three things:

1. copies the native-host manifest into `NativeMessagingHosts/` of every browser
   profile root that exists — or whose browser binary is installed
   (`chromium`, `google-chrome*`, `BraveSoftware/*`, `microsoft-edge*`);
2. adds `--load-extension=...,<path>/extension` to `~/.config/chromium-flags.conf`
   and `~/.config/brave-origin-flags.conf` (backing them up first, and keeping the
   three stock Omarchy extensions on the same line); the flags file is **created**
   if the browser is installed but has never written one;
3. prints what it changed.

It refuses to run without `python3`/`jq`, and warns (without stopping) when
`yt-dlp`/`ffmpeg`/`ffprobe` are missing, since those are only needed at download
time.

**The flags files are only read at browser start**, so fully quit and reopen the
browser afterwards. Check `chrome://extensions` — "Video Grabber" should be
listed with no errors, alongside Omarchy's `copy-url`, `yt-dlp`, `whatsapp-slim`.

## Usage

Hover a video → click the sage download button (top-right of the player).

* **Video** — pick a height (or *Best available*), then a codec pill
  (`Auto` / only the codecs actually offered at that height).
  Container rule: **mkv** for VP9/AV1/VP8, **mp4** for H.264/HEVC/auto.
* **Audio** — pick *Best audio* (or a specific stream) and, if wanted, a
  **Format**: `Original`, `MP3 320k` (CBR 320), `M4A (AAC)`, `FLAC`.
* **Embedding** — two checkboxes in the sticky footer, both **on by default**:
  *thumbnail* (cover art) and *metadata* (title/artist/date tags). They are
  per-download, applied to every job started from that panel state, and remembered
  in `chrome.storage.local` under `videodl.embed`.
* Keys inside the panel never reach the page: `Escape` closes it and typing in the
  folder field does not type into the site's search box.

If the quality list can't be enumerated (live streams, galleries, some embeds),
the panel falls back to a fixed ladder and says *"Exact quality list unavailable —
the closest match to your pick is used."* The download still works.

## Where files are saved

The bottom row of the in-page panel has a **folder field** and a folder button.

* Type any absolute path — any disk, any mount, anywhere — and press **Set** (or
  `Enter`): `/mnt/media/Videos`, `/run/media/linuxer/MyDrive/Films`, `~/Downloads`
* Or click the **folder button** for a real folder picker (`zenity`, with
  `kdialog` as fallback). It opens rooted at the current folder and saving a
  choice happens immediately; cancelling leaves the setting alone.

`~` and `$VARS` are expanded, the folder is created if missing, and it is
write-probe tested before being accepted, so a typo or a read-only mount is
reported in the panel instead of failing mid-download. If it is not usable the
setting is rejected — nothing silently falls back to another disk.

Precedence (highest first):

1. `VIDEODL_DIR` in the environment — when set, the field is disabled and the
   panel says so.
2. `~/.config/videodl/config.json` → `{"dir": "/your/folder"}` (written by **Set**
   or by the picker).
3. `~/Videos`.

The setting is stored by the native host, not in `chrome.storage`, so it is the
same in Chromium, Brave and every profile, and it survives extension reloads.

## The bar widget

A `linuxer.videodl` entry sits in the right section of the Omarchy bar
(`~/.config/omarchy/shell.json`, colour `color02`) and follows the live theme
accent.

* **Idle** — a plain download glyph.
* **Busy** — a small circular progress ring instead of the glyph.
* **Left-click** — opens the panel below the bar. **Right-click** — forces a
  refresh.
* **Panel** — for every transfer in flight: thumbnail, site, `1080p · h264 ·
  thumb+meta`, one **continuous progress line** (no segment blocks) that tracks
  the real byte count, and a live info line — `38.3/39.4 MB · 2.3 MB/s · 9s left`,
  with elapsed time once it is done.
* **`✓ Finished (N)`** at the bottom of the panel switches the whole panel to the
  files that are no longer in flight. `Esc`, `Enter` or `f` go back; `Escape`
  again closes the panel. `r` refreshes, `c` clears the finished list.

Row actions:

| State | Click the row | Chips |
|---|---|---|
| downloading | — | cancel |
| completed | opens the file in **mpv** (`--force-window=yes --loop=no`), or the file manager for a directory | open / reveal / remove |
| failed, cancelled | — | retry / remove |

`mpv` is used deliberately (overriding the local `mpv.conf`'s `loop=yes`); when
`mpv` is not installed the host falls back to `xdg-open`, and `reveal` always
opens the file manager.

Polling is 2 s while something is active (or while the panel is open) and 20 s
when idle; both are configurable in the widget settings, as is how many finished
entries the list keeps (`0` hides the finished switch entirely).

## Progress, and why the engine is plain yt-dlp

The host runs `yt-dlp` **with `--ignore-config` as its first argument**, so the
user's `~/.config/yt-dlp/config` cannot change a download behind the UI's back.
That config on this machine forces `--downloader aria2c`, `--concurrent-fragments
12`, `-P /mnt/media/`, `-o`, `-f`, `--merge-output-format mkv` and the embed flags
— every one of which would override the panel's choices (and it wrote files into
`/mnt/media`). Everything the download needs is passed explicitly instead.

Parallel fragments are yt-dlp's own `--concurrent-fragments 4`. `aria2c` was
benchmarked on the same 360p H.264 video and was **not faster** (24.4 s vs
24.9 s) while emitting **one** progress tick instead of 28 — with aria2c the bar
would sit still and then jump. Live progress is therefore free.

Progress is folded **cumulatively across streams**: yt-dlp reports video and audio
separately, each from zero, so finished-stream bytes accumulate into a base
instead of resetting the line. `status` stays `downloading` per stream and only
switches to `processing` (muxing/embedding) once post-processing starts. All
sizes and speeds use real byte counts (`B`/`KB`/`MB`), never percentages of an
unknown total.

## Cookies (needed for most YouTube videos)

YouTube now refuses many videos from a "bot"-looking client — `Sign in to confirm
you're not a bot`, or an age/region gate — which no format list can work around.
The host passes `--cookies-from-browser <browser>`, so downloads use the browser
you are already signed in to.

Resolution order:

1. `"cookies"` in `~/.config/videodl/config.json`:
   `"auto"` (default), a browser name, `browser:profile`
   (e.g. `"chromium:Profile 1"`), or `"none"` to disable cookies entirely.
2. `x-scheme-handler/https=` in `~/.config/mimeapps.list`.
3. `chromium`, then `brave`, then `chrome`.

The cookie database is validated first; if it doesn't exist the host logs a
warning and runs without cookies. If yt-dlp still fails on a cookie *read*
problem (locked/keyring database, or `could not find … cookies database`) the job
is retried **once without cookies**. The bot check is deliberately *not* retried
that way — it is not a cookie read failure.

## Fresh Omarchy machine

**1. Dependencies** (`python3` and `jq` are stock; `yt-dlp`/`ffmpeg` usually are too):

```sh
sudo pacman -S --needed yt-dlp ffmpeg jq python zenity mpv
```

`zenity` is only needed for the folder picker, `mpv` only for the "open in mpv"
row click; both are stock on Omarchy.

**2. Restore the tree** to `~/.local/share/videodl` — the copy in `/mnt/media/Dots`
is the archive, and the flags files bake in this absolute path, so don't run it
from a removable drive:

```sh
mkdir -p ~/.local/share
cp -a /mnt/media/Dots/videodl ~/.local/share/videodl          # or, from the tarball:
# tar -xzf /mnt/media/Dots/videodl-1.0.tar.gz -C ~/.local/share
```

**3. Restore the bar widget** (the plugin lives outside the tree above):

```sh
cp -a /mnt/media/Dots/videodl/plugin/linuxer.videodl ~/.config/omarchy/plugins/
```

Then add `{"id": "linuxer.videodl", "color": "color02"}` to `bar.layout.right` in
`~/.config/omarchy/shell.json` — anywhere that keeps the declared
`bar.box.groups` consecutive — and mirror the file to
`~/.config/omarchy/profiles/shell.localbar.json`. `omarchy restart shell` picks it
up.

**4. Install:**

```sh
bash ~/.local/share/videodl/install.sh
```

**5. Fully restart the browser** — flags files are read only at start:

```sh
pkill chromium    # or close every window
```

Then open any video. No sudo is needed at any step; nothing outside `$HOME` is
touched.

The same tree (and the extension ID `ckoadpikjppjggoenpjgiaoodfhjnclo`) works on
another machine without re-signing: the ID comes from `"key"` in
`extension/manifest.json`, and `install.sh` regenerates `allowed_origins` from it.

## Troubleshooting

* `~/.local/state/videodl/host.log` — every host invocation and the full `yt-dlp`
  command line. **Progress ticks are not logged**; watch
  `~/.local/state/videodl/jobs/<id>.json` instead (`done`, `total`, `speed`,
  `eta`, `percent` are rewritten ~2.5×/s).
* `Sign in to confirm you're not a bot` → fix the cookies (above); this is not a
  download-engine problem.
* Host reports `error` → exit code 1 (usually "yt-dlp not found" or a bad URL).
* The native host prepends `/usr/share/omarchy/bin` to `PATH`, because a
  browser-spawned process may not have it.
* Wrong save folder → delete `~/.config/videodl/config.json` (back to `~/Videos`)
  or check `VIDEODL_DIR` in the browser's environment.
* Bar icon missing → `ls ~/.config/omarchy/plugins/linuxer.videodl`, then
  `omarchy restart shell` and check the newest
  `/run/user/1000/quickshell/by-id/*/log.qslog` for `linuxer.videodl`.

## Uninstall

```sh
bash ~/.local/share/videodl/uninstall.sh
```

It removes, in this order, backing up every file it edits:

1. the `com.linuxer.videodl.json` host manifests from every browser profile;
2. this extension's path from the `--load-extension` line of the flags files,
   while leaving Omarchy's three stock extensions alone;
3. the `linuxer.videodl` entry from `bar.layout` in **both**
   `~/.config/omarchy/shell.json` and `~/.config/omarchy/profiles/shell.localbar.json`
   (run `omarchy restart shell` afterwards).

The files in this tree, the plugin directory
`~/.config/omarchy/plugins/linuxer.videodl`, `~/.config/videodl/config.json` and
the job records under `~/.local/state/videodl/` are all **kept** — the script
prints them so you can delete them by hand. `./install.sh` restores the browser
wiring; put the bar entry back with the step in *Fresh Omarchy machine* below.

## Notes

* Firefox-family browsers are not supported.
* Stock Omarchy files (`/usr/bin/omarchy-chromium-ytdlp-host`,
  `/usr/share/omarchy/default/chromium/extensions/yt-dlp`) are never modified.
* `sendNativeMessage` spawns one host process per message and it must exit after
  replying. The actual download runs in a **detached** `--worker` process, so the
  reply is `{ok: true, queued: true, id, mode, dir}`; each worker writes only its
  own `jobs/<id>.json`, so there is no locking.
* Job records are pruned to the newest 60 on every `--jobs` call.
