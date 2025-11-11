import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:track_on/core/ML/Recognition.dart';
import 'package:track_on/core/ML/RecognizerV2.dart';
import 'package:track_on/feature/auth/domain/services/secure_storage_service.dart';
import 'package:track_on/core/endpoints/base_url.dart';

import 'face_recognition_screen.dart';
import 'multi_angle_face_capture_page.dart';

class FaceRegistrationPage extends StatefulWidget {
  final img.Image? croppedFace;
  final Recognition? recognition;
  final List<List<double>>? multiAngleEmbeddings;

  const FaceRegistrationPage({
    Key? key,
    this.croppedFace,
    this.recognition,
    this.multiAngleEmbeddings,
  }) : super(key: key);

  @override
  _FaceRegistrationPageState createState() => _FaceRegistrationPageState();
}

class _FaceRegistrationPageState extends State<FaceRegistrationPage> {
  final TextEditingController _idCardController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _facilityIdController = TextEditingController();
  
  // ✅ FIXED: Use RecognizerV2 consistently
  final RecognizerV2 _recognizer = RecognizerV2();
  
  bool isLoading = false;
  bool _isMultiAngleMode = false;
  String _statusMessage = "";

  @override
  void initState() {
    super.initState();
    _isMultiAngleMode = widget.multiAngleEmbeddings != null;
    print("📋 Registration page opened. Multi-angle: $_isMultiAngleMode");
    if (_isMultiAngleMode) {
      print("✅ ${widget.multiAngleEmbeddings!.length} embeddings received");
    }
  }

  @override
  void dispose() {
    _idCardController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _facilityIdController.dispose();
    super.dispose();
  }

  Future<String?> _fetchPersonId(String idCardNum) async {
    try {
      setState(() {
        _statusMessage = "🔍 Fetching employee ID...";
      });

      final token = await SecureStorageService.getAccessToken();
      if (token == null) {
        setState(() {
          _statusMessage = "❌ Not authorized. Please log in.";
        });
        return null;
      }

      final url = Uri.parse(
        "${BaseUrl.baseUrl}/api/services/app/Persons/GetPersonIdByIdCardNum?idCardNum=$idCardNum",
      );

      print("🌐 Fetching PersonId for ID: $idCardNum");

      final response = await http.get(
        url,
        headers: {
          HttpHeaders.authorizationHeader: "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("📡 Response status: ${response.statusCode}");

      if (response.statusCode == 200 &&
          response.headers['content-type']?.contains("application/json") == true) {
        final jsonResponse = jsonDecode(response.body);
        print("📦 Response: $jsonResponse");
        
        if (jsonResponse['success'] == true && jsonResponse['result'] != null) {
          String employeeId = jsonResponse['result'].toString();
          print("✅ Employee ID found: $employeeId");
          setState(() {
            _statusMessage = "✅ Employee ID found";
          });
          return employeeId;
        } else {
          setState(() {
            _statusMessage = "❌ No employee found with this ID card number";
          });
        }
      } else if (response.statusCode == 401) {
        setState(() {
          _statusMessage = "❌ Unauthorized. Please login again.";
        });
      } else {
        setState(() {
          _statusMessage = "❌ Server error: ${response.statusCode}";
        });
        print("❌ API failed: ${response.statusCode}");
        print("Response: ${response.body}");
      }
    } catch (e) {
      setState(() {
        _statusMessage = "❌ Network error: $e";
      });
      print("🚫 Error fetching PersonId: $e");
    }
    return null;
  }

  Future<void> _registerFace(
    BuildContext context,
    String name,
    String email,
    String phone,
    String idCardNum,
    String facilityId,
  ) async {
    print("\n🚀 Starting registration...");
    print("Name: $name");
    print("ID Card: $idCardNum");
    print("Email: $email");
    print("Phone: $phone");
    print("Multi-angle: $_isMultiAngleMode");

    // Validation
    if (idCardNum.isEmpty) {
      _showError("Please enter ID Card Number");
      return;
    }
    if (name.isEmpty) {
      _showError("Please enter a name");
      return;
    }
    if (email.isNotEmpty && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      _showError("Enter a valid email");
      return;
    }
    if (phone.isNotEmpty && !RegExp(r'^\d{10}$').hasMatch(phone)) {
      _showError("Enter a valid 10-digit phone number");
      return;
    }

    setState(() {
      isLoading = true;
      _statusMessage = "⏳ Processing...";
    });

    try {
      // Fetch employeeId from server
      final employeeId = await _fetchPersonId(idCardNum);

      if (employeeId == null) {
        setState(() {
          isLoading = false;
          _statusMessage = "❌ Could not find employee";
        });
        _showError("Could not resolve Employee ID. Check ID card number.");
        return;
      }

      print("✅ Employee ID resolved: $employeeId");

      // ✅ FIXED: Use the class instance _recognizer (RecognizerV2)
      // Register based on mode
      if (_isMultiAngleMode && widget.multiAngleEmbeddings != null) {
        print("🎯 Registering with ${widget.multiAngleEmbeddings!.length} embeddings");
        
        setState(() {
          _statusMessage = "💾 Saving multi-angle data...";
        });

        Uint8List placeholderImage = Uint8List(0);
        
        // ✅ FIXED: Use _recognizer instead of new Recognizer()
        await _recognizer.registerMultipleEmbeddingsInHive(
          name,
          widget.multiAngleEmbeddings!,
          placeholderImage,
          email.isEmpty ? '' : email,
          phone.isEmpty ? '' : phone,
          employeeId,
          facilityId,
        );
        
        // ✅ NEW: Test registration quality (if method exists in RecognizerV2)
        print("\n🧪 Testing registration quality...");
        // await _recognizer.testRegistrationQuality(name); // Uncomment if you added this method
        
        print("✅ Multi-angle registration successful");
      } else {
        // Single-angle registration
        if (widget.croppedFace == null || widget.recognition == null) {
          setState(() {
            isLoading = false;
            _statusMessage = "❌ No face data";
          });
          _showError("No face data available");
          return;
        }

        print("📸 Registering single angle");
        
        setState(() {
          _statusMessage = "💾 Saving face data...";
        });

        Uint8List faceImageBytes =
            Uint8List.fromList(img.encodePng(widget.croppedFace!));

        // ✅ FIXED: Use _recognizer.registerMultipleEmbeddingsInHive with single embedding
        await _recognizer.registerMultipleEmbeddingsInHive(
          name,
          [widget.recognition!.embeddings], // ✅ Wrap in list for consistency
          faceImageBytes,
          email.isEmpty ? '' : email,
          phone.isEmpty ? '' : phone,
          employeeId,
          facilityId,
        );

        print("✅ Single-angle registration successful");
      }

      // Success!
      setState(() {
        isLoading = false;
        _statusMessage = "✅ Registration complete!";
      });

      // Clear fields
      _idCardController.clear();
      _nameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _facilityIdController.clear();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isMultiAngleMode 
              ? "✅ Face Registered with ${widget.multiAngleEmbeddings!.length} angles"
              : "✅ Face Registered Successfully"
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // Wait a bit then navigate back
      await Future.delayed(const Duration(milliseconds: 500));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const FaceRecognitionScreen()),
      );

    } catch (e, stackTrace) {
      print("❌ Registration error: $e");
      print("Stack trace: $stackTrace");
      
      setState(() {
        isLoading = false;
        _statusMessage = "❌ Registration failed: $e";
      });
      
      _showError("Registration failed: ${e.toString()}");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isMultiAngleMode ? "Complete Registration" : "Face Registration"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const FaceRecognitionScreen()),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 25),

