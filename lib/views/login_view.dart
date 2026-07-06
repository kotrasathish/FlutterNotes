import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynotesflutter/helpers/loading/loading_screen.dart';
import 'package:mynotesflutter/services/auth/auth_exceptions.dart';
import 'package:mynotesflutter/services/auth/bloc/auth_bloc.dart';
import 'package:mynotesflutter/services/auth/bloc/auth_events.dart';
import 'package:mynotesflutter/services/auth/bloc/auth_state.dart';
import 'package:mynotesflutter/utilitis/dialogs/error_dialog.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final TextEditingController _email;
  late final TextEditingController _password;

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
       if(state.isLoading){
        LoadingScreen().show(
          context: context,
          text: state.text ?? 'Please wait a moment',
        );
       }else{
        LoadingScreen().hide();
       }
      },
      builder: (context, state) {
        return BlocListener<AuthBloc, AuthState>(
          listener: (context, state) async {
            if (state is AuthStateLoggedOut) {
              if (state.exception is UserNotFoundAuthException) {
                await showErrorDialog(context, 'User not found');
              } else if (state.exception is WrongPasswordAuthException) {
                await showErrorDialog(context, 'Wrong password');
              } else if (state.exception is GenericAuthException) {
                await showErrorDialog(context, 'Authentication error');
              }
            }
          },
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              title: const Text("Login"),
            ),
            body: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Text(
                    "Please log in to your account to continue using the app and access all its features and functionality",
                    style: TextStyle(fontSize: 16),
                  ),
                  TextField(
                    controller: _email,
                    enableSuggestions: false,
                    autocorrect: false,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(hintText: 'Enter Email'),
                  ),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: const InputDecoration(hintText: 'Password'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      context.read<AuthBloc>().add(
                        AuthEventLogIn(
                          email: _email.text,
                          password: _password.text,
                        ),
                      );
                    },
                    child: const Text("Login"),
                  ),
                  TextButton(
                    onPressed: () {
                      context.read<AuthBloc>().add(
                        const AuthEventShouldRegister(),
                      );
                    },
                    child: const Text("Not Registered? Register Here"),
                  ),
                  TextButton(
                    onPressed: () {
                      context.read<AuthBloc>().add(
                        const AuthEventForgotPassword(),
                      );
                    },
                    child: const Text("Forgot Password?"),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
