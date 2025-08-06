import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ReusableWebView extends StatefulWidget {
  final String url;
  final String? title;

  const ReusableWebView({
    super.key,
    required this.url,
    this.title,
  });

  @override
  State<ReusableWebView> createState() => _ReusableWebViewState();
}

class _ReusableWebViewState extends State<ReusableWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (url) {
            setState(() => _isLoading = false);

            // ✅ Check for success URL or keyword
            if (url.contains("success")) {
              Get.find<LocationController>()
                  .navigateToLocationScreen(RouteHelper.signUp);
            }
          },
          onWebResourceError: (error) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Failed to load page.")),
            );
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
