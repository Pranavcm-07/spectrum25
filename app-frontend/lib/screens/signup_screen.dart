import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/upload_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'home_screen.dart';
import 'package:flutter_application_1/utils/color_utils.dart';
import 'package:flutter_application_1/reusable_widgets/reusable_widget.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/themes/theme_provider.dart';
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _passwordTextController = TextEditingController();
  final TextEditingController _emailTextController = TextEditingController();
  final TextEditingController _userNameTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,color:Color.fromARGB(255, 51, 85, 255), size: 30),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
        const SizedBox(height: 5),
        IconButton(
          icon: const Icon(Icons.brightness_6),
          onPressed: () {
            Provider.of<ThemeProvider>(context, listen: false).toogleTheme();
          },
        ),
      ],
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start, // Aligns the text to the left
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                    "Create Account",
                    style: TextStyle(
                      color: Color.fromARGB(255, 51, 85, 255),
                      fontWeight: FontWeight.w900,
                      fontFamily: "Roboto",
                      fontSize: 30,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "Sign up to get started",
                    style: TextStyle(
                      fontFamily: "Roboto",
                      fontSize: 14,
                      fontWeight: FontWeight.w600
                    ),
                  )
                    ],
                  )
                ],
              ),
              SizedBox(height: 20),
              Column(
              children: <Widget>[
                const SizedBox(height: 20),

                // Logo Widget
                SvgPicture.asset(
                      'assets/images/sign-in.svg',
                      height: 400,
                      width: 300,
                    ),
                const SizedBox(height: 30),

                // Sign Up Title
                const Text(
                  "Create Your Account",
                  style: TextStyle(
                    color: Color.fromARGB(255, 51, 85, 255),
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Join us to get started",
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 30),

                // Username Field
                reusableTextField(
                  "Enter Username",
                  Icons.person_outline,
                  false,
                  _userNameTextController,
                ),
                const SizedBox(height: 20),

                // Email Field
                reusableTextField(
                  "Enter Email Id",
                  Icons.email_outlined,
                  false,
                  _emailTextController,
                ),
                const SizedBox(height: 20),

                // Password Field
                reusableTextField(
                  "Enter Password",
                  Icons.lock_outlined,
                  true,
                  _passwordTextController,
                ),
                const SizedBox(height: 20),

                // Sign Up Button
                firebaseUIButton(context, "Sign Up", () {
                  FirebaseAuth.instance
                      .createUserWithEmailAndPassword(
                    email: _emailTextController.text,
                    password: _passwordTextController.text,
                  )
                      .then((value) {
                    print("Created New Account");
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => UploadScreen()),
                    );
                  }).onError((error, stackTrace) {
                    print("Error ${error.toString()}");
                  });
                }),
                const SizedBox(height: 5),

                // Already have an account? Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account?",
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context); // Navigate back to the login screen
                      },
                      child: const Text(
                        " Login",
                        style: TextStyle(
                          color: Color.fromARGB(255, 51, 85, 255),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30),
              ])
            ],
          ),
          ),
        ),
    );
  }
}