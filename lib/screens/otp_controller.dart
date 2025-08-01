import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:sixam_mart/main.dart';

class OtpController extends GetxController with CodeAutoFill {
  final int otpCodeLength = 4;
  final textEditingController = TextEditingController();

  var otpCode = ''.obs;
  String _correctOtp = '';
  var isLoadingButton = false.obs;
  var enableButton = false.obs;
  var seconds = 0.obs;
  Timer? _timer;

  final RegExp intRegex = RegExp(r'^\d+$');

  @override
  void onInit() {
    super.onInit();
    _listenForOtp();
    startTimer();
    fetchOtpFromApi(); // Simulate API + notification
  }

  void _listenForOtp() async {
    await SmsAutoFill().unregisterListener(); // Avoid duplicate listeners
    listenForCode(); // CodeAutoFill method
  }

  /// Called when SMS or manual input changes
  void _onOtpCallBack(String code, bool isAutoFill) {
    otpCode.value = code;
    final isValid = code.length == otpCodeLength && intRegex.hasMatch(code);

    if (isValid && isAutoFill) {
      enableButton.value = false;
      isLoadingButton.value = true;
      // Trigger verification on auto-fill
      verifyOtpCode();
    } else {
      enableButton.value = isValid;
      isLoadingButton.value = false;
    }
  }

  void onOtpChanged(String code) {
    textEditingController.text = code;
    _onOtpCallBack(code, false);
  }

  @override
  void codeUpdated() {
    if (code != null && code!.isNotEmpty) {
      textEditingController.text = code!;
      _onOtpCallBack(code!, true); // true means autofill
    }
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
    isLoadingButton.value = true;

    Future.delayed(const Duration(seconds: 1), () {
      isLoadingButton.value = false;
      enableButton.value = true;

      if (otpCode.value == _correctOtp) {
        debugPrint("✅ Auto OTP Verified: ${otpCode.value}");
        Get.snackbar(
          "Verification Successful",
          '✅ OTP Verified: ${otpCode.value}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade50,
          colorText: Colors.black,
          duration: const Duration(seconds: 3),
        );
        Get.toNamed(RouteHelper.getSignUpRoute());
        //  List<int> encoded = utf8.encode(password);
        //           String data = base64Encode(encoded);
        // Get.toNamed(RouteHelper.categories);
        //Get.offNamed(RouteHelper.getInitialRoute(fromSplash: true));
        //Get.toNamed(RouteHelper.getVerificationRoute(RouteHelper.signUp, data,''));
      } else {
        // Invalid OTP
        Get.snackbar(
          "Verification Failed",
          '❌ Incorrect OTP: ${otpCode.value}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade50,
          colorText: Colors.black,
          duration: const Duration(seconds: 3),
        );
      }
    });
  }

  void retry() {
    textEditingController.clear();
    otpCode.value = '';
    enableButton.value = false;
    fetchOtpFromApi(); // Simulate resend
    _listenForOtp(); // Re-listen after resend
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

  void fetchOtpFromApi() async {
    await Future.delayed(const Duration(seconds: 2));
    const fakeOtp = '1234';

    _correctOtp = fakeOtp; // store it for verification
    await _showNotification(fakeOtp);

    // Simulate auto-fill
    code = fakeOtp;
    codeUpdated(); // Triggers auto-submit
  }

  Future<void> _showNotification(String otp) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'otp_channel',
      'OTP Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      'Your OTP Code',
      'Use $otp to verify your login',
      notificationDetails,
    );
  }

  @override
  void onClose() {
    textEditingController.dispose();
    _timer?.cancel();
    cancel(); // Cancel CodeAutoFill
    super.onClose();
  }
}
