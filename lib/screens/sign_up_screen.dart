import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../auth/sign_up_validator.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_widgets.dart';

class SignUpScreen extends StatefulWidget {
  final AuthService auth;

  const SignUpScreen({super.key, this.auth = const FirebaseAuthService()});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  static const List<String> roles = ['Student', 'Developer', 'Gamer'];

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  String role = roles.first;
  bool termsAccepted = false;
  bool obscurePassword = true;
  bool obscureConfirm = true;

  // Errors are only shown after the first submit attempt.
  bool submitted = false;
  bool loading = false;

  String? get nameError =>
      submitted ? SignUpValidator.fullName(nameController.text) : null;
  String? get emailError =>
      submitted ? SignUpValidator.email(emailController.text) : null;
  String? get passwordError =>
      submitted ? SignUpValidator.password(passwordController.text) : null;
  String? get confirmError => submitted
      ? SignUpValidator.confirmPassword(
          passwordController.text,
          confirmController.text,
        )
      : null;
  String? get termsError =>
      submitted ? SignUpValidator.terms(termsAccepted) : null;

  bool get isValid =>
      SignUpValidator.fullName(nameController.text) == null &&
      SignUpValidator.email(emailController.text) == null &&
      SignUpValidator.password(passwordController.text) == null &&
      SignUpValidator.confirmPassword(
            passwordController.text,
            confirmController.text,
          ) ==
          null &&
      SignUpValidator.terms(termsAccepted) == null;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  void revalidate(String _) {
    if (submitted) setState(() {});
  }

  Future<void> createAccount() async {
    FocusScope.of(context).unfocus();
    setState(() => submitted = true);
    if (!isValid) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => loading = true);
    try {
      await widget.auth.signUp(
        name: nameController.text,
        email: emailController.text,
        password: passwordController.text,
        role: role,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }

    // Signed in now: the auth gate under this route already shows the store.
    if (!mounted) return;
    setState(() => loading = false);
    navigator.popUntil((route) => route.isFirst);

    final String firstName = nameController.text.trim().split(' ').first;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.darkBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.successBackground),
        ),
        content: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.successBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.check, color: AppColors.success),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Account created!',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Welcome to GameVault, $firstName',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: authBackground,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    buildHeader(),
                    const SizedBox(height: 24),
                    const Text(
                      'Create your account',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Join GameVault to build your library and wishlist.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...buildFields(),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: loading ? null : createAccount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.darkBackground,
                        disabledBackgroundColor:
                            AppColors.accent.withValues(alpha: 0.35),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        loading ? 'Creating account…' : 'Create account',
                      ),
                    ),
                    const SizedBox(height: 24),
                    buildSignInLink(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildHeader() {
    return Row(
      children: [
        CircleIconButton(
          icon: Icons.arrow_back,
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        const Expanded(child: Center(child: GameVaultLogo())),
        // Balances the back button so the logo stays centered.
        const SizedBox(width: 40),
      ],
    );
  }

  List<Widget> buildFields() {
    const gap = SizedBox(height: 16);
    return [
      AuthTextField(
        label: 'Full Name',
        hint: 'Your full name',
        icon: Icons.person_outline,
        controller: nameController,
        keyboardType: TextInputType.name,
        errorText: nameError,
        showValid: submitted && nameError == null,
        onChanged: revalidate,
      ),
      gap,
      AuthTextField(
        label: 'Email',
        hint: 'name@narxoz.kz',
        icon: Icons.mail_outline,
        controller: emailController,
        keyboardType: TextInputType.emailAddress,
        errorText: emailError,
        showValid: submitted && emailError == null,
        onChanged: revalidate,
      ),
      gap,
      AuthTextField(
        label: 'Password',
        hint: 'At least ${SignUpValidator.minPasswordLength} characters',
        icon: Icons.lock_outline,
        controller: passwordController,
        obscure: obscurePassword,
        onToggleObscure: () =>
            setState(() => obscurePassword = !obscurePassword),
        errorText: passwordError,
        onChanged: revalidate,
      ),
      gap,
      AuthTextField(
        label: 'Confirm Password',
        hint: 'Repeat your password',
        icon: Icons.shield_outlined,
        controller: confirmController,
        obscure: obscureConfirm,
        onToggleObscure: () => setState(() => obscureConfirm = !obscureConfirm),
        textInputAction: TextInputAction.done,
        errorText: confirmError,
        onChanged: revalidate,
      ),
      gap,
      buildRolePicker(),
      const SizedBox(height: 12),
      buildTerms(),
    ];
  }

  Widget buildRolePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Role',
          style: TextStyle(
            color: Color(0xFFC7D5E0),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: role,
          dropdownColor: AppColors.inputFill,
          iconEnabledColor: AppColors.accent,
          icon: const Icon(Icons.keyboard_arrow_down),
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.inputFill,
            prefixIcon: const Icon(
              Icons.badge_outlined,
              color: AppColors.textSecondary,
              size: 20,
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          items: [
            for (final r in roles) DropdownMenuItem(value: r, child: Text(r)),
          ],
          onChanged: (value) => setState(() => role = value ?? role),
        ),
      ],
    );
  }

  Widget buildTerms() {
    final String? error = termsError;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: termsAccepted,
              activeColor: AppColors.accent,
              checkColor: AppColors.darkBackground,
              side: BorderSide(
                color: error != null ? AppColors.error : AppColors.textSecondary,
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              onChanged: (value) =>
                  setState(() => termsAccepted = value ?? false),
            ),
            const Expanded(
              child: Text.rich(
                TextSpan(
                  style: TextStyle(color: Color(0xFFC7D5E0), fontSize: 15),
                  children: [
                    TextSpan(text: 'I accept the '),
                    TextSpan(
                      text: 'Terms and Conditions',
                      style: TextStyle(color: AppColors.accent),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: FieldError(error),
          ),
      ],
    );
  }

  Widget buildSignInLink() {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          'Already have an account?',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: const Text(
            'Sign in',
            style: TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}
