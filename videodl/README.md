# Video Grabber (videodl)

A Chromium/Brave extension that puts an IDM-style floating download button on
every `<video>` on the page, with real quality selection: **height + codec** for
video, and **stream + format conversion** for audio.

Downloads are performed by `yt-dlp`, driven by a local native-messaging host.
Nothing is uploaded anywhere; the host only spawns `yt-dlp` on your machine.

## Layout

| Path | What it is |
|---|---|
| `extension/` | The unpacked MV3 extension (loaded via `--load-extension`). |
| `host/videodl-host` | Native messaging host. Handles `formats`, `download`, and `--worker <payload.json>`. |
| `native-messaging/com.linuxer.videodl.json` | Host manifest template; `install.sh` rewrites `path` and `allowed_origins` and copies it into every browser profile. |
| `key/` | Signing key + derived extension ID (**`ckoadpikjppjggoenpjgiaoodfhjnclo`**). |
| `install.sh` / `uninstall.sh` | Install / remove. |

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

Progress and completion are shown via `omarchy-osd` / `omarchy-notification-send`.

## Where files are saved

The bottom row of the panel has a **folder field**. Type any absolute path — any
disk, any mount, anywhere — and press **Set** (or `Enter`):

    /mnt/media/Videos        /run/media/linuxer/MyDrive/Films        ~/Downloads

`~` and `$VARS` are expanded, the folder is created if missing, and it is
write-probe tested before being accepted, so a typo or a read-only mount is
reported in the panel instead of failing mid-download. If it is not usable the
setting is rejected — nothing silently falls back to another disk.

Precedence (highest first):

1. `VIDEODL_DIR` in the environment — when set, the field is disabled and the
   panel says so.
2. `~/.config/videodl/config.json` → `{"dir": "/your/folder"}` (written by **Set**).
3. `~/Videos`.

The setting is stored by the native host, not in `chrome.storage`, so it is the
same in Chromium, Brave and every profile, and it survives extension reloads.

If the quality list can't be enumerated (live streams, galleries, some embeds),
the panel falls back to a fixed ladder and says *"Exact quality list unavailable
— the closest match to your pick is used."* The download still works.

## Fresh Omarchy machine

Nothing here is Omarchy-specific except `omarchy-osd` / `omarchy-notification-send`
(used for progress) and the stock `--load-extension` extensions — so a stock
Omarchy install is the target, and `chrome://extensions` will show the extension
beside Omarchy's own.

**1. Dependencies** (`python3` and `jq` are stock; `yt-dlp`/`ffmpeg` usually are too):

```sh
sudo pacman -S --needed yt-dlp ffmpeg jq python
```

**2. Restore the tree** to `~/.local/share/videodl` — the copy in `/mnt/media/Dots`
is the archive, and the flags files bake in this absolute path, so don't run it
from a removable drive:

```sh
mkdir -p ~/.local/share
cp -a /mnt/media/Dots/videodl ~/.local/share/videodl          # or, from the tarball:
# tar -xzf /mnt/media/Dots/videodl-1.0.tar.gz -C ~/.local/share
```

**3. Install:**

```sh
bash ~/.local/share/videodl/install.sh
```

**4. Fully restart the browser** — flags files are read only at start:

```sh
pkill chromium    # or close every window
```

Then open any video. No sudo is needed at any step; nothing outside `$HOME` is
touched.

The same tree (and the extension ID `ckoadpikjppjggoenpjgiaoodfhjnclo`) works on
another machine without re-signing: the ID comes from `"key"` in
`extension/manifest.json`, and `install.sh` regenerates `allowed_origins` from it.

## Troubleshooting

* `~/.local/state/videodl/host.log` — every host invocation and full `yt-dlp`
  command line.
* Host reports `error` → exit code 1 (usually "yt-dlp not found" or a bad URL).
* The native host prepends `/usr/share/omarchy/bin` to `PATH`, because a
  browser-spawned process may not have it.
* Wrong save folder → delete `~/.config/videodl/config.json` (back to `~/Videos`)
  or check `VIDEODL_DIR` in the browser's environment.

## Uninstall

```sh
bash ~/.local/share/videodl/uninstall.sh
```

Removes the `--load-extension` entry from the flags files and deletes the host
manifests. The extension directory itself stays on disk; delete it if you want.

## Notes

* Firefox-family browsers are not supported.
* Stock Omarchy files (`/usr/bin/omarchy-chromium-ytdlp-host`,
  `/usr/share/omarchy/default/chromium/extensions/yt-dlp`) are never modified.
* `sendNativeMessage` spawns one host process per message and it must exit after
  replying. The actual download runs in a **detached** `--worker` process, so the
  reply is `{ok: true, queued: true}` and the UI polls nothing.
