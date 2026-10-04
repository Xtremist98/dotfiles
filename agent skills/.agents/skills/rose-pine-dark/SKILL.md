---
name: rose-pine-dark
description: Build, switch, and maintain the Rose Pine Dark Omarchy theme on this machine — covers the GTK3/GTK4 + Qt/Kvantum theme system, the solitude coexistence/switch, the local.bar solid-background fix, the kvswitch user/root scripts, and root-app theming (gparted, btrfs-assistant). Use when editing the rose-pine-dark theme, adding a new app to it, fixing bar/widget transparency, or switching the whole desktop between rose-pine-dark and solitude.
---

# Rose Pine Dark — Omarchy theme system

## Architecture (AS-BUILT 2026-08-29 — full GTK3/4 theme, NOT pure-thpm)
rose-pine-dark uses a **full GTK theme** at `/usr/share/themes/rose-pine-dark` (the same one root apps use), NOT the pure-thpm/Adwaita-dark-only approach described in older notes. The skill text documented pure-thpm, but the running machine is the full-theme variant — this is correct and working.

**How it actually works:**
1. `omarchy theme set rose-pine-dark` → thpm hook (`90-thpm`) copies `~/.config/omarchy/themes/rose-pine-dark/gtk.css` → `~/.config/gtk-{3,4}.0/thpm-theme.css` (the user overlay) AND the full theme is installed at `/usr/share/themes/rose-pine-dark` (root apps + GTK3 detail).
2. The GTK theme NAME is forced to `rose-pine-dark` by **`~/.config/hypr/looknfeel.lua:124`** — `hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme 'rose-pine-dark'")` runs on every Hyprland config load + `color-scheme 'prefer-dark'`.
3. `gsettings get ... gtk-theme` → `'rose-pine-dark'` (NOT `Adwaita-dark`).
4. NOTE: `/usr/bin/omarchy-theme-set-gnome` is STOCK (unpatched, identical to `.orig` — the 2026-08-24 patch was reverted by an `omarchy update`). So the `rose-pine-dark` name comes ONLY from looknfeel.lua, not a patched setter. If looknfeel.lua ever loses line 124, GTK3 apps fall back to stock.
5. Overlay still wins for the user session because it redefines all named + widget colors on top of whichever base GTK3 theme loads.
6. `gnome-themes-extra` IS installed → `/usr/share/themes/Adwaita-dark/` exists, so a stock fallback is never light.

## Palette (rose-pine dark)
- `bg #191724`, `surface #1f1d2e`, `overlay #26233a`, `muted #6e6a86`, `fg #e0def4`
- `rose #ebbcba` (accent), `pine #31748f`, `foam #9ccfd8`, `gold #f6c177`, `iris #c4a7e7`, `love #eb6f92`, `selection #524f67`

## Theme naming
- MUST be `rose-pine-dark` (NOT `rose-pine`) so it never overrides the stock light `rose-pine` theme.
- The qt6ct color-scheme file is spelled `rosepine-dark.conf` (no hyphen) — watch this in scripts.

## File inventory (what exists)
**Omarchy theme (apps + wallpapers):**
- `~/.config/omarchy/themes/rose-pine-dark/` — `colors.toml` (new format), `icons.theme` (Papirus-Dark), `neovim.lua`, `vscode.json`, `chromium.theme`, `btop.theme`, `backgrounds/` (10 wallpapers), `preview*.png`, `unlock.png`
- `omarchy theme set rose-pine-dark` regenerates terminal/editor app configs; verified bg `#191724`.

**GTK overlay (the SINGLE source of truth for user GTK theming):**
- `~/.config/omarchy/themes/rose-pine-dark/gtk.css` — the overlay file. thpm copies it to `~/.config/gtk-{3,4}.0/thpm-theme.css` on every reconcile. Contains:
  - GTK4 libadwaita `@define-color` named colors (background, surface, view, headerbar, sidebar, card, popover, dialog, accent, destructive, success, warning, error, etc.)
  - GTK3 Adwaita legacy `@define-color` names (theme_bg_color, theme_fg_color, theme_base_color, headerbar_bg_color, titlebar_bg_color, backdrop_bg_color, etc.)
  - **Explicit widget selectors** for widgets that use hard-coded hex values in Adwaita-dark (see "GTK3 widget overrides" section below)
  - Rose slider-fix rules (rose accent on all scales)
  - Chromium-specific rules

