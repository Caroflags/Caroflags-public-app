import 'package:flutter/material.dart';
import 'signup.dart'; // Import the signup page
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home.dart';
import 'privacy_policy.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Check if a user is already logged in
  User? currentUser = FirebaseAuth.instance.currentUser;

  runApp(
    MyApp(
      initialPage: currentUser != null ? const RealHome() : const LoginPage(),
    ),
  );
}

class MyApp extends StatelessWidget {
  final Widget initialPage;

  const MyApp({super.key, required this.initialPage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Page',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: false,
      ),
      home: initialPage,
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _login() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      // Show an error message if fields are empty
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Wha- Huh?'),
            content: const Text(
              'How am i going to login without an email and password?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Ok'),
              ),
            ],
          );
        },
      );
      return;
    }

    try {
      // Attempt to sign in with Firebase
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;

      if (user != null && !user.emailVerified) {
        // If the user is not verified, show a message
        if (!context.mounted) return;
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Is your email verified?'),
              content: const Text(
                'Please verify your email before logging in. If you can\'t find the verification email, check your spam folder.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Ok'),
                ),
              ],
            );
          },
        );
        return;
      }

      // Navigate to the home page or show success message
      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const RealHome()),
      );
    } on FirebaseAuthException catch (e) {
      // Handle errors here, e.g., show an error message
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Uh-oh'),
            content: Text(e.message ?? 'An unknown error occurred.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Ok'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      // Handle any other exceptions
      print('Login failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 20.0, top: 20.0),
              child: const Text(
                'Welcome Back!',
                style: TextStyle(fontSize: 24),
              ),
            ),

            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _login, child: const Text('Login')),

            // uncultured container
            Container(
              margin: const EdgeInsets.only(top: 40.0),
              child: Column(
                children: [
                  const Text(
                    'Uncultured?',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignupPage(),
                        ),
                      );
                    },
                    child: const Text('Signup'),
                  ),
                ],
              ),
            ),

            Container(
              margin: const EdgeInsets.only(top: 40.0),
              child: Column(
                children: [
                  const Text(
                    'Legal Stuff?',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PrivacyPolicyPage(), // Assuming PrivacyPolicyPage exists
                        ),
                      );
                    },
                    child: const Text('Privacy Policy'),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
