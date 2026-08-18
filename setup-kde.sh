#!/usr/bin/env bash
#
# setup-kde.sh (Arch-only)
# Bootstraps a fresh Arch-based KDE Plasma install to match inder's setup:
# apps, theming, panels/widgets, shell, and dotfiles.
#
# PREREQUISITE: ~/dotfiles must already exist on this machine, populated by
# populate-dotfiles.sh, INCLUDING an exported Klassy preset at:
#   ~/dotfiles/klassy-preset/yukimipreset.klpw
# (see the Klassy export instructions before running this)
#
# Usage: ./setup-kde.sh
# Safe to re-run; steps that are already done are mostly idempotent.

set -uo pipefail

DOTFILES="$HOME/dotfiles"
LOG_PREFIX="==>"

log()  { echo "$LOG_PREFIX $*"; }
warn() { echo "$LOG_PREFIX [!] $*" >&2; }

# ---------------------------------------------------------------------------
# 0. Sanity check: Arch-based only
# ---------------------------------------------------------------------------
if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "${ID_LIKE:-$ID}" in
        *arch*) : ;;
        *) warn "This script is written for Arch-based distros only."
           warn "Detected ID_LIKE/ID: ${ID_LIKE:-$ID}. Continuing anyway, but"
           warn "package installs will likely fail." ;;
    esac
fi

# Pre-install step
cp -r "$(dirname "$0")/dotfiles" ~

# ---------------------------------------------------------------------------
# 1. Packages
# ---------------------------------------------------------------------------
log "Ensuring paru is available..."
if ! command -v paru >/dev/null; then
    log "paru not found, building it now..."
    sudo pacman -S base-devel git --noconfirm --needed
    tmpdir=$(mktemp -d)
    git clone https://aur.archlinux.org/paru.git "$tmpdir/paru"
    (cd "$tmpdir/paru" && makepkg -si --noconfirm)
    rm -rf "$tmpdir"
fi

log "Installing official-repo packages..."
sudo pacman -S python vlc discord chromium kitty krita qbittorrent mpv rofi ueberzugpp gwenview kdeconnect obs-studio fish fastfetch oxygen-sounds python-pywal base-devel cmake extra-cmake-modules qt6-base qt6-declarative kwin libplasma plasma-activities plasma-workspace linux-headers --needed --noconfirm \

log "Installing AUR packages via paru..."
paru -S floorp-bin visual-studio-code-bin spotify spicetify-cli curd klassy klassy-settings darkly-bin kde-material-you-colors oh-my-posh-bin --needed --noconfirm \
python3 -m pip install --user pipx python3 -m pipx ensurepath


log "Removing Firefox if present (replaced by Floorp)..."
sudo pacman -Rns --noconfirm firefox 2>/dev/null || true

# ---------------------------------------------------------------------------
# 2. Dotfiles: copy configs back into place
# ---------------------------------------------------------------------------
if [ -d "$DOTFILES" ]; then
    log "Copying dotfiles from $DOTFILES into \$HOME..."
    cp -a "$DOTFILES/." "$HOME/"
else
    warn "No $DOTFILES directory found - skipping dotfiles copy."
fi

# ---------------------------------------------------------------------------
# 3. Keyboard shortcuts + MinimizeAllWindows KWin script
# ---------------------------------------------------------------------------
log "Enabling MinimizeAllWindows and reloading shortcuts/KWin..."
if command -v kwriteconfig6 >/dev/null; then
    kwriteconfig6 --file kwinrc --group Plugins --key minimizeallEnabled true
fi
qdbus org.kde.kglobalaccel /kglobalaccel org.kde.KGlobalAccel.reloadConfig 2>/dev/null || \
    qdbus6 org.kde.kglobalaccel /kglobalaccel org.kde.KGlobalAccel.reloadConfig 2>/dev/null || true
qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
warn "If shortcuts don't take effect immediately, log out and back in."

# ---------------------------------------------------------------------------
# 4. Theming: Klassy (decoration + your preset), Darkly, colors, sound
# ---------------------------------------------------------------------------
log "Applying theming..."

if command -v kwriteconfig6 >/dev/null; then
    kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library org.kde.klassy
    kwriteconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage org.kde.darkly.desktop
    kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle Darkly
    kwriteconfig6 --file plasmarc --group Theme --key name Darkly
    kwriteconfig6 --file kcminputrc --group Mouse --key cursorTheme breeze_cursors
