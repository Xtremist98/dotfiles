#!/usr/bin/env bash
#
# Solitude Theme Kit installer
# Installs a fully self-contained solitude desktop. Everything needed
# (GTK theme, Kvantum style, qt6ct/qt5ct color schemes, a KDE color scheme,
# vencord theme) is pre-rendered in this kit -- no external theming engine
# is required.
#
# The kit is fetched from the GitHub dotfiles repo if it is not already present
# next to this script. So you can run this straight from a curl'd copy:
#   bash <(curl -fsSL https://raw.githubusercontent.com/Xtremist98/dotfiles/main/solitude-kit/install.sh)
# or after cloning:  bash solitude-kit/install.sh
#
# Run AFTER selecting the solitude theme in Omarchy (for hyprland/bar theming).

set -euo pipefail

REPO="https://github.com/Xtremist98/dotfiles.git"
BRANCH="main"
KIT_SUBDIR="solitude-kit"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Use the kit next to this script if present; otherwise clone it from GitHub.
if [[ -d "$SCRIPT_DIR/solitude-gtk-theme" ]]; then
  KIT="$SCRIPT_DIR"
else
  echo "==> solitude-kit not found beside this script; cloning from GitHub ($REPO)..."
  TMP="$(mktemp -d)"
  git clone --depth 1 --filter=blob:none --sparse --branch "$BRANCH" "$REPO" "$TMP/dotfiles"
  git -C "$TMP/dotfiles" sparse-checkout set "$KIT_SUBDIR"
  KIT="$TMP/dotfiles/$KIT_SUBDIR"
  CLEANUP_TMP="$TMP"
fi

echo "==> Solitude Theme Kit installer"
echo "    kit: $KIT"

# 1. GTK theme (GTK2/3/4) — solitude-gtk-theme replaces adw-gtk-theme-git
#    (the adwaita GTK3 port). We do NOT force-remove adw-gtk-theme-git here;
#    pacman will happily keep both installed side by side, and solitude is
#    selected as the active theme below. Force-removal used to break GTK apps
#    whose theme briefly pointed at a removed package.
GTK_PKG="$(ls "$KIT"/solitude-gtk-theme/solitude-gtk-theme-*.pkg.tar.gz 2>/dev/null | head -n1)"
if [[ -z "${GTK_PKG:-}" ]]; then
  echo "!! solitude-gtk-theme package not found; building from source..."
  ( cd "$KIT/solitude-gtk-theme" && PKGEXT='.pkg.tar.gz' makepkg -f )
  GTK_PKG="$(ls "$KIT"/solitude-gtk-theme/solitude-gtk-theme-*.pkg.tar.gz | head -n1)"
fi
echo "==> Installing solitude-gtk-theme (GTK2/3/4)..."
sudo pacman -U --needed "$GTK_PKG"

# 2. Kvantum solitude (hand-made style)
echo "==> Installing Kvantum solitude..."
mkdir -p "$HOME/.config/Kvantum/solitude"
cp -r "$KIT/Kvantum/solitude/." "$HOME/.config/Kvantum/solitude/"
printf '[General]\ntheme=solitude\n' > "$HOME/.config/Kvantum/kvantum.kvconfig"

# 3. qt6ct + qt5ct color schemes (pre-rendered)
echo "==> Installing qt6ct / qt5ct..."
mkdir -p "$HOME/.config/qt6ct" "$HOME/.config/qt5ct"
cp -r "$KIT/qt6ct/." "$HOME/.config/qt6ct/"
cp -r "$KIT/qt5ct/." "$HOME/.config/qt5ct/"

