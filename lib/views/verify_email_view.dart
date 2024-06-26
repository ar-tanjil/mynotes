import 'package:flutter/material.dart';
import 'package:mynotes/constants/routes.dart';
import 'package:mynotes/services/auth/auth_service.dart';

class VerifyEmailView extends StatefulWidget {
  const VerifyEmailView({super.key});

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify Email"),
        backgroundColor: Colors.amber,
      ),
      body: Column(
        children: [
          const Text("We've sent you an Email Verifiacation,"
              " Please verify your account."),
          const Text("If you haven't received a verification email yet,"
              " press the button below."),
          TextButton(
            onPressed: () async {
              AuthService.firebase().emailVerification();
            },
            child: const Text("Send Verification Email Again"),
          ),
          TextButton(
            onPressed: () {
              AuthService.firebase().logOut();
              Navigator.of(context).pushNamedAndRemoveUntil(
                loginRoute,
                (route) => false,
              );
            },
            child: const Text("Reset"),
          ),
        ],
      ),
    );
  }
}
