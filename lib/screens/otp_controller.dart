import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/helper/route_helper.dart';

class OtpController extends GetxController {
  final int otpCodeLength = 4;
  final textEditingController = TextEditingController();

  var otpCode = ''.obs;
  String _correctOtp = '';
  var isLoadingButton = false.obs;
  var enableButton = false.obs;
  var seconds = 0.obs;
  Timer? _timer;
  RxBool valid = false.obs;
  var number = ''.obs;

  final RegExp intRegex = RegExp(r'^\d+$');

  @override
  void onInit() {
    super.onInit();
    startTimer();
  }

  void onOtpChanged(String code) {
    otpCode.value = code;
    final isValid = code.length == otpCodeLength && intRegex.hasMatch(code);
    enableButton.value = isValid;
  }

  void onSubmitOtp(BuildContext context) {
    if (otpCode.value.length != otpCodeLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please enter the OTP')),
      );
      return;
    }
    verifyOtpCode(context: context);
  }

  void verifyOtpCode({BuildContext? context}) {
    if (!valid.value) {
      print('ganesh what are doing 1: ${valid.value}');
      Get.toNamed(RouteHelper.getSignUpRoute());
    } else {
      print('ganesh what are doing 2: ${valid.value}');

      Get.find<AuthController>().firebaseVerifyPhoneNumber('+91',
          'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiIzIiwianRpIjoiMjAyY2M2NmQ1Zjg0MzkzNjRiNzBhM2I3Njg2ZjMxMmJjM2Q3ODdlYmU0MmU1NDcyZjU2YzQ1MWNjYmM2OWFhZmI4NmViMGNjMzE3NDc1MzYiLCJpYXQiOjE3NTQzMDU4MDkuMjMzMzcyLCJuYmYiOjE3NTQzMDU4MDkuMjMzMzc3LCJleHAiOjE3ODU4NDE4MDkuMjIzOTk3LCJzdWIiOiIxMTUiLCJzY29wZXMiOltdfQ.YHnvFkBihY8QMgHYo1zVhTwwSyaMnjsCEhGPm2JHpIDLHB3RjmBc8DjnfWs4XkkCOIKMunmgkO2kMGRNdYcv3EFd876ppHZ3SmAjHH9WX9a4THGZVUVJqY7XC8DrPxqWfrAYdPhPENMsxtczKMo1DOBomrxTNpwpLXt9ogLHioET3E7yRHZUvHmvRNrHl8F-VZpQQOr4ljnhD5koDfwXuGq7EmGstuwNN3TCIH8SkktDfhgObTosItAs78ARUDTZ2KSfN-dKn2CD-VmWDyCJPCgK60mfeUjySWZqOo_F4n5WjN6yINN0pHZTvQq09RTX3ocDxLlxhkUx4Rl8irwfEKTJvCV24j4IX0VJFm4XCcRanRBZT296HXQ11sDkwd2iY8y6vVqCz0SJwmIs2nWmsNxhFySVb5tikl5nB_iXT4m4TbDbWNVKQWYv_9PtX7Yp_CfgEiexT1GmVKezRyKKgbcfGqSEjDEE7XgEpYB7d3R-CIPbAZNEKJzdVe2fWE4UnY2KRlXB5waa55kiloILihI-ixr7N5s-qQ4UuYu6Qats313s7PqRB_kWOhVScaZ56rcgxYCSLSxFm8F5VWQCMaPW80s67iKqgJ9rj16MiV2rZXY5RPUdjHCamQqHBa0URkVyvivozbnI-iUa7GPmcXthiaZSqFKqGMQDIAcLOmw',
          fromSignUp: true);
    }
    isLoadingButton.value = true;

    Future.delayed(const Duration(seconds: 1), () {
      isLoadingButton.value = false;

      if (otpCode.value == _correctOtp) {
        debugPrint("✅ OTP Verified: ${otpCode.value}");
        Get.snackbar(
          "Verification Successful",
          '✅ OTP Verified: ${otpCode.value}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade50,
          colorText: Colors.black,
        );

        resetOtpState(); // Clear after success
      } else {
        Get.snackbar(
          "Verification Failed",
          '❌ Incorrect OTP: ${otpCode.value}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade50,
          colorText: Colors.black,
        );
      }
    });
  }

  void retry() {
    resetOtpState();
    startTimer();
  }

  void startTimer() {
    seconds.value = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (seconds.value >= 30) {
        timer.cancel();
      } else {
        seconds.value++;
      }
    });
  }

  Future<void> fetchOtpFromApi({required String phone}) async {
    number.value = phone;
    debugPrint('$phone ➡️ Fetching OTP...');
    try {
      isLoadingButton.value = true;

      final url = Uri.parse('https://mandapam.co/api/v1/auth/sendOtp');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'user_type': 'Decorator',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        valid.value = data['phone_exists'];

        if (data['otp'] != null) {
          _correctOtp = data['otp'].toString();
          debugPrint("✅ OTP received from API: $_correctOtp");
        } else {
          Get.snackbar("Error", "OTP not received from server",
              backgroundColor: Colors.red.shade100);
        }
      } else {
        Get.snackbar("Error", "Failed to fetch OTP: ${response.statusCode}",
            backgroundColor: Colors.red.shade100);
      }
    } catch (e) {
      debugPrint("❌ OTP Fetch Error: $e");
      Get.snackbar(
        "Error",
        "Failed to send OTP",
        backgroundColor: Colors.red.shade100,
        colorText: Colors.black,
      );
    } finally {
      isLoadingButton.value = false;
    }
  }

  /// Reset all OTP values
  void resetOtpState() {
    textEditingController.clear();
    otpCode.value = '';
    enableButton.value = false;
    seconds.value = 0;
    _timer?.cancel();
  }

  @override
  void onClose() {
    resetOtpState();
    textEditingController.dispose();
    super.onClose();
  }
}
