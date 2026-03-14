import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/bottom_sheets/bottom_sheets_notifier.dart';
import 'package:hiddify/core/router/dialog/dialog_notifier.dart';
import 'package:hiddify/core/theme/theme_extensions.dart';
import 'package:hiddify/core/widget/animated_text.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/features/settings/notifier/config_option/config_option_notifier.dart';
import 'package:hiddify/gen/assets.gen.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ConnectionButton extends HookConsumerWidget {
  const ConnectionButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final connectionStatus = ref.watch(connectionNotifierProvider);
    final activeProxy = ref.watch(activeProxyNotifierProvider);
    final delay = activeProxy.valueOrNull?.urlTestDelay ?? 0;

    final requiresReconnect = ref.watch(configOptionNotifierProvider).valueOrNull;

    const buttonTheme = ConnectionButtonTheme.light;

    var secureLabel =
        (ref.watch(ConfigOptions.enableWarp) && ref.watch(ConfigOptions.warpDetourMode) == WarpDetourMode.warpOverProxy)
        ? t.connection.secure
        : "";
    if (delay <= 0 || delay > 65000 || connectionStatus.value != const Connected()) {
      secureLabel = "";
    }

    final bool isConnected = connectionStatus.value == const Connected() &&
        delay > 0 &&
        delay < 65000 &&
        requiresReconnect != true;

    return _ConnectionButton(
      onTap: switch (connectionStatus) {
        AsyncData(value: Connected()) when requiresReconnect == true => () async {
          final activeProfile = await ref.read(activeProfileProvider.future);
          return await ref.read(connectionNotifierProvider.notifier).reconnect(activeProfile);
        },
        AsyncData(value: Disconnected()) || AsyncError() => () async {
          if (ref.read(activeProfileProvider).valueOrNull == null) {
            await ref.read(dialogNotifierProvider.notifier).showNoActiveProfile();
            ref.read(bottomSheetsNotifierProvider.notifier).showAddProfile();
          }
          if (await ref.read(dialogNotifierProvider.notifier).showExperimentalFeatureNotice()) {
            return await ref.read(connectionNotifierProvider.notifier).toggleConnection();
          }
        },
        AsyncData(value: Connected()) => () async {
          if (requiresReconnect == true &&
              await ref.read(dialogNotifierProvider.notifier).showExperimentalFeatureNotice()) {
            return await ref
                .read(connectionNotifierProvider.notifier)
                .reconnect(await ref.read(activeProfileProvider.future));
          }
          return await ref.read(connectionNotifierProvider.notifier).toggleConnection();
        },
        _ => () {},
      },
      enabled: switch (connectionStatus) {
        AsyncData(value: Connected()) || AsyncData(value: Disconnected()) || AsyncError() => true,
        _ => false,
      },
      label: switch (connectionStatus) {
        AsyncData(value: Connected()) when requiresReconnect == true => t.connection.reconnect,
        AsyncData(value: Connected()) when delay <= 0 || delay >= 65000 => t.connection.connecting,
        AsyncData(value: final status) => status.present(t),
        _ => "",
      },
      buttonColor: switch (connectionStatus) {
        AsyncData(value: Connected()) when requiresReconnect == true => Colors.teal,
        AsyncData(value: Connected()) when delay <= 0 || delay >= 65000 => const Color.fromARGB(255, 185, 176, 103),
        AsyncData(value: Connected()) => buttonTheme.connectedColor!,
        AsyncData(value: _) => buttonTheme.idleColor!,
        _ => buttonTheme.disconnectedColor ?? Colors.red,
      },
      isConnected: isConnected,
      isConnecting: connectionStatus.value is Connecting,
      secureLabel: secureLabel,
    );
  }
}

class _ConnectionButton extends StatelessWidget {
  const _ConnectionButton({
    required this.onTap,
    required this.enabled,
    required this.label,
    required this.buttonColor,
    required this.isConnected,
    required this.isConnecting,
    required this.secureLabel,
  });

  final VoidCallback onTap;
  final bool enabled;
  final String label;
  final Color buttonColor;
  final bool isConnected;
  final bool isConnecting;
  final String secureLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 600;
    final buttonSize = isDesktop ? 148.0 : 132.0;
    final iconPadding = isDesktop ? 36.0 : 30.0;

    // Protection status text
    final protectionText = isConnected ? "Protected" : "Not Protected";
    final protectionColor = isConnected
        ? const Color(0xFF22c55e)
        : const Color(0xFFef4444);
    final protectionIcon = isConnected
        ? FontAwesomeIcons.shieldHalved
        : FontAwesomeIcons.shieldVirus;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Semantics(
          button: true,
          enabled: enabled,
          label: label,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  blurRadius: 24,
                  spreadRadius: isConnected ? 4 : 0,
                  color: buttonColor.withValues(alpha: isConnected ? .45 : .35),
                ),
                if (isConnected)
                  BoxShadow(
                    blurRadius: 48,
                    spreadRadius: 8,
                    color: buttonColor.withValues(alpha: .15),
                  ),
              ],
            ),
            width: buttonSize,
            height: buttonSize,
            child: Material(
              key: const ValueKey("home_connection_button"),
              shape: const CircleBorder(),
              color: Colors.white,
              child: InkWell(
                focusColor: Colors.grey,
                onTap: onTap,
                child: Padding(
                  padding: EdgeInsets.all(iconPadding),
                  child: TweenAnimationBuilder(
                    tween: ColorTween(end: buttonColor),
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut,
                    builder: (context, value, child) {
                      return Assets.images.logo.svg(
                        colorFilter: ColorFilter.mode(value!, BlendMode.srcIn),
                      );
                    },
                  ),
                ),
              ),
            ).animate(target: enabled ? 0 : 1).blurXY(end: 1),
          ).animate(target: enabled ? 0 : 1).scaleXY(end: .88, curve: Curves.easeIn),
        ),
        const Gap(16),
        ExcludeSemantics(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedText(label, style: theme.textTheme.titleMedium),
              const Gap(6),
              // Protection status indicator
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Row(
                  key: ValueKey(isConnected),
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(protectionIcon, size: 14, color: protectionColor),
                    const Gap(6),
                    Text(
                      protectionText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: protectionColor,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (secureLabel.isNotEmpty) ...[
                const Gap(4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(FontAwesomeIcons.shieldHalved, size: 16, color: theme.colorScheme.secondary),
                    const Gap(4),
                    Text(
                      secureLabel,
                      style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.secondary),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
