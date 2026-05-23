import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nextunnel_app/core/preferences/preferences_provider.dart';
import 'package:nextunnel_app/features/nextunnel/data/dnstun_client_controller.dart';
import 'package:nextunnel_app/features/nextunnel/data/nextunnel_api.dart';
import 'package:nextunnel_app/features/nextunnel/data/session_repository.dart';
import 'package:nextunnel_app/features/nextunnel/model/auth_session.dart';
import 'package:nextunnel_app/features/nextunnel/model/config_bundle.dart';
import 'package:nextunnel_app/utils/custom_loggers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'nextunnel_session_notifier.g.dart';

@Riverpod(keepAlive: true)
NexTunnelApi nexTunnelApi(Ref ref) {
  return NexTunnelApi(dio: Dio());
}

@Riverpod(keepAlive: true)
SessionRepository sessionRepository(Ref ref) {
  return SessionRepository(ref.watch(sharedPreferencesProvider).requireValue);
}

@Riverpod(keepAlive: true)
DnsTunnelClientController dnsTunnelClient(Ref ref) {
  final controller = DnsTunnelClientController();
  ref.onDispose(() => controller.stop());
  return controller;
}

@Riverpod(keepAlive: true)
class NexTunnelSession extends _$NexTunnelSession with InfraLogger {
  @override
  Future<AuthSession?> build() async {
    return ref.watch(sessionRepositoryProvider).read();
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    try {
      final session = await ref.read(nexTunnelApiProvider).login(email: email, password: password);
      await ref.read(sessionRepositoryProvider).write(session);
      state = AsyncData(session);
      loggy.info("login OK for $email");
    } catch (e, st) {
      loggy.warning("login failed for $email: $e");
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> signup({
    required String name,
    required String email,
    required String password,
    String? locale,
  }) async {
    state = const AsyncLoading();
    try {
      final session = await ref.read(nexTunnelApiProvider).signup(
            name: name,
            email: email,
            password: password,
            locale: locale,
          );
      await ref.read(sessionRepositoryProvider).write(session);
      state = AsyncData(session);
      loggy.info("signup OK for $email");
    } catch (e, st) {
      loggy.warning("signup failed for $email: $e");
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> logout() async {
    await ref.read(sessionRepositoryProvider).clear();
    state = const AsyncData(null);
  }
}

/// Fetches the auto-config bundle (sing-box outbounds + DNS tunnel entries)
/// for the current session. Refreshes every hour while the app is open.
@Riverpod(keepAlive: true)
Future<ConfigBundle?> autoConfigBundle(Ref ref) async {
  final sessionAsync = ref.watch(nexTunnelSessionProvider);
  final session = sessionAsync.value;
  if (session == null) return null;

  // Refresh every 1h
  Future.delayed(const Duration(hours: 1), () => ref.invalidateSelf());

  return ref.read(nexTunnelApiProvider).fetchAutoConfig(sessionToken: session.sessionToken);
}

