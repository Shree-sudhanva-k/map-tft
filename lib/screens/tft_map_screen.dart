import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/nav_state.dart';
import '../services/websocket_server.dart';
import '../widgets/hud_widgets.dart';

class TftMapScreen extends StatefulWidget {
  final NavState initialState;

  const TftMapScreen({super.key, required this.initialState});

  @override
  State<TftMapScreen> createState() => _TftMapScreenState();
}

class _TftMapScreenState extends State<TftMapScreen> {
  final MapController _mapController = MapController();
  final WebSocketServer _server = WebSocketServer();

  late NavState _navState;
  MirrorStatus _mirrorStatus = MirrorStatus.live;

  StreamSubscription<NavState>? _navSub;
  StreamSubscription<MirrorStatus>? _mirrorSub;

  // Smooth camera follow — don't snap every update
  Timer? _cameraTimer;
  bool _cameraScheduled = false;

  // Tile server: offline on Pi (tileserver-gl) or online OSM fallback
  // Change this to 'http://localhost:8080/styles/basic/{z}/{x}/{y}.png'
  // when tileserver-gl is running on the Pi
  static const String _tileUrl =
      'http://localhost:8080/styles/basic-preview/{z}/{x}/{y}.png';
  static const String _fallbackTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  bool _useOfflineTiles = true; // set false to use online OSM as fallback

  @override
  void initState() {
    super.initState();
    _navState = widget.initialState;

    _navSub = _server.navStream.listen(_onNavUpdate);
    _mirrorSub = _server.mirrorStream.listen((m) {
      if (mounted) setState(() => _mirrorStatus = m);
    });
  }

  void _onNavUpdate(NavState state) {
    if (!mounted) return;
    setState(() => _navState = state);
    _scheduleCameraMove(state);
  }

  void _scheduleCameraMove(NavState state) {
    if (_cameraScheduled) return;
    _cameraScheduled = true;
    _cameraTimer = Timer(const Duration(milliseconds: 150), () {
      _cameraScheduled = false;
      if (!mounted) return;
      try {
        _mapController.move(state.location, state.zoom);
        _mapController.rotate(-state.heading); // rotate map to heading
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _navSub?.cancel();
    _mirrorSub?.cancel();
    _cameraTimer?.cancel();
    super.dispose();
  }

  String get _tileTemplate =>
      _useOfflineTiles ? _tileUrl : _fallbackTileUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _navState.location,
              initialZoom: _navState.zoom,
              minZoom: 4,
              maxZoom: 18,
              // Disable all interaction on TFT — phone controls everything
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.none,
              ),
            ),
            children: [
              // Tile layer — offline from Pi tileserver-gl
              TileLayer(
                urlTemplate: _tileTemplate,
                userAgentPackageName: 'com.bikenav.tft',
                maxZoom: 18,
                // Fallback to OSM if offline tile fetch fails
                errorTileCallback: _useOfflineTiles
                    ? (tile, error, stackTrace) {
                        if (mounted) {
                          setState(() => _useOfflineTiles = false);
                        }
                      }
                    : null,
              ),

              // Route polyline
              if (_navState.hasRoute)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _navState.routePoints,
                      strokeWidth: 6,
                      color: const Color(0xFF1976D2),
                      borderStrokeWidth: 3,
                      borderColor: Colors.white.withOpacity(0.5),
                    ),
                  ],
                ),

              // Destination marker
              if (_navState.destination != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _navState.destination!,
                      width: 48,
                      height: 56,
                      child: const Icon(
                        Icons.location_pin,
                        color: Color(0xFFD32F2F),
                        size: 44,
                      ),
                    ),
                  ],
                ),

              // Current location — always centre of screen on TFT
              // We move the map to follow, so this is a fixed centre dot
              MarkerLayer(
                markers: [
                  Marker(
                    point: _navState.location,
                    width: 32,
                    height: 32,
                    child: Transform.rotate(
                      angle: 0, // map already rotated to heading
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0),
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 8,
                            )
                          ],
                        ),
                        child: const Icon(Icons.navigation,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── Signal lost overlay ───────────────────────────────
          if (_mirrorStatus == MirrorStatus.lost)
            const SignalLostOverlay(),

          // ── Top-left: status bar ──────────────────────────────
          Positioned(
            top: 12,
            left: 12,
            child: StatusBar(
              mirrorStatus: _mirrorStatus,
              lastUpdate: _navState.receivedAt,
            ),
          ),

          // ── Top-right: heading indicator ──────────────────────
          Positioned(
            top: 12,
            right: 12,
            child: HeadingIndicator(heading: _navState.heading),
          ),

          // ── Bottom centre: route HUD ──────────────────────────
          if (_navState.hasRoute)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: RouteHud(state: _navState),
              ),
            ),

          // ── Tile source indicator (dev) ───────────────────────
          Positioned(
            bottom: 4,
            right: 8,
            child: Text(
              _useOfflineTiles ? 'offline tiles' : 'OSM fallback',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
