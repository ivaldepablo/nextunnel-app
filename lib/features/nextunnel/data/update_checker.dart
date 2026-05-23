import 'dart:io';

import 'package:dio/dio.dart';
import 'package:nextunnel_app/core/model/constants.dart';
import 'package:nextunnel_app/utils/custom_loggers.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateInfo {
  final String latestVersion;
  final String? releaseNotes;
  final String? downloadUrl;
  final bool hasUpdate;

  const UpdateInfo({
    required this.latestVersion,
    this.releaseNotes,
    this.downloadUrl,
    required this.hasUpdate,
  });
}

class UpdateChecker with InfraLogger {
  final Dio _dio;
  UpdateChecker({Dio? dio}) : _dio = dio ?? Dio();

  Future<UpdateInfo?> check() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version;
      loggy.info("checking for updates (current: $currentVersion)");

      final res = await _dio.get(
        "${Constants.apiBaseUrl}/api/client/version",
        options: Options(
          headers: {"X-Client": "nextunnel-app"},
          validateStatus: (s) => s != null && s < 500,
        ),
      );

      if (res.statusCode != 200 || res.data is! Map<String, dynamic>) {
        loggy.warning("version endpoint returned ${res.statusCode}");
        return null;
      }

      final data = res.data as Map<String, dynamic>;
      final latest = data["version"] as String? ?? currentVersion;
      final platforms = data["platforms"] as Map<String, dynamic>?;

      final platformKey = _platformKey();
      final platformInfo = platforms?[platformKey] as Map<String, dynamic>?;
      final downloadUrl = platformInfo?["url"] as String?;

      return UpdateInfo(
        latestVersion: latest,
        releaseNotes: data["releaseNotes"] as String?,
        downloadUrl: downloadUrl,
        hasUpdate: _isNewer(latest, currentVersion),
      );
    } catch (e) {
      loggy.warning("update check failed: $e");
      return null;
    }
  }

  bool _isNewer(String latest, String current) {
    final l = latest.split(RegExp(r'[.\-+]')).take(3).map(int.tryParse).toList();
    final c = current.split(RegExp(r'[.\-+]')).take(3).map(int.tryParse).toList();
    for (var i = 0; i < 3; i++) {
      final lv = (i < l.length ? l[i] : 0) ?? 0;
      final cv = (i < c.length ? c[i] : 0) ?? 0;
      if (lv > cv) return true;
      if (lv < cv) return false;
    }
    return false;
  }

  String _platformKey() {
    if (Platform.isWindows) return "windows-x64";
    if (Platform.isMacOS) return "macos-arm64";
    if (Platform.isLinux) return "linux-x64";
    if (Platform.isAndroid) return "android";
    return "unknown";
  }
}
