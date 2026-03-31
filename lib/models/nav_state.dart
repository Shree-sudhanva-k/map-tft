import 'package:latlong2/latlong.dart';

enum MirrorStatus { waiting, live, lost }

class NavState {
  final LatLng location;
  final double heading;
  final double zoom;
  final LatLng? destination;
  final List<LatLng> routePoints;
  final double? distanceMeters;
  final int? durationSeconds;
  final DateTime receivedAt;

  NavState({
    required this.location,
    required this.heading,
    required this.zoom,
    this.destination,
    this.routePoints = const [],
    this.distanceMeters,
    this.durationSeconds,
    required this.receivedAt,
  });

  bool get hasRoute => routePoints.isNotEmpty;

  String get distanceText {
    if (distanceMeters == null) return '';
    if (distanceMeters! >= 1000) {
      return '${(distanceMeters! / 1000).toStringAsFixed(1)} km';
    }
    return '${distanceMeters!.toInt()} m';
  }

  String get durationText {
    if (durationSeconds == null) return '';
    final minutes = (durationSeconds! / 60).round();
    if (minutes >= 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      return '${h}h ${m}m';
    }
    return '$minutes min';
  }

  /// Parse from the WebSocket JSON payload sent by the phone app
  factory NavState.fromJson(Map<String, dynamic> json) {
    final lat = (json['lat'] as num).toDouble();
    final lng = (json['lng'] as num).toDouble();
    final heading = (json['heading'] as num?)?.toDouble() ?? 0.0;
    final zoom = (json['zoom'] as num?)?.toDouble() ?? 15.0;

    LatLng? destination;
    if (json['dest_lat'] != null && json['dest_lng'] != null) {
      destination = LatLng(
        (json['dest_lat'] as num).toDouble(),
        (json['dest_lng'] as num).toDouble(),
      );
    }

    List<LatLng> routePoints = [];
    if (json['route'] != null) {
      final rawRoute = json['route'] as List;
      routePoints = rawRoute.map((p) {
        final point = p as Map<String, dynamic>;
        return LatLng(
          (point['lat'] as num).toDouble(),
          (point['lng'] as num).toDouble(),
        );
      }).toList();
    }

    return NavState(
      location: LatLng(lat, lng),
      heading: heading,
      zoom: zoom,
      destination: destination,
      routePoints: routePoints,
      distanceMeters: (json['distance'] as num?)?.toDouble(),
      durationSeconds: (json['duration'] as num?)?.toInt(),
      receivedAt: DateTime.now(),
    );
  }
}
