# mpv — hikari mode

Backup of `~/.config/mpv` after installing hikari 0.12.0, with the personal
customisations merged back in (Espressuccin palette, slim timeline, smaller
controls/top bar, Noto Sans OSD font, volume settings, default directory
`/mnt/media/Music-Video`, skip-button margin, ...).

Local patch: `scripts/uosc/lib/cursor.lua` re-arms cursor autohide and clears
uosc's held visibility shortly after each `file-loaded`, so the bar fades
again after hikari's next-episode button. A hikari update will overwrite this
patch — reapply from this backup.

## Restore

    cp -a /mnt/media/Dots/mpv-hikari/. ~/.config/mpv/

## Pre-hikari mode

The previous (pre-hikari) configuration is kept in `/mnt/media/Dots/mpv/`.

Switch back with:

    cp -a /mnt/media/Dots/mpv/. ~/.config/mpv/
