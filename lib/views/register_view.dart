// import 'dart:developer' as dev show log;
import 'package:flutter/material.dart';
import 'package:mynotes/constants/routes.dart';
import 'package:mynotes/services/auth/auth_exception.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/utilities/show_error_dialog.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
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
        title: const Text("Register"),
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
                  await AuthService.firebase()
                      .createUser(email: email, password: password);

                  AuthService.firebase().emailVerification();

                  Navigator.of(context).pushNamed(
                    verifyEmailRoute,
                  );
                } on WeakPasswordAuthException {
                  await showErrorDialog(
                    context,
                    "Password Is Incorrect",
                  );
                } on EmailAlreadyInUseAuthException {
                  await showErrorDialog(
                    context,
                    "Email Is Already Registerd",
                  );
                } on InvalidEmailAuthException {
                  await showErrorDialog(
                    context,
                    "Ivalid Email",
                  );
                } on GenericAuthException {
                  await showErrorDialog(
                    context,
                    "Failed To Register",
                  );
                }
              },
              child: const Text("Register"),
            ),
            TextButton(
                onPressed: () {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil(loginRoute, (route) => false);
                },
                child: const Text("Log In Here!")),
          ],
        ),
      ),
    );
  }
}
