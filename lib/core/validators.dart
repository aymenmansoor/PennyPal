class Validators {
  static String? requiredText(String? value, String label) => (value == null || value.trim().isEmpty) ? '$label is required' : null;
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }
  static String? password(String? value) {
    if (value == null || value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }
  static String? positiveAmount(String? value) {
    final n = double.tryParse(value ?? '');
    return n == null || n <= 0 ? 'Enter a valid amount' : null;
  }
}
