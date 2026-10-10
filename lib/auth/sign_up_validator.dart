/// Validation rules for the sign-up form. Each method returns an error
/// message, or null when the value is valid.
class SignUpValidator {
  static const int minPasswordLength = 6;

  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  static String? fullName(String value) =>
      value.trim().isEmpty ? 'Please enter your full name' : null;

  static String? email(String value) => _emailPattern.hasMatch(value.trim())
      ? null
      : 'Enter a valid email, e.g. name@narxoz.kz';

  static String? password(String value) => value.length < minPasswordLength
      ? 'Password must be at least $minPasswordLength characters'
      : null;

  static String? confirmPassword(String password, String confirm) =>
      confirm.isEmpty || confirm != password ? 'Passwords do not match' : null;

  static String? terms(bool accepted) =>
      accepted ? null : 'You must accept the Terms to continue';
}
