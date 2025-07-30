import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/home/controllers/home_controller.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/language/widgets/language_bottom_sheet_widget.dart';
import 'package:sixam_mart/features/media/view_media.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/confirmation_dialog.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/menu/widgets/portion_widget.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      body: GetBuilder<ProfileController>(builder: (profileController) {
        final bool isLoggedIn = AuthHelper.isLoggedIn();

        return Column(children: [
          // HEADER WITH PROFILE + TOP-RIGHT LOGOUT/SIGN IN
          Container(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: Padding(
              padding: const EdgeInsets.only(
                left: Dimensions.paddingSizeExtremeLarge,
                right: Dimensions.paddingSizeExtremeLarge,
                top: 50,
                bottom: Dimensions.paddingSizeExtremeLarge,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start, // <-- ALWAYS TOP-ALIGNED VERTICALLY
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(1),
                    child: ClipOval(
                      child: CustomImage(
                        placeholder: Images.guestIconLight,
                        image:
                        '${(profileController.userInfoModel != null && isLoggedIn) ? profileController.userInfoModel!.imageFullUrl : ''}',
                        height: 70,
                        width: 70,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeDefault),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topLeft, // <-- ENSURE NAME BLOCK STICKS TO TOP
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isLoggedIn
                                ? '${profileController.userInfoModel?.fName} ${profileController.userInfoModel?.lName ?? ''}'
                                : 'guest_user'.tr,
                            style: robotoBold.copyWith(
                              fontSize: Dimensions.fontSizeExtraLarge,
                              color: Theme.of(context).cardColor,
                            ),
                          ),
                          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                          isLoggedIn
                              ? Text(
                            profileController.userInfoModel != null
                                ? DateConverter.containTAndZToUTCFormat(
                              profileController.userInfoModel!.createdAt!,
                            )
                                : '',
                            style: robotoMedium.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              color: Theme.of(context).cardColor,
                            ),
                          )
                              : InkWell(
                            onTap: () async {
                              if (!ResponsiveHelper.isDesktop(context)) {
                                await Get.offAllNamed(
                                    RouteHelper.getSignInRoute(RouteHelper.splash));
                                if (AuthHelper.isLoggedIn()) {
                                  profileController.getUserInfo();
                                }
                              } else {
                                Get.offAllNamed(
                                    RouteHelper.getSignInRoute(RouteHelper.splash));
                              }
                            },
                            child: Text(
                              'login_to_view_all_feature'.tr,
                              style: robotoMedium.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                color: Theme.of(context).cardColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  // TOP-RIGHT LOGOUT / SIGN-IN ACTION (SOLID RED WITH WHITE TEXT & ICON)
                  InkWell(
                    onTap: _onLogoutOrSignInTap,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeSmall,
                        vertical: Dimensions.paddingSizeExtraSmall,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(children: [
                        const Icon(
                          Icons.power_settings_new_sharp,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                        Text(
                          isLoggedIn ? 'logout'.tr : 'sign_in'.tr,
                          style: robotoMedium.copyWith(
                            fontSize: Dimensions.fontSizeLarge,
                            color: Colors.white,
                          ),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // BODY
          Expanded(
            child: SingleChildScrollView(
              child: Ink(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                padding: const EdgeInsets.only(top: Dimensions.paddingSizeLarge),
                child: Column(children: [
                  // ===== GENERAL =====
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        left: Dimensions.paddingSizeDefault,
                        right: Dimensions.paddingSizeDefault,
                      ),
                      child: Text(
                        'general'.tr,
                        style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeDefault,
                          color: Theme.of(context).primaryColor.withOpacity(0.5),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeLarge,
                        vertical: Dimensions.paddingSizeDefault,
                      ),
                      margin: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                      child: Column(children: [
                        PortionWidget(icon: Images.profileIcon, title: 'profile'.tr, route: RouteHelper.getProfileRoute()),
                        PortionWidget(icon: Images.addressIcon, title: 'my_address'.tr, hideDivider: true, route: RouteHelper.getAddressRoute()),
                        // PortionWidget(icon: Images.languageIcon, title: 'language'.tr, hideDivider: true, onTap: ()=> _manageLanguageFunctionality(), route: ''),
                      ]),
                    ),
                  ]),

                  // ===== MEDIA =====
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        left: Dimensions.paddingSizeDefault,
                        right: Dimensions.paddingSizeDefault,
                      ),
                      child: Text(
                        'Media',
                        style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeDefault,
                          color: Theme.of(context).primaryColor.withOpacity(0.5),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeLarge,
                        vertical: Dimensions.paddingSizeDefault,
                      ),
                      margin: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                      child: Column(children: [
                        PortionWidget(
                          icon: Images.viewmediaIcon,
                          title: 'View Media',
                          hideDivider: true,
                          onTap: () async {
                            SharedPreferences prefs = await SharedPreferences.getInstance();
                            // ignore: use_build_context_synchronously
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ViewMediaScreen(sharedPreferences: prefs),
                              ),
                            );
                          },
                          route: '',
                        ),
                      ]),
                    ),
                  ]),

                  // ===== PROMOTIONAL ACTIVITY =====
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        left: Dimensions.paddingSizeDefault,
                        right: Dimensions.paddingSizeDefault,
                      ),
                      child: Text(
                        'promotional_activity'.tr,
                        style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeDefault,
                          color: Theme.of(context).primaryColor.withOpacity(0.5),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeLarge,
                        vertical: Dimensions.paddingSizeDefault,
                      ),
                      margin: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                      child: Column(children: [
                        PortionWidget(
                          icon: Images.couponIcon,
                          title: 'Coupon for purchase',
                          route: RouteHelper.getCouponRoute(),
                          hideDivider: Get.find<SplashController>().configModel!.loyaltyPointStatus == 1 ||
                              Get.find<SplashController>().configModel!.customerWalletStatus == 1
                              ? false
                              : true,
                        ),
                        (Get.find<SplashController>().configModel!.loyaltyPointStatus == 1)
                            ? PortionWidget(
                          icon: Images.pointIcon,
                          title: 'loyalty_points'.tr,
                          route: RouteHelper.getLoyaltyRoute(),
                          hideDivider: Get.find<SplashController>().configModel!.customerWalletStatus == 1 ? false : true,
                          suffix: !isLoggedIn
                              ? null
                              : '${Get.find<ProfileController>().userInfoModel?.loyaltyPoint != null ? Get.find<ProfileController>().userInfoModel!.loyaltyPoint.toString() : '0'} ${'points'.tr}',
                        )
                            : const SizedBox(),
                        (Get.find<SplashController>().configModel!.customerWalletStatus == 1)
                            ? PortionWidget(
                          icon: Images.walletIcon,
                          title: 'my_wallet'.tr,
                          hideDivider: true,
                          route: RouteHelper.getWalletRoute(),
                          suffix: !isLoggedIn
                              ? null
                              : PriceConverter.convertPrice(
                            Get.find<ProfileController>().userInfoModel != null
                                ? Get.find<ProfileController>().userInfoModel!.walletBalance
                                : 0,
                          ),
                        )
                            : const SizedBox(),
                      ]),
                    ),
                  ]),

                  // ===== HELP & SUPPORT =====
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        left: Dimensions.paddingSizeDefault,
                        right: Dimensions.paddingSizeDefault,
                      ),
                      child: Text(
                        'help_and_support'.tr,
                        style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeDefault,
                          color: Theme.of(context).primaryColor.withOpacity(0.5),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeLarge,
                        vertical: Dimensions.paddingSizeDefault,
                      ),
                      margin: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                      child: Column(children: [
                        // PortionWidget(icon: Images.chatIcon, title: 'live_chat'.tr, route: RouteHelper.getConversationRoute()),
                        PortionWidget(icon: Images.helpIcon, title: 'help_and_support'.tr, route: RouteHelper.getSupportRoute()),
                        // PortionWidget(icon: Images.aboutIcon, title: 'about_us'.tr, route: RouteHelper.getHtmlRoute('about-us')),
                        PortionWidget(icon: Images.privacyIcon, title: 'privacy_policy'.tr, route: RouteHelper.getHtmlRoute('privacy-policy')),
                        PortionWidget(icon: Images.termsIcon, title: 'terms_conditions'.tr, route: RouteHelper.getHtmlRoute('terms-and-condition')),
                        (Get.find<SplashController>().configModel!.refundPolicyStatus == 1)
                            ? PortionWidget(
                          icon: Images.refundIcon,
                          title: 'refund_policy'.tr,
                          route: RouteHelper.getHtmlRoute('refund-policy'),
                          hideDivider: (Get.find<SplashController>().configModel!.cancellationPolicyStatus == 1) ||
                              (Get.find<SplashController>().configModel!.shippingPolicyStatus == 1)
                              ? false
                              : true,
                        )
                            : const SizedBox(),
                        (Get.find<SplashController>().configModel!.cancellationPolicyStatus == 1)
                            ? PortionWidget(
                          icon: Images.cancelationIcon,
                          title: 'cancellation_policy'.tr,
                          route: RouteHelper.getHtmlRoute('cancellation-policy'),
                          hideDivider: (Get.find<SplashController>().configModel!.shippingPolicyStatus == 1) ? false : true,
                        )
                            : const SizedBox(),
                        (Get.find<SplashController>().configModel!.shippingPolicyStatus == 1)
                            ? PortionWidget(
                          icon: Images.shippingIcon,
                          title: 'shipping_policy'.tr,
                          hideDivider: true,
                          route: RouteHelper.getHtmlRoute('shipping-policy'),
                        )
                            : const SizedBox(),
                      ]),
                    ),
                  ]),

                  SizedBox(
                    height: ResponsiveHelper.isDesktop(context)
                        ? Dimensions.paddingSizeExtremeLarge
                        : 100,
                  ),
                ]),
              ),
            ),
          ),
        ]);
      }),
    );
  }

  void _onLogoutOrSignInTap() async {
    if (AuthHelper.isLoggedIn()) {
      Get.dialog(
        ConfirmationDialog(
          icon: Images.support,
          description: 'are_you_sure_to_logout'.tr,
          isLogOut: true,
          onYesPressed: () async {
            Get.find<ProfileController>().clearUserInfo();
            Get.find<AuthController>().socialLogout();
            Get.find<CartController>().clearCartList(canRemoveOnline: false);
            Get.find<FavouriteController>().removeFavourite();
            await Get.find<AuthController>().clearSharedData();
            Get.find<HomeController>().forcefullyNullCashBackOffers();
            await Get.toNamed(RouteHelper.getSignInRoute(Get.currentRoute));
          },
        ),
        useSafeArea: false,
      );
    } else {
      Get.find<FavouriteController>().removeFavourite();
      await Get.toNamed(RouteHelper.getSignInRoute(Get.currentRoute));
      if (AuthHelper.isLoggedIn()) {
        await Get.find<FavouriteController>().getFavouriteList();
        Get.find<ProfileController>().getUserInfo();
      }
    }
  }

  _manageLanguageFunctionality() {
    Get.find<LocalizationController>().saveCacheLanguage(null);
    Get.find<LocalizationController>().searchSelectedLanguage();

    showModalBottomSheet(
      isScrollControlled: true,
      useRootNavigator: true,
      context: Get.context!,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(Dimensions.radiusExtraLarge),
          topRight: Radius.circular(Dimensions.radiusExtraLarge),
        ),
      ),
      builder: (context) {
        return ConstrainedBox(
          constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          child: const LanguageBottomSheetWidget(),
        );
      },
    ).then((value) => Get.find<LocalizationController>()
        .setLanguage(Get.find<LocalizationController>().getCacheLocaleFromSharedPref()));
  }
}
