import 'package:flutter/material.dart';
import '../services/websocket_server.dart';

class WaitingScreen extends StatelessWidget {
  final ServerStatus status;
  final String serverIp;

  const WaitingScreen({
    super.key,
    required this.status,
    required this.serverIp,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated dots indicator
              _PulsingDot(active: status == ServerStatus.listening ||
                  status == ServerStatus.phoneConnected),
              const SizedBox(height: 32),

              Text(
                _title(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _subtitle(),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),

              if (status == ServerStatus.listening ||
                  status == ServerStatus.phoneConnected) ...[
                const SizedBox(height: 40),
                _IpCard(ip: serverIp),
              ],

              if (status == ServerStatus.error) ...[
                const SizedBox(height: 24),
                const Text(
                  'Check that port 8765 is not in use.\nRestart the app to retry.',
                  style: TextStyle(color: Colors.red, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _title() {
    switch (status) {
      case ServerStatus.starting:
        return 'Starting server...';
      case ServerStatus.listening:
        return 'Waiting for phone';
      case ServerStatus.phoneConnected:
        return 'Phone connected\nWaiting for mirror...';
      case ServerStatus.error:
        return 'Server error';
    }
  }

  String _subtitle() {
    switch (status) {
      case ServerStatus.starting:
        return 'Initialising WebSocket server';
      case ServerStatus.listening:
        return 'Open BikeNav on your phone\nand tap "Mirror to bike"';
      case ServerStatus.phoneConnected:
        return 'Tap "Mirror to bike" on the phone app';
      case ServerStatus.error:
        return 'Could not start WebSocket server';
    }
  }
}

class _IpCard extends StatelessWidget {
  final String ip;
  const _IpCard({required this.ip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text(
            'Enter this IP in the phone app:',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ip,
            style: const TextStyle(
              color: Color(0xFF58A6FF),
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Port: 8765',
            style: TextStyle(
              color: Colors.white.withOpacity(0.35),
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final bool active;
  const _PulsingDot({required this.active});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.red.withOpacity(0.5), width: 2),
        ),
        child: const Icon(Icons.error_outline, color: Colors.red, size: 32),
      );
    }
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFF1565C0).withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(
              color: const Color(0xFF58A6FF).withOpacity(0.6), width: 2),
        ),
        child: const Icon(Icons.wifi, color: Color(0xFF58A6FF), size: 32),
      ),
    );
  }
}
