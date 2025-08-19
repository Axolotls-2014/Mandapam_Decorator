import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/features/auth/domain/reposotories/auth_repository_interface.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/screens/subscreption_screen.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ReusableWebView extends StatefulWidget {
  final String url;
  final String? title;
  final int? storeId;
  final bool? isSubscriptionPayment;
  final int? packageId;

  const ReusableWebView({
    super.key,
    required this.url,
    this.title,
    this.storeId,
    this.isSubscriptionPayment,
    this.packageId,
  });

  @override
  State<ReusableWebView> createState() => _ReusableWebViewState();
}

class _ReusableWebViewState extends State<ReusableWebView> {
  late final WebViewController _controller;
  final authService = Get.find<AuthRepositoryInterface>();
  bool _isLoading = true;
//  bool _canRedirect = true;

  @override
  void dispose() {
    // Clear any pending callbacks to prevent setState after dispose
    _controller.clearCache();
    super.dispose();
  }

  Future<void> _redirect(String url, int? storeId, bool? isSubscriptionPayment,
      int? packageId) async {
    final prefs = await SharedPreferences.getInstance();
    bool? userExits = prefs.getBool('phone_exists');
    String? token = prefs.getString('token') ?? '';
    if (kDebugMode) {
      print('---url---$url');
    }
    // if (!_canRedirect || !mounted) return;

    // Parse URL to extract query parameters
    final uri = Uri.tryParse(url);
    final flag = uri?.queryParameters['flag'];
    final isSuccess = flag == 'success' || url.contains('payment-success');
    final isFailed = flag == 'fail' || url.contains('payment-fail');
    final isCancel = flag == 'cancel' || url.contains('payment-cancel');

    if (isSuccess) {
      if (kDebugMode) {
        print('====> Subscription Payment Status: SUCCESS');
      }

      // _canRedirect = false;
      // if (!mounted) return;
      // await authRepositoryInterface.updateToken();
      //  authRepositoryInterface.clearSharedPrefGuestId();

      Get.snackbar(
        'Payment Successful',
        'Subscription completed successfully.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      // SharedPreferences prefs = await SharedPreferences.getInstance();
      // await prefs.setBool(AppConstants.isOtpVerified, true);
      // Get.offAllNamed(RouteHelper.getInitialRoute());
      if (userExits == true) {
        authService.saveUserToken(token);
        authService.updateToken();
        authService.clearSharedPrefGuestId();
        Get.offNamed(RouteHelper.getInitialRoute(fromSplash: true));
      } else {
        Get.offAllNamed(RouteHelper.getInitialRoute());
      }
    } else if (isFailed) {
      Get.snackbar(
        'Payment Failed',
        'Subscription payment could not be processed.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      Get.to(() => const SubscreptionScreen());
    } else if (isCancel) {
      Get.snackbar(
        'Payment Cancelled',
        'You have cancelled the subscription payment.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      RouteHelper.getSignInRoute(RouteHelper.splash);
    }
  }

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() => _isLoading = true);
            }
          },
          onPageFinished: (url) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
            _redirect(url, widget.storeId, widget.isSubscriptionPayment,
                widget.packageId);
          },
          onNavigationRequest: (request) {
            _redirect(request.url, widget.storeId, widget.isSubscriptionPayment,
                widget.packageId);
            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Failed to load page.")),
              );
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.title != null
          ? AppBar(
        title: Text(widget.title!),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      )
          : null,
      body: SafeArea(
        minimum: const EdgeInsets.only(top: 3),
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
