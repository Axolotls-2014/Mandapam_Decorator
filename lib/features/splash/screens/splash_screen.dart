import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/features/notification/domain/models/notification_body_model.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SplashScreen extends StatefulWidget {
  final NotificationBodyModel? body;
  const SplashScreen({super.key, required this.body});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  final GlobalKey<ScaffoldState> _globalKey = GlobalKey();
  StreamSubscription<List<ConnectivityResult>>? _onConnectivityChanged;
  final String currentAppVersion = '1.0.0';
  String decoratorAppVersion = '';

  @override
  void initState() {
    super.initState();
    _checkAppVersion();
  }

  Future<void> _checkAppVersion() async {
    const String url = 'https://mandapam.co/api/v1/auth/app_version';
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['version'] != null && data['version'].isNotEmpty) {
          for (var version in data['version']) {
            if (version['key'] == 'decorator_app_version') {
              setState(() {
                decoratorAppVersion = version['value'];
                if (decoratorAppVersion == currentAppVersion) {
                  _navigateToHome();
                } else {
                  _showUpdateDialog();
                }
              });
              print('Decorator_App_Version: $decoratorAppVersion');
              break;
            }
          }
        }
      } else {
        print('Failed to fetch app version');
      }
    } catch (e) {
      print("Error fetching app version: $e");
    }
  }

  void _showUpdateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          AlertDialog(
            title: Text('Update Required'),
            content: Text(
                'A new version is detected. Please update to continue.'),
            actions: [
              TextButton(
                child: Text('UPDATE'),
                onPressed: () => _launchUpdateUrl(),
              ),
            ],
          ),
    );
  }

  Future<void> _launchUpdateUrl() async {
    const url = 'https://play.google.com/store/apps/details?id=com.mandapam.decorator&pcampaignid=web_share';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      Get.snackbar('Error', 'Could not launch update URL');
    }
  }

  void _navigateToHome() {
    bool firstTime = true;
    _onConnectivityChanged = Connectivity().onConnectivityChanged.listen((
        List<ConnectivityResult> result) {
      bool isConnected = result.contains(ConnectivityResult.wifi) ||
          result.contains(ConnectivityResult.mobile);

      if (!firstTime) {
        isConnected
            ? ScaffoldMessenger.of(Get.context!).hideCurrentSnackBar()
            : const SizedBox();
        ScaffoldMessenger.of(Get.context!).showSnackBar(SnackBar(
          backgroundColor: isConnected ? Colors.green : Colors.red,
          duration: Duration(seconds: isConnected ? 3 : 6000),
          content: Text(isConnected ? 'connected'.tr : 'No internet connection',
              textAlign: TextAlign.center),
        ));
        if (isConnected) {
          _route();
        }
      }
      firstTime = false;
    });

    Get.find<SplashController>().initSharedData();
    if ((AuthHelper
        .getGuestId()
        .isNotEmpty || AuthHelper.isLoggedIn()) && Get
        .find<SplashController>()
        .cacheModule != null) {
      Get.find<CartController>().getCartDataOnline();
    }
    _route();
  }

  @override
  void dispose() {
    super.dispose();
    _onConnectivityChanged?.cancel();
  }

  void _route() {
    Get.find<SplashController>().getConfigData().then((isSuccess) {
      if (isSuccess) {
        Timer(const Duration(seconds: 1), () async {
          double? minimumVersion = _getMinimumVersion();
          bool isMaintenanceMode = Get
              .find<SplashController>()
              .configModel!
              .maintenanceMode!;
          bool needsUpdate = AppConstants.appVersion < minimumVersion!;

          if (needsUpdate || isMaintenanceMode) {
            Get.offNamed(RouteHelper.getUpdateRoute(needsUpdate));
          } else {
            if (widget.body != null) {
              _forNotificationRouteProcess(widget.body);
            } else {
              _handleUserRouting();
            }
          }
        });
      }
    });
  }

  double? _getMinimumVersion() {
    if (GetPlatform.isAndroid) {
      return Get
          .find<SplashController>()
          .configModel!
          .appMinimumVersionAndroid;
    } else if (GetPlatform.isIOS) {
      return Get
          .find<SplashController>()
          .configModel!
          .appMinimumVersionIos;
    }
    return 0;
  }

  void _forNotificationRouteProcess(NotificationBodyModel? notificationBody) {
    final notificationType = notificationBody?.notificationType;

    final Map<NotificationType, Function> notificationActions = {
      NotificationType.order: () =>
          Get.toNamed(RouteHelper.getOrderDetailsRoute(
              widget.body!.orderId, fromNotification: true)),
      NotificationType.block: () =>
          Get.offNamed(RouteHelper.getSignInRoute(RouteHelper.notification)),
      NotificationType.unblock: () =>
          Get.offNamed(RouteHelper.getSignInRoute(RouteHelper.notification)),
      NotificationType.message: () =>
          Get.toNamed(RouteHelper.getChatRoute(notificationBody: widget.body,
              conversationID: widget.body!.conversationId,
              fromNotification: true)),
      NotificationType.otp: () => null,
      NotificationType.add_fund: () =>
          Get.toNamed(RouteHelper.getWalletRoute(fromNotification: true)),
      NotificationType.referral_earn: () =>
          Get.toNamed(RouteHelper.getWalletRoute(fromNotification: true)),
      NotificationType.cashback: () =>
          Get.toNamed(RouteHelper.getWalletRoute(fromNotification: true)),
      NotificationType.general: () =>
          Get.toNamed(RouteHelper.getNotificationRoute(fromNotification: true)),
    };
    notificationActions[notificationType]?.call();
  }

  Future<void> _forLoggedInUserRouteProcess() async {
    Get.find<AuthController>().updateToken();
    if (AddressHelper.getUserAddressFromSharedPref() != null) {
      if (Get
          .find<SplashController>()
          .module != null) {
        await Get.find<FavouriteController>().getFavouriteList();
      }
      Get.offNamed(RouteHelper.getInitialRoute(fromSplash: true));
    } else {
      Get.find<LocationController>().navigateToLocationScreen(
          'splash', offNamed: true);
    }
  }

  // void _newlyRegisteredRouteProcess() {
  //   if(AppConstants.languages.length > 1) {
  //     Get.offNamed(RouteHelper.getLanguageRoute('splash'));
  //   } else {
  //     Get.offNamed(RouteHelper.getOnBoardingRoute());
  //   }
  // }

  void _newlyRegisteredRouteProcess() {
    int staticIndex = 0;
    LocalizationController localizationController = Get.find<
        LocalizationController>();
    if (localizationController.languages.isNotEmpty) {
      localizationController.setLanguage(Locale(
        AppConstants.languages[staticIndex].languageCode!,
        AppConstants.languages[staticIndex].countryCode,
      ));
    }
    Get.offNamed(RouteHelper.getOnBoardingRoute());
  }

  Future<void> _handleUserRouting() async {
    if (AuthHelper.isLoggedIn()) {
      _forLoggedInUserRouteProcess();
    } else if (Get.find<SplashController>().showIntro() == true) {
      _newlyRegisteredRouteProcess();
    } else {
      _newlyRegisteredRouteProcess();
    }
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     key: _globalKey,
  //     body: Center(
  //       child: Padding(
  //         padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
  //         child: Column(mainAxisSize: MainAxisSize.min, children: [
  //           Image.asset(Images.logo, width: 300),
  //           const SizedBox(height: Dimensions.paddingSizeSmall),
  //           Text('suffix_name'.tr, style: robotoMedium,
  //               textAlign: TextAlign.center),
  //         ]),
  //       ),  ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _globalKey,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(Images.logo, width: 300),
              const SizedBox(height: 4.0),
              Column(
                children: [
                  Text(
                    'MANDAPAM',
                    style: robotoBold.copyWith(
                      fontSize: 30,
                      color: Theme.of(context).primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'DECORATOR',
                    style: robotoBold.copyWith(
                      fontSize: 15,
                      color: Theme.of(context).primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

}
