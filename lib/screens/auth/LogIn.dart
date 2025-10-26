import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:meditrack/classes/MyTextField.dart';
import 'package:meditrack/screens/auth/SignUp.dart';
import 'package:meditrack/screens/home.dart';
import 'package:meditrack/style/colors.dart';

class Login extends StatefulWidget {
  Login({super.key});

  @override
  State<Login> createState() => _SigninState();
}

class _SigninState extends State<Login> {
  GlobalKey<FormState> formKey = GlobalKey();
  TextEditingController username = TextEditingController();
  String? userid;
  final myTextField = MyTextField();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;

  //SignIn Method
  Future<void> signIn() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      setState(() {
        isLoading = true;
      });
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (context) => home()));
    } catch (e) {
      //Displays a small message bar that appears briefly at the bottom of the screen.
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('An error occurred')));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  //Reset Password Method
  Future<void> resetPassword() async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailController.text.trim(),
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Password reset email sent!')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('An error occurred')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        width: MediaQuery.sizeOf(context).width,
        height: MediaQuery.sizeOf(context).height,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 10),
                //logo
                SizedBox(
                  height: 200,
                  width: 200,
                  child: Image.asset('images/1.png'),
                ),
                SizedBox(height: 50),
                //welcome
                Text(
                  'Welcome Back!',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge!.copyWith(fontSize: 30),
                ),
                SizedBox(height: 100),

                //username field
                SizedBox(
                  width: 300,
                  child: myTextField.buildTextField(
                    'Email',
                    emailController,
                    prefixIcon: Icons.person,
                    validator: (value) {
                      if (value!.isEmpty) return "Email can't be empty";
                      if (!value.contains('@')) return "Enter a valid email";
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 10),
                //password field
                SizedBox(
                  width: 300,
                  child: myTextField.buildTextField(
                    'Password',
                    passwordController,
                    prefixIcon: Icons.password,
                    validator: (value) {
                      if (value!.isEmpty) return "Password can't be empty";
                      if (value.length < 6) {
                        return "Password must be at least 6 characters";
                      }
                      return null;
                    },
                    obscureText: true,
                  ),
                ),

                //forget password button
                Container(
                  margin: EdgeInsets.fromLTRB(189, 0, 0, 0),
                  child: TextButton(
                    onPressed: () {
                      resetPassword();
                    },
                    child: Text('Forgot password?'),
                  ),
                ),

                //login button
                SizedBox(
                  height: 50,
                  width: 300,
                  child: Builder(
                    builder:
                        (context) => ElevatedButton(
                          onPressed: () {
                            //Is It Validated?
                            if (formKey.currentState!.validate()) {
                              signIn();
                            }
                          },
                          style: Theme.of(context).elevatedButtonTheme.style,

                          child: Text(
                            'LOGIN',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                  ),
                ),

                //create account buttton
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account?",
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        color: AppColors.darkGray,
                      ),
                    ),
                    Builder(
                      builder:
                          (context) => TextButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => Createacc(),
                                ),
                              );
                            },
                            child: Text('SIGNUP'),
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
