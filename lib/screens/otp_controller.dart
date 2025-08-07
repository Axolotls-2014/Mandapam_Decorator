import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/models/response_model.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/auth/screens/sign_in_screen.dart';
import 'package:sixam_mart/helper/route_helper.dart';

class OtpController extends GetxController {
  final int otpCodeLength = 4;
  final textEditingController = TextEditingController();

  RxBool userExit = false.obs;
  var numberWithCountryCode = ''.obs;

  ResponseModel? _status;
  ResponseModel? get statusValue => _status;
  set status(ResponseModel? value) => _status = value;

  AuthController? _auth;
  AuthController? get auth => _auth;
  set authController(AuthController? value) => _auth = value;

  var otpCode = ''.obs;
  RxString correctOtp = ''.obs;

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

  void verifyOtpCode({BuildContext? context, bool? valid}) {
    isLoadingButton.value = true;
    Future.delayed(const Duration(seconds: 1), () {
      isLoadingButton.value = false;
      debugPrint(
          'Entered OTP: ${otpCode.value}, Correct OTP: ${correctOtp.value}');

      if (otpCode.value == correctOtp.value) {
        debugPrint("✅ OTP Verified: ${otpCode.value}");
        Get.snackbar(
          "Verification Successful",
          '✅ OTP Verified: ${otpCode.value}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade50,
          colorText: Colors.black,
        );
        if (userExit == true) {
          exitsUser(statusValue!, auth!, numberWithCountryCode.value);
        } else {
          Get.toNamed(RouteHelper.getSignUpRoute());
        }
        resetOtpState();

        // Navigate or handle post-verification logic
        // Get.offNamed(RouteHelper.getNextRoute());
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
    //  textEditingController.dispose();
    super.onClose();
  }
}
