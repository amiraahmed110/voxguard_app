import 'dart:async';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../config/colors.dart';
import '../custom_widgets/custom_button.dart';
import 'safe_home_screen.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  int _start = 3;
  Timer? _timer;
  

  bool _isLocationSharing = true;
  bool _isAudioRecording = true;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 1) {
        setState(() {
          _start = 0;
          _timer?.cancel();
        });
         Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SafeHomeScreen()),
     );
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.bgBlueLight,
              AppColors.bgPurpleLight,
              Colors.white,
            ],
          stops: [0.0, 0.3, 0.7],
          ),
        ),
        child: Column(
          children: [
            const Spacer(flex: 3),
            Text(
              '$_start',
              style: const TextStyle(
                fontSize: 200,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryPurple,
                height: 1.0,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 10),
            

            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: AppColors.logoGradient,
              ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
              child: const Text(
                'SOS Mode Activated',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, 
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            const Text(
              'Sending Alerts to Emergency Contacts',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black45,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            
            _buildActionCard(
              Icons.location_on, 
              'Share live Location', 
              _isLocationSharing,
              (val) => setState(() => _isLocationSharing = val)
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              Icons.mic_rounded, 
              'Recording Audio', 
              _isAudioRecording,
              (val) => setState(() => _isAudioRecording = val)
            ),
            
            const Spacer(flex: 2),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 50),
              child: CustomButton(
                text: 'Cancel sos',
                onPressed: () {
                  _timer?.cancel(); 
                   Navigator.pushReplacement(
                   context,
                 MaterialPageRoute(builder: (context) => const HomeScreen()),
                );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(IconData icon, String title, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primaryPurple, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: Colors.black87,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: AppColors.primaryPurple,
          ),
        ],
      ),
    );
  }
}