import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:track_on/feature/face_recognition/presentation/pages/face_recognition_screen.dart';
import 'package:track_on/feature/face_recognition/presentation/pages/setting_page.dart';

class FaceListingPage extends StatefulWidget {
  const FaceListingPage({Key? key}) : super(key: key);

  @override
  State<FaceListingPage> createState() => _FaceListingPageState();
}

class _FaceListingPageState extends State<FaceListingPage> {
  final List<Map<String, dynamic>> _faces = [];
  bool _isLoading = true;
  String _debugInfo = '';

  @override
  void initState() {
    super.initState();
    _loadFaces();
  }

  Future<void> _loadFaces() async {
    setState(() {
      _isLoading = true;
      _debugInfo = 'Loading faces...';
      _faces.clear();
    });

    try {
      final box = await Hive.openBox('faces');
      _debugInfo += '\nOpened box: faces';
      _debugInfo += '\nNumber of faces: ${box.length}';

      for (var key in box.keys) {
        final faceData = box.get(key);

        if (faceData != null && faceData is Map) {
          final name = faceData['name'] ?? 'Unregister';
          final embedding = faceData['embedding'] ?? <double>[];
          final imageBytes = faceData['faceImage'] as Uint8List?;
          final email = faceData['email'] as String;
          final phone = faceData['phone'] as String;
          final employeeId = faceData['employeeId'] as String? ?? 'N/A';
          final facilityId = faceData['facilityId'] as String? ?? 'N/A';

          if (embedding is List) {
            List<double> embeddingList = [];

            for (var value in embedding) {
              if (value is double) {
                embeddingList.add(value);
              } else if (value is int) {
                embeddingList.add(value.toDouble());
              }
            }

            _faces.add({
              'name': name,
              'embedding': embeddingList,
              'faceImage': imageBytes,
              'email': email,
              'phone': phone,
              'employeeId': employeeId,
              'facilityId': facilityId,
            });
          }
        }
      }

      setState(() {
        _isLoading = false;
        _debugInfo += '\nLoaded ${_faces.length} faces successfully';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _debugInfo += '\nError loading faces: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registered Employees'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // Back arrow icon
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    SettingsPage(), // Replace with the actual previous page
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFaces,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _faces.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.face, size: 72, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            const Text(
                              'No registered faces found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add faces using face recognition',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _faces.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final face = _faces[index];
                          final name = face['name'] as String;
                          final embedding = face['embedding'] as List<double>;
                          final faceImage = face['faceImage'] as Uint8List?;
                          final email = face['email'] as String;
                          final phone = face['phone'] as String;
                          final employeeId = face['employeeId'] as String;
                          final facilityId = face['facilityId'] as String;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      faceImage != null
                                          ? CircleAvatar(
                                              radius: 40,
                                              backgroundImage:
                                                  MemoryImage(faceImage),
                                            )
                                          : const CircleAvatar(
                                              radius: 40,
                                              backgroundColor: Colors.grey,
                                              child:
                                                  Icon(Icons.person, size: 40),
                                            ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              email,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              phone,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              'Employee ID: $employeeId',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            // Text(
                                            //   'Facility ID: $facilityId',
                                            //   style: const TextStyle(
                                            //     fontSize: 18,
                                            //     fontWeight: FontWeight.bold,
                                            //   ),
                                            // ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () => _deleteFace(name),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.blue),
                                        onPressed: () => _editFace(face),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _deleteFace(String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Face'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final box = await Hive.openBox('faces');
        await box.delete(name);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Face "$name" deleted successfully')),
        );

        _loadFaces();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting face: $e')),
        );
      }
    }
  }

  void _editFace(Map<String, dynamic> face) {
    final nameController = TextEditingController(text: face['name']);
    final emailController = TextEditingController(text: face['email']);
    final phoneController = TextEditingController(text: face['phone']);
    final employeeIdController =
        TextEditingController(text: face['employeeId']);
    final facilityIdController =
        TextEditingController(text: face['facilityId']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Person'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
                TextField(
                  controller: employeeIdController,
                  decoration: const InputDecoration(labelText: 'Employee ID'),
                ),
                TextField(
                  controller: facilityIdController,
                  decoration: const InputDecoration(labelText: 'Facility ID'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final box = await Hive.openBox('faces');
                final updatedFace = {
                  'name': nameController.text.trim(),
                  'email': emailController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'employeeId': employeeIdController.text.trim(),
                  'facilityId': facilityIdController.text.trim(),
                  'embedding': face['embedding'],
                  'faceImage': face['faceImage'],
                };

                await box.put(updatedFace['name'], updatedFace);
                if (updatedFace['name'] != face['name']) {
                  await box.delete(face['name']); // Remove old key if renamed
                }

                Navigator.pop(context);
                _loadFaces();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Person updated')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
