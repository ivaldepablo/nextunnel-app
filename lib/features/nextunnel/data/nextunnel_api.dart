import 'package:dio/dio.dart';
import 'package:nextunnel_app/core/model/constants.dart';
import 'package:nextunnel_app/features/nextunnel/model/auth_session.dart';
import 'package:nextunnel_app/features/nextunnel/model/config_bundle.dart';
import 'package:nextunnel_app/utils/custom_loggers.dart';

class NexTunnelApiException implements Exception {
  final int? statusCode;
  final String message;
  NexTunnelApiException(this.message, {this.statusCode});

  @override
  String toString() => "NexTunnelApiException($statusCode): $message";
}

class NexTunnelApi with InfraLogger {
  final Dio _dio;

  NexTunnelApi({required Dio dio}) : _dio = dio;

  /// Sign up a new account (with 3-day auto-trial). Returns an AuthSession.
  Future<AuthSession> signup({
    required String name,
    required String email,
    required String password,
    String? locale,
  }) async {
    try {
      final res = await _dio.post(
        "${Constants.apiBaseUrl}/api/client/signup",
        data: {
          "name": name,
          "email": email,
          "password": password,
          if (locale != null) "locale": locale,
        },
        options: Options(
          headers: {"Content-Type": "application/json", "X-Client": "nextunnel-app"},
          validateStatus: (s) => s != null && s < 500,
        ),
      );

      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        final data = res.data as Map<String, dynamic>;
        return AuthSession(
          userId: data["userId"] as String,
          email: data["email"] as String,
          sessionToken: data["sessionToken"] as String,
          subscriptionToken: data["subscriptionToken"] as String,
          planName: data["planName"] as String?,
          planExpiresAt: data["planExpiresAt"] != null
              ? DateTime.parse(data["planExpiresAt"] as String)
              : null,
          createdAt: DateTime.now(),
        );
      }

      final body = res.data;
      final msg = body is Map<String, dynamic> ? (body["error"]?.toString() ?? "signup_failed") : "signup_failed";
      throw NexTunnelApiException(msg, statusCode: res.statusCode);
    } on DioException catch (e) {
      throw NexTunnelApiException(e.message ?? "network_error", statusCode: e.response?.statusCode);
    }
  }

  /// Login with email + password. Returns the AuthSession or throws.
  /// Maps to POST /api/auth/callback/credentials (NextAuth) or
  /// POST /api/client/login (custom — currently planned).
  Future<AuthSession> login({required String email, required String password}) async {
    try {
      final res = await _dio.post(
        "${Constants.apiBaseUrl}/api/client/login",
        data: {"email": email, "password": password},
        options: Options(
          headers: {"Content-Type": "application/json", "X-Client": "nextunnel-app"},
          validateStatus: (s) => s != null && s < 500,
        ),
      );

      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        final data = res.data as Map<String, dynamic>;
        return AuthSession(
          userId: data["userId"] as String,
          email: data["email"] as String,
          sessionToken: data["sessionToken"] as String,
          subscriptionToken: data["subscriptionToken"] as String,
          planName: data["planName"] as String?,
          planExpiresAt: data["planExpiresAt"] != null
              ? DateTime.parse(data["planExpiresAt"] as String)
              : null,
          createdAt: DateTime.now(),
        );
      }

      final body = res.data;
      final msg = body is Map<String, dynamic> ? (body["error"]?.toString() ?? "login_failed") : "login_failed";
      throw NexTunnelApiException(msg, statusCode: res.statusCode);
    } on DioException catch (e) {
      throw NexTunnelApiException(e.message ?? "network_error", statusCode: e.response?.statusCode);
    }
  }

  /// Fetch auto-config bundle: sing-box outbounds + DNS tunnel entries.
  /// Maps to GET /api/client/auto-config?country=XX (server-side route already exists).
  Future<ConfigBundle> fetchAutoConfig({required String sessionToken, String? country}) async {
    try {
      final res = await _dio.get(
        "${Constants.apiBaseUrl}/api/client/auto-config",
        queryParameters: country != null ? {"country": country} : null,
        options: Options(
          headers: {
            "Authorization": "Bearer $sessionToken",
            "X-Client": "nextunnel-app",
          },
          validateStatus: (s) => s != null && s < 500,
        ),
      );

      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        final data = res.data as Map<String, dynamic>;
        final bundle = data["bundle"] as Map<String, dynamic>;

        return ConfigBundle(
          outbounds: ((bundle["outbounds"] as List?) ?? [])
              .whereType<Map<String, dynamic>>()
              .map((m) => ConfigBundleOutbound(
                    tag: m["tag"] as String? ?? "",
                    type: m["type"] as String? ?? "",
                    server: m["server"] as String? ?? "",
                    serverPort: m["server_port"] as int?,
                    uuid: m["uuid"] as String?,
                    password: m["password"] as String?,
                    tls: m["tls"] as Map<String, dynamic>?,
                    transport: m["transport"] as Map<String, dynamic>?,
                  ))
              .toList(),
          dnsTunnel: ((bundle["dnsTunnel"] as List?) ?? [])
              .whereType<Map<String, dynamic>>()
              .map((m) => DnsTunnelEntry(
                    serverName: m["serverName"] as String? ?? "",
                    country: m["country"] as String? ?? "",
                    dnsDomain: m["dnsDomain"] as String? ?? "",
                    encryptionKey: m["encryptionKey"] as String? ?? "",
                    resolvers: ((m["resolvers"] as List?) ?? [])
                        .whereType<String>()
                        .toList(),
                  ))
              .toList(),
          recommendedOutbound: bundle["recommendedOutbound"] as String?,
          generatedAt: bundle["generatedAt"] as int? ?? DateTime.now().millisecondsSinceEpoch,
        );
      }

      throw NexTunnelApiException("config_fetch_failed", statusCode: res.statusCode);
    } on DioException catch (e) {
      throw NexTunnelApiException(e.message ?? "network_error", statusCode: e.response?.statusCode);
    }
  }

  /// Fetch resolver list for a given country (no auth required).
  Future<List<String>> fetchResolversForCountry(String countryIso2) async {
    try {
      final res = await _dio.get(
        "${Constants.apiBaseUrl}/api/client/resolvers/$countryIso2",
        options: Options(
          headers: {"X-Client": "nextunnel-app"},
          validateStatus: (s) => s != null && s < 500,
        ),
      );

      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        final data = res.data as Map<String, dynamic>;
        return ((data["resolvers"] as List?) ?? []).whereType<String>().toList();
      }

      return const [];
    } on DioException {
      return const [];
    }
  }

  /// Send protocol success telemetry (best-effort; failures swallowed).
  Future<void> sendTelemetry({
    required String sessionToken,
    required String protocol,
    required String serverName,
    required bool success,
    int? latencyMs,
    String? errorCode,
  }) async {
    try {
      await _dio.post(
        "${Constants.apiBaseUrl}/api/client/telemetry",
        data: {
          "protocol": protocol,
          "serverName": serverName,
          "success": success,
          if (latencyMs != null) "latencyMs": latencyMs,
          if (errorCode != null) "errorCode": errorCode,
        },
        options: Options(
          headers: {
            "Authorization": "Bearer $sessionToken",
            "X-Client": "nextunnel-app",
            "Content-Type": "application/json",
          },
          validateStatus: (s) => s != null && s < 500,
        ),
      );
    } catch (_) {
      // Telemetry never breaks the user flow
    }
  }
}
