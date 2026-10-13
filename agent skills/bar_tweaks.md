# Bar height tweaks (Omarchy 4.0 / Quickshell)

How to make the bar taller or shorter on this machine, and how to verify it.

Verified against Omarchy `4.0.0.r6713.ga85e29a-1`, Quickshell `0.3.1`.

---

## How the bar gets its height

The bar is not its own program — it's QML loaded into the long-running
`omarchy-shell` Quickshell process. Size flows through four hops:

| # | Where | What |
|---|-------|------|
| 1 | `~/.config/omarchy/plugins/mihai.bar/Bar.qml:561` | `barSize` — the single value every widget reads |
| 2 | `/usr/share/omarchy/shell/Commons/Style.qml:343` | `Style.bar.sizeHorizontal = barToken("size-horizontal", 26)` |
| 3 | `Style.qml:297` | `barToken()` — reads `barOverrides`, then multiplies by `fontScale` |
| 4 | `Commons/Color.qml:210` | `mergeShell()` — `~/.config/omarchy/shell.toml` keys override theme keys |

`barSize` is injected into every widget as `bar.barSize`, which is why changing
it resizes the bar and its contents together (see `Ui/BarWidget.qml:23`).

### Current values on this machine

- Active theme is **Alpine Marmot**, which ships **no `shell.toml`** — so every
  `Style` token falls back to the hardcoded default in `Style.qml`.
- `~/.config/omarchy/shell.toml` contains only:

  ```toml
  [font]
  base-size = 14
  ```

- `fontScale = 14 / 12 = 1.1667`, and `scale-with-font` defaults to `true`.

So the *stock* bar height would resolve to `round(26 × 1.1667)` = **30px** — but
`mihai.bar` overrides it to a flat **50px**, which is why the stock number no
longer describes what you see.

> Trap: `~/.config/omarchy/themes/0xleovision/shell.toml` is a large commented
> reference file with `[bar]`, `[font]`, and `[spacing]` sections all documented
> in it. That theme is **not active**, so none of those keys are in effect.
> Read it as key-name documentation only.

---

## Option A — `shell.toml` (no clone, preferred for pure sizing)

The supported path. Survives `omarchy update` and theme switches, and there is
nothing to hand-merge later.

```bash
nvim ~/.config/omarchy/shell.toml
```

```toml
[font]
base-size = 14

[bar]
# Set this to false or your number gets multiplied by fontScale (14/12),
# so 50 would render as 58px.
scale-with-font = false
size-horizontal = 50
```

Then:

```bash
omarchy restart shell
```

Only `size-horizontal` and `size-vertical` are honoured from `[bar]`; the other
`Style.bar.*` tokens (`icon-slot`, `icon-canvas`, `icon-font`, `status-slot`)
are parsed but not overridable this way.

Use Option A when you only want the bar bigger or smaller. **This machine
does not use Option A for height** — `mihai.bar` pins the height instead, which
is why no `[bar]` section appears in `shell.toml`. See "Text and icon size"
below for why height and text are set through different files here.

---

## Option B — clone `omarchy.bar` (for anything the tokens can't express)

Use this when you need to change bar *behaviour* or layout code, not just a
size. This machine has already done this — `mihai.bar` is the active bar.

### 1. Clone

```bash
omarchy plugin clone omarchy.bar
```

This:

- copies `/usr/share/omarchy/shell/plugins/bar/` to
  `~/.config/omarchy/plugins/mihai.bar/` (dereferencing symlinks with `cp -aL`)
- rewrites `manifest.json`: `id` → `mihai.bar`, `name` → `"My Bar"`, and adds
  `"omarchy": { "clonedFrom": "omarchy.bar" }`
- runs `omarchy shell shell rescanPlugins`
- runs `omarchy plugin enable mihai.bar`, which writes `"id": "mihai.bar"` into
  `.bar` in `~/.config/omarchy/shell.json`

`omarchy.bar` stays installed but goes inactive — nothing is deleted, so this
is reversible.

