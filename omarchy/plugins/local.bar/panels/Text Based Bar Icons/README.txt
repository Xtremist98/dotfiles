Text-based bar icons (Bluetooth, Audio, Monitor, Power)
=====================================================

What changed
------------
These four panel files (bluetooth/Panel.qml, audio/Panel.qml,
monitor/Panel.qml, power/Panel.qml) were modified so the bar icon is
drawn as a plain QML Text overlay instead of using BarIconButton's
built-in OpticalGlyph normalizer.

Before:
  - Each icon used BarIconButton with `text: <glyph>` (Nerd Font glyphs
    for Bluetooth/Monitor/Power, a Material Symbols "graphic_eq" for Audio).
  - BarIconButton's OpticalGlyph forced every glyph's painted bounds to
    Style.bar.iconSize (12px), so glyphs with different ink shapes looked
    different sizes (Bluetooth looked big, Audio looked small).

After:
  - `text` is set to " " (a space) and `iconComponent` to an empty Item,
    so BarIconButton paints nothing itself (keeps the slot/opacity logic).
  - A plain Text child is added, anchored center, with per-icon
    font.pixelSize and a per-icon `scale` factor:
      * Bluetooth:  font.pixelSize 12 (iconFont-1), scale 1.10
      * Audio:      font.pixelSize 12, Material Symbols, FILL + wght 700, scale 1.00
      * Monitor:    font.pixelSize 12 (iconFont-1), scale 1.00
      * Power:      font.pixelSize 12 (iconFont-1), scale 1.10
  - `enabled: false` on the Text so clicks pass through to the button.
  - `scale: button.pressScale * <factor>` keeps the press feedback.

How this differs from the other glyph icons
------------------------------------------
- Network, CPU, memory, etc. still use the stock BarIconButton/OpticalGlyph
  path: a single Nerd Font glyph normalized to 12px.
- These four use a plain Text overlay with explicit font size + scale, so
  each icon's optical size can be tuned independently instead of being
  forced to one common painted dimension.
- Audio additionally uses a Material Symbols glyph with a heavier weight
  (wght 700) and FILL axis to make the equalizer bars read as solid.

Notes
-----
- To retune sizes later, edit the `scale:` and `font.pixelSize:` values
  in the Text overlay of the relevant panel file.
