import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../auth/sign_up_validator.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/web_qr_login_panel.dart';
import 'sign_up_screen.dart';

class SignInScreen extends StatefulWidget {
  final AuthService auth;

  /// The QR panel lets a phone sign this browser in, so it's web-only.
  final bool showQrPanel;

  const SignInScreen({
    super.key,
    this.auth = const FirebaseAuthService(),
    this.showQrPanel = kIsWeb,
  });

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;
  bool submitted = false;
  bool loading = false;
  String? formError;

  String? get emailError =>
      submitted ? SignUpValidator.email(emailController.text) : null;
  String? get passwordError => submitted && passwordController.text.isEmpty
      ? 'Enter your password'
      : null;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void revalidate(String _) {
    if (submitted || formError != null) {
      setState(() => formError = null);
    }
  }

  Future<void> signIn() async {
    FocusScope.of(context).unfocus();
    setState(() {
      submitted = true;
      formError = null;
    });
    if (emailError != null || passwordError != null) return;

    setState(() => loading = true);
    try {
      await widget.auth.signIn(
        email: emailController.text,
        password: passwordController.text,
      );
      // The auth gate swaps this screen for the store.
    } on AuthException catch (e) {
      if (mounted) setState(() => formError = e.message);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void openSignUp() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => SignUpScreen(auth: widget.auth)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: authBackground,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool wide =
                  widget.showQrPanel && constraints.maxWidth >= 860;
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: wide ? 900 : 500),
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(child: buildForm()),
                              const SizedBox(width: 48),
                              const SizedBox(
                                width: 320,
                                child: WebQrLoginPanel(),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              buildForm(),
                              if (widget.showQrPanel) ...[
                                const SizedBox(height: 32),
                                const WebQrLoginPanel(),
                              ],
                            ],
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: GameVaultLogo()),
        const SizedBox(height: 32),
        const Text(
          'Welcome back',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Sign in to your GameVault account.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
        ),
        const SizedBox(height: 20),
        AuthTextField(
          label: 'Email',
          hint: 'name@narxoz.kz',
          icon: Icons.mail_outline,
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          errorText: emailError,
          onChanged: revalidate,
        ),
        const SizedBox(height: 16),
        AuthTextField(
          label: 'Password',
          hint: 'Your password',
          icon: Icons.lock_outline,
          controller: passwordController,
          obscure: obscurePassword,
          onToggleObscure: () =>
              setState(() => obscurePassword = !obscurePassword),
          textInputAction: TextInputAction.done,
          errorText: passwordError,
          onChanged: revalidate,
        ),
        if (formError != null) ...[
          const SizedBox(height: 12),
          FieldError(formError!),
        ],
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: loading ? null : signIn,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.darkBackground,
            disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.35),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(loading ? 'Signing in…' : 'Sign in'),
        ),
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text(
              "Don't have an account?",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
            TextButton(
              onPressed: openSignUp,
              child: const Text(
                'Create account',
                style: TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
