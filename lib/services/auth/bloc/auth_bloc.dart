import 'package:bloc/bloc.dart';
import 'package:mynotesflutter/services/auth/auth_provider.dart';
import 'package:mynotesflutter/services/auth/bloc/auth_events.dart';
import 'package:mynotesflutter/services/auth/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
   AuthBloc(AuthProvider provider):super(const AuthUnInitialized(isLoading: true)) {

    on<AuthEventShouldRegister>((event, emit) {
      emit(const AuthStateRegistering(isLoading: false));
    });

    //forgot password event
    on<AuthEventForgotPassword>((event, emit) async{
      emit(const AuthStateForgotPassword(exception: null, hasSentEmail: false, isLoading: false));
     final email = event.email;
     if(email == null){ 
      return;
    }
    emit(const AuthStateForgotPassword(exception: null, hasSentEmail: false, isLoading: true));
    bool didSendEmail;
    Exception? exception;
    try{
      await provider.sendForgotPasswordEmail(toEmail: email);
      didSendEmail = true;
      exception = null;
    } on Exception catch(e){
      didSendEmail = false;
      exception = e;
    }
      emit(AuthStateForgotPassword(exception: exception, hasSentEmail: didSendEmail, isLoading: false));

    }
    );

    on<AuthEventSendEmailVerification>((event, emit) async {
      await provider.sendEmailVerification();
      emit(state);
    });

    on<AuthEventRegister>((event, emit) async{
      final email = event.email;
      final password = event.password;
      try{
        await provider.createUser(email: email, password: password);
        await provider.sendEmailVerification();
        emit(const AuthStateNeedsVerification(isLoading: false));
      }on Exception catch(e){
        emit(AuthStateRegistering(exception: e, isLoading: false));
      }
    });

    on<AuthEventInitialize>((event, emit) async{
      await provider.initialize();
      final user = provider.currentUser;
      if(user==null){
        emit(const AuthStateLoggedOut(isLoading: false, exception: null, text: ''));
      }else if(!user.isEmailVerified){
        emit(const AuthStateNeedsVerification(isLoading: false));
      }else{
        emit(AuthStateLoggedIn(user: user, isLoading: false));
      }
    });
    on<AuthEventLogIn>((event, emit) async{
      emit(const  AuthStateLoggedOut(isLoading: true, exception: null, text: 'Loading...'));
      try{
        final user = await provider.login(
          email: event.email,
          password: event.password,
        );
        if(!user.isEmailVerified){
          emit(const AuthStateLoggedOut(isLoading: false, exception: null, text: 'Please verify your email'));
          emit(const AuthStateNeedsVerification(isLoading: false));
        }else{
          emit(const AuthStateLoggedOut(isLoading: false, exception: null, text: ''));
          emit(AuthStateLoggedIn(user: user, isLoading: false));
        }
      }on Exception catch(e){
        emit(AuthStateLoggedOut(isLoading: false, exception: e, text: ''));
      }
    });
    on<AuthEventLogOut>((event, emit) async{
      try{
        await provider.logout();
        emit(const AuthStateLoggedOut(isLoading: false, exception: null, text: ''));
      }on Exception catch(e){
        emit(AuthStateLoggedOut(isLoading: false, exception: e, text: ''));
      }
    });
   }
}