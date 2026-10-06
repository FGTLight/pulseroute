/// Form validators shared by every feature. Each returns an error message or
/// `null` when the value is valid, so they plug directly into
/// `TextFormField.validator`.
abstract final class Validators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static const minPasswordLength = 8;
  static const maxDisplayNameLength = 50;

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter your email';
    if (!_email.hasMatch(email)) return 'Enter a valid email';
    return null;
  }

  static String? password(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Enter your password';
    if (password.length < minPasswordLength) {
      return 'Use at least $minPasswordLength characters';
    }
    return null;
  }

  static String? displayName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Enter your name';
    if (name.length > maxDisplayNameLength) {
      return 'Keep it under $maxDisplayNameLength characters';
    }
    return null;
  }
}
