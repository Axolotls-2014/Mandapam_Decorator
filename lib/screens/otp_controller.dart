import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/auth/domain/reposotories/auth_repository_interface.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:http/http.dart' as http;
import 'package:sixam_mart/screens/subscreption_screen.dart';

class OtpController extends GetxController {
  final int otpCodeLength = 4;
  final textEditingController = TextEditingController();

  // API values
  RxBool phoneExists = false.obs;
  RxString subscriptionStatus = ''.obs;
  RxString numberWithCountryCode = ''.obs;
  RxString token = ''.obs;

  // OTP handling
  RxString otpCode = ''.obs;
  RxString correctOtp = ''.obs;
  final RegExp intRegex = RegExp(r'^\d+$');

  // UI state
  RxBool isLoadingButton = false.obs;
  RxBool enableButton = false.obs;
  RxInt seconds = 0.obs;
  Timer? _timer;

  // Auth ref
  AuthController? _auth;
  AuthController? get auth => _auth;
  set authController(AuthController? value) => _auth = value;

  @override
  void onInit() {
    super.onInit();
    startTimer();
  }

  void resendOtp(String number) {
    debugPrint("Resending OTP to ${numberWithCountryCode.value}");
    textEditingController.clear();
    otpCode.value = '';
    enableButton.value = false;
    // Restart timer
    login(phone: numberWithCountryCode.value);
    retry();
  }

  /// API: Send OTP
  Future<Map<String, dynamic>> login({required String phone}) async {
    retry();
    isLoadingButton.value = true;
    if (phone.isEmpty) {
      return {
        'success': false,
        'statusCode': 400,
        'message': 'Phone number is required.',
      };
    }

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final response = await http.post(
        Uri.parse('https://mandapam.co/api/v1/auth/sendOtp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "phone": phone,
          "user_type": "Decorator",
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint("OTP sent successfully: ${data['otp']}");

        // Save locally
        await prefs.setString("otp", "${data['otp']}");
        await prefs.setBool('phone_exists', data['phone_exists']);
        await prefs.setString(
            'subscription_status', data['subscription_status'] ?? '');
        await prefs.setString('number', phone);
        await prefs.setString('token', data['token']);

        if (data['phone_exists'] == true && data.containsKey("user_id")) {
          await prefs.setString("user_id", data["user_id"].toString());
        }

        // Keep in controller state
        phoneExists.value = data['phone_exists'] ?? false;
        subscriptionStatus.value = data['subscription_status'] ?? '';
        correctOtp.value = data['otp']?.toString() ?? '';
        token.value = data['token'] ?? '';

        return {
          'success': true,
          'statusCode': 200,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': 'Request failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'statusCode': 500,
        'message': 'Something went wrong: $e',
      };
    } finally {
      isLoadingButton.value = false;
    }
  }

  /// OTP changed
  void onOtpChanged(String code) {
    otpCode.value = code;
    enableButton.value =
        code.length == otpCodeLength && intRegex.hasMatch(code);
  }

  /// Submit OTP
  void onSubmitOtp(BuildContext context) {
    if (otpCode.value.length != otpCodeLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please enter the OTP')),
      );
      return;
    }
    verifyOtpCode(context: context);
  }

  /// Verify OTP
  Future<bool> verifyOtpCode({BuildContext? context}) async {
    final prefs = await SharedPreferences.getInstance();

    if (correctOtp.value.isEmpty) {
      correctOtp.value = prefs.getString('otp') ?? '';
      phoneExists.value = prefs.getBool('phone_exists') ?? false;
      subscriptionStatus.value = prefs.getString('subscription_status') ?? '';
    }

    isLoadingButton.value = true;

    if (otpCode.value == correctOtp.value) {
      Get.snackbar(
        "Verification Successful",
        '✅ OTP Verified',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade50,
        colorText: Colors.black,
      );

      // Navigation logic
      if (!phoneExists.value) {
        // New user → sign-up
        Get.offNamed(RouteHelper.getSignUpRoute());
      } else {
        // Existing user → check subscription
        if (subscriptionStatus.value.toLowerCase() == 'active') {
          final authService = Get.find<AuthRepositoryInterface>();
          authService.saveUserToken(token.value);
          authService.updateToken();
          authService.clearSharedPrefGuestId();
          Get.offNamed(RouteHelper.getInitialRoute(fromSplash: true));
        } else {
          Get.to(() => const SubscreptionScreen());
        }
      }

      resetOtpState();
      isLoadingButton.value = false;
      return true;
    } else {
      Get.snackbar(
        "Verification Failed",
        '❌ Incorrect OTP',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade50,
        colorText: Colors.black,
      );
      isLoadingButton.value = false;
      return false;
    }
  }

  /// Retry OTP
  void retry() {
    resetOtpState();
    startTimer();
  }

  /// Start timer
  void startTimer() {
    seconds.value = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (seconds.value <= 0) {
        timer.cancel();
      } else {
        seconds.value--;
      }
    });
  }

  /// Reset OTP state
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
    super.onClose();
  }
}