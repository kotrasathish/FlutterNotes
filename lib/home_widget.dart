import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynotesflutter/services/auth/bloc/auth_bloc.dart';
import 'package:mynotesflutter/services/auth/bloc/auth_events.dart';
import 'package:mynotesflutter/services/auth/bloc/auth_state.dart';
import 'package:mynotesflutter/views/forgot_password_view.dart';
import 'package:mynotesflutter/views/login_view.dart';
import 'package:mynotesflutter/views/notes/notes_view.dart';
import 'package:mynotesflutter/views/register_view.dart';
import 'package:mynotesflutter/views/verify_email.dart';

class HomeWidget extends StatelessWidget {
  const HomeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    context.read<AuthBloc>().add(const AuthEventInitialize());
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthStateLoggedIn) {
          return const NotesPage();
        } else if (state is AuthStateLoggedOut) {
          return const LoginView();
        } else if (state is AuthStateNeedsVerification) {
          return const VerifyEmail();
        } else if (state is AuthSateLoggedOutFailed) {
          return const NotesPage();
        } else if (state is AuthStateForgotPassword) {
          return const ForgotPasswordView();
        } else if (state is AuthStateRegistering) {
          return const RegisterView();
        } else {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}