Confirm which bar is live:

```bash
omarchy plugin list --json | jq '.[] | select(.id | test("bar"))'
```

`mihai.bar` should show `"enabled": true, "active": true, "clonedFrom":
"omarchy.bar"`, and `omarchy.bar` `"active": false`.

### 2. Edit the size

`~/.config/omarchy/plugins/mihai.bar/Bar.qml`, around line 555:

```qml
readonly property bool vertical: position === "left" || position === "right"

// Local bar sizing override. Replaces the Style.bar.* tokens with fixed
// pixel values so the bar can be resized without touching the shared Style
// singleton (which every menu, panel, and overlay also reads). Vertical bars
// are left on the stock token.
readonly property int horizontalSizeOverride: 50
readonly property int barSize: vertical ? Style.bar.sizeVertical : horizontalSizeOverride
```

Also in `Bar.qml` (~line 1506), the drag-preview slab was switched from the
stock token to `root.barSize` so the ghost matches the real bar while dragging
it to another edge:

```qml
readonly property int edgeSize: root.barSize
```

### 3. Validate, restart, verify

```bash
omarchy plugin validate ~/.config/omarchy/plugins/mihai.bar
omarchy restart shell
hyprctl layers | grep omarchy-bar
```

Expected: `xywh: 1920 0 1920 50`. The fourth number is the height.

### 4. Increase / decrease

It is the same one-line edit in both directions — change
`horizontalSizeOverride` and restart. Values used on this machine:

| `horizontalSizeOverride` | Observed bar height |
|---|---|
| *(stock, unmodified, at base-size 11)* | 24px |
| *(stock value, at base-size 14)* | 30px |
| 28 | 28px |
| 32 | 32px |
| 50 | 50px |

Roughly 20px is the practical floor before widget content starts clipping.

Note the stock row: the clone is what decouples height from text size. Without
it, raising `base-size` would drag the bar height along with it.

---

## Text and icon size

Bar height and bar **text** are set in two different places, deliberately.

- **Height** → `horizontalSizeOverride` in the cloned `Bar.qml`. A flat pixel
  value, immune to font changes.
- **Text and icons** → `[font] base-size` in `~/.config/omarchy/shell.toml`.

Bar labels default to `Style.font.body` (`Ui/WidgetButton.qml:10`), which *is*
`base-size` (`Style.qml:330`). Every token derives from it:

| Token | at base-size 11 | at base-size 14 |
|---|---|---|
| `body` (most bar labels) | 11px | **14px** |
| `body-small` | 10px | 13px |
| `caption` | 9px | 12px |
| `title` / `icon` | 13px | 16px |
| `bar.iconCanvas` | 15px | 19px |
| `bar.iconSlot` | 25px | 32px |

```toml
# ~/.config/omarchy/shell.toml
[font]
base-size = 14
```

```bash
omarchy restart shell
```

### Why not bar-only text?

`Style.font.*` is one global scale shared by bar labels, popout panels, the
launcher, OSD, notifications, and menus. There is no per-surface font context,
so `base-size` moves all of them together. Restricting the change to bar text
alone would mean cloning every widget that renders text — clock, weather,
tray, audio, network, bluetooth, power, monitor — roughly ten plugins, each one
needing hand-merges after `omarchy update`. Not worth it.

### Raising base-size also fixes the icons

`barToken()` multiplies by `fontScale` too, so the icon tokens scale with the
font. That is the cheap fix for the sparse-icons problem described in Caveats:
raise `base-size` instead of hardcoding icon sizes.

### Pinning individual tokens instead

To change one step of the ramp without touching the rest, pin it — the keys are
the token names in kebab-case, in px:

```toml
[font]
base-size = 14
body = 16        # bar labels only, headings untouched
caption = 11
```

Per-token values are not clamped beyond a 1px floor, so large values are
allowed.

---

## `omarchy restart shell` is mandatory

