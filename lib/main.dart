import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynotesflutter/constants/routes.dart';
import 'package:mynotesflutter/services/auth/bloc/auth_bloc.dart';
import 'package:mynotesflutter/services/auth/firebase_auth_provider.dart';
import 'package:mynotesflutter/views/notes/create_update_note_view.dart';
import 'package:mynotesflutter/views/splash_screen.dart';

void main() {
  runApp(
    BlocProvider<AuthBloc>(
      create: (context) => AuthBloc(FirebaseAuthProvider()),
      child: MaterialApp(
        title: 'MyNotes',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.deepPurple),
        home: const SplashScreen(),
        routes: {
          createUpdateroute: (context) => const CreateUpdateNoteView(),
        },
      ),
    ),
  );
}
