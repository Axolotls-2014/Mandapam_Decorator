import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';

class OtpForm extends StatelessWidget {
  final double? defaultBoxSize;
  final dynamic provider;

  const OtpForm({super.key, required this.provider, this.defaultBoxSize});

  @override
  Widget build(BuildContext context) {
    return OtpTextField(
      numberOfFields: provider.otpCodeLength ?? 5,
      borderRadius: BorderRadius.circular(10),
      fieldWidth: defaultBoxSize ?? 45,
      focusedBorderColor: Colors.blue,
      borderColor: Colors.grey.shade400,
      showFieldAsBox: true,
      obscureText: true,
      cursorColor: Colors.black,
      onCodeChanged: (code) {
        provider.onOtpChanged(code);
      },
      onSubmit: (code) {
        provider.onOtpChanged(code);
      },
    );
  }
}