**GTK3 widget overrides in the overlay (critical — these fix hard-coded Adwaita-dark colors):**
Adwaita-dark's compiled CSS hard-codes hex values like `toolbar { background-color: #353535; }`. `@define-color` named colors CANNOT override these — only explicit widget selectors can. The overlay includes:
- `headerbar, .titlebar, .headerbar, .primary-toolbar` → `#191724` (+ `:backdrop`)
- `.sidebar, .sidebar:backdrop, paned > sidebar, .navigation-sidebar` → `#1f1d2e` (surface)
- `.view, iconview, treeview, treeview.view` → `#191724`
- `stack, stack > *` → `#191724` (fixes GNOME Disks right pane — GtkStack content area)
- `scrolledwindow, scrolledwindow > viewport, viewport` → `#191724` (fixes scroll containers)
- `.toolbar, .inline-toolbar` → `#1f1d2e`
- `.gnome-disk-utility-grid` → `#191724` (GNOME Disks partition grid)
- `.gnome-disk-utility-grid:selected` → `#524f67` (no radial gradient)
- Chromium `.background.chromium` → `#191724`
- `filechooser` widgets → `#191724`
- Rose slider-fix rules (rose accent on all scales)

**CRITICAL: Do NOT add `.background > box` rules.** They leak into popover/menu wrapper boxes and create a visible double-layer behind every right-click menu, three-dot menu, and options menu in GTK apps. Only target specific widget types (headerbar, sidebar, view, stack, scrolledwindow, toolbar). The `.background` node itself also causes double-layer issues — avoid it.

**GTK user override (minimal safety net):**
- `~/.config/gtk-4.0/gtk.css` — minimal `:root { --view-bg-color: #191724; ... }` block. Belt-and-suspenders for libadwaita. Present only on rose-pine-dark; `kvswitch` removes it for solitude.

**Root apps (`/usr/share/themes/rose-pine-dark/`):**
- Full GTK3/GTK4 theme installed at `/usr/share/themes/rose-pine-dark/` — used by the user session (name driven by looknfeel.lua) AND root pkexec apps (gparted, btrfs-assistant).
- `/root/.config/gtk-3.0/settings.ini` (`gtk-theme-name=rose-pine-dark`, `prefer-dark=1`) — expected for root, but CANNOT be verified by the agent (sudoless). Confirm with: `sudo cat /root/.config/gtk-3.0/settings.ini`.

**local.bar (solid taskbar):**
- `~/.config/omarchy/plugins/local.bar/Bar.qml:78` — `property color background: Qt.rgba(..., 1.0)` (solid).
- `~/.config/omarchy/plugins/local.bar/styles/VisualTokens.qml:82` — `panelBackground` alpha `1.0`.
- `VisualTokens.qml:81` `barBackground` is a DEAD property — do not edit it.
- **Bar panel toggles** use local `panels/shared/ThemedToggle.qml` (see the 2026-08-29 AGENTS entry) — pill (radius `height/2`, ignores square corner rounding), theme-accent ON track via `Color.accent`, ON knob auto-contrasted by luminance. `import "../shared"` then `<DistinctName>` per panel (audio/network/bluetooth). Distinct name is REQUIRED — a file named `ToggleSwitch.qml` does NOT shadow `qs.Ui.ToggleSwitch` (module types win).
- **Dropbox panel toggle** (`local.dropbox/Panel.qml`, PanelHero `trailingControl`) uses the same `ThemedToggle`, but `import "../shared"` cannot traverse OUT of the `local.bar` tree into the sibling `local.dropbox` plugin dir — THE COMPONENT IS COPIED to `local.dropbox/ThemedToggle.qml` (resolves as a sibling type like `DropboxIcon.qml`). Note the bar layout uses `local.dropbox`, NOT stock `omarchy.dropbox`.
- **Themed scrollbar (see 2026-08-29 session):** the default `ScrollBar { policy: ScrollBar.AsNeeded }` on a panel `Flickable` is app-default WHITE and OVERLAYS the content (covers right-edge toggles/file rows). On `local.dropbox` it was replaced with a custom sibling-of-Flickable handle: 2px wide pill, parked in the popup's 14px padding gutter via `anchors.rightMargin: -(Style.spacing.popupPadding - 6)` (~6px off the border; the `KeyboardPanel` content holder has no `clip`, so negative margins are safe), colored translucent `bar.panelForeground` (`scrollbarColor` prop, 45% alpha) so it re-themes. Column width shrunk `Style.space(4)` to reserve the gutter. Wheel/keyboard scrolling work without a draggable handle.
- **Memory glyph sizing:** `local.memory/MemoryRing.qml` gained `property int size` (default `Style.space(13)`; the hardcoded 16 rounded ring read larger than the 15px `tokens.iconSize` text glyphs). `local.memory/BarWidget.qml` instantiates it `size: root.tokens.iconSize - Commons.Style.space(2)` in BOTH horizontal + vertical content.

