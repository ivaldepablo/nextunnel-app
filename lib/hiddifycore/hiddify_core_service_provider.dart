import 'package:nextunnel_app/core/directories/directories_provider.dart';
import 'package:nextunnel_app/core/notification/in_app_notification_controller.dart';
import 'package:nextunnel_app/core/preferences/general_preferences.dart';
import 'package:nextunnel_app/hiddifycore/hiddify_core_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'hiddify_core_service_provider.g.dart';

@Riverpod(keepAlive: true, dependencies: [AppDirectories, DebugModeNotifier, inAppNotificationController])
HiddifyCoreService hiddifyCoreService(Ref ref) {
  return HiddifyCoreService(ref);
}
