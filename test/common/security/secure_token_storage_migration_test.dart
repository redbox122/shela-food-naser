import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/common/security/secure_token_storage.dart';

/// Storage keys used by [SecureTokenStorage] (kept in sync with the
/// private constants in the implementation).
const String _keyName = 'secure_encryption_key';
const String _ivName = 'secure_initialization_vector';
const String _tokenKey = 'encrypted_auth_token';
const String _tokenExpiryKey = 'token_expiry_timestamp';

// A realistic JWT-shaped token: >= 32 chars, no whitespace, passes _isValidToken.
const String _sampleToken =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Builds a base64 key/IV pair and the ciphertext for [_sampleToken],
  /// encrypted exactly the way SecureTokenStorage does it.
  ({String keyB64, String ivB64, String cipherB64}) seedMaterial() {
    final key = Key.fromSecureRandom(32);
    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(key));
    final cipher = encrypter.encrypt(_sampleToken, iv: iv);
    return (keyB64: key.base64, ivB64: iv.base64, cipherB64: cipher.base64);
  }

  setUp(() {
    SecureTokenStorage.resetForTesting();
  });

  test(
      'migrates legacy key/IV out of SharedPreferences while keeping the user logged in',
      () async {
    final m = seedMaterial();
    final future = DateTime.now().add(const Duration(hours: 1));

    // Legacy state: key, IV and the encrypted token all live in SharedPreferences.
    SharedPreferences.setMockInitialValues({
      _keyName: m.keyB64,
      _ivName: m.ivB64,
      _tokenKey: m.cipherB64,
      _tokenExpiryKey: future.millisecondsSinceEpoch,
    });
    // Secure storage starts empty — nothing migrated yet.
    FlutterSecureStorage.setMockInitialValues({});

    await SecureTokenStorage.initialize();

    // Existing session survives: same key/IV still decrypt the stored token.
    final token = await SecureTokenStorage.getToken();
    expect(token, _sampleToken,
        reason: 'existing users must not be logged out by the migration');

    // Security goal: the key/IV are gone from SharedPreferences...
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(_keyName), isNull);
    expect(prefs.getString(_ivName), isNull);

    // ...and now live in secure storage (Keystore/Keychain) instead.
    const secure = FlutterSecureStorage();
    expect(await secure.read(key: _keyName), m.keyB64);
    expect(await secure.read(key: _ivName), m.ivB64);
  });

  test('reads key/IV straight from secure storage when already migrated',
      () async {
    final m = seedMaterial();
    final future = DateTime.now().add(const Duration(hours: 1));

    // No legacy key in prefs — only the ciphertext remains there.
    SharedPreferences.setMockInitialValues({
      _tokenKey: m.cipherB64,
      _tokenExpiryKey: future.millisecondsSinceEpoch,
    });
    FlutterSecureStorage.setMockInitialValues({
      _keyName: m.keyB64,
      _ivName: m.ivB64,
    });

    await SecureTokenStorage.initialize();

    expect(await SecureTokenStorage.getToken(), _sampleToken);
  });

  test('fresh install generates the key only in secure storage', () async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});

    await SecureTokenStorage.initialize();
    // Save+read a token to force key generation and exercise the round-trip.
    expect(await SecureTokenStorage.saveToken(_sampleToken), isTrue);
    expect(await SecureTokenStorage.getToken(), _sampleToken);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(_keyName), isNull,
        reason: 'the key must never be written to SharedPreferences');

    const secure = FlutterSecureStorage();
    expect(await secure.read(key: _keyName), isNotNull);
    expect(await secure.read(key: _ivName), isNotNull);
  });
}
