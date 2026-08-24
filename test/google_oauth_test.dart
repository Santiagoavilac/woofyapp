import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mi_app/core/config/env.dart';

void main() {
  test('OAuth mobile redirect matches the AndroidManifest deep link', () {
    final redirect = Uri.parse(Env.oauthMobileRedirect);
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(redirect.scheme, 'io.woofy.app');
    expect(redirect.host, 'login-callback');
    expect(manifest, contains('android:scheme="${redirect.scheme}"'));
    expect(manifest, contains('android:host="${redirect.host}"'));
  });
}
