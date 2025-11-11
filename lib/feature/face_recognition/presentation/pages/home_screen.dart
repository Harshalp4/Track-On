import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final String userName;
  
  const HomeScreen({super.key, required this.userName});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome'),
        automaticallyImplyLeading: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 80,
            ),
            const SizedBox(height: 20),
            Text(
              'Welcome, $userName!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                // Add navigation to your main app content here
                // For example:
                // Navigator.pushReplacement(
                //   context,
                //   MaterialPageRoute(builder: (context) => HomePage()),
                // );
              },
              child: const Text('Continue to App'),
            ),
          ],
        ),
      ),
    );
  }
}