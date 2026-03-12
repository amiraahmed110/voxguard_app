import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../config/colors.dart';
import '../../custom_widgets/custom_button.dart';
import '../../custom_widgets/custom_text_field.dart';
import '../../custom_widgets/logo_header.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
              const SizedBox(height: 30),
              const AppLogoHeader(),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Container(
                      width: 343,
                      padding: const EdgeInsets.all(24),
                      margin: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.white, 
                        borderRadius: BorderRadius.circular(30)
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              onPressed: () => Navigator.pop(context), 
                              icon: const Icon(Icons.arrow_back)
                            ),
                          ),
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: AppColors.logoGradient,
                            ).createShader(bounds),
                            child: const Text(
                              "Sign Up", 
                              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Already have an account? ",
                                style: TextStyle(fontSize: 13, color: Colors.black),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(context, '/login'),
                                child: const Text(
                                  "Login",
                                  style: TextStyle(
                                    fontSize: 13, 
                                    fontWeight: FontWeight.bold, 
                                    color: AppColors.primaryPurple,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Row(
                            children: [
                              Expanded(child: CustomTextField(label: "First Name", hintText: "First Name")),
                              SizedBox(width: 15),
                              Expanded(child: CustomTextField(label: "Last Name", hintText: "Last Name")),
                            ],
                          ),
                          const CustomTextField(label: "Email", hintText: "Enter your email"),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Phone Number",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ),
                          const SizedBox(height: 8),
                          IntlPhoneField(
                            initialCountryCode: 'EG',
                            disableLengthCheck: true,
                            flagsButtonMargin: const EdgeInsets.only(left: 8, right: 15),
                            dropdownIconPosition: IconPosition.trailing,
                            decoration: InputDecoration(
                              hintText: '1551471747',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: const BorderSide(color: AppColors.buttonBorderBlue, width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                            ),
                          ),
                          const SizedBox(height: 15),
                          const CustomTextField(label: "Set Password", isPassword: true),
                          const CustomTextField(label: "Confirm password", isPassword: true),
                          const SizedBox(height: 30),
                          CustomButton(
                            text: "Register", 
                            onPressed: () => Navigator.pushNamed(context, '/confirmed')
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}