fi

KLASSY_PRESET="$DOTFILES/klassy-preset/yukimipreset.klpw"
if [ -d "$DOTFILES/.config/klassy" ]; then
    log "Klassy config (klassyrc/windecopresetsrc) restored via the dotfiles copy in"
    log "step 2 already matches your yukimipreset live settings - no import needed."
elif [ -f "$KLASSY_PRESET" ]; then
    warn "\$DOTFILES/.config/klassy wasn't found, but a standalone preset file exists"
    warn "at $KLASSY_PRESET - import it manually via klassy-settings > Presets."
else
    warn "No Klassy config or preset found - Klassy will use its defaults."
fi

log "Enabling Material You colors (wallpaper-based accent, dark)..."
if command -v kde-material-you-colors >/dev/null; then
    systemctl --user enable --now kde-material-you-colors.service 2>/dev/null || \
        warn "Could not enable kde-material-you-colors.service - check it manually."
else
    warn "kde-material-you-colors not found on PATH - theming step skipped for it."
fi

log "Setting Oxygen sound theme (no login/logout sounds)..."
if command -v kwriteconfig6 >/dev/null; then
    kwriteconfig6 --file kdeglobals --group Sounds --key Theme oxygen
    kwriteconfig6 --file ksmserverrc --group General --key loginSound ""
    kwriteconfig6 --file ksmserverrc --group General --key logoutSound ""
fi
warn "Sound theme keys above are best-effort - verify in System Settings > Sound if"
warn "login/logout sounds still play."

# pywal's colors (.cache/wal) and templates (.config/wal) are restored by the
# blanket dotfiles copy in step 2 if present. kde-material-you-colors also has
# pywal=true in its own config, so its service (enabled above) regenerates
# pywal colors automatically on wallpaper change - no separate wal -i call needed.

# ---------------------------------------------------------------------------
# 5. Shell: fish + oh-my-posh
# ---------------------------------------------------------------------------
if command -v fish >/dev/null; then
    log "Setting fish as default shell..."
    FISH_PATH="$(command -v fish)"
    grep -qxF "$FISH_PATH" /etc/shells || echo "$FISH_PATH" | sudo tee -a /etc/shells >/dev/null
    chsh -s "$FISH_PATH" "$USER"
    log "Default shell changed to fish (takes effect on next login)."
fi
# oh-my-posh theme + fish config are restored from dotfiles in step 2 already -
# double check your fish config's oh-my-posh init line points at the right
# theme filename after copying.

# ---------------------------------------------------------------------------
# 6. Extra Plasma panel widgets: Kara, PlasMusic Toolbar, Window Title Fork
# ---------------------------------------------------------------------------
log "Building and installing Kara (desktop pager)..."
tmpdir=$(mktemp -d)
git clone https://github.com/dhruv8sh/kara.git "$tmpdir/kara"
(cd "$tmpdir/kara" && ./install.sh)
rm -rf "$tmpdir"

cat <<'EOF'

==> Manual step required: PlasMusic Toolbar + Window Title Fork
Both are KDE Store (pling.com) widgets and only install reliably through
Plasma's own "Get New Widgets" dialog:

  1. Right-click a panel -> Add Widgets... -> Get New Widgets...
  2. Search "PlasMusic Toolbar" -> Install
  3. Search "Window Title" -> find "Window Title Fork" (by the kara author) -> Install
  4. Add both widgets to your panels to match your layout.

EOF

# ---------------------------------------------------------------------------
# 7. ROG-specific reminder (not automated, per your request)
# ---------------------------------------------------------------------------
PRODUCT_NAME=""
[ -f /sys/class/dmi/id/product_name ] && PRODUCT_NAME=$(cat /sys/class/dmi/id/product_name)

if echo "$PRODUCT_NAME" | grep -qiE "ROG|Strix|TUF|Zephyrus"; then
    cat <<EOF

==> Asus Gaming laptop detected ($PRODUCT_NAME)
Install ROG Control Center / asusctl manually - not automated here.
If you have an NVIDIA graphics card, make sure to install those drivers too.

Arch guide: https://asus-linux.org/guides/arch-guide/
EOF
fi

log "Done. Recommended: log out and back in (or reboot) to make sure every"
log "change (shell, shortcuts, theming) is fully applied."