**Switch scripts (MISSING on this machine as of 2026-08-29):**
- `~/.local/bin/kvswitch` and `~/kvswitch-root` are REFERENCED in old notes but DO NOT currently exist on disk. grep for `kvswitch` over `~/.config` returns nothing. There is NO hook that updates Kvantum/qt6ct/root configs on theme switch — only `55-icon-theme` (icons) and `90-thpm` (GTK overlay). So a theme switch does NOT auto-re-theme Qt apps or root apps today; Kvantum/qt6ct currently happen to be correct from a manual set. If full auto-switching is wanted, recreate these scripts (or add a theme-set hook).

**Kvantum (Qt):**
- System-wide: `/usr/share/Kvantum/rose-pine-dark/` and `/usr/share/Kvantum/solitude/`
- User: `~/.config/Kvantum/kvantum.kvconfig` → `theme=...`
- Root: `/root/.config/Kvantum/kvantum.kvconfig` → `theme=...`

**qt6ct color schemes:**
- User: `~/.config/qt6ct/colors/rose-pine-dark.conf` (HYPHEN name) + `solitude.conf`
- Root: `/root/.config/qt6ct/colors/rose-pine-dark.conf` + `solitude.conf` (if created)
- Current active scheme verified: `grep color_scheme_path ~/.config/qt6ct/qt6ct.conf` → `.../rose-pine-dark.conf`

**GtkSourceView (xed/gedit):**
- `~/.local/share/gtksourceview-4/styles/rose-pine.xml` (+ `gtksourceview-3.0/`) bg `#191724`
- `gsettings set org.x.editor.preferences.editor scheme 'rose-pine'`

## The switch mechanism (as-built)
1. `omarchy theme set rose-pine-dark` (or picker) → `90-thpm` hook → copies overlay `gtk.css` → `~/.config/gtk-{3,4}.0/thpm-theme.css`.
2. The GTK theme NAME is set to `rose-pine-dark` by `~/.config/hypr/looknfeel.lua:124` on every Hyprland load (NOT a patched `/usr/bin/omarchy-theme-set-gnome` — that is stock/unpatched; the 08-24 patch was reverted by an update).
3. `thpm run` / `thpm reconcile --refresh` → re-reads the source `gtk.css` → re-copies to `thpm-theme.css`. **Any edit to the source gtk.css auto-applies on next reconcile.**
4. Kvantum + qt6ct + root configs are NOT auto-switched (no script/hook exists). Check/edit manually:
   - `~/.config/Kvantum/kvantum.kvconfig` `theme=rose-pine-dark`
   - `~/.config/qt6ct/qt6ct.conf` `color_scheme_path=.../rose-pine-dark.conf`

