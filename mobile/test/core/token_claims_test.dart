import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartbank/core/utils/token_claims.dart';

import '../support/fakes.dart';

String tokenWith(Map<String, Object> payload) {
  String encode(Map<String, Object> part) =>
      base64Url.encode(utf8.encode(jsonEncode(part))).replaceAll('=', '');
  return '${encode({'alg': 'HS256'})}.${encode(payload)}.signature';
}

void main() {
  group('emailFromToken', () {
    test('returns the sub claim', () {
      expect(emailFromToken(tokenFor('george@gmail.com')), 'george@gmail.com');
    });

    test('ignores a payload without a usable subject', () {
      expect(emailFromToken(tokenWith({'iat': 1})), isNull);
      expect(emailFromToken(tokenWith({'sub': ''})), isNull);
      expect(emailFromToken(tokenWith({'sub': 42})), isNull);
    });

    test('returns null instead of throwing on anything malformed', () {
      final notJson = base64Url
          .encode(utf8.encode('not json'))
          .replaceAll('=', '');

      expect(emailFromToken(''), isNull);
      expect(emailFromToken('a.b'), isNull);
      expect(emailFromToken('a.not-base64!a.c'), isNull);
      expect(emailFromToken('header.$notJson.signature'), isNull);
    });
  });
}
