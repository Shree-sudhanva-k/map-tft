import 'dart:async';
import 'package:flutter/material.dart';
import '../models/nav_state.dart';
import '../services/websocket_server.dart';
import '../screens/waiting_screen.dart';
import '../screens/tft_map_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final WebSocketServer _server = WebSocketServer();

  ServerStatus _serverStatus = ServerStatus.starting;
  MirrorStatus _mirrorStatus = MirrorStatus.waiting;
  NavState? _firstNavState;

  StreamSubscription<ServerStatus>? _statusSub;
  StreamSubscription<MirrorStatus>? _mirrorSub;
  StreamSubscription<NavState>? _navSub;

  @override
  void initState() {
    super.initState();
    _statusSub = _server.statusStream.listen((s) {
      if (mounted) setState(() => _serverStatus = s);
    });
    _mirrorSub = _server.mirrorStream.listen((m) {
      if (mounted) setState(() => _mirrorStatus = m);
    });
    // Capture first nav state to transition to map screen
    _navSub = _server.navStream.listen((state) {
      if (_firstNavState == null && mounted) {
        setState(() => _firstNavState = state);
      }
    });
    _server.start();
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _mirrorSub?.cancel();
    _navSub?.cancel();
    _server.stop();
    super.dispose();
  }

  bool get _showMap =>
      _firstNavState != null && _mirrorStatus != MirrorStatus.waiting;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: _showMap
          ? TftMapScreen(
              key: const ValueKey('map'),
              initialState: _firstNavState!,
            )
          : WaitingScreen(
              key: const ValueKey('waiting'),
              status: _serverStatus,
              serverIp: _server.serverIp,
            ),
    );
  }
}
