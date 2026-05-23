import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nextunnel_app/features/nextunnel/data/dnstun_client_controller.dart';
import 'package:nextunnel_app/features/nextunnel/notifier/nextunnel_session_notifier.dart';

/// Compact banner shown at the top of the HomePage. Displays:
/// - Signed-in user email + plan
/// - Auto-config bundle status (X outbounds, Y DNS-tunnel servers)
/// - "Emergency DNS Tunnel" button (starts MasterDnsVPN client locally)
class NexTunnelStatusBanner extends ConsumerWidget {
  const NexTunnelStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(nexTunnelSessionProvider).valueOrNull;
    final bundle = ref.watch(autoConfigBundleProvider).valueOrNull;
    final dnstunState = ref.watch(dnsTunnelClientProvider);
    final theme = Theme.of(context);

    if (session == null) return const SizedBox.shrink();

    final outboundCount = bundle?.outbounds.length ?? 0;
    final dnsTunCount = bundle?.dnsTunnel.length ?? 0;
    final hasBundle = bundle != null;
    final running = dnstunState == DnsTunnelStatus.running;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user_outlined,
                  color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(session.email,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis),
                    Text(
                      session.planName ?? "Free",
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () async {
                  await ref.read(nexTunnelSessionProvider.notifier).logout();
                },
                child: const Text("Sign out"),
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            children: [
              _Chip(
                icon: Icons.dns_outlined,
                label: hasBundle ? "$outboundCount outbounds" : "Loading...",
              ),
              const SizedBox(width: 8),
              _Chip(
                icon: Icons.security_outlined,
                label: hasBundle ? "$dnsTunCount DNS servers" : "—",
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Emergency DNS-tunnel: works when everything else is blocked
          ElevatedButton.icon(
            onPressed: !hasBundle || dnsTunCount == 0
                ? null
                : () async {
                    final ctrl = ref.read(dnsTunnelClientProvider.notifier);
                    if (running) {
                      await ctrl.stop();
                    } else {
                      final entry = bundle.dnsTunnel.first;
                      await ctrl.start(
                        domain: entry.dnsDomain,
                        encryptionKey: entry.encryptionKey,
                        resolvers: entry.resolvers,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                "Emergency tunnel via ${entry.serverName} started on 127.0.0.1:18000"),
                          ),
                        );
                      }
                    }
                  },
            icon: Icon(running ? Icons.stop_circle_outlined : Icons.bolt),
            label: Text(running
                ? "Stop Emergency DNS Tunnel"
                : "Start Emergency DNS Tunnel"),
            style: ElevatedButton.styleFrom(
              backgroundColor: running
                  ? theme.colorScheme.errorContainer
                  : theme.colorScheme.tertiaryContainer,
              foregroundColor: running
                  ? theme.colorScheme.onErrorContainer
                  : theme.colorScheme.onTertiaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(label,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
