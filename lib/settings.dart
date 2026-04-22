import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'login.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _useLocalPasses = false;
  bool _isAnonymous = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    _isAnonymous = user?.isAnonymous ?? false;

    final prefs = await SharedPreferences.getInstance();
    if (_isAnonymous) {
      if (mounted) {
        setState(() {
          _useLocalPasses = true;
        });
      }
      await prefs.setBool('use_local_passes', true);
    } else {
      if (mounted) {
        setState(() {
          _useLocalPasses = prefs.getBool('use_local_passes') ?? false;
        });
      }
    }
  }

  Future<void> _toggleLocalPasses(bool value) async {
    if (_isAnonymous) return;
    setState(() {
      _useLocalPasses = value;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_local_passes', value);
  }

  Future<void> _deleteAccount() async {
    final passwordController = TextEditingController();

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Are you sure?'),
        content: const Text(
          'Do you really want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (!user.isAnonymous) {
      String? password = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Password'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, passwordController.text),
              child: const Text('Submit'),
            ),
          ],
        ),
      );

      if (password == null || password.isEmpty || !mounted) return;

      try {
        if (user.email != null) {
          AuthCredential credential = EmailAuthProvider.credential(
            email: user.email!,
            password: password,
          );
          // Re-authenticate
          await user.reauthenticateWithCredential(credential);
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to reauthenticate: $e')));
        return;
      }
    }

    try {
      // Clear local passes to be safe
      await Hive.box('local_passes').clear();

      if (!user.isAnonymous) {
        // Delete passes subcollection
        final passesSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('passes')
            .get();
        for (var doc in passesSnapshot.docs) {
          await doc.reference.delete();
        }

        // Delete user document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .delete();
      }

      // Delete user authentication record
      await user.delete();

      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Thanks for using Caroflags!'),
          content: const Text(
            'Your account data has now been deleted. Thanks for using caroflags!',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Okay'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete account: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete account: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SwitchListTile(
            title: const Text('Use Local Passes'),
            subtitle: _isAnonymous
                ? const Text(
                    'You cannot use cloud passes because you are on an anonymous account.',
                  )
                : const Text('Store passes locally instead of in the cloud.'),
            value: _useLocalPasses,
            onChanged: _isAnonymous ? null : _toggleLocalPasses,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.red,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: _deleteAccount,
            child: const Text('Delete account'),
          ),
        ],
      ),
    );
  }
}
