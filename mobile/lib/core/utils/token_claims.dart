//token_claims.dart

import 'dart:convert';

/// Reads the account holder's email out of a JWT.
///
/// The backend signs the issued token with the email as the `sub` claim and
/// exposes no endpoint that returns the signed-in user's profile, so this is
/// the only identity the app can show without inventing an API. The payload is
/// used for display only and is never treated as authorisation - the server
/// still verifies the signature on every request.
String? emailFromToken(String token) {
  final segments = token.split('.');
  if (segments.length != 3) return null;

  try {
    final payload = segments[1];
    final decoded = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(payload))),
    );
    if (decoded is! Map) return null;
    final subject = decoded['sub'];
    return subject is String && subject.isNotEmpty ? subject : null;
  } on FormatException {
    return null;
  }
}
