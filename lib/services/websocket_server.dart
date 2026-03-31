import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/nav_state.dart';

enum ServerStatus { starting, listening, phoneConnected, error }

class WebSocketServer {
  static final WebSocketServer _instance = WebSocketServer._internal();
  factory WebSocketServer() => _instance;
  WebSocketServer._internal();

  static const int port = 8765;

  HttpServer? _server;
  WebSocketChannel? _phoneChannel;
  Timer? _timeoutTimer;

  ServerStatus _status = ServerStatus.starting;
  MirrorStatus _mirrorStatus = MirrorStatus.waiting;
  String _serverIp = '';

  final StreamController<NavState> _navController =
      StreamController<NavState>.broadcast();
  final StreamController<ServerStatus> _statusController =
      StreamController<ServerStatus>.broadcast();
  final StreamController<MirrorStatus> _mirrorController =
      StreamController<MirrorStatus>.broadcast();

  Stream<NavState> get navStream => _navController.stream;
  Stream<ServerStatus> get statusStream => _statusController.stream;
  Stream<MirrorStatus> get mirrorStream => _mirrorController.stream;

  ServerStatus get status => _status;
  MirrorStatus get mirrorStatus => _mirrorStatus;
  String get serverIp => _serverIp;

  Future<void> start() async {
    _setStatus(ServerStatus.starting);
    try {
      // Get local IP to display on screen
      _serverIp = await _getLocalIp();

      final handler = webSocketHandler((WebSocketChannel channel, String? p) {
        _handlePhoneConnection(channel);
      });

      _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
      _setStatus(ServerStatus.listening);
    } catch (e) {
      _setStatus(ServerStatus.error);
    }
  }

  void _handlePhoneConnection(WebSocketChannel channel) {
    // Only allow one phone at a time
    _phoneChannel?.sink.close();
    _phoneChannel = channel;
    _setStatus(ServerStatus.phoneConnected);
    _setMirror(MirrorStatus.waiting);
    _resetTimeout();

    channel.stream.listen(
      (message) {
        try {
          final data = json.decode(message as String) as Map<String, dynamic>;
          _handleMessage(data);
        } catch (_) {}
      },
      onDone: () {
        _phoneChannel = null;
        _timeoutTimer?.cancel();
        _setStatus(ServerStatus.listening);
        _setMirror(MirrorStatus.lost);
      },
      onError: (_) {
        _phoneChannel = null;
        _timeoutTimer?.cancel();
        _setStatus(ServerStatus.listening);
        _setMirror(MirrorStatus.lost);
      },
    );
  }

  void _handleMessage(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    switch (type) {
      case 'mirror_start':
        _setMirror(MirrorStatus.live);
        _resetTimeout();
        break;
      case 'mirror_stop':
        _setMirror(MirrorStatus.waiting);
        _timeoutTimer?.cancel();
        break;
      case 'ping':
        _resetTimeout();
        break;
      case 'nav_update':
        _resetTimeout();
        _setMirror(MirrorStatus.live);
        try {
          final state = NavState.fromJson(data);
          _navController.add(state);
        } catch (_) {}
        break;
    }
  }

  // If no message in 8 seconds, mark as lost
  void _resetTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 8), () {
      _setMirror(MirrorStatus.lost);
    });
  }

  Future<String> _getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (final iface in interfaces) {
        // Prefer wlan0 (WiFi) over eth0
        if (iface.name.startsWith('wlan') || iface.name.startsWith('w')) {
          for (final addr in iface.addresses) {
            if (!addr.isLoopback) return addr.address;
          }
        }
      }
      // Fallback to any non-loopback
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) return addr.address;
        }
      }
    } catch (_) {}
    return 'unknown';
  }

  void _setStatus(ServerStatus s) {
    _status = s;
    _statusController.add(s);
  }

  void _setMirror(MirrorStatus m) {
    _mirrorStatus = m;
    _mirrorController.add(m);
  }

  Future<void> stop() async {
    _timeoutTimer?.cancel();
    _phoneChannel?.sink.close();
    await _server?.close();
    _setStatus(ServerStatus.starting);
    _setMirror(MirrorStatus.waiting);
  }

  void dispose() {
    stop();
    _navController.close();
    _statusController.close();
    _mirrorController.close();
  }
}
