import 'package:flutter/material.dart';
import 'package:flutter_kiosk_mode/flutter_kiosk_mode.dart';      // ← only if you use kiosk‑mode
import 'package:track_on/feature/auth/domain/services/auth_service.dart';
import 'package:track_on/feature/face_recognition/presentation/pages/setting_page.dart';

class LoginController extends ChangeNotifier {
  final AuthService _authService = AuthService();
  bool isLoading = false;


  Future<bool> login(String username, String password) async {
    isLoading = true;
    notifyListeners();

    final success = await _authService.login(username, password);

    isLoading = false;
    notifyListeners();
    return success;
  }


Future<void> openSettingsGate(
  BuildContext context,
  void Function() pauseRecognition,
  void Function() resumeRecognition
) async {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  // Pause face recognition before showing dialog
  pauseRecognition();

  final bool allowed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            '🔒 Admin Login Required',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    hintText: 'Enter admin username',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter password',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                final isValid = await login(
                  usernameController.text.trim(),
                  passwordController.text.trim(),
                );
                Navigator.pop(context, isValid);
              },
              icon: const Icon(Icons.login, size: 18),
              label: const Text('Unlock'),
            ),
          ],
        ),
      ) ??
      false;

  // Resume face recognition
  resumeRecognition();

  if (!allowed) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invalid credentials'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => SettingsPage()),
    );
  }
}
