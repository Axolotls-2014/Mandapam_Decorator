import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/screens/subscreption_controller.dart';
import 'package:sixam_mart/screens/subscreption_model.dart';

class SubscreptionScreen extends StatelessWidget {
  const SubscreptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SubscriptionController());

    controller.fetchSubscriptionPackages();
    RxInt selectedIndex = (-1).obs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Registration'),
        leading: const BackButton(),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        } else if (controller.hasError.value) {
          return Center(child: Text(controller.errorMessage.value));
        } else {
          return Column(
            children: [
              const SizedBox(height: 8),
              const Text(
                'You are one step away! Choose your business plan',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: 1.0,
                color: Colors.green,
                backgroundColor: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              const Text(
                'Choose your business plan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            'Subscription Base',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const Positioned(
                        right: 12,
                        top: 12,
                        child: CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.blue,
                          child:
                              Icon(Icons.check, color: Colors.white, size: 14),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Run store by purchasing subscription packages. You will have access the features of in restaurant panel, app and interaction with user according to the subscription packages.",
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 370,
                child: Obx(() {
                  if (controller.packages.length == 1) {
                    final pkg = controller.packages[0];
                    final isSelected = selectedIndex.value == 0;

                    return Center(
                      child: GestureDetector(
                        onTap: () => selectedIndex.value = 0,
                        child: _buildPackageCard(pkg, isSelected),
                      ),
                    );
                  }

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: controller.packages.length,
                    itemBuilder: (context, index) {
                      final pkg = controller.packages[index];
                      final isSelected = selectedIndex.value == index;

                      return GestureDetector(
                        onTap: () => selectedIndex.value = index,
                        child: _buildPackageCard(pkg, isSelected),
                      );
                    },
                  );
                }),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D6EFD),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      if (selectedIndex.value == -1) {
                        Get.snackbar(
                          'Error',
                          'Please select a package',
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                        );
                      } else {
                        final selectedPackage =
                            controller.packages[selectedIndex.value];
                        log("${selectedPackage.price}");
                        Get.find<LocationController>()
                            .navigateToLocationScreen(RouteHelper.signUp);
                      }
                    },
                    child: const Text('Submit',
                        style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
              ),
            ],
          );
        }
      }),
    );
  }

  Widget _buildPackageCard(Package pkg, bool isSelected) {
    return Container(
      width: 220,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D6EFD),
        borderRadius: BorderRadius.circular(16),
        border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              pkg.packageName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              '₹ ${pkg.price}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Center(
            child: Text(
              '${pkg.validity} days',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _featureItem('Max Order (${pkg.maxOrder})'),
          _featureItem('Max Product (${pkg.maxProduct})'),
          if (pkg.pos == 1) _featureItem('POS'),
          if (pkg.mobileApp == 1) _featureItem('Mobile App'),
          if (pkg.chat == 1) _featureItem('Chat'),
          if (pkg.review == 1) _featureItem('Review'),
          if (pkg.selfDelivery == 1) _featureItem('Self Delivery'),
        ],
      ),
    );
  }

  Widget _featureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white),
            ),
          )
        ],
      ),
    );
  }
}
