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
}
