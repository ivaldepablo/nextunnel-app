import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nextunnel_app/features/nextunnel/data/nextunnel_api.dart';
import 'package:nextunnel_app/features/nextunnel/notifier/nextunnel_session_notifier.dart';

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final isLoading = useState(false);
    final errorMsg = useState<String?>(null);

    Future<void> handleLogin() async {
      if (emailController.text.trim().isEmpty || passwordController.text.isEmpty) {
        errorMsg.value = "Email and password are required";
        return;
      }
      isLoading.value = true;
      errorMsg.value = null;
      try {
        await ref.read(nexTunnelSessionProvider.notifier).login(
              email: emailController.text.trim(),
              password: passwordController.text,
            );
      } on NexTunnelApiException catch (e) {
        if (e.statusCode == 401) {
          errorMsg.value = "Invalid email or password";
        } else if (e.statusCode == 429) {
          errorMsg.value = "Too many attempts. Please wait a moment.";
        } else {
          errorMsg.value = "Login failed: ${e.message}";
        }
      } catch (e) {
        errorMsg.value = "Login failed. Check your connection.";
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.lock_outline, size: 64),
                const SizedBox(height: 16),
                Text(
                  "Welcome to NexTunnel",
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Sign in to load your VPN configuration",
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  enabled: !isLoading.value,
                  onSubmitted: (_) => handleLogin(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  enabled: !isLoading.value,
                  onSubmitted: (_) => handleLogin(),
                ),
                if (errorMsg.value != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: Theme.of(context).colorScheme.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errorMsg.value!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: isLoading.value ? null : handleLogin,
                  child: isLoading.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Sign in"),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: isLoading.value
                      ? null
                      : () {
                          // Sub-plan 03 will add the in-app signup flow.
                          // For now, redirect users to the web signup.
                          showDialog<void>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text("Create account"),
                              content: const Text(
                                "Visit https://nextunnel.com/signup to create your account, then return here to sign in.",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text("OK"),
                                ),
                              ],
                            ),
                          );
                        },
                  child: const Text("Don't have an account? Sign up"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