## CRITICAL gotchas
- **`@define-color` alone cannot override hard-coded Adwaita-dark hex values.** Adwaita-dark's compiled CSS (inside `libgtk-3.so`) has rules like `toolbar { background-color: #353535; }` with hard-coded hex. The overlay's `@define-color headerbar_bg_color #191724` only works for widgets that REFERENCE that named color — widgets with hard-coded hex need explicit selector overrides (e.g. `toolbar { background-color: #191724; }`). This is why the overlay has both `@define-color` blocks AND explicit widget rules.
- **libadwaita captures `--view-bg-color: @view_bg_color` at parse time.** Overriding the *named color* does NOT change the already-captured custom property. To recolour the view you MUST override the custom property directly: `:root { --view-bg-color: #191724 }`. The user `~/.config/gtk-4.0/gtk.css` safety net handles this.
- **Kvantum + qt6ct are TWO layers.** `kvantum.kvconfig theme` (widgets) and qt6ct `color_scheme_path` (palette). A full switch must change BOTH — done manually (no kvswitch script exists as of 2026-08-29).
- **Root apps need separate switching.** Hooks run as USER; `/root/.config/...` is untouched by `omarchy theme set`. Adjust root configs with sudo (`sudo bash ...`), or recreate the missing `kvswitch-root`.
- **qt6ct `custom_palette=true` is required** (else quickshell reload popup renders light). Keep it.
- **Agent is sudoless.** Any `/root`, `/usr/share`, or system edit must be done by the user with `sudo`.
- **Kvantum highlight is rose `#eb6f92`** (in `rose-pine-dark.kvconfig` `[GeneralColors]` and every `text.*`/accent + SVG).
- **Solitude switching:** `/usr/share/themes/solitude` does NOT exist — solitude relies on Adwaita-dark base + overlay. If switching to solitude, its GTK3 styling breaks the SAME way (no `Adwaita-dark` GTK3 theme unless solitude ships a full theme), so plan a full `/usr/share/themes/solitude` GTK theme (or install `adw-gtk3`). Note: switching to solitude will NOT auto-flip Kvantum/qt6ct/root configs either — adjust manually.

## shell.toml — panel style (2026-09-11): sakura merge reverted to stock look, opacity kept
- **History:** rose-pine-dark historically shipped NO `shell.toml` — the shell used the generated output of `/usr/share/omarchy/default/themed/shell.toml.tpl` (interpolated with `colors.toml`). On **2026-09-10** the sakura-mochi theme's `shell.toml` was merged in (rose-pine colors), which changed the panel look. The user disliked it: panels became BIG and options lost their separating lines (e.g. the system panel).
- **What the sakura merge changed (and what must be reverted to get the old look):**
  1. **"Lines between options" = `[controls]` normal-state border on `bordered: true` buttons** (e.g. `panels/system/Panel.qml` uses `Button { bordered: true }`, which renders `Border.controlSpec("normal", ...)`; see `/usr/share/omarchy/shell/Ui/Button.qml`). Sakura set `normal-border-width = 0` → lines gone. STOCK (old): `normal-border-width = 1`, `normal-border-alpha = 0.4` (+ hover/focus width 1/alpha 0.25).
  2. **Big panels = `[spacing]`** `scale = 1.08` (sakura) vs stock `1.0`, plus larger per-token values. STOCK defaults per the template comments: `control-gap 8`, `control-padding-x 10`, `control-padding-y 6`, `input-padding-y 7`, `control-height 28`, `popup-row-height 28`, `row-gap 8`, `row-padding-x 12`, `label-gap 4`, `panel-gap 14`, `panel-padding 18`, `popup-padding 14`.
  3. **Bigger text = `[font]` overrides** (sakura `title 15 / heading 18 / display 26 / display-large 31 / icon-large 19` vs stock defaults `14 / 16 / 24 / 28 / 18`). Old = `base-size 12` only, no per-token overrides.
- **CURRENT FIX (applied 2026-09-11):** `~/.config/omarchy/themes/rose-pine-dark/shell.toml` now has stock-shape `[controls]` (borders 1/0.4–0.25, all `#e0def4`), `[spacing] scale = 1.0` (no per-token keys), `[font] base-size = 12` (no overrides). ALL `background-alpha` values kept from the merged version: bar `1.0`, popups `0.90`, menu `0.93`, launcher `0.91`, notifications `0.92`, tooltip `0.96`, polkit `0.96`, lock `0.84`. Backup of the pre-revert merged file: `/tmp/opencode/rose-pine-dark-shell.toml.bak-sakura-merge`.
- **Apply-edit procedure:** edit `~/.config/omarchy/themes/rose-pine-dark/shell.toml` → `cp` it to `~/.local/state/omarchy/current/theme/shell.toml` (what the running shell reads) → `omarchy restart shell` → verify exactly 1 quickshell + no shell.toml parse errors in the log.
- **Tuning knobs if lines too faint/strong:** `normal-border-alpha` / `normal-border-width` in `[controls]`. The `PanelSeparator` (1px rule) is separate and unaffected.

