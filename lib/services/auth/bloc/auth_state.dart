import 'package:flutter/foundation.dart' show immutable;
import 'package:mynotesflutter/services/auth/auth_user.dart';
import 'package:equatable/equatable.dart';

@immutable
abstract class AuthState {
  final bool isLoading;
  final String? text;
  const AuthState({required this.isLoading, this.text ='Pl'});
}

class AuthStateloading extends AuthState {
  const AuthStateloading({required super.isLoading});
}

class AuthUnInitialized extends AuthState {
  const AuthUnInitialized({required bool isLoading}) 
  : super(isLoading: isLoading);
}

class AuthStateRegistering extends AuthState {
  final Exception? exception;
  const AuthStateRegistering({this.exception, required bool isLoading}) 
  : super(isLoading: isLoading);
}

class AuthStateLoggedIn extends AuthState {
 final AuthUser user;
  const AuthStateLoggedIn({required this.user, required bool isLoading}) 
  : super(isLoading: isLoading);
}

class AuthStateLoggedOut extends AuthState with EquatableMixin {
  final Exception? exception;
  const AuthStateLoggedOut({required  this.exception ,required bool isLoading,required String text})
  : super(isLoading: isLoading, text: text);

  @override
  List<Object?> get props => [isLoading, exception];
}

class AuthStateNeedsVerification extends AuthState {
  const AuthStateNeedsVerification({required bool isLoading}) 
  : super(isLoading: isLoading);
}

class AuthSateLoggedOutFailed extends AuthState {
  final Exception exception;
  const AuthSateLoggedOutFailed(this.exception, {required super.isLoading});
}

class AuthStateForgotPassword extends AuthState {
  final Exception? exception;
  final bool hasSentEmail;
  const AuthStateForgotPassword({
    required this.exception,
    required this.hasSentEmail,
    required bool isLoading,
  }):super (isLoading: isLoading);
}

