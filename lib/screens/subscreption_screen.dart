import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/auth/domain/reposotories/auth_repository_interface.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/screens/subscreption_controller.dart';
import 'package:sixam_mart/screens/subscreption_model.dart';
import 'package:sixam_mart/screens/webview_screen.dart';

class SubscreptionScreen extends StatelessWidget {
  const SubscreptionScreen({super.key});

  void _stopEverythingAndNavigateToSignIn() {
    Get.delete<SubscriptionController>();
    Get.offAllNamed(RouteHelper.getSignInRoute(RouteHelper.splash));
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SubscriptionController());
    final authController = Get.find<AuthController>();
    controller.fetchSubscriptionPackages();
    RxInt selectedIndex = 0.obs;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          _stopEverythingAndNavigateToSignIn();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Subscription',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              _stopEverythingAndNavigateToSignIn();
            },
          ),
          centerTitle: true,
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          } else if (controller.hasError.value) {
            return Center(child: Text(controller.errorMessage.value));
          } else {
            return SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'You are one step away! Choose your business plan',
                    style: TextStyle(color: Colors.grey),
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
                              child: Icon(Icons.check,
                                  color: Colors.white, size: 14),
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
                      "Use the app by purchasing subscription package to unlock all premium features and enjoy uninterrupted access to exclusive services.",
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
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
                        onPressed: () async {
                          if (selectedIndex.value == -1) {
                            Get.snackbar(
                              'Error',
                              'Please select a package',
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                          } else {
                            try {
                              final selectedPackage =
                              controller.packages[selectedIndex.value];
                              final userId = await authController.getUserId();

                              final response =
                              await controller.subscribeToBusinessPlan(
                                packageId: selectedPackage.id,
                                userId: userId,
                              );

                              if (response != null &&
                                  response['redirect_link'] != null) {
                                // final prefs =
                                //     await SharedPreferences.getInstance();
                                // String? token = prefs.getString('token') ?? '';
                                // bool? userExits = prefs.getBool('phone_exists');
                                // final authService =
                                //     Get.find<AuthRepositoryInterface>();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ReusableWebView(
                                      url: response['redirect_link'],
                                      title: 'Payment',
                                    ),
                                  ),
                                );
                                // authService.saveUserToken(token);
                                // authService.updateToken();
                                // authService.clearSharedPrefGuestId();
                                // Get.offNamed(RouteHelper.getInitialRoute(
                                //     fromSplash: true));
                                // SharedPreferences prefs = await SharedPreferences.getInstance();
                                // await prefs.setBool(AppConstants.isOtpVerified, true);
                                // if (userExits == true) {
                                //   authService.saveUserToken(token);
                                //   authService.updateToken();
                                //   authService.clearSharedPrefGuestId();
                                //   Get.offNamed(RouteHelper.getInitialRoute(
                                //       fromSplash: true));
                                // } else {
                                //   Get.offAllNamed(
                                //       RouteHelper.getInitialRoute());
                                // }
                              } else {
                                throw Exception('Invalid response from server');
                              }
                            } catch (e) {
                              Get.snackbar(
                                'Error',
                                'Failed to process subscription: ${e.toString()}',
                                backgroundColor: Colors.red,
                                colorText: Colors.white,
                              );
                            }
                          }
                        },
                        child: const Text('Submit',
                            style:
                            TextStyle(fontSize: 16, color: Colors.white)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }
        }),
      ),
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
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            pkg.packageName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '₹ ${pkg.price}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            '${pkg.validity} days',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
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
