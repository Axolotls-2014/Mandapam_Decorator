import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:sixam_mart/screens/subscreption_model.dart';

class SubscriptionController extends GetxController {
  @override
  void onInit() {
    fetchSubscriptionPackages();
    super.onInit();
  }

  final isLoading = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;

  RxList<Package> packages = <Package>[].obs;

  Future<void> fetchSubscriptionPackages() async {
    isLoading.value = true;
    hasError.value = false;
    errorMessage.value = '';

    try {
      final response = await http.get(
        Uri.parse('https://mandapam.co/api/v1/decorator/package-view'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        SubscriptionModel data = SubscriptionModel.fromJson(jsonData);
        packages.assignAll(data.packages);
      } else {
        hasError.value = true;
        errorMessage.value =
        'Error ${response.statusCode}: ${response.reasonPhrase}';
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Something went wrong. Please try again.';
      debugPrint('Fetch Subscription Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>?> subscribeToBusinessPlan({
    required packageId,
    required userId,
  }) async {
    try {
      isLoading.value = true;

      final requestBody = {
        'package_id': packageId.toString(),
        'user_id': userId,
        'type': 'payment',
        'payment_type': 'pay_now',
        'payment_method': 'razor_pay',
        'payment_gateway': 'razor_pay',
        'business_plan': 'subscription',
        'callback': 'success',
      };

      // Print request parameters

      print('====> API Request: POST https://mandapam.co/api/v1/decorator/business_plan');
      print('====> Request Parameters: $requestBody');


      final response = await http.post(
        Uri.parse('https://mandapam.co/api/v1/decorator/business_plan'),
        body: requestBody,
      );

      // Print response details

      print('====> API Response Status Code: ${response.statusCode}');
      print('====> API Response Body: ${response.body}');


      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to subscribe: ${response.statusCode}');
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to subscribe: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    } finally {
      isLoading.value = false;
    }
  }

}