              // Show different UI based on mode
              if (!_isMultiAngleMode && widget.croppedFace != null)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      Uint8List.fromList(img.encodePng(widget.croppedFace!)),
                      width: 200,
                      height: 240,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

              if (_isMultiAngleMode)
                Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.green, width: 2),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 60),
                      const SizedBox(height: 10),
                      Text(
                        "${widget.multiAngleEmbeddings!.length} Angles Captured",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        "Multi-angle registration complete!",
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // Status message
              if (_statusMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                  child: Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: _statusMessage.contains("❌") 
                          ? Colors.red 
                          : _statusMessage.contains("✅")
                              ? Colors.green
                              : Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              // Form fields
              _buildTextField(
                  _idCardController, "ID Card Number *", Icons.credit_card),
              const SizedBox(height: 10),

              _buildTextField(
                  _nameController, "Full Name *", Icons.person_outlined),
              const SizedBox(height: 10),
              
              _buildTextField(
                  _emailController, "Email (optional)", Icons.email_outlined,
                  keyboard: TextInputType.emailAddress),
              const SizedBox(height: 10),
              
              _buildTextField(_phoneController, "Phone (optional)",
                  Icons.phone_android_outlined,
                  keyboard: TextInputType.phone),
              
              const SizedBox(height: 20),

              if (isLoading) 
                const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text("Please wait...", style: TextStyle(color: Colors.grey)),
                  ],
                ),

              if (!isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        print("\n📘 Complete Registration button pressed");
                        _registerFace(
                          context,
                          _nameController.text.trim(),
                          _emailController.text.trim(),
                          _phoneController.text.trim(),
                          _idCardController.text.trim(),
                          _facilityIdController.text.trim(),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        _isMultiAngleMode ? "Complete Registration" : "Register",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String hint, IconData icon,
      {TextInputType keyboard = TextInputType.text}) {
    return SizedBox(
      width: 320,
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.purple),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[150],
        ),
      ),
    );
  }
}