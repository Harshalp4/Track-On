import 'dart:convert';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:track_on/core/endpoints/base_url.dart';
import 'package:track_on/feature/face_recognition/presentation/pages/face_list_page.dart';
import 'package:track_on/feature/face_recognition/presentation/pages/face_recognition_screen.dart';
import 'package:flutter_kiosk_mode/flutter_kiosk_mode.dart';
import 'package:http/http.dart' as http;
import 'package:track_on/feature/auth/domain/services/secure_storage_service.dart';
import '../../domain/services/tts_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with SingleTickerProviderStateMixin {
  String _kioskName = 'Default Kiosk';
  String _facilityId = 'FAC-001';
  String _deviceKey = '';
  bool _useLivenessConfirmationCard = true;
  bool _useSpeedRecognitionMode = false;
  bool _enableTTS = true;
  bool _useAILiveness = false;
  bool _enableGeofencing = true; // ✅ ADD this
  
  // Voice settings
  double _speechRate = 0.5;
  double _pitch = 1.0;
  double _volume = 1.0;
  String? _selectedVoice;
  List<Map<String, dynamic>> _availableVoices = [];
  
  // Voice filtering
  String _voiceGenderFilter = 'All'; // All, Male, Female
  
  final TTSService _ttsService = TTSService();
  final TextEditingController _kioskNameController = TextEditingController();
  final TextEditingController _facilityIdController = TextEditingController();

  List<Map<String, String>> _deviceList = [];
  bool _isDeviceKeysLoading = true;
  bool _isSaving = false;
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSettings();
    _fetchDeviceKeys();
    _loadVoiceSettings();
  }

  @override
  void dispose() {
    _kioskNameController.dispose();
    _facilityIdController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadVoiceSettings() async {
    await _ttsService.initialize();
    
    final settings = _ttsService.getCurrentSettings();
    _availableVoices = _ttsService.getAvailableVoices();
    
    setState(() {
      _speechRate = settings['speechRate'] ?? 0.5;
      _pitch = settings['pitch'] ?? 1.0;
      _volume = settings['volume'] ?? 1.0;
      _selectedVoice = settings['voice'];
    });
  }

  Future<void> _updateVoiceSettings() async {
    await _ttsService.updateSettings(
      speechRate: _speechRate,
      pitch: _pitch,
      volume: _volume,
      voice: _selectedVoice,
    );
  }

  Future<void> _testVoice() async {
    await _ttsService.speak("Hello! This is a test of the voice settings. Welcome to the kiosk system.");
  }

  Future<void> _loadSettings() async {
    final settingsBox = Hive.box('settingsBox');
    setState(() {
      _kioskName = settingsBox.get('kioskName');
      _facilityId = settingsBox.get('facilityId');
      _deviceKey = settingsBox.get('deviceKey', defaultValue: '');
      _useLivenessConfirmationCard =
          settingsBox.get('useLivenessConfirmationCard', defaultValue: true);
      _useSpeedRecognitionMode =
          settingsBox.get('useSpeedRecognitionMode', defaultValue: false);
      _enableTTS = settingsBox.get('enableTTS', defaultValue: true);
      _useAILiveness = settingsBox.get('useAILiveness', defaultValue: false);

      _kioskNameController.text = _kioskName;
      _facilityIdController.text = _facilityId;
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    
    final settingsBox = Hive.box('settingsBox');
    await settingsBox.put('kioskName', _kioskName);
    await settingsBox.put('facilityId', _facilityId);
    await settingsBox.put('deviceKey', _deviceKey);
    await settingsBox.put('useLivenessConfirmationCard', _useLivenessConfirmationCard);
    await settingsBox.put('useSpeedRecognitionMode', _useSpeedRecognitionMode);
    await settingsBox.put('enableTTS', _enableTTS);
    await settingsBox.put('useAILiveness', _useAILiveness);

    await Future.delayed(Duration(milliseconds: 500));
    
    setState(() => _isSaving = false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Settings saved successfully!'),
          ],
        ),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _fetchDeviceKeys() async {
    setState(() => _isDeviceKeysLoading = true);
    try {
      final token = await SecureStorageService.getAccessToken();
      final response = await http.get(
        Uri.parse(BaseUrl.getDeviceLookup),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': "Bearer $token"
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> items = decoded["result"] as List<dynamic>;

        final List<Map<String, String>> fetchedDevices = items
            .map((item) => {
                  "key": item['deviceKey'].toString(),
                  "name": item['name']?.toString() ?? "Unnamed Device",
                })
            .toList();

        setState(() {
          _deviceList = fetchedDevices;
          _isDeviceKeysLoading = false;
        });
      } else {
        throw Exception('Failed to load device keys: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _isDeviceKeysLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading device keys: $e')),
      );
    }
  }

  void _applyVoicePreset(String presetName, double rate, double pitch) {
    setState(() {
      _speechRate = rate;
      _pitch = pitch;
    });
    _updateVoiceSettings();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Applied preset: $presetName'),
        duration: Duration(seconds: 1),
      ),
    );
    
    Future.delayed(Duration(milliseconds: 500), _testVoice);
  }

  String _getSpeechRateLabel(double rate) {
    if (rate < 0.3) return 'Very Slow';
    if (rate < 0.5) return 'Slow';
    if (rate < 0.7) return 'Normal';
    if (rate < 0.9) return 'Fast';
    return 'Very Fast';
  }

  String _getPitchLabel(double pitch) {
    if (pitch < 0.8) return 'Very Low';
    if (pitch < 1.0) return 'Low';
    if (pitch < 1.3) return 'Normal';
    if (pitch < 1.7) return 'High';
    return 'Very High';
  }

  List<Map<String, dynamic>> _getFilteredVoices() {
    if (_voiceGenderFilter == 'All') return _availableVoices;
    
    return _availableVoices.where((voice) {
      final name = voice['name']?.toLowerCase() ?? '';
      
      if (_voiceGenderFilter == 'Male') {
        return name.contains('male') && !name.contains('female');
      } else if (_voiceGenderFilter == 'Female') {
        return name.contains('female');
      }
      
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Color(0xFF8B5CF6),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color(0xFF8B5CF6),
              indicatorWeight: 3,
              tabs: [
                Tab(icon: Icon(Icons.settings), text: 'General'),
                Tab(icon: Icon(Icons.face), text: 'Recognition'),
                Tab(icon: Icon(Icons.record_voice_over), text: 'Voice'),
              ],
            ),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => FaceRecognitionScreen()),
            );
          },
        ),
        // ✅ ADD: AI Liveness toggle in AppBar (same as face recognition screen)
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Icon(
                _useAILiveness ? Icons.psychology : Icons.remove_red_eye,
                color: _useAILiveness ? Color(0xFF8B5CF6) : Colors.blue,
                size: 28,
              ),
              tooltip: _useAILiveness ? 'AI Liveness Enabled' : 'Rule-based Liveness',
              onPressed: () async {
                setState(() => _useAILiveness = !_useAILiveness);
                await _saveSettings();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(
                          _useAILiveness ? Icons.psychology : Icons.remove_red_eye,
                          color: Colors.white,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(_useAILiveness 
                            ? '🤖 AI Liveness Enabled' 
                            : '👁️ Rule-based Liveness Enabled'),
                        ),
                      ],
                    ),
                    backgroundColor: _useAILiveness ? Color(0xFF8B5CF6) : Colors.blue,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGeneralTab(),
          _buildRecognitionTab(),
          _buildVoiceTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ======================== GENERAL TAB ========================
  Widget _buildGeneralTab() {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Kiosk Configuration', Icons.devices),
        _buildCard([
          _buildListTile(
            icon: Icons.store,
            iconColor: Color(0xFF3B82F6),
            title: 'Kiosk Name',
            subtitle: _kioskName,
            trailing: Icon(Icons.edit, size: 20),
            onTap: _showKioskNameDialog,
          ),
          Divider(height: 1),
          _buildListTile(
            icon: Icons.key,
            iconColor: Color(0xFFFBBF24),
            title: 'Device Key',
            subtitle: _isDeviceKeysLoading
                ? 'Loading...'
                : (_deviceKey.isNotEmpty ? _deviceKey : 'Not selected'),
            trailing: Icon(Icons.arrow_drop_down, size: 24),
            onTap: () {
              if (!_isDeviceKeysLoading) {
                _showDeviceKeyDialog();
              }
            },
          ),
        ]),
        
        SizedBox(height: 20),
        
        _buildSectionHeader('Management', Icons.admin_panel_settings),
        _buildCard([
          _buildListTile(
            icon: Icons.people,
            iconColor: Color(0xFF3B82F6),
            title: 'Registered Members',
            subtitle: 'Manage registered faces',
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FaceListingPage()),
              );
            },
          ),
        ]),
        
        SizedBox(height: 20),
        
        _buildSectionHeader('System Actions', Icons.security),
        _buildCard([
          _buildListTile(
            icon: Icons.lock_open,
            iconColor: Colors.redAccent,
            title: 'Exit Kiosk Mode',
            subtitle: 'Disable kiosk restrictions',
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              await FlutterKioskMode.instance().stop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Kiosk Mode Exited'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
        ]),
      ],
    );
  }

  // ======================== RECOGNITION TAB ========================
  Widget _buildRecognitionTab() {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Liveness Detection', Icons.verified_user),
        _buildCard([
          SwitchListTile(
            title: Text('AI Liveness Detection', 
              style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(_useAILiveness 
              ? '🤖 Using AI model for anti-spoofing' 
              : '👁️ Using rule-based liveness checks'),
            value: _useAILiveness,
            activeColor: Color(0xFF8B5CF6),
            secondary: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (_useAILiveness ? Color(0xFF8B5CF6) : Colors.blue).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _useAILiveness ? Icons.psychology : Icons.remove_red_eye,
                color: _useAILiveness ? Color(0xFF8B5CF6) : Colors.blue,
              ),
            ),
            onChanged: (value) {
              setState(() => _useAILiveness = value);
              _saveSettings();
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(
                        value ? Icons.psychology : Icons.remove_red_eye,
                        color: Colors.white,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(value 
                          ? '🤖 AI Liveness Enabled' 
                          : '👁️ Rule-based Liveness Enabled'),
                      ),
                    ],
                  ),
                  backgroundColor: value ? Color(0xFF8B5CF6) : Colors.blue,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
          ),
        ]),
        
        SizedBox(height: 20),
        
        _buildSectionHeader('Location Verification', Icons.location_on),
        _buildCard([
          SwitchListTile(
            title: Text('Enable Geofencing', 
              style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(_enableGeofencing 
              ? '📍 Location verified during clock-in' 
              : '🔓 Location check disabled (testing mode)'),
            value: _enableGeofencing,
            activeColor: Color(0xFF10B981),
            secondary: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _enableGeofencing ? Icons.location_on : Icons.location_off,
                color: Color(0xFF10B981),
              ),
            ),
            onChanged: (value) {
              setState(() => _enableGeofencing = value);
              _saveSettings();
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(
                        value ? Icons.location_on : Icons.location_off,
                        color: Colors.white,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(value 
                          ? '📍 Geofencing Enabled' 
                          : '🔓 Geofencing Disabled'),
                      ),
                    ],
                  ),
                  backgroundColor: value ? Color(0xFF10B981) : Colors.orange,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
          ),
        ]),
        
        SizedBox(height: 20),
        
        _buildSectionHeader('Recognition Mode', Icons.face_retouching_natural),
        _buildCard([
          RadioListTile<bool>(
            title: Text('Facial Recognition Mode', 
              style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('Full verification with liveness confirmation'),
            value: true,
            groupValue: _useLivenessConfirmationCard,
            activeColor: Color(0xFF10B981),
            secondary: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.face, color: Color(0xFF10B981)),
            ),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _useLivenessConfirmationCard = value;
                  _useSpeedRecognitionMode = !value;
                });
                _saveSettings();
              }
            },
          ),
          Divider(height: 1),
          RadioListTile<bool>(
            title: Text('Speed Recognition Mode', 
              style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('Quick recognition without confirmation popup'),
            value: false,
            groupValue: _useLivenessConfirmationCard,
            activeColor: Color(0xFFEF4444),
            secondary: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.speed, color: Color(0xFFEF4444)),
            ),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _useLivenessConfirmationCard = value;
                  _useSpeedRecognitionMode = !value;
                });
                _saveSettings();
              }
            },
          ),
        ]),
      ],
    );
  }

  // ======================== VOICE TAB ========================
  Widget _buildVoiceTab() {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Voice Greeting', Icons.campaign),
        _buildCard([
          SwitchListTile(
            title: Text('Enable Voice Greeting', 
              style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(_enableTTS 
              ? 'Voice will greet users during clock in/out'
              : 'Voice greeting is disabled'),
            value: _enableTTS,
            activeColor: Color(0xFF8B5CF6),
            secondary: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Color(0xFF8B5CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _enableTTS ? Icons.volume_up : Icons.volume_off,
                color: Color(0xFF8B5CF6),
              ),
            ),
            onChanged: (value) {
              setState(() => _enableTTS = value);
              _saveSettings();
            },
          ),
        ]),

        if (_enableTTS) ...[
          SizedBox(height: 20),
          
          // Test Voice Button
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF8B5CF6).withOpacity(0.3),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _testVoice,
              icon: Icon(Icons.play_circle_filled, size: 28),
              label: Text('Test Voice Settings', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          
          SizedBox(height: 20),
          
          _buildSectionHeader('Voice Controls', Icons.tune),
          
          // Speech Rate
          _buildVoiceControlCard(
            title: 'Speech Rate',
            subtitle: _getSpeechRateLabel(_speechRate),
            icon: Icons.speed,
            color: Color(0xFF3B82F6),
            value: _speechRate,
            min: 0.1,
            max: 1.0,
            divisions: 9,
            onChanged: (value) {
              setState(() => _speechRate = value);
            },
            onChangeEnd: (value) {
              _updateVoiceSettings();
              _testVoice();
            },
          ),
          
          SizedBox(height: 12),
          
          // Pitch
          _buildVoiceControlCard(
            title: 'Voice Pitch',
            subtitle: _getPitchLabel(_pitch),
            icon: Icons.graphic_eq,
            color: Color(0xFF10B981),
            value: _pitch,
            min: 0.5,
            max: 2.0,
            divisions: 15,
            onChanged: (value) {
              setState(() => _pitch = value);
            },
            onChangeEnd: (value) {
              _updateVoiceSettings();
              _testVoice();
            },
          ),
          
          SizedBox(height: 12),
          
          // Volume
          _buildVoiceControlCard(
            title: 'Volume',
            subtitle: '${(_volume * 100).toInt()}%',
            icon: Icons.volume_up,
            color: Color(0xFFFBBF24),
            value: _volume,
            min: 0.0,
            max: 1.0,
            divisions: 10,
            onChanged: (value) {
              setState(() => _volume = value);
            },
            onChangeEnd: (value) {
              _updateVoiceSettings();
              _testVoice();
            },
          ),
          
          SizedBox(height: 20),
          
          // Voice Selection
          if (_availableVoices.isNotEmpty) ...[
            _buildSectionHeader('Select Voice', Icons.person),
            
            // Gender Filter
            Container(
              margin: EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: SegmentedButton<String>(
                      segments: [
                        ButtonSegment(
                          value: 'All',
                          label: Text('All'),
                          icon: Icon(Icons.people, size: 18),
                        ),
                        ButtonSegment(
                          value: 'Male',
                          label: Text('Male'),
                          icon: Icon(Icons.man, size: 18),
                        ),
                        ButtonSegment(
                          value: 'Female',
                          label: Text('Female'),
                          icon: Icon(Icons.woman, size: 18),
                        ),
                      ],
                      selected: {_voiceGenderFilter},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() {
                          _voiceGenderFilter = newSelection.first;
                        });
                      },
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.resolveWith((states) {
                          if (states.contains(MaterialState.selected)) {
                            return Color(0xFF8B5CF6);
                          }
                          return Colors.grey.shade200;
                        }),
                        foregroundColor: MaterialStateProperty.resolveWith((states) {
                          if (states.contains(MaterialState.selected)) {
                            return Colors.white;
                          }
                          return Colors.black87;
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            _buildCard([
              Container(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.record_voice_over, 
                          color: Color(0xFFEC4899), size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Voice Type',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedVoice,
                          hint: Text('Default Voice'),
                          isExpanded: true,
                          icon: Icon(Icons.arrow_drop_down, 
                            color: Color(0xFFEC4899)),
                          items: [
                            DropdownMenuItem<String>(
                              value: null,
                              child: Row(
                                children: [
                                  Icon(Icons.settings_voice, 
                                    size: 20, color: Colors.grey),
                                  SizedBox(width: 8),
                                  Text('Default Voice'),
                                ],
                              ),
                            ),
                            ..._getFilteredVoices().map((voice) {
                              final name = voice['name'] ?? 'Unknown';
                              final locale = voice['locale'] ?? '';
                              final isMale = name.toLowerCase().contains('male') && 
                                           !name.toLowerCase().contains('female');
                              final isFemale = name.toLowerCase().contains('female');
                              
                              return DropdownMenuItem<String>(
                                value: name,
                                child: Row(
                                  children: [
                                    Icon(
                                      isMale ? Icons.man : 
                                      isFemale ? Icons.woman : 
                                      Icons.person,
                                      size: 20,
                                      color: isMale ? Colors.blue : 
                                            isFemale ? Colors.pink : 
                                            Colors.grey,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '$name ($locale)',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedVoice = value);
                            _updateVoiceSettings();
                            Future.delayed(Duration(milliseconds: 300), _testVoice);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ],
          
          SizedBox(height: 20),
          
          // Voice Presets
          _buildSectionHeader('Quick Presets', Icons.dashboard_customize),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildPresetButton('Normal', Icons.person, 
                      () => _applyVoicePreset('Normal', 0.5, 1.0))),
                    SizedBox(width: 8),
                    Expanded(child: _buildPresetButton('Slow', Icons.directions_walk, 
                      () => _applyVoicePreset('Slow', 0.3, 1.0))),
                    SizedBox(width: 8),
                    Expanded(child: _buildPresetButton('Fast', Icons.directions_run, 
                      () => _applyVoicePreset('Fast', 0.7, 1.0))),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildPresetButton('Deep', Icons.arrow_downward, 
                      () => _applyVoicePreset('Deep Voice', 0.5, 0.7))),
                    SizedBox(width: 8),
                    Expanded(child: _buildPresetButton('High', Icons.arrow_upward, 
                      () => _applyVoicePreset('High Voice', 0.5, 1.5))),
                    SizedBox(width: 8),
                    Expanded(child: _buildPresetButton('Reset', Icons.refresh, 
                      () => _applyVoicePreset('Default', 0.5, 1.0))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ======================== HELPER WIDGETS ========================
  
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(left: 4, bottom: 12, top: 8),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Colors.grey.shade700),
          SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 13)),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildVoiceControlCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required ValueChanged<double> onChangeEnd,
  }) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: color.withOpacity(0.2),
              thumbColor: color,
              overlayColor: color.withOpacity(0.2),
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 24),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetButton(String label, IconData icon, VoidCallback onTap) {
    return Material(
      color: Color(0xFF8B5CF6),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, size: 24, color: Colors.white),
              SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveSettings,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF10B981),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: _isSaving
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save, size: 22),
                    SizedBox(width: 12),
                    Text(
                      'Save All Settings',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _showKioskNameDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit Kiosk Name'),
        content: TextField(
          controller: _kioskNameController,
          decoration: InputDecoration(
            labelText: 'Kiosk Name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _kioskName = _kioskNameController.text);
              _saveSettings();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF10B981),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('SAVE'),
          ),
        ],
      ),
    );
  }

  void _showDeviceKeyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Select Device Key'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _deviceList.length,
            itemBuilder: (context, index) {
              final device = _deviceList[index];
              return RadioListTile<String>(
                title: Text(device['name']!),
                subtitle: Text(device['key']!),
                value: device['key']!,
                groupValue: _deviceKey,
                activeColor: Color(0xFF8B5CF6),
                onChanged: (value) {
                  setState(() => _deviceKey = value ?? '');
                  _saveSettings();
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL'),
          ),
        ],
      ),
    );
  }
}