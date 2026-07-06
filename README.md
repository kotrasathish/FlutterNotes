# mynotesflutter

A new Flutter project.

## Getting Started

BLoC Architecture — Complete Guide for mynotesflutter
What is BLoC?
BLoC = Business Logic Component.

It is a state management pattern for Flutter. The core idea is simple:

UI sends Events → BLoC processes them → BLoC emits States → UI rebuilds based on State

The UI never touches business logic directly. BLoC sits in the middle and handles everything.

The 3 Core Pieces

┌──────────┐   add(Event)   ┌──────────┐   emit(State)   ┌──────────┐
│    UI    │ ─────────────► │   BLoC   │ ───────────────► │    UI    │
│ (Widget) │                │          │                  │ rebuilds │
└──────────┘                └──────────┘                  └──────────┘
Piece	What it is	Your file
Event	A user action or trigger (button tap, app start)	auth_events.dart
State	A snapshot of what the app looks like right now	auth_state.dart
BLoC	Listens to Events, runs logic, emits new States	auth_bloc.dart
Full Architecture of Your Project

main.dart
  └── BlocProvider<AuthBloc>          ← creates one AuthBloc for the whole app
        └── MaterialApp
              └── SplashScreen
                    └── HomeWidget    ← reads AuthBloc and routes to correct screen

lib/
├── main.dart                          ← BlocProvider setup
├── home_widget.dart                   ← BlocBuilder (routing brain)
├── services/
│   └── auth/
│       ├── auth_provider.dart         ← Abstract interface (contract)
│       ├── firebase_auth_provider.dart← Concrete Firebase implementation
│       ├── auth_service.dart          ← Thin wrapper used by views
│       └── bloc/
│           ├── auth_events.dart       ← All possible events
│           ├── auth_state.dart        ← All possible states
│           └── auth_bloc.dart         ← The brain
└── views/
    ├── login_view.dart                ← dispatches AuthEventLogIn
    ├── register_view.dart             ← dispatches AuthEventRegister
    ├── verify_email.dart              ← dispatches AuthEventSendEmailVerification
    ├── forgot_password_view.dart      ← dispatches AuthEventForgotPassword
    └── notes/
        └── notes_view.dart            ← dispatches AuthEventLogOut
Step 1 — BlocProvider in main.dart

// main.dart
BlocProvider<AuthBloc>(
  create: (context) => AuthBloc(FirebaseAuthProvider()),
  child: MaterialApp(...),
)
BlocProvider creates one single instance of AuthBloc and makes it available to every widget below it in the tree. Any widget can call context.read<AuthBloc>() to access it.

FirebaseAuthProvider is passed into the BLoC. This is the dependency injection pattern — the BLoC doesn't know or care that it's Firebase; it just knows it has an AuthProvider.

Step 2 — Events (What can happen)
Every user action is modelled as a class in auth_events.dart:


abstract class AuthEvent { }         // base class

AuthEventInitialize                  // app just launched
AuthEventLogIn(email, password)      // user tapped Login button
AuthEventLogOut                      // user tapped Logout
AuthEventRegister(email, password)   // user tapped Register
AuthEventShouldRegister              // user tapped "Not Registered? Register here"
AuthEventForgotPassword(email?)      // user tapped Forgot Password
AuthEventSendEmailVerification       // user tapped Resend Verification
All are @immutable — once created they never change. This prevents bugs where an event is modified after being sent.

Step 3 — States (What the UI can look like)
Every possible screen/condition is a class in auth_state.dart:


abstract class AuthState {
  final bool isLoading;  // ← used to show/hide LoadingScreen
  final String? text;    // ← loading message text
}

AuthUnInitialized          // app is starting up (shows spinner)
AuthStateLoggedIn          // user is logged in → show NotesPage
AuthStateLoggedOut         // user is logged out → show LoginView
AuthStateNeedsVerification // registered but email not verified → show VerifyEmail
AuthStateRegistering       // show RegisterView
AuthStateForgotPassword    // show ForgotPasswordView
AuthSateLoggedOutFailed    // logout failed (shows NotesPage still)
All states carry isLoading so any screen can show a loading spinner without duplicating that logic.

Step 4 — AuthBloc (The Brain)
auth_bloc.dart registers one handler per event using on<EventType>:


class AuthBloc extends Bloc<AuthEvent, AuthState> {

