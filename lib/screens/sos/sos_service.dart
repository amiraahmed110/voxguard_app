import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/api_config.dart';

/// An active emergency session, returned by the backend when an SOS is opened.
@immutable
class SosSession {
  const SosSession({required this.sosId, required this.token});

  final int sosId;
  final String token;
}

/// Owns the lifecycle of an SOS alert, with no UI dependencies so it can be
/// shared by both the manual flow ([EmergencyScreen]) and the AI
/// auto-detection flow.
///
/// Responsibilities:
///  * [startSession]        – open a session on the server with the current GPS.
///  * [startBackgroundGuard]– launch the foreground service (live location +
///                            audio recording) that survives the screen going off.
///  * [cancelSession]       – close a session that was aborted during the
///                            cancel grace period.
class SosService {
  const SosService();

  static const Duration _locationTimeout = Duration(seconds: 5);

  /// Opens a new SOS session on the backend.
  ///
  /// Captures the current location (falling back to the last known position,
  /// then to `0.0, 0.0`) and posts it to `/sos/start`. Returns the created
  /// [SosSession], or `null` if the device is unauthenticated or the request
  /// fails — the caller decides how to surface that.
  Future<SosSession?> startSession({required String triggerType}) async {
    final token = await _readToken();
    if (token == null) {
      debugPrint('SosService: no auth token, cannot start session.');
      return null;
    }

    final position = await _currentPosition();

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.sosBaseUrl}/start'),
        headers: _jsonHeaders(token),
        body: jsonEncode({
          'latitude': position?.latitude.toString() ?? '0.0',
          'longitude': position?.longitude.toString() ?? '0.0',
          'trigger_type': triggerType,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final sosId = data['sos_id'] as int;

        // Persist so SafeHomeScreen / the background service can recover the
        // active session id if they are reached without it.
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('current_sos_id', sosId);

        return SosSession(sosId: sosId, token: token);
      }

      debugPrint('SosService: start failed '
          '(${response.statusCode}) ${response.body}');
    } catch (e) {
      debugPrint('SosService: start error $e');
    }
    return null;
  }

  /// Starts the foreground background service and hands it the session so it
  /// can stream live location and record audio while the screen is off.
  Future<void> startBackgroundGuard({
    required SosSession session,
    required bool shareLocation,
    required bool recordAudio,
  }) async {
    try {
      final service = FlutterBackgroundService();
      await service.startService();

      // Give the isolate a moment to spin up before delivering the payload.
      await Future<void>.delayed(const Duration(milliseconds: 800));

      service.invoke('startSOS', {
        'sos_id': session.sosId,
        'token': session.token,
        'share_location': shareLocation,
        'record_audio': recordAudio,
      });
    } catch (e) {
      debugPrint('SosService: background guard error $e');
    }
  }

  /// Best-effort close of a session the user cancelled during the countdown.
  /// Failures are swallowed since the alert never really started.
  Future<void> cancelSession(SosSession session) async {
    try {
      await http.post(
        Uri.parse('${ApiConfig.sosBaseUrl}/${session.sosId}/safe'),
        headers: {
          'Authorization': 'Bearer ${session.token}',
          'Accept': 'application/json',
        },
      );
    } catch (e) {
      debugPrint('SosService: cancel error $e');
    }
  }

  // --- helpers -------------------------------------------------------------

  Future<String?> _readToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? prefs.getString('auth_token');
  }

  /// Best available position: a fresh high-accuracy fix, else the last known
  /// one, else `null` (e.g. permission denied or location services off).
  Future<Position?> _currentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: _locationTimeout,
      );
    } catch (_) {
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
  }

  Map<String, String> _jsonHeaders(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
}
