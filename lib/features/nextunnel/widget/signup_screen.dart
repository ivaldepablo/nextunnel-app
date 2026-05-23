import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nextunnel_app/features/nextunnel/data/nextunnel_api.dart';
import 'package:nextunnel_app/features/nextunnel/notifier/nextunnel_session_notifier.dart';

class SignupScreen extends HookConsumerWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController();
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final confirmController = useTextEditingController();
    final isLoading = useState(false);
    final errorMsg = useState<String?>(null);

    Future<void> handleSignup() async {
      final name = nameController.text.trim();
      final email = emailController.text.trim();
      final pw = passwordController.text;
      final confirm = confirmController.text;

      if (name.isEmpty || email.isEmpty || pw.isEmpty) {
        errorMsg.value = "All fields are required";
        return;
      }
      if (pw != confirm) {
        errorMsg.value = "Passwords don't match";
        return;
      }
      if (pw.length < 8) {
        errorMsg.value = "Password must be at least 8 characters";
        return;
      }
      if (!RegExp(r'[A-Z]').hasMatch(pw) ||
          !RegExp(r'[a-z]').hasMatch(pw) ||
          !RegExp(r'[0-9]').hasMatch(pw)) {
        errorMsg.value = "Password must include uppercase, lowercase, and a number";
        return;
      }

      isLoading.value = true;
      errorMsg.value = null;
      try {
        await ref.read(nexTunnelSessionProvider.notifier).signup(
              name: name,
              email: email,
              password: pw,
            );
      } on NexTunnelApiException catch (e) {
        if (e.statusCode == 409) {
          errorMsg.value = "An account with this email already exists. Try signing in.";
        } else if (e.statusCode == 429) {
          errorMsg.value = "Too many sign-up attempts. Please wait a moment.";
        } else if (e.statusCode == 400) {
          errorMsg.value = "Check your input: ${e.message}";
        } else {
          errorMsg.value = "Sign-up failed: ${e.message}";
        }
      } catch (e) {
        errorMsg.value = "Sign-up failed. Check your connection.";
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Create your NexTunnel account")),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Full name",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  enabled: !isLoading.value,
                ),
                const SizedBox(height: 16),
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
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: "Password",
                    helperText: "Min 8 chars, with uppercase, lowercase, and a number",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  enabled: !isLoading.value,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmController,
                  decoration: const InputDecoration(
                    labelText: "Confirm password",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  enabled: !isLoading.value,
                  onSubmitted: (_) => handleSignup(),
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
                  onPressed: isLoading.value ? null : handleSignup,
                  child: isLoading.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Create account + start 3-day trial"),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: isLoading.value
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text("Already have an account? Sign in"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
