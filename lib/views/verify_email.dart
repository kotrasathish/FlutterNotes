import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynotesflutter/constants/routes.dart';
import 'package:mynotesflutter/services/auth/auth_service.dart';
import 'package:mynotesflutter/services/auth/bloc/auth_bloc.dart';
import 'package:mynotesflutter/services/auth/bloc/auth_events.dart';
class VerifyEmail extends StatefulWidget {
  const VerifyEmail({super.key});

  @override
  State<VerifyEmail> createState() => _VerifyEmailState();
}

class _VerifyEmailState extends State<VerifyEmail> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: const Text("Verify Email"),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'A verification email has been sent to your email.',
              style: TextStyle(fontSize: 20),
            ),
            const Text(
              'Please verify your email to continue.',
              style: TextStyle(fontSize: 30),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: ()  {
               context.read<AuthBloc>().add(const AuthEventSendEmailVerification());
              },
              child: const Text('Send Email code'),
            ),
            TextButton(
              onPressed: ()  {
               context.read<AuthBloc>().add(const AuthEventLogOut());
              },
              child: const Text('Restart'),
            )
          ],
        ),
      ),
    );
  }
}
