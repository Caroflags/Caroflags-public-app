import 'package:flutter/material.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'home.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login.dart';
import 'notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'wear_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Determine if this is the wear/watch flavor or a Wear OS device
  bool isWearOS = appFlavor == 'wear' || appFlavor == 'watch';
  if (!isWearOS && Platform.isAndroid) {
    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      isWearOS = androidInfo.systemFeatures.contains(
        'android.hardware.type.watch',
      );
    } catch (e) {
      debugPrint("Failed to get device info: $e");
    }
  }

  // 2. Initialize Hive only for phone/tablet build
  if (!isWearOS) {
    await Hive.initFlutter();
    await Hive.openBox('local_passes');
    await Hive.openBox('timer_settings');
    await Hive.openBox('settings');
  }

  // 3. Initialize Firebase only for phone/tablet build
  if (!isWearOS) {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
    } catch (e) {
      debugPrint("Firebase was already initialized: $e");
    }
  }

  // 4. Initialize Notifications only for phone/tablet build
  if (!isWearOS) {
    await NotificationService.initializeNotifications();
  }

  // 5. Check Firebase Auth only for phone/tablet build
  if (!isWearOS) {
    final user = FirebaseAuth.instance.currentUser;
    debugPrint(
      user != null ? 'Current user: ${user.uid}' : 'No user logged in',
    );
  }

  runApp(isWearOS ? const WearApp() : const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Caroflags',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlueAccent),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.lightBlueAccent,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Case 1: Waiting for Firebase to check the disk for a token
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Case 2: Error in the stream
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text("Something went wrong!")),
          );
        }

        // Case 3: User is logged in
        if (snapshot.hasData) {
          return const RealHome();
        }
        // Case 4: User is not logged in
        else {
          return const LoginPage();
        }
      },
    );
  }
}
