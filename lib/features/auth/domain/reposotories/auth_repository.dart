import 'dart:convert';
import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/common/models/response_model.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/auth/domain/models/signup_body_model.dart';
import 'package:sixam_mart/features/auth/domain/models/social_log_in_body.dart';
import 'package:sixam_mart/features/auth/domain/reposotories/auth_repository_interface.dart';
import 'package:sixam_mart/features/auth/screens/image_picker.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/module_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/screens/otp_controller.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:path/path.dart';

class AuthRepository implements AuthRepositoryInterface {
  final ApiClient apiClient;
  final SharedPreferences sharedPreferences;
  AuthRepository({required this.sharedPreferences, required this.apiClient});

  @override
  bool isSharedPrefNotificationActive() {
    return sharedPreferences.getBool(AppConstants.notification) ?? true;
  }

  @override
  Future<ResponseModel> registration(SignUpBodyModel signUpBody) async {
    final controller = Get.put(SubmitAssignmentController());
    final uri = Uri.parse('https://mandapam.co/api/v1/auth/decorator-sign-up');

    final request = http.MultipartRequest('POST', uri);

    // Add text fields
    request.fields['phone'] = signUpBody.phone ?? '';
    request.fields['f_name'] = signUpBody.fName ?? '';
    request.fields['l_name'] = signUpBody.lName ?? '';
    request.fields['email'] = signUpBody.email ?? '';
    request.fields['UserType'] = signUpBody.UserType ?? '';
    request.fields['firm_name'] = signUpBody.firmName ?? '';
    request.fields['latitude'] = signUpBody.latitude ?? '';
    request.fields['longitude'] = signUpBody.longitude ?? '';
    request.fields['zone_id'] = signUpBody.zoneId ?? '';
    request.fields['module_id'] = signUpBody.moduleId ?? '';
    request.fields['address'] = signUpBody.address ?? '';
    request.fields['ref_by'] = signUpBody.refCode ?? '';

    // Add image if provided
    if (controller.file.value != null) {
      final file = controller.file.value;
      request.files.add(await http.MultipartFile.fromPath(
        'firm_image',
        file!.path,
        filename: basename(file.path),
      ));
    }

    try {
      // Actually send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      log('🔁 Status: ${response.statusCode}');
      log('📥 Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // Save user_id if returned
        if (responseData.containsKey("user_id")) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString("user_id", responseData["user_id"].toString());
        }

        return ResponseModel(true, responseData["token"]);
      } else {
        final errorMessage =
            jsonDecode(response.body)['message'] ?? 'Something went wrong';
        return ResponseModel(false, errorMessage);
      }
    } catch (e) {
      log('❌ Registration failed: $e');
      return ResponseModel(false, 'Registration failed: $e');
    }
  }

  @override
  Future<Response> login({
    String? phone,
  }) async {
    Map<String, String> data = {
      "phone": phone!,
      "user_type": "Decorator",
    };

    Response response = await apiClient.postData('/api/v1/auth/sendOtp', data,
        handleError: false);
    log('Ganesh code status: ${response.status}');
    if (response.body['phone_exists'] == false) {
      Get.offAllNamed(RouteHelper.otpScreen);
    } else {
      Get.toNamed(RouteHelper.otpScreen);
    }

    if (response.statusCode == 200 && response.body != null) {
      final controller = Get.put(OtpController());
      Map<String, dynamic> responseData = response.body;
      controller.correctOtp.value = "${responseData['otp']}";
      controller.userExit.value = responseData['phone_exists'];
      controller.numberWithCountryCode.value = phone;
      debugPrint("✅ OTP API Response:");
      debugPrint("👉 Message: ${responseData['message']}");
      debugPrint("👉 Phone Exists: ${responseData['phone_exists']}");
      debugPrint("👉 OTP: ${responseData['otp']}");
      debugPrint("👉 User ID: ${responseData['user_id']}");
      debugPrint("👉 Token: ${responseData['token']}");
      if (responseData.containsKey("user_id")) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("user_id", responseData["user_id"].toString());
      }
    }
    return response;
  }

  Future<String?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("user_id");
  }

  @override
  Future<ResponseModel> guestLogin() async {
    ResponseModel responseModel;
    String? deviceToken = await saveDeviceToken();
    Response response = await apiClient
        .postData(AppConstants.guestLoginUri, {'fcm_token': deviceToken});
    if (response.statusCode == 200) {
      await saveSharedPrefGuestId(response.body['guest_id'].toString());
      responseModel = ResponseModel(true, '${response.body['guest_id']}');
    } else {
      responseModel = ResponseModel(false, response.statusText);
    }
    return responseModel;
  }

  @override
  Future<Response> loginWithSocialMedia(
      SocialLogInBody socialLogInBody, int timeout) async {
    return await apiClient.postData(
        AppConstants.socialLoginUri, socialLogInBody.toJson(),
        timeout: timeout);
  }

  @override
  Future<Response> registerWithSocialMedia(
      SocialLogInBody socialLogInBody) async {
    return await apiClient.postData(
        AppConstants.socialRegisterUri, socialLogInBody.toJson());
  }

  @override
  Future<bool> saveUserToken(String token) async {
    apiClient.token = token;
    if (sharedPreferences.getString(AppConstants.userAddress) != null) {
      AddressModel? addressModel = AddressModel.fromJson(
          jsonDecode(sharedPreferences.getString(AppConstants.userAddress)!));
      apiClient.updateHeader(
        token,
        addressModel.zoneIds,
        addressModel.areaIds,
        sharedPreferences.getString(AppConstants.languageCode),
        ModuleHelper.getModule()?.id,
        addressModel.latitude,
        addressModel.longitude,
      );
    } else {
      apiClient.updateHeader(
          token,
          null,
          null,
          sharedPreferences.getString(AppConstants.languageCode),
          ModuleHelper.getModule()?.id,
          null,
          null);
    }
    return await sharedPreferences.setString(AppConstants.token, token);
  }

  @override
  Future<Response> updateToken({String notificationDeviceToken = ''}) async {
    String? deviceToken;
    if (notificationDeviceToken.isEmpty) {
      if (GetPlatform.isIOS && !GetPlatform.isWeb) {
        FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
            alert: true, badge: true, sound: true);
        NotificationSettings settings =
            await FirebaseMessaging.instance.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );
        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          deviceToken = await saveDeviceToken();
        }
      } else {
        deviceToken = await saveDeviceToken();
      }
      if (!GetPlatform.isWeb) {
        FirebaseMessaging.instance.subscribeToTopic(AppConstants.topic);
        FirebaseMessaging.instance.subscribeToTopic(
            'zone_${AddressHelper.getUserAddressFromSharedPref()!.zoneId}_customer');
      }
    }
    return await apiClient.postData(
        AppConstants.tokenUri,
        {
          "_method": "put",
          "cm_firebase_token": notificationDeviceToken.isNotEmpty
              ? notificationDeviceToken
              : deviceToken
        },
        handleError: false);
  }

  @override
  Future<String?> saveDeviceToken() async {
    String? deviceToken = '@';
    if (!GetPlatform.isWeb) {
      try {
        deviceToken = (await FirebaseMessaging.instance.getToken())!;
      } catch (_) {}
    }
    if (deviceToken != null) {
      if (kDebugMode) {
        print('--------Device Token---------- $deviceToken');
      }
    }
    return deviceToken;
  }

  @override
  bool isLoggedIn() {
    // bool hasToken = sharedPreferences.containsKey(AppConstants.token);
    bool otpVerified = sharedPreferences.getBool(AppConstants.isOtpVerified) ?? false;
    return otpVerified;
  }

  @override
  Future<bool> saveSharedPrefGuestId(String id) async {
    return await sharedPreferences.setString(AppConstants.guestId, id);
  }

  @override
  String getSharedPrefGuestId() {
    return sharedPreferences.getString(AppConstants.guestId) ?? "";
  }

  @override
  Future<bool> clearSharedPrefGuestId() async {
    return await sharedPreferences.remove(AppConstants.guestId);
  }

  @override
  bool isGuestLoggedIn() {
    return sharedPreferences.containsKey(AppConstants.guestId);
  }

  @override
  Future<bool> clearSharedAddress() async {
    await sharedPreferences.remove(AppConstants.userAddress);
    return true;
  }

  @override
  Future<bool> clearSharedData({bool removeToken = true}) async {
    if (!GetPlatform.isWeb) {
      FirebaseMessaging.instance.unsubscribeFromTopic(AppConstants.topic);
      FirebaseMessaging.instance.unsubscribeFromTopic(
          'zone_${AddressHelper.getUserAddressFromSharedPref()!.zoneId}_customer');
      if (removeToken) {
        apiClient.postData(
            AppConstants.tokenUri, {"_method": "put", "cm_firebase_token": '@'},
            handleError: false);
      }
    }
    sharedPreferences.remove(AppConstants.token);
    sharedPreferences.remove(AppConstants.guestId);
    sharedPreferences.setStringList(AppConstants.cartList, []);
    // sharedPreferences.remove(AppConstants.userAddress);
    apiClient.token = null;
    // apiClient.updateHeader(null, null, null, null, null, null, null);
    await guestLogin();
    if (sharedPreferences.getString(AppConstants.userAddress) != null) {
      AddressModel? addressModel = AddressModel.fromJson(
          jsonDecode(sharedPreferences.getString(AppConstants.userAddress)!));
      apiClient.updateHeader(
        null,
        addressModel.zoneIds,
        null,
        sharedPreferences.getString(AppConstants.languageCode),
        null,
        addressModel.latitude,
        addressModel.longitude,
      );
    }
    return true;
  }

  @override
  Future<void> saveUserNumberAndPassword(
      String number, String password, String countryCode) async {
    try {
      await sharedPreferences.setString(AppConstants.userPassword, password);
      await sharedPreferences.setString(AppConstants.userNumber, number);
      await sharedPreferences.setString(
          AppConstants.userCountryCode, countryCode);
    } catch (e) {
      rethrow;
    }
  }

  @override
  String getUserNumber() {
    return sharedPreferences.getString(AppConstants.userNumber) ?? "";
  }

  @override
  String getUserCountryCode() {
    return sharedPreferences.getString(AppConstants.userCountryCode) ?? "";
  }

  @override
  String getUserPassword() {
    return sharedPreferences.getString(AppConstants.userPassword) ?? "";
  }

  @override
  Future<bool> clearUserNumberAndPassword() async {
    await sharedPreferences.remove(AppConstants.userPassword);
    await sharedPreferences.remove(AppConstants.userCountryCode);
    return await sharedPreferences.remove(AppConstants.userNumber);
  }

  @override
  String getUserToken() {
    return sharedPreferences.getString(AppConstants.token) ?? "";
  }

  @override
  Future<Response> updateZone() async {
    return await apiClient.getData(AppConstants.updateZoneUri);
  }

  @override
  Future<bool> saveGuestContactNumber(String number) async {
    return await sharedPreferences.setString(AppConstants.guestNumber, number);
  }

  @override
  String getGuestContactNumber() {
    return sharedPreferences.getString(AppConstants.guestNumber) ?? "";
  }

  ///Todo:
  @override
  Future<bool> saveDmTipIndex(String index) async {
    return await sharedPreferences.setString(AppConstants.dmTipIndex, index);
  }

  @override
  String getDmTipIndex() {
    return sharedPreferences.getString(AppConstants.dmTipIndex) ?? "";
  }

  @override
  Future<bool> saveEarningPoint(String point) async {
    return await sharedPreferences.setString(AppConstants.earnPoint, point);
  }

  @override
  String getEarningPint() {
    return sharedPreferences.getString(AppConstants.earnPoint) ?? "";
  }

  @override
  Future<void> setNotificationActive(bool isActive) async {
    if (isActive) {
      await updateToken();
    } else {
      if (!GetPlatform.isWeb) {
        await updateToken(notificationDeviceToken: '@');
        FirebaseMessaging.instance.unsubscribeFromTopic(AppConstants.topic);
        if (isLoggedIn()) {
          FirebaseMessaging.instance.unsubscribeFromTopic(
              'zone_${AddressHelper.getUserAddressFromSharedPref()!.zoneId}_customer');
        }
      }
    }
    sharedPreferences.setBool(AppConstants.notification, isActive);
  }

  @override
  Future add(value) {
    throw UnimplementedError();
  }

  @override
  Future delete(int? id) {
    throw UnimplementedError();
  }

  @override
  Future get(String? id) {
    throw UnimplementedError();
  }

  @override
  Future getList({int? offset}) {
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    throw UnimplementedError();
  }
}
