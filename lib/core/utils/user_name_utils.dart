String displayNameFromEmail(String email) {
  final trimmed = email.trim();
  if (trimmed.isEmpty) return 'User';

  final atIndex = trimmed.indexOf('@');
  final localPart = atIndex > 0 ? trimmed.substring(0, atIndex) : trimmed;
  final cleaned = localPart.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '');

  return cleaned.isEmpty ? 'User' : cleaned;
}