## Hyprland border colors (FINAL 2026-09-12 — corner-converged)
- **Active border = `[rose #ebbcba, pine #31748f, love #eb6f92, rose #ebbcba] @ 41.8deg`** — a 4-stop gradient so **rose sits on the top-LEFT and bottom-RIGHT corners** (user's explicit request), with pine on top-right and love on bottom-left. History: `[rose,iris,love,foam] 35deg` → `[rose,pine,love] 35deg` → `[pine,rose,love] 30deg` (rose on TR+BL) → final `[rose,pine,love,rose] 41.8deg`.
- **Inactive border = `#403d52`** (rose-pine highlight_med, OPAQUE). Gotcha: `rgba(ff403d52)` parses as RGB `ff403d` alpha `0x52` = DEEP RED — always write the full 8-hex with alpha LAST (`rgba(403d52ff)`).
- **Where it lives (keep ALL in sync):**
  1. `~/.config/omarchy/themes/rose-pine-dark/hyprland.lua` — `activeBorderColor` (`{ colors = {...}, angle = 41.8 }`) → applied to `general:col.active_border` AND `group:col.border_active` (menu/groups inherit); `inactiveBorderColor = "rgba(403d52ff)"` → `general:col.inactive_border` + `group:col.border_inactive`.
  2. `~/.config/omarchy/themes/rose-pine-dark/shell.toml` — `[hyprland] active-border` = `"rgba(ebbcbaff) rgba(31748fff) rgba(eb6f92ff) rgba(ebbcbaff) 41.8deg"` (line 20). Stock panels/popups/menus/notifications/polkit/lock reference it via `border = "hyprland.active-border"`.
- **Apply procedure (3 steps, or it won't show):**
  1. Edit BOTH files, then `cp` them to `~/.local/state/omarchy/current/theme/{shell.toml,hyprland.lua}`.
  2. `hyprctl reload` → picks up the live Hyprland gradient. `hyprctl getoption general:col.active_border -j` → `ffebbcba ff31748f ffeb6f92 ffebbcba 41deg` (`hyprctl` DISPLAYS the angle rounded to int but STORES the 41.8 double — corners still land exactly).
  3. **For the shell/bar/popups ALSO `omarchy theme refresh` + `omarchy restart shell`** — the theme `shell.toml` is loaded with `watchChanges: false`, so editing the file alone never re-renders popup borders.
- **Corner geometry (the formula):** Hyprland borders are a single linear axis, NOT a perimeter wrap: `t = y·sin(a) + x·(1−sin(a))`, x,y∈[0,1]. Top-LEFT is ALWAYS t=0 (first stop), bottom-RIGHT ALWAYS t=1 (last stop); top-right = t=1−sin(a), bottom-left = t=sin(a). Consequences:
  - To put a color on BOTH TL+BR it must be the FIRST and LAST stop (hence rose duplicated at both ends).
  - **30° / 150°** (sin=0.5) makes TR=BL=t=0.5 → a single mid color falls on BOTH those corners.
  - **41.81°** (sin=2/3) makes TR=t=1/3 and BL=t=2/3 → for a 4-stop `[a,b,c,d]`, TR=b and BL=c exactly.
  - Only 0°/90° put exact stops on the mid corners.
- **Shadow:** fully disabled (`shadowEnabled = false` in hyprland.lua keeps `shadowColor` `rgba(000000b0)` but never applies it). Verify with `hyprctl getoption decoration:shadow:enabled -j` (COLON-form — it errors on the old `decoration:shadow_range`). `-j` output shows colors in ALPHA-FIRST form (`ff403d52` outside = opaque #403d52).

## Verify a switch worked
```
gsettings get org.gnome.desktop.interface gtk-theme          # 'rose-pine-dark' (driven by looknfeel.lua:124)
gsettings get org.gnome.desktop.interface color-scheme       # 'prefer-dark'
diff ~/.config/gtk-3.0/thpm-theme.css ~/.config/omarchy/themes/rose-pine-dark/gtk.css  # empty
grep theme ~/.config/Kvantum/kvantum.kvconfig                # rose-pine-dark
grep color_scheme_path ~/.config/qt6ct/qt6ct.conf            # .../rose-pine-dark.conf
grep -c "191724" /usr/share/themes/rose-pine-dark/gtk-4.0/libadwaita.css   # >=1 (flat baked)
```
Then restart GTK/Qt apps. Root apps: recreate `kvswitch-root` or set `/root/.config/...` manually via sudo.

## Apply a bar-transparency change
After editing `Bar.qml` (`root.background` alpha) or `VisualTokens.qml` (`panelBackground` alpha), run `omarchy restart shell`.
