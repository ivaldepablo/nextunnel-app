import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class ConnectionTimer extends HookConsumerWidget {
  const ConnectionTimer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionStatus = ref.watch(connectionNotifierProvider);
    final isConnected = connectionStatus.valueOrNull is Connected;

    final elapsed = useState(Duration.zero);
    final startTime = useRef<DateTime?>(null);

    useEffect(() {
      if (isConnected) {
        startTime.value ??= DateTime.now();
        final timer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (startTime.value != null) {
            elapsed.value = DateTime.now().difference(startTime.value!);
          }
        });
        return timer.cancel;
      } else {
        startTime.value = null;
        elapsed.value = Duration.zero;
        return null;
      }
    }, [isConnected]);

    if (!isConnected) return const SizedBox.shrink();

    final hours = elapsed.value.inHours.toString().padLeft(2, '0');
    final minutes = (elapsed.value.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (elapsed.value.inSeconds % 60).toString().padLeft(2, '0');
    final timerText = "$hours:$minutes:$seconds";

    final theme = Theme.of(context);

    return AnimatedOpacity(
      opacity: isConnected ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Text(
        timerText,
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w300,
          letterSpacing: 2.0,
          fontFeatures: [const FontFeature.tabularFigures()],
          color: theme.colorScheme.onSurface.withValues(alpha: .7),
        ),
      ),
    );
  }
}
