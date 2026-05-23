import 'dart:convert';

import 'package:nextunnel_app/features/nextunnel/model/auth_session.dart';
import 'package:nextunnel_app/utils/custom_loggers.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kSessionKey = "nextunnel_session_v1";

class SessionRepository with InfraLogger {
  final SharedPreferences _prefs;
  SessionRepository(this._prefs);

  Future<AuthSession?> read() async {
    final raw = _prefs.getString(_kSessionKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return AuthSession(
        userId: json["userId"] as String,
        email: json["email"] as String,
        sessionToken: json["sessionToken"] as String,
        subscriptionToken: json["subscriptionToken"] as String,
        planName: json["planName"] as String?,
        planExpiresAt: json["planExpiresAt"] != null
            ? DateTime.parse(json["planExpiresAt"] as String)
            : null,
        createdAt: DateTime.parse(json["createdAt"] as String),
      );
    } catch (e) {
      loggy.warning("failed to deserialize session", e);
      return null;
    }
  }

  Future<void> write(AuthSession session) async {
    final json = {
      "userId": session.userId,
      "email": session.email,
      "sessionToken": session.sessionToken,
      "subscriptionToken": session.subscriptionToken,
      "planName": session.planName,
      "planExpiresAt": session.planExpiresAt?.toIso8601String(),
      "createdAt": session.createdAt.toIso8601String(),
    };
    await _prefs.setString(_kSessionKey, jsonEncode(json));
  }

  Future<void> clear() async {
    await _prefs.remove(_kSessionKey);
  }
}
