import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nextunnel_app/core/model/constants.dart';
import 'package:nextunnel_app/features/nextunnel/notifier/nextunnel_session_notifier.dart';
import 'package:url_launcher/url_launcher.dart';

class _Plan {
  final String slug;
  final String name;
  final String price;
  final String description;
  final String? badge;
  const _Plan({
    required this.slug,
    required this.name,
    required this.price,
    required this.description,
    this.badge,
  });
}

const _plans = <_Plan>[
  _Plan(
    slug: "basic",
    name: "Basic",
    price: "\$5.99/mo",
    description: "1 device, unlimited bandwidth, all servers",
  ),
  _Plan(
    slug: "premium",
    name: "Premium",
    price: "\$7.99/mo",
    description: "3 devices, priority support, all servers",
    badge: "Most popular",
  ),
  _Plan(
    slug: "unlimited",
    name: "Unlimited",
    price: "\$9.99/mo",
    description: "10 devices, dedicated IP option, all servers",
  ),
];

class UpgradeScreen extends ConsumerWidget {
  const UpgradeScreen({super.key});

  Future<void> _openCheckout(WidgetRef ref, String planSlug) async {
    final session = ref.read(nexTunnelSessionProvider).value;
    if (session == null) return;
    // Hand off to the web for the payment step. Stripe + NowPayments + Lavatop
    // are all wired up server-side; the web bridge handles redirecting back
    // via the nextunnel:// custom scheme once payment succeeds.
    final uri = Uri.parse(
      "${Constants.apiBaseUrl}/checkout/redirect"
      "?token=${Uri.encodeQueryComponent(session.sessionToken)}"
      "&plan=$planSlug"
      "&return=nextunnel://payment-complete",
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text("Choose a plan")),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _plans.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final plan = _plans[i];
          return Card(
            elevation: plan.badge != null ? 4 : 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          plan.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      if (plan.badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            plan.badge!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    plan.price,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(plan.description),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => _openCheckout(ref, plan.slug),
                    child: const Text("Subscribe"),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
