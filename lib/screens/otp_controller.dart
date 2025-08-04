import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:sms_autofill/sms_autofill.dart';
import 'package:sixam_mart/helper/route_helper.dart';
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
    // fetchOtpFromApi() removed from here — now manually call with phone/user_type
  }

  void _listenForOtp() async {
    await SmsAutoFill().unregisterListener(); // Avoid duplicate listeners
    listenForCode(); // CodeAutoFill method
  }

  void _onOtpCallBack(String code, bool isAutoFill) {
    otpCode.value = code;
    final isValid = code.length == otpCodeLength && intRegex.hasMatch(code);

    if (isValid && isAutoFill) {
      enableButton.value = false;
      isLoadingButton.value = true;
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
  @override
  void codeUpdated() {
    if (code != null && code!.isNotEmpty) {
      textEditingController.text = code!;
      otpCode.value = code!;

      // ⏳ Add a delay before submitting so the screen is visible
      Future.delayed(const Duration(seconds: 2), () {
        _onOtpCallBack(code!, true);
      });
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
      } else {
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
    //fetchOtpFromApi(phone: phone,);
    _listenForOtp();
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
    print('$phone Ganesh');
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

        if (data['otp'] != null) {
          _correctOtp = data['otp'].toString();
          await _showNotification(_correctOtp);

          code = _correctOtp;
          codeUpdated();
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
