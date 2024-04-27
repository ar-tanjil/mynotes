import "package:mynotes/services/auth/auth_exception.dart";
import "package:mynotes/services/auth/auth_provider.dart";
import "package:mynotes/services/auth/auth_user.dart";
import "package:test/test.dart";

void main() {
  group("Mock Authentication", () {
    final provider = MockAuthProvider();

    test("Should not be initialized to begin with", () {
      expect(provider._isInitialized, false);
    });

    test("can not log out if not initialized", () {
      expect(
          provider.logOut(),
          throwsA(
            const TypeMatcher<NotInitializedException>(),
          ));
    });

    test("Should be able to initialized", () async {
      await provider.initialize();
      expect(provider.isInitialize, true);
    });

    test("User should be null after initialization", () {
      expect(provider.currentUser, null);
    });

    test("Shoul be able to initialize in less then 2 sec", () async {
      await provider.initialize();
      expect(provider.isInitialize, true);
    }, timeout: const Timeout(Duration(seconds: 2)));

    test("create user login", () async {
      final badEmailUser = provider.createUser(
        email: "foo@bar.com",
        password: "ssss",
      );

      expect(badEmailUser,
          throwsA(const TypeMatcher<UserNotFoundAuthException>()));

      final badPassword = provider.createUser(
        email: "foo@barss.com",
        password: "foobar",
      );

      expect(badPassword,
          throwsA(const TypeMatcher<WrongPasswordAuthException>()));

      final user = await provider.createUser(
        email: "fff",
        password: "fdf",
      );

      expect(provider.currentUser, user);
      expect(user.isEmailVerified, false);
    });

    test(
      "email verification code",
      () {
        provider.emailVerification();
        final usr = provider.currentUser;
        expect(usr, isNotNull);
        expect(usr!.isEmailVerified, true);
      },
    );

    test(
      "should be able to log out and lo in again",
      () async {
        await provider.logIn(
          email: "email",
          password: "password",
        );
        final user = provider.currentUser;
        expect(user, isNotNull);
      },
    );
  });
}

class NotInitializedException implements Exception {}

class MockAuthProvider implements AuthProvider {
  AuthUser? _user;
  var _isInitialized = false;
  bool get isInitialize => _isInitialized;

  @override
  Future<AuthUser> createUser({
    required String email,
    required String password,
  }) async {
    if (!isInitialize) throw NotInitializedException();

    await Future.delayed(const Duration(seconds: 1));

    return logIn(
      email: email,
      password: password,
    );
  }

  @override
  AuthUser? get currentUser => _user;

  @override
  Future<void> emailVerification() async {
    if (!isInitialize) throw NotInitializedException();
    final user = _user;
    if (user == null) throw UserNotFoundAuthException();
    const newUser = AuthUser(isEmailVerified: true);
    _user = newUser;
  }

  @override
  Future<void> initialize() async {
    await Future.delayed(const Duration(seconds: 1));
    _isInitialized = true;
  }

  @override
  Future<AuthUser> logIn({
    required String email,
    required String password,
  }) {
    if (!isInitialize) throw NotInitializedException();
    if (email == 'foo@bar.com') throw UserNotFoundAuthException();
    if (password == 'foobar') throw WrongPasswordAuthException();
    const user = AuthUser(isEmailVerified: false);
    _user = user;
    return Future.value(user);
  }

  @override
  Future<void> logOut() async {
    if (!isInitialize) throw NotInitializedException();
    if (_user == null) throw UserNotFoundAuthException();

    await Future.delayed(const Duration(seconds: 1));

    _user == null;
  }
}
