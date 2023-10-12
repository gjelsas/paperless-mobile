(String username, String obscuredUrl) splitRedactUserId(String userId) {
  final parts = userId.split('@');
  if (parts.length != 2) {
    return ('unknown', 'unknown');
  }

  final username = parts.first;
  final serverUrl = parts.last;
  final uri = Uri.parse(serverUrl);
  final hostLen = uri.host.length;
  final obscuredUrl = uri.scheme +
      "://" +
      uri.host.substring(0, 2) +
      List.filled(hostLen - 4, '*').join() +
      uri.host.substring(uri.host.length - 2, uri.host.length);
  return (username, obscuredUrl);
}

String redactUserId(String userId) {
  final (username, obscuredUrl) = splitRedactUserId(userId);
  return '$username@$obscuredUrl';
}
