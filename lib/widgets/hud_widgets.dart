import 'package:flutter/material.dart';
import '../models/nav_state.dart';

/// Top status bar: connection quality + mirror status
class StatusBar extends StatelessWidget {
  final MirrorStatus mirrorStatus;
  final DateTime? lastUpdate;

  const StatusBar({
    super.key,
    required this.mirrorStatus,
    this.lastUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final staleness = lastUpdate == null
        ? null
        : DateTime.now().difference(lastUpdate!).inSeconds;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _dot(),
          const SizedBox(width: 6),
          Text(
            _label(staleness),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          if (staleness != null && mirrorStatus == MirrorStatus.live) ...[
            const SizedBox(width: 6),
            Text(
              '${staleness}s ago',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 10,
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _dot() {
    final color = mirrorStatus == MirrorStatus.live
        ? Colors.greenAccent
        : mirrorStatus == MirrorStatus.waiting
            ? Colors.orangeAccent
            : Colors.redAccent;
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  String _label(int? staleness) {
    switch (mirrorStatus) {
      case MirrorStatus.live:
        return 'LIVE';
      case MirrorStatus.waiting:
        return 'WAITING';
      case MirrorStatus.lost:
        return 'SIGNAL LOST';
    }
  }
}

/// Bottom HUD panel — distance and ETA
class RouteHud extends StatelessWidget {
  final NavState state;

  const RouteHud({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (!state.hasRoute) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.72),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Stat(
            label: 'DISTANCE',
            value: state.distanceText,
            icon: Icons.straighten,
          ),
          if (state.durationText.isNotEmpty) ...[
            Container(
              width: 1,
              height: 32,
              color: Colors.white.withOpacity(0.2),
              margin: const EdgeInsets.symmetric(horizontal: 14),
            ),
            _Stat(
              label: 'ETA',
              value: state.durationText,
              icon: Icons.timer_outlined,
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _Stat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.6), size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Compass / heading indicator
class HeadingIndicator extends StatelessWidget {
  final double heading;

  const HeadingIndicator({super.key, required this.heading});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: heading * 3.14159 / 180,
            child: const Icon(
              Icons.navigation,
              color: Color(0xFF58A6FF),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

/// Signal lost overlay shown over the map
class SignalLostOverlay extends StatelessWidget {
  const SignalLostOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.65),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.signal_wifi_off,
                color: Colors.white.withOpacity(0.7), size: 48),
            const SizedBox(height: 12),
            const Text(
              'Signal lost',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Waiting for phone to reconnect...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
