import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:track_on/feature/face_recognition/domain/services/network_monitor_api_call.dart';
import 'face_recognition_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

import 'dart:async';

class ConfirmPage extends StatelessWidget {
  final String recognizedName;
  final Uint8List faceImage;

  const ConfirmPage(
      {super.key, required this.recognizedName, required this.faceImage});

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final String formattedDate = DateFormat('EEE, d MMM yyyy').format(now);
    final String formattedTime = DateFormat('hh:mm a').format(now);
    final settingsBox = Hive.box('settingsBox');

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const FaceRecognitionScreen(),
              ),
            );
          },
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Confirm Clock In',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Clock in and start timer',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // User profile card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              height: 130,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Profile picture
                  //Icon(Icons.person, size: 80),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      border: Border.all(color: Colors.grey.shade200, width: 1),
                      image: DecorationImage(
                        image:
                            MemoryImage(faceImage), // ✅ Display faceImage here
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),
                  // User info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recognizedName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Facility Id ${settingsBox.get('facilityId', defaultValue: 'FAC-001')}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        // Text(
                        //   'iPhone 14 | iPhone',
                        //   style: TextStyle(
                        //     fontSize: 12,
                        //     color: Colors.grey[600],
                        //   ),
                        // ),
                        Text(
                          'Last out 10:11 am today',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Clock-in details
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Date and time
                  ListTile(
                    leading: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.calendar_today,
                          size: 25, color: Colors.green[400]),
                    ),
                    title: Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Text(
                      formattedTime,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  //const Divider(height: 8),

                  // Location
                  // ListTile(
                  //   leading: Container(
                  //     width: 32,
                  //     height: 32,
                  //     decoration: BoxDecoration(
                  //       color: Colors.grey[100],
                  //       borderRadius: BorderRadius.circular(6),
                  //     ),
                  //     child: const Icon(Icons.location_on_outlined,
                  //         size: 25, color: Colors.blueGrey),
                  //   ),
                  //   title: const Text(
                  //     'Platform 9 3/4',
                  //     style: TextStyle(
                  //       fontSize: 14,
                  //       fontWeight: FontWeight.w500,
                  //     ),
                  //   ),
                  //   trailing:
                  //       const Icon(Icons.chevron_right, color: Colors.grey),
                  // ),
                  // const Divider(height: 8),

                  // // Activity selection
                  // ListTile(
                  //   leading: Container(
                  //     width: 32,
                  //     height: 32,
                  //     decoration: BoxDecoration(
                  //       color: Colors.grey[100],
                  //       borderRadius: BorderRadius.circular(6),
                  //     ),
                  //     child: const Icon(Icons.label_outline,
                  //         size: 25, color: Colors.blueGrey),
                  //   ),
                  //   title: Text(
                  //     'Select an activity',
                  //     style: TextStyle(
                  //       fontSize: 14,
                  //       color: Colors.grey[400],
                  //     ),
                  //   ),
                  //   trailing: Row(
                  //     mainAxisSize: MainAxisSize.min,
                  //     children: [
                  //       Text(
                  //         'required',
                  //         style: TextStyle(
                  //           fontSize: 12,
                  //           color: Colors.grey[400],
                  //         ),
                  //       ),
                  //       const Icon(Icons.chevron_right, color: Colors.grey),
                  //     ],
                  //   ),
                  // ),
                  // const Divider(height: 8),

                  // // Project selection
                  // ListTile(
                  //   leading: Container(
                  //     width: 32,
                  //     height: 32,
                  //     decoration: BoxDecoration(
                  //       color: Colors.grey[100],
                  //       borderRadius: BorderRadius.circular(6),
                  //     ),
                  //     child: const Icon(Icons.folder_outlined,
                  //         size: 25, color: Colors.blueGrey),
                  //   ),
                  //   title: Text(
                  //     'Select a project',
                  //     style: TextStyle(
                  //       fontSize: 14,
                  //       color: Colors.grey[400],
                  //     ),
                  //   ),
                  //   trailing: Row(
                  //     mainAxisSize: MainAxisSize.min,
                  //     children: [
                  //       Text(
                  //         'required',
                  //         style: TextStyle(
                  //           fontSize: 12,
                  //           color: Colors.grey[400],
                  //         ),
                  //       ),
                  //       const Icon(Icons.chevron_right, color: Colors.grey),
                  //     ],
                  //   ),
                  // ),
                  const Divider(height: 8),

                  // Notes
                  ListTile(
                    leading: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.notes,
                          size: 25, color: Colors.blueGrey),
                    ),
                    title: Text(
                      'Add a note',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom options
            // Container(
            //   margin: const EdgeInsets.all(16),
            //   child: Row(
            //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //     children: [
            //       // Add reminder button
            //       OutlinedButton.icon(
            //         onPressed: () {},
            //         icon: const Icon(Icons.notifications_outlined, size: 16),
            //         label: const Text('Add reminder'),
            //         style: OutlinedButton.styleFrom(
            //           foregroundColor: Colors.black,
            //           side: const BorderSide(color: Colors.grey),
            //           shape: RoundedRectangleBorder(
            //             borderRadius: BorderRadius.circular(20),
            //           ),
            //         ),
            //       ),

            //       // Time button
            //       ElevatedButton.icon(
            //         onPressed: () {},
            //         icon: const Icon(Icons.access_time, size: 16),
            //         label: const Text('11:30 am'),
            //         style: ElevatedButton.styleFrom(
            //           backgroundColor: Colors.orange[100],
            //           foregroundColor: Colors.orange[800],
            //           elevation: 0,
            //           shape: RoundedRectangleBorder(
            //             borderRadius: BorderRadius.circular(20),
            //           ),
            //         ),
            //       ),
            //     ],
            //   ),
            // ),

            // Bottom spacer
            const SizedBox(height: 100),
          ],
        ),
      ),

      // FAB for clock-in action
      floatingActionButton: Container(
        width: double.infinity,
        height: 50,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: ElevatedButton(
          onPressed: () =>
              sendDataToApi(type: 'null', faceImage: faceImage, employeeId: ''),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color.fromRGBO(170, 120, 220, 0.866),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Confirm',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
