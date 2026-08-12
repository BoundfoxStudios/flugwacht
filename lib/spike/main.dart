import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

const frankfurt = LatLng(50.033, 8.570);
const searchRadiusNauticalMiles = 250;
const pollInterval = Duration(seconds: 3);
const maximumMarkers = 300;

void main() {
  runApp(const SpikeApp());
}

class SpikeApp extends StatelessWidget {
  const SpikeApp({super.key});

  @override
  Widget build(final BuildContext context) =>
      const MaterialApp(debugShowCheckedModeBanner: false, home: SpikeScreen());
}

class Aircraft {
  const Aircraft({
    required this.hex,
    required this.callsign,
    required this.position,
    required this.altitude,
    required this.groundSpeedKnots,
    required this.trackDegrees,
    required this.positionAgeSeconds,
  });

  final String hex;
  final String callsign;
  final LatLng position;
  final Object? altitude;
  final double? groundSpeedKnots;
  final double? trackDegrees;
  final double? positionAgeSeconds;

  static Aircraft? fromJson(final Map<String, dynamic> json) {
    final latitude = json['lat'];
    final longitude = json['lon'];
    if (latitude is! num || longitude is! num) {
      return null;
    }
    return Aircraft(
      hex: json['hex'] as String? ?? '',
      callsign: (json['flight'] as String? ?? '').trim(),
      position: LatLng(latitude.toDouble(), longitude.toDouble()),
      altitude: json['alt_baro'],
      groundSpeedKnots: (json['gs'] as num?)?.toDouble(),
      trackDegrees: (json['track'] as num?)?.toDouble(),
      positionAgeSeconds: (json['seen_pos'] as num?)?.toDouble(),
    );
  }

  String get label => callsign.isEmpty ? hex : callsign;

  String get altitudeLabel => switch (altitude) {
    final num feet => '${feet.round()} ft',
    'ground' => 'am Boden',
    _ => 'unbekannt',
  };
}

class SpikeScreen extends StatefulWidget {
  const SpikeScreen({super.key});

  @override
  State<SpikeScreen> createState() => _SpikeScreenState();
}

class _SpikeScreenState extends State<SpikeScreen> {
  final List<Aircraft> _aircraft = [];
  Timer? _pollTimer;
  bool _requestInFlight = false;
  String? _selectedHex;
  DateTime? _lastFetchedAt;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    _fetchAircraft();
    _pollTimer = Timer.periodic(pollInterval, (_) => _fetchAircraft());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchAircraft() async {
    if (_requestInFlight) {
      return;
    }
    _requestInFlight = true;
    try {
      final uri = Uri.parse(
        'https://api.adsb.lol/v2/point/${frankfurt.latitude}/${frankfurt.longitude}/$searchRadiusNauticalMiles',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw http.ClientException('HTTP ${response.statusCode}');
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final entries = (body['ac'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(Aircraft.fromJson)
          .whereType<Aircraft>()
          .take(maximumMarkers)
          .toList();
      if (!mounted) {
        return;
      }
      setState(() {
        _aircraft
          ..clear()
          ..addAll(entries);
        _lastFetchedAt = DateTime.now();
        _lastError = null;
      });
    } on Exception catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _lastError = error.toString());
    } finally {
      _requestInFlight = false;
    }
  }

  Aircraft? get _selectedAircraft {
    for (final aircraft in _aircraft) {
      if (aircraft.hex == _selectedHex) {
        return aircraft;
      }
    }
    return null;
  }

  @override
  Widget build(final BuildContext context) {
    final selected = _selectedAircraft;
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(initialCenter: frankfurt, initialZoom: 7),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'flugwacht.spike',
              ),
              MarkerLayer(
                markers: [
                  for (final aircraft in _aircraft)
                    Marker(
                      point: aircraft.position,
                      width: 32,
                      height: 32,
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedHex = aircraft.hex),
                        child: Transform.rotate(
                          angle: (aircraft.trackDegrees ?? 0) * pi / 180,
                          child: Icon(
                            Icons.flight,
                            size: 26,
                            color: aircraft.hex == _selectedHex
                                ? Colors.amber.shade700
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: _OverlayCard(
                child: Text(
                  _lastError != null
                      ? 'Fehler: $_lastError'
                      : '${_aircraft.length} Flugzeuge · Stand ${_lastFetchedAt != null ? _formatTime(_lastFetchedAt!) : '–'}',
                ),
              ),
            ),
          ),
          const SafeArea(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: _OverlayCard(
                child: Text('© OpenStreetMap · Daten: adsb.lol'),
              ),
            ),
          ),
          if (selected != null)
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _OverlayCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selected.label,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('Höhe: ${selected.altitudeLabel}'),
                      Text(
                        'Tempo: ${selected.groundSpeedKnots?.round() ?? '–'} kt',
                      ),
                      Text(
                        'Signal: vor ${selected.positionAgeSeconds?.round() ?? '–'} s',
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(final DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
}

class _OverlayCard extends StatelessWidget {
  const _OverlayCard({required this.child});

  final Widget child;

  @override
  Widget build(final BuildContext context) => Container(
    margin: const EdgeInsets.all(8),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(8),
    ),
    child: DefaultTextStyle(
      style: const TextStyle(color: Colors.black87, fontSize: 13),
      child: child,
    ),
  );
}
