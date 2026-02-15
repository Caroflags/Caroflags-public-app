import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Authentication
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';
// test commit thingy

void main() { 
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Signup',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const SignupPage(),
    );
  }
}

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  void _signup() async {
    final email = _emailController.text;
    final password = _passwordController.text;
    final username = _usernameController.text;

    try {
      if (email.isEmpty || password.isEmpty || username.isEmpty) {
              showDialog(context: context, builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Wha- Huh?'),
          content: const Text('How am i going to make an account without an email, password, and username?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                
              },
              child: const Text('Ok'),
            ),
          ],
        );
      });
      return;
      }

      // Check if the username is not funny
      if (username.toLowerCase() == 'dixie normus') {
        showDialog(context: context, builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Haha'),
            content: const Text('You\'re funny, REALLY funny. Get rid of that username and try again.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Ok'),
              ),
            ],
          );
        });
        return;
      }
      if (username.toLowerCase() == 'bogos binted') {
        showDialog(context: context, builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Haha'),
            content: const Text('Hey just wondering if you got your photos printed?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Ok'),
              ),
            ],
          );
        });
        return;
      }

      // Attempt to create a new user with Firebase
      try {
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        await userCredential.user?.sendEmailVerification();

        await FirebaseFirestore.instance.collection('users').doc(userCredential.user?.uid).set({
          'username': username,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });


        if (!context.mounted) return;
        showDialog(context: context, builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Success!'),
            content: Text('Thanks For making an account, $username! Now, You need to verify your email. There should be an email in your inbox. If you don\'t see it, check your spam folder.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(context, MaterialPageRoute(
                    builder: (context) => const LoginPage(),
                  ));
                },
                child: const Text('Ok'),
              ),
            ],
          );
        });




      } catch (error) {
        // Handle errors during Firebase Authentication
        if (!context.mounted) return;
        showDialog(context: context, builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to create account: $error'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Ok'),
              ),
            ],
          );
        });
      }





    }
    catch (e) {
      if (!context.mounted) return;
      showDialog(context: context, builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('uh'),
          content: Text('An error occurred: $e'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Ok'),
            ),
          ],
        );
      });
    }
    


  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Signup'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 20.0, top: 20.0),
              child: const Text(
                'Welcome to Caroflags!',
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
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
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
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true
            ),



            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _signup,
              child: const Text('Signup'),
            ),

            Container(
              margin: const EdgeInsets.only(top: 40.0),
              child: Column(
                children: [
                  const Text(
                    'Cultured?',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => const LoginPage(),
                    ));
                    },
                    child: const Text('Login'),
                  ),
                ],
              ),
            ),



          ],
        ),
      ),
    );
  }
}
