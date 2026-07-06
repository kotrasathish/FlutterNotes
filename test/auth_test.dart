import 'package:mynotesflutter/services/auth/auth_exceptions.dart';
import 'package:mynotesflutter/services/auth/auth_provider.dart';
import 'package:mynotesflutter/services/auth/auth_user.dart';
import 'package:test/test.dart';
void main(){
 group('Mock Authentication', () {
   final provider = MockAuthProvider();
   test('Should not be initialized to begin with', ()async {
     expect(provider.isInitialized, false);
   });
   test('Cannot log out if not initialized', () async {
     expect(provider.logout(), throwsA(isA<NotInitializedException>()));
   });
    test('Should be able to initialize', () async {
      await provider.initialize();
      expect(provider.isInitialized, true);
    });
    test('User should be null after initialization', () {
      expect(provider.currentUser, null);
    });
    test('Should be able to initialize in less than 2 seconds', () async {
      await provider.initialize();
      expect(provider.isInitialized, true);
    }, timeout: const Timeout(Duration(seconds: 2)));
    test('Create user should delegate to login function', ()async {
      expect(
        provider.createUser(email: 'foo@example.com', password: 'password'),
        throwsA(const TypeMatcher<UserNotFoundAuthException>()),
      );
       final badPasswordFuture = provider.createUser(email: 'someone@example com', password: 'foobar');
       expect(badPasswordFuture, throwsA(const TypeMatcher<WrongPasswordAuthException>()));
       final user = await  provider.createUser(email: 'someone@example com', password: 'password');
        expect(provider.currentUser, user);
        expect(user.isEmailVerified, false);
  });

  test('Logged in user should be able to get verified', () async {
    await provider.initialize();
    await provider.createUser(email: 'someone@example.com', password: 'password');
    await provider.sendEmailVerification();
    final user = provider.currentUser;
    expect(user, isNotNull);
    expect(user!.isEmailVerified, true);
  });
  test('Should be able to log out and log in again', () async {
    await provider.logout();
    expect(provider.currentUser, null);
    await provider.login(email: 'someone@example.com', password: 'password');
    final user = provider.currentUser;
    expect(user, isNotNull);
  });
  });
}

class NotInitializedException implements Exception {}

class MockAuthProvider implements AuthProvider {
  AuthUser? _user;
  var _isInitialized = false;
  bool get isInitialized => _isInitialized;
  @override
  Future<AuthUser> createUser({required String email, required String password}) 
 async {
    if(!isInitialized) throw NotInitializedException();
    await Future.delayed(const Duration(seconds: 1));
    return login(email: email, password: password);
    }

  @override
AuthUser? get currentUser =>  _user;

  @override
  Future<void> initialize() async {
    await Future.delayed(const Duration(seconds: 1));
    _isInitialized = true;
    
  }

  @override
  Future<AuthUser> login({required String email, required String password}) {
   if(!isInitialized) throw NotInitializedException();
    if(email == 'foo@example.com')throw UserNotFoundAuthException();
    if(password == 'foobar') throw WrongPasswordAuthException();
     const user = AuthUser(
      id: 'foo',
      isEmailVerified: false,
       email: '');
    _user = user;
    return Future.value(user);
  }

  @override
  Future<void> logout() async {
    if (!isInitialized) throw NotInitializedException();
    if (_user == null) throw UserNotLoggedInAuthException();
    await Future.delayed(const Duration(seconds: 1));
    _user = null;
  }

  @override
  Future<void> sendEmailVerification() async {
    if (!isInitialized) throw NotInitializedException();
    final user = _user;
    if (user == null) throw UserNotLoggedInAuthException();
    const newUser = AuthUser(
      id: 'foo',
      isEmailVerified: true,
      email: 'foo@google.com'
    );
    _user = newUser;
  }
  
  @override
  Future<void> sendForgotPasswordEmail({required String? toEmail}) {
    // TODO: implement sendForgotPasswordEmail
    throw UnimplementedError();
  }
}