  AuthBloc(AuthProvider provider)
    : super(const AuthUnInitialized(isLoading: true)) {  // ← initial state

    on<AuthEventInitialize>((event, emit) async {
      await provider.initialize();          // start Firebase
      final user = provider.currentUser;
      if (user == null)
        emit(AuthStateLoggedOut(...));      // → LoginView
      else if (!user.isEmailVerified)
        emit(AuthStateNeedsVerification()); // → VerifyEmail
      else
        emit(AuthStateLoggedIn(user));      // → NotesPage
    });

    on<AuthEventLogIn>((event, emit) async {
      emit(AuthStateLoggedOut(isLoading: true, ...)); // show spinner
      try {
        final user = await provider.login(...);
        emit(AuthStateLoggedIn(user));       // success → NotesPage
      } on Exception catch (e) {
        emit(AuthStateLoggedOut(exception: e, ...));  // show error
      }
    });

    on<AuthEventLogOut>((event, emit) async {
      await provider.logout();
      emit(AuthStateLoggedOut(...));         // → LoginView
    });

    // ... similar pattern for Register, ForgotPassword, etc.
  }
}
Key point: The BLoC never imports Flutter widgets. It is pure Dart — this is why it is easy to test.

Step 5 — HomeWidget routes using BlocBuilder
home_widget.dart is the routing brain of the app. It watches the state and returns the right screen:


context.read<AuthBloc>().add(const AuthEventInitialize()); // kick off startup

BlocBuilder<AuthBloc, AuthState>(
  builder: (context, state) {
    if (state is AuthStateLoggedIn)         return NotesPage();
    if (state is AuthStateLoggedOut)        return LoginView();
    if (state is AuthStateNeedsVerification)return VerifyEmail();
    if (state is AuthStateForgotPassword)   return ForgotPasswordView();
    if (state is AuthStateRegistering)      return RegisterView();
    return CircularProgressIndicator();     // AuthUnInitialized
  },
)
There is no Navigator.push here. Navigation is driven entirely by state changes. When BLoC emits a new state, Flutter rebuilds and automatically shows the correct screen.

Step 6 — Views dispatch Events
Each view only knows how to send events. It does not handle logic itself.

LoginView example:


// User taps Login button
context.read<AuthBloc>().add(
  AuthEventLogIn(email: _email.text, password: _password.text),
);

// User taps "Forgot Password?"
context.read<AuthBloc>().add(const AuthEventForgotPassword());

// User taps "Not Registered?"
context.read<AuthBloc>().add(const AuthEventShouldRegister());
NotesPage (logout) example:


context.read<AuthBloc>().add(const AuthEventLogOut());
BlocConsumer vs BlocBuilder vs BlocListener
Your project uses all three. Here is what each does:

Widget	Rebuilds UI?	Side effects?	Used in your project
BlocBuilder	Yes	No	HomeWidget — routing
BlocListener	No	Yes	LoginView — showing error dialogs
BlocConsumer	Yes	Yes	LoginView outer — showing LoadingScreen
In LoginView specifically:

BlocConsumer (outer) — watches isLoading to show/hide the full-screen loading overlay
BlocListener (inner) — watches for exceptions on AuthStateLoggedOut to show error dialogs
The Provider/Interface Layer
Your project uses an abstraction layer between BLoC and Firebase:


AuthBloc
  └── uses AuthProvider (abstract interface)
        └── implemented by FirebaseAuthProvider (real Firebase calls)
Why this matters: If you ever want to swap Firebase for another backend, you only write a new AuthProvider class. The BLoC and all views stay exactly the same. It also makes the BLoC fully unit-testable with a mock provider.

Complete Data Flow — Login Example

User types email & password, taps "Login"
          │
          ▼
LoginView calls:
  context.read<AuthBloc>().add(AuthEventLogIn(email, password))
          │
          ▼
AuthBloc.on<AuthEventLogIn> runs:
  1. emit(AuthStateLoggedOut(isLoading: true))   → LoadingScreen appears
  2. await provider.login(email, password)        → Firebase call
  3a. Success → emit(AuthStateLoggedIn(user))     → HomeWidget shows NotesPage
  3b. Failure → emit(AuthStateLoggedOut(exception: e))
                 → BlocListener shows error dialog
Summary
Concept	Role in your project
AuthEvent	Represents every user action
AuthState	Represents every screen/condition
AuthBloc	Processes events, calls Firebase via AuthProvider, emits states
BlocProvider	Injects one AuthBloc instance into the whole widget tree
BlocBuilder	Rebuilds the widget tree when state changes (used for routing in HomeWidget)
BlocListener	Runs side effects like showing dialogs without rebuilding
BlocConsumer	Combines both — used for loading screen + error dialog in LoginView
AuthProvider	Abstract interface that decouples BLoC from Firebase
FirebaseAuthProvider	Concrete implementation of AuthProvider using Firebase
