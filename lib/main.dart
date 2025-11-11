import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_kiosk_mode/flutter_kiosk_mode.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:track_on/feature/auth/domain/services/auth_service.dart';
import 'package:track_on/feature/auth/presentation/pages/login_controller.dart';
import 'package:track_on/feature/auth/presentation/pages/login_screen.dart';
import 'package:track_on/feature/face_recognition/presentation/pages/confirm_page.dart';
import 'package:track_on/feature/face_recognition/presentation/pages/face_recognition_screen.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:track_on/feature/splash/splash_screen.dart';

// Global camera list
late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  await Hive.initFlutter();

  // Keep screen on
  WakelockPlus.enable();

  // Start kiosk mode
  final kiosk = FlutterKioskMode.instance();
  await kiosk.start();

  // Open necessary boxes
  await Hive.openBox('faces');
  await Hive.openBox('settingsBox');

  final authService = AuthService();
  final bool isLoggedIn = await authService.isLoggedIn();

  runApp(FaceRecognitionApp(isLoggedIn: isLoggedIn));
}

class FaceRecognitionApp extends StatelessWidget {
  final bool isLoggedIn;

  const FaceRecognitionApp({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginController()),
      ],
      child: MaterialApp(
        title: 'TrackOn',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'GothicA1',
          primarySwatch: Colors.purple, // ✅ Changed to purple for brand consistency
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.purple,
            brightness: Brightness.light,
          ),
          // ✅ Add modern visual density
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        
        // ✅ CHANGED: Show splash screen first, then redirect based on login
        home: SplashScreenWrapper(isLoggedIn: isLoggedIn),
        
        // ✅ ADD: Named routes for navigation
        routes: {
          '/login': (context) => LoginScreen(),
          '/face-recognition': (context) => const FaceRecognitionScreen(),
          '/confirm': (context) => ConfirmPage(
            recognizedName: '', 
            faceImage: (ModalRoute.of(context)?.settings.arguments as Map)['faceImage'],
          ),
        },
      ),
    );
  }
}

// ✅ NEW: Wrapper to handle splash → login/face-recognition flow
class SplashScreenWrapper extends StatefulWidget {
  final bool isLoggedIn;
  
  const SplashScreenWrapper({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  State<SplashScreenWrapper> createState() => _SplashScreenWrapperState();
}

class _SplashScreenWrapperState extends State<SplashScreenWrapper> {
  @override
  void initState() {
    super.initState();
    _navigateAfterSplash();
  }

  Future<void> _navigateAfterSplash() async {
    // Wait for splash screen animation (3 seconds)
    await Future.delayed(Duration(seconds: 3));
    
    if (!mounted) return;
    
    // Navigate based on login status
    if (widget.isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const FaceRecognitionScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}