# 4. KDE color scheme (Solitude). qt6ct only sets the Qt widget style + QPalette;
#    it does NOT populate KDE's KColorScheme, which KDE apps (Dolphin's
#    "Acting as administrator" banner, KMessageWidget, etc.) read. Without a
#    real KDE color scheme those roles fall back to white/defaults.
echo "==> Installing KDE color scheme (Solitude)..."
mkdir -p "$HOME/.local/share/color-schemes"
cp "$KIT/kde/Solitude.colors" "$HOME/.local/share/color-schemes/Solitude.colors"
# Merge [Colors:*] + ColorScheme into kdeglobals. Idempotent: strip old
# [Colors:*] blocks and any duplicate [General] headers (keep only the first
# [General] block + its body), then insert ColorScheme into that [General].
KG="$HOME/.config/kdeglobals"
TMPKG="$(mktemp)"
if [[ -f "$KG" ]]; then
  awk '
    /^\[Colors:/ { skip=1; next }
    /^\[General\]/ { if (seen) { skip=1; next } seen=1; skip=0; print; next }
    /^\[/ { skip=0 }
    skip { next }
    { print }
  ' "$KG" | grep -v '^ColorScheme=' > "$TMPKG"
else
  : > "$TMPKG"
fi
if grep -q '^\[General\]' "$TMPKG"; then
  sed -i '/^\[General\]/a ColorScheme=Solitude' "$TMPKG"
else
  sed -i '1i [General]\nColorScheme=Solitude' "$TMPKG"
fi
awk '/^\[Colors:/{p=1} p' "$KIT/kde/Solitude.colors" >> "$TMPKG"
mv "$TMPKG" "$KG"

# 5. vencord (Discord) theme (pre-rendered)
echo "==> Installing vencord theme..."
mkdir -p "$HOME/.config/vesktop/themes"
cp "$KIT/vencord/vencord.theme.css" "$HOME/.config/vesktop/themes/vencord.theme.css"

# 5b. GtkSourceView editor scheme (xed / gedit / pluma). Gives the text editing
#     surface solitude's own palette instead of the default light source scheme.
echo "==> Installing GtkSourceView solitude scheme..."
mkdir -p "$HOME/.local/share/gtksourceview-4/styles" "$HOME/.local/share/gtksourceview-3.0/styles"
cp "$KIT/gtksourceview/solitude.xml" "$HOME/.local/share/gtksourceview-4/styles/solitude.xml"
cp "$KIT/gtksourceview/solitude.xml" "$HOME/.local/share/gtksourceview-3.0/styles/solitude.xml"
# Point xed (if installed) at the solitude scheme so it matches the GTK theme.
if command -v xed >/dev/null 2>&1; then
  gsettings set org.x.editor.preferences.editor scheme solitude 2>/dev/null || true
fi

# 6. GTK theme setting
echo "==> Setting GTK theme to solitude..."
gsettings set org.gnome.desktop.interface gtk-theme solitude
gsettings set org.gnome.desktop.interface color-scheme prefer-dark

# 6b. Stop Omarchy's looknfeel.lua from overriding the GTK theme back to
#     adw-gtk3-dark on every Hyprland reload (it hardcodes that gsettings line).
LOOKNFEEL="$HOME/.config/hypr/looknfeel.lua"
if [[ -f "$LOOKNFEEL" ]] && grep -q "gtk-theme" "$LOOKNFEEL"; then
  echo "==> Patching $LOOKNFEEL to keep gtk-theme=solitude..."
  sed -i "s/gtk-theme '[^']*'/gtk-theme 'solitude'/g; s/gtk-theme \"[^\"]*\"/gtk-theme \"solitude\"/g" "$LOOKNFEEL"
fi

# 7. Root theming for pkexec GUI apps (GParted, btrfs-assistant, ...).
#
#    CRITICAL: pkexec launches these as root with a *sanitized* environment.
#    It does NOT open a PAM session, so /etc/environment and ~/.pam_environment
#    are ignored, and QT_QPA_PLATFORMTHEME / GTK_THEME are stripped. Root GTK
#    apps are themed via /root/.config/gtk-3.0/settings.ini (GTK falls back to
#    it when there is no dconf value set). NOTE: we deliberately do NOT copy the
#    user's kdeglobals to /root and do NOT force the Qt platform theme globally
#    via /etc/xdg/qt*.conf -- either would load qt6ct/Kvantum into the root
#    kio-admin-helper (Dolphin's "Open as Administrator" backend) and crash it
#    ("unknown error, loading canceled").
echo "==> Installing root theming for pkexec apps..."
# 7b. Root config tree (GTK3 + GTK4 both need settings.ini; GTK4 ignores gtk-3.0).
REAL_HOME="$HOME"
sudo mkdir -p /root/.config/gtk-3.0 /root/.config/gtk-4.0 \
             /root/.config/qt6ct/colors /root/.config/qt5ct/colors \
             /root/.config/Kvantum/solitude

# GTK3 + GTK4 settings. gtk-color-scheme=prefer-dark is invalid; use
# gtk-application-prefer-dark-theme=1 to force dark.
sudo tee /root/.config/gtk-3.0/settings.ini >/dev/null <<'EOF'
[Settings]
gtk-theme-name=solitude
gtk-icon-theme-name=Papirus-Dark
gtk-application-prefer-dark-theme=1
EOF
sudo cp /root/.config/gtk-3.0/settings.ini /root/.config/gtk-4.0/settings.ini

# Kvantum (Qt style) for root
sudo cp -r "$KIT/Kvantum/solitude/." /root/.config/Kvantum/solitude/
sudo tee /root/.config/Kvantum/kvantum.kvconfig >/dev/null <<'EOF'
[General]
theme=solitude
EOF

# qt6ct / qt5ct color schemes — rewrite color_scheme_path to /root (was $REAL_HOME)
sudo cp -r "$KIT/qt6ct/." /root/.config/qt6ct/
sudo cp -r "$KIT/qt5ct/." /root/.config/qt5ct/
sudo sed -i "s#${REAL_HOME}#/root#g" /root/.config/qt6ct/qt6ct.conf /root/.config/qt5ct/qt6ct.conf 2>/dev/null || true

# NOTE: we intentionally do NOT install a KDE color scheme / kdeglobals under
# /root. Doing so (e.g. copying the user's kdeglobals, which sets
# widgetStyle=qt6ct-style) would make the root kio-admin-helper load qt6ct/
# Kvantum and crash Dolphin's "Open as Administrator". Root KDE GUI apps are
# rare; the user-facing Dolphin admin banner is themed by the USER's kdeglobals
# (set above in section 4), not by /root.

# copy any custom gtk.css the user has
if [[ -f "$HOME/.config/gtk-3.0/gtk.css" ]]; then
  sudo cp "$HOME/.config/gtk-3.0/gtk.css" /root/.config/gtk-3.0/gtk.css
fi
if [[ -f "$HOME/.config/gtk-4.0/gtk.css" ]]; then
  sudo cp "$HOME/.config/gtk-4.0/gtk.css" /root/.config/gtk-4.0/gtk.css
fi

# 7c. Bulletproof the GTK theme for root pkexec apps (GParted). pkexec strips
#     GTK_THEME from the environment, so a polkit exec.env annotation re-permits
#     it. The user session carries GTK_THEME=solitude via /etc/environment below,
#     so pkexec forwards it to the root GParted process -> guaranteed solitude
#     even if /root/.config/gtk-3.0/settings.ini is somehow not read.
echo "==> Whitelisting GTK_THEME through pkexec (GParted)..."
if ! grep -q '^GTK_THEME=' /etc/environment 2>/dev/null; then
  echo 'GTK_THEME=solitude' | sudo tee -a /etc/environment >/dev/null
fi
POL="/usr/share/polkit-1/actions/org.gnome.gparted.policy"
if [[ -f "$POL" ]] && ! grep -q 'exec.env' "$POL"; then
  sudo python3 - <<PY
p="$POL"
s=open(p).read()
ins='  <annotate key="org.freedesktop.policykit.exec.env">GTK_THEME</annotate>\n'
s=s.replace('  <annotate key="org.freedesktop.policykit.exec.allow_gui">true</annotate>\n',
            '  <annotate key="org.freedesktop.policykit.exec.allow_gui">true</annotate>\n'+ins)
open(p,"w").write(s)
PY
fi
# Apply GTK_THEME to the *current* user session too (without waiting for a
# re-login), so the pkexec passthrough above is effective immediately.
systemctl --user set-environment GTK_THEME=solitude 2>/dev/null || true

# Force GTK_THEME=solitude inside the GParted launcher itself. The user's session
# may still export a stale GTK_THEME (e.g. adw-gtk3-dark left over from before
# solitude); the polkit exec.env above would forward that value through pkexec
# and override the root settings.ini. Exporting it in the launcher makes solitude
# win unconditionally, regardless of what the launching shell has.
echo "==> Forcing GTK_THEME=solitude in the GParted launcher..."
if ! grep -q 'GTK_THEME=solitude' /usr/bin/gparted; then
  sudo sed -i '1a export GTK_THEME=solitude' /usr/bin/gparted
fi

# clean up temp clone if we made one
[[ -n "${CLEANUP_TMP:-}" ]] && rm -rf "$CLEANUP_TMP"

echo
echo "==> Done. Solitude is installed:"
echo "   - GTK theme : solitude (GTK2/3/4)"
echo "   - Qt style  : Kvantum solitude (set in kdeglobals widgetStyle)"
echo "   - qt6ct/qt5ct color schemes : installed from kit"
echo "   - KDE color scheme : Solitude (fixes Dolphin admin banner, KColorScheme roles)"
echo "   - vencord theme : installed"
echo "   - root apps : GTK themed via /root/.config settings.ini + GTK_THEME passthrough (pkexec)"
echo "   Re-login (or restart the shell) so qt6ct + Kvantum fully apply."