**`omarchy shell shell rescanPlugins` is not enough.** It re-reads
`manifest.json` files only. It will happily report success while an edited
`Bar.qml` sits unloaded — this was confirmed: after editing to 32px and
rescanning, `hyprctl layers` still reported the old 24px. Only
`omarchy restart shell` reloaded it. The bar blinks and open menus close.

---

## Verifying

```bash
hyprctl layers | grep omarchy-bar
# Layer 5607...: xywh: 1920 0 1920 50, a: 1, namespace: omarchy-bar, pid: 197270
```

`1920 0 1920 <height>` — x, y, width, height. Note the `pid`: if it changes
between checks, the shell restarted and your edit is live.

For QML errors after any change:

```bash
journalctl --user -b -p 3 --since "2 min ago"
```

### Verifying text size (which `hyprctl` cannot show)

`hyprctl layers` only reports the bar surface height — it says nothing about
font size, and the shell exposes no style IPC (`omarchy shell shell ping` is
the only method). To check text and icons, screenshot the bar and compare:

```bash
grim -o eDP-1 /tmp/shot.png
magick /tmp/shot.png -crop 700x50+600+0 +repage -resize 200% /tmp/strip.png
```

`-o` takes an **output name**, not coordinates (`-o 1920,0` fails). This
machine's monitor sits at position 1920,0 and is named `eDP-1`.

For a rigorous before/after, capture at both settings and stack them:

```bash
magick /tmp/before.png -crop 700x50+600+0 +repage -resize 200% \
        -bordercolor red   -border 2 /tmp/a.png
magick /tmp/after.png  -crop 700x50+600+0 +repage -resize 200% \
        -bordercolor green -border 2 /tmp/b.png
magick /tmp/a.png /tmp/b.png -append /tmp/compare.png
```

Do not trust an automated ink-height measurement here — thresholding a
50px strip of antialiased text on a dark background reported only 9px → 10px
for an 11px → 14px change, while the visual A/B was unambiguous. Look at it.

---

## Rollback

```bash
omarchy plugin remove mihai.bar
omarchy restart shell
```

That deletes the clone and restores the stock bar. If you only want the stock
height back but keep the clone, set `horizontalSizeOverride` to `24`.

---

## Caveats

- **Bar height does not scale text or icons — the reverse is true.** Icons and
  text come from the package-owned `Style` singleton (`Style.qml:345-348`),
  which the bar plugin only *reads*, so changing `horizontalSizeOverride` alone
  leaves 16px glyphs sitting in a 50px bar. Raising `[font] base-size` *does*
  scale them (see "Text and icon size"), which is the current setup here.
- **Never edit `/usr/share/omarchy/shell/`.** It is package-owned and pacman
  overwrites it on update. Clone instead.
- **Clones do not merge on update.** After `omarchy update`, stock `Bar.qml`
  may gain features your copy lacks. There is no automatic three-way merge —
  diff `/usr/share/omarchy/shell/plugins/bar/Bar.qml` against
  `~/.config/omarchy/plugins/mihai.bar/Bar.qml` and port changes across by
  hand. This is the main cost of Option B, and the reason to prefer Option A
  when sizing is all you need.
- **Only horizontal bars are affected.** Left/right bars still use
  `Style.bar.sizeVertical`.

---

## Troubleshooting

| Symptom | Cause |
|---|---|
| Edit has no effect | Didn't run `omarchy restart shell`. `rescanPlugins` won't reload QML. |
| Bar height not what you typed | `[bar] scale-with-font` is `true` (the default), so your number is multiplied by `fontScale` (= `base-size / 12`). Set it `false` for exact pixels. |
| Bar shows old height | A *different* bar is active. Check `omarchy plugin list --json` for `"active": true`. |
| Clone not picked up | Validate the manifest, then confirm `.bar.id` in `shell.json` is `"mihai.bar"`. |
| Widget vanished | A `bar.`-rooted expression threw on a null deref. Check the journal at priority 3. |
| Changes lost after update | Expected — see the update caveat above. |
