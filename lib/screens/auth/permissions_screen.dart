import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../config/colors.dart';
import '../../custom_widgets/custom_button.dart';
import '../../custom_widgets/logo_header.dart';
import '../../custom_widgets/feature_info_card.dart';

class PermissionsScreen extends StatelessWidget {
  const PermissionsScreen({super.key});

  Future<void> _requestPermissions(BuildContext context) async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.microphone,
      Permission.bluetooth,
      Permission.sensors,
    ].request();

    if (statuses[Permission.location]!.isGranted && statuses[Permission.microphone]!.isGranted) {
      Navigator.pushNamedAndRemoveUntil(context, '/trust_contacts', (route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please grant essential permissions to continue")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.bgBlueLight, AppColors.bgPurpleLight, Colors.white],
            stops: const [0.0, 0.3, 0.7],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              const AppLogoHeader(),
              const SizedBox(height: 15),
              _buildStepper(1), 
              const SizedBox(height: 25),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: AppColors.logoGradient,
                ).createShader(bounds),
                child: const Text(
                  "Enable your safety net",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: const [
                    FeatureInfoCard(
                      title: "Location Access", 
                      description: "Used for sharing your real-time location with emergency contacts.", 
                      icon: Icons.location_on
                    ),
                    FeatureInfoCard(
                      title: "Microphone Access", 
                      description: "Used for recording audio evidence when a threat is detected.", 
                      icon: Icons.mic
                    ),
                    FeatureInfoCard(
                      title: "Bluetooth Access", 
                      description: "Used to connect to safety accessories or detect nearby devices.", 
                      icon: Icons.bluetooth
                    ),
                    FeatureInfoCard(
                      title: "Motion Activity", 
                      description: "Used for detecting falls, sudden movements, or distress signals.", 
                      icon: Icons.directions_run
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Column(
                  children: [
                    CustomButton(text: "Grant permissions", onPressed: () => _requestPermissions(context)),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/trust_contacts', (route) => false),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF4983F6)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text("Skip for now", style: TextStyle(color: Colors.black)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepper(int activeStep) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: index == activeStep ? 9.7 : 9.7,
        height: 10,
        decoration: BoxDecoration(
          color: index == activeStep ? const Color(0xFFCB30E0) : const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(5),
        ),
      )),
    );
  }
}