// import 'dart:developer' as dev show log;
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:mynotes/constants/routes.dart';
import 'package:mynotes/services/auth/auth_exception.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/utilities/show_error_dialog.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Log In"),
        backgroundColor: Colors.amber,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            TextField(
              controller: _email,
              enableSuggestions: false,
              autocorrect: false,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(hintText: "Enter Your Email"),
            ),
            TextField(
              controller: _password,
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              decoration:
                  const InputDecoration(hintText: "Enter Your Password"),
            ),
            TextButton(
              onPressed: () async {
                final email = _email.text;
                final password = _password.text;

                try {
                  await AuthService.firebase().logIn(
                    email: email,
                    password: password,
                  );

                  final user = AuthService.firebase().currentUser;

                  log(user.toString());

                  if (user?.isEmailVerified ?? false) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      notesRoute,
                      (route) => false,
                    );
                  } else {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      verifyEmailRoute,
                      (route) => false,
                    );
                  }
                } on UserNotFoundAuthException {
                  await showErrorDialog(
                    context,
                    "User Not Found",
                  );
                } on WrongPasswordAuthException {
                  await showErrorDialog(
                    context,
                    "Wrong Credentials",
                  );
                } on GenericAuthException {
                  await showErrorDialog(
                    context,
                    "Authentication Error",
                  );
                }
              },
              child: const Text("Login"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  registerRoute,
                  (route) => false,
                );
              },
              child: const Text("Not Registerd? Register Here."),
            )
          ],
        ),
      ),
    );
  }
}
