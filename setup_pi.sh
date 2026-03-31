#!/bin/bash
# BikeNav Pi Setup Script
# Run once on a fresh Raspberry Pi OS (64-bit)
# Usage: chmod +x setup_pi.sh && ./setup_pi.sh

set -e
echo "=== BikeNav Pi Setup ==="

# ── 1. System packages ────────────────────────────────────────
echo "[1/6] Installing system packages..."
sudo apt-get update -qq
sudo apt-get install -y \
    curl wget git unzip xz-utils \
    libgtk-3-dev libblkid-dev liblzma-dev \
    clang cmake ninja-build pkg-config \
    libgles2-mesa-dev \
    nodejs npm

# ── 2. Flutter (Linux ARM64) ──────────────────────────────────
echo "[2/6] Installing Flutter..."
FLUTTER_DIR="$HOME/flutter"
if [ ! -d "$FLUTTER_DIR" ]; then
    # Download Flutter for Linux ARM64
    FLUTTER_VERSION="3.22.2"
    wget -q "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
        -O /tmp/flutter.tar.xz
    tar xf /tmp/flutter.tar.xz -C "$HOME"
    rm /tmp/flutter.tar.xz
fi

export PATH="$PATH:$FLUTTER_DIR/bin"
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc

flutter config --enable-linux-desktop
flutter doctor

# ── 3. tileserver-gl (offline map tiles) ─────────────────────
echo "[3/6] Installing tileserver-gl..."
sudo npm install -g tileserver-gl-light

# ── 4. Download offline map tiles for your region ────────────
echo "[4/6] Downloading offline tiles..."
TILES_DIR="$HOME/tiles"
mkdir -p "$TILES_DIR"

# Karnataka state tiles (~280MB) — change URL for other regions
# Full India: https://download.geofabrik.de/asia/india-latest.osm.pbf (~700MB after conversion)
# Karnataka only (faster): use openfreemap.org tiles
TILES_URL="https://data.maptiler.com/downloads/asia/india/karnataka/"
echo ""
echo ">>> MANUAL STEP: Download .mbtiles file for your region"
echo "    Visit: https://openfreemap.org or https://data.maptiler.com"
echo "    Place the .mbtiles file in: $TILES_DIR/"
echo "    Then re-run: tileserver-gl-light $TILES_DIR/your-file.mbtiles --port 8080"
echo ""

# ── 5. Build the Flutter TFT app ─────────────────────────────
echo "[5/6] Building Flutter TFT app..."
APP_DIR="$HOME/bike_nav_tft"
if [ -d "$APP_DIR" ]; then
    cd "$APP_DIR"
    flutter pub get
    flutter build linux --release
    echo "    Built at: $APP_DIR/build/linux/arm64/release/bundle/"
else
    echo "    Skipping build — copy bike_nav_tft/ to $HOME first"
fi

# ── 6. Autostart setup ────────────────────────────────────────
echo "[6/6] Setting up autostart..."
AUTOSTART_DIR="$HOME/.config/autostart"
mkdir -p "$AUTOSTART_DIR"

# Autostart tileserver-gl
cat > "$AUTOSTART_DIR/tileserver.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=TileServer
Exec=bash -c 'sleep 5 && tileserver-gl-light ~/tiles/*.mbtiles --port 8080'
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

# Autostart the nav app
cat > "$AUTOSTART_DIR/bikenav.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=BikeNav TFT
Exec=bash -c 'sleep 8 && ~/bike_nav_tft/build/linux/arm64/release/bundle/bike_nav_tft'
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

echo ""
echo "=== Setup complete ==="
echo ""
echo "Next steps:"
echo "  1. Download .mbtiles for your region into ~/tiles/"
echo "  2. Copy bike_nav_tft/ project here and run: flutter build linux --release"
echo "  3. Reboot — both tileserver and app will autostart"
echo "  4. The screen will show the Pi's IP address"
echo "  5. Enter that IP in the phone app and tap 'Mirror to bike'"
echo ""
