#!/bin/bash
# Manual launch script — use this while testing before setting up autostart
# Run from the bike_nav_tft directory

APP_BUNDLE="$HOME/bike_nav_tft/build/linux/arm64/release/bundle/bike_nav_tft"
TILES_DIR="$HOME/tiles"

# Start tileserver-gl in background if tiles exist
if ls "$TILES_DIR"/*.mbtiles 1>/dev/null 2>&1; then
    echo "Starting tileserver-gl on port 8080..."
    tileserver-gl-light "$TILES_DIR"/*.mbtiles --port 8080 &
    TILE_PID=$!
    echo "Tileserver PID: $TILE_PID"
    sleep 3
else
    echo "No .mbtiles found in $TILES_DIR — will use OSM online fallback"
fi

# Launch the Flutter app
echo "Launching BikeNav TFT..."
"$APP_BUNDLE"

# Clean up tileserver when app exits
if [ -n "$TILE_PID" ]; then
    kill $TILE_PID 2>/dev/null
fi
