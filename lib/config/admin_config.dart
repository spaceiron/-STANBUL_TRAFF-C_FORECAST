/// Admin access is granted only for whitelisted emails (case-insensitive).
/// Passwords are managed by Firebase Authentication — never store them here.
class AdminConfig {
  static const Set<String> adminEmails = {
    'demor.uzay@gmail.com',
  };

  static bool isAdminEmail(String? email) {
    if (email == null || email.trim().isEmpty) return false;
    return adminEmails.contains(email.trim().toLowerCase());
  }
}
