//import 'dart:async';
//import 'dart:io';
import 'dart:convert';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:sixam_mart/common/models/response_model.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
//import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/auth/widgets/condition_check_box_widget.dart';
import 'package:sixam_mart/helper/custom_validator.dart';
//import 'package:sixam_mart/features/auth/widgets/social_login_widget.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/helper/validate_check.dart';
import 'package:sixam_mart/screens/otp_controller.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_text_field.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:flutter/material.dart';
//import 'package:flutter/services.dart';
import 'package:get/get.dart';

class SignInScreen extends StatefulWidget {
  final bool exitFromApp;
  final bool backFromThis;
  final bool fromNotification;
  const SignInScreen(
      {super.key,
      required this.exitFromApp,
      required this.backFromThis,
      this.fromNotification = false});

  @override
  SignInScreenState createState() => SignInScreenState();
}

class SignInScreenState extends State<SignInScreen> {
  final controller = Get.put(OtpController());
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _countryDialCode;
  bool canExit = GetPlatform.isWeb ? true : false;
  GlobalKey<FormState>? _formKeyLogin;

  @override
  void initState() {
    super.initState();
    _formKeyLogin = GlobalKey<FormState>();
    _countryDialCode =
        Get.find<AuthController>().getUserCountryCode().isNotEmpty
            ? Get.find<AuthController>().getUserCountryCode()
            : CountryCode.fromCountryCode(
                    Get.find<SplashController>().configModel!.country!)
                .dialCode;
    _phoneController.text = Get.find<AuthController>().getUserNumber();
    _passwordController.text = Get.find<AuthController>().getUserPassword();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: SafeArea(
        child: Scaffold(
          backgroundColor: ResponsiveHelper.isDesktop(context)
              ? Colors.transparent
              : Theme.of(context).cardColor,
          appBar: (ResponsiveHelper.isDesktop(context)
              ? null
              : !widget.exitFromApp
                  ? AppBar(
                      leading: const SizedBox(),
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                      actions: const [SizedBox()],
                    )
                  : null),
          endDrawer: const MenuDrawer(),
          endDrawerEnableOpenDragGesture: false,
          body: Center(
            child: Container(
              height: ResponsiveHelper.isDesktop(context) ? 690 : null,
              width: context.width > 700 ? 500 : context.width,
              padding: context.width > 700
                  ? const EdgeInsets.symmetric(horizontal: 0)
                  : const EdgeInsets.all(Dimensions.paddingSizeExtremeLarge),
              decoration: context.width > 700
                  ? BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius:
                          BorderRadius.circular(Dimensions.radiusSmall),
                      boxShadow: ResponsiveHelper.isDesktop(context)
                          ? null
                          : const [
                              BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 5,
                                  spreadRadius: 1)
                            ],
                    )
                  : null,
              child: GetBuilder<AuthController>(builder: (authController) {
                return Center(
                  child: SingleChildScrollView(
                    child: Stack(
                      children: [
                        ResponsiveHelper.isDesktop(context)
                            ? Positioned(
                                top: 0,
                                right: 0,
                                child: Align(
                                  alignment: Alignment.topRight,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    onPressed: () => Get.back(),
                                    icon: const Icon(Icons.clear),
                                  ),
                                ),
                              )
                            : const SizedBox(),
                        Form(
                          key: _formKeyLogin,
                          child: Padding(
                            padding: ResponsiveHelper.isDesktop(context)
                                ? const EdgeInsets.all(40)
                                : EdgeInsets.zero,
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(Images.logo, width: 125),
                                  // SizedBox(height: Dimensions.PADDING_SIZE_SMALL),
                                  // Center(child: Text(AppConstants.APP_NAME, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge))),
                                  const SizedBox(
                                      height: Dimensions.paddingSizeExtraLarge),

                                  Align(
                                    alignment:
                                        Get.find<LocalizationController>().isLtr
                                            ? Alignment.topLeft
                                            : Alignment.topRight,
                                    child: Text('sign_in'.tr,
                                        style: robotoBold.copyWith(
                                            fontSize:
                                                Dimensions.fontSizeExtraLarge)),
                                  ),
                                  const SizedBox(
                                      height: Dimensions.paddingSizeLarge),

                                  CustomTextField(
                                    titleText: 'enter_phone_number'.tr,
                                    controller: _phoneController,
                                    focusNode: _phoneFocus,
                                    nextFocus: _passwordFocus,
                                    inputType: TextInputType.phone,
                                    isPhone: true,
                                    onCountryChanged:
                                        (CountryCode countryCode) {
                                      _countryDialCode = countryCode.dialCode;
                                    },
                                    countryDialCode: _countryDialCode ??
                                        Get.find<LocalizationController>()
                                            .locale
                                            .countryCode,
                                    required: true,
                                    labelText: 'phone'.tr,
                                    validator: (value) =>
                                        ValidateCheck.validatePhone(
                                            value, null),
                                    maxLength: 10,
                                  ),
                                  const SizedBox(
                                      height:
                                          Dimensions.paddingSizeExtremeLarge),

                                  // CustomTextField(
                                  //   titleText: 'enter_your_password'.tr,
                                  //   controller: _passwordController,
                                  //   focusNode: _passwordFocus,
                                  //   inputAction: TextInputAction.done,
                                  //   inputType: TextInputType.visiblePassword,
                                  //   prefixIcon: Icons.lock,
                                  //   isPassword: true,
                                  //   onSubmit: (text) => (GetPlatform.isWeb) ? _login(authController, _countryDialCode!) : null,
                                  //   required: true,
                                  //   labelText: 'password'.tr,
                                  //   validator: (value) => ValidateCheck.validateEmptyText(value, null),
                                  //   maxLength: 40,
                                  // ),
                                  // const SizedBox(height: Dimensions.paddingSizeLarge),
                                  // Row(children: [
                                  //   Expanded(
                                  //     child: ListTile(
                                  //       onTap: () =>
                                  //           authController.toggleRememberMe(),
                                  //       leading: Checkbox(
                                  //         visualDensity: const VisualDensity(
                                  //             horizontal: -4, vertical: -4),
                                  //         activeColor:
                                  //             Theme.of(context).primaryColor,
                                  //         value:
                                  //             authController.isActiveRememberMe,
                                  //         onChanged: (bool? isChecked) =>
                                  //             authController.toggleRememberMe(),
                                  //       ),
                                  //       title: Text('remember_me'.tr),
                                  //       contentPadding: EdgeInsets.zero,
                                  //       visualDensity: const VisualDensity(
                                  //           horizontal: 0, vertical: -4),
                                  //       dense: true,
                                  //       horizontalTitleGap: 0,
                                  //     ),
                                  //   ),
                                  //   TextButton(
                                  //     onPressed: () => Get.toNamed(
                                  //         RouteHelper.getForgotPassRoute(
                                  //             false, null)),
                                  //     child: Text('${'forgot_password'.tr}?',
                                  //         style: robotoRegular.copyWith(
                                  //             color: Theme.of(context)
                                  //                 .primaryColor)),
                                  //   ),
                                  // ]
                                  // ),
                                  // const SizedBox(
                                  //     height: Dimensions.paddingSizeLarge),

                                  // const Align(
                                  //   alignment: Alignment.center,
                                  //   child: ConditionCheckBoxWidget(
                                  //       forDeliveryMan: false),
                                  // ),

                                  const SizedBox(
                                      height: Dimensions.paddingSizeExtraLarge),

                                  CustomButton(
                                    height: ResponsiveHelper.isDesktop(context)
                                        ? 45
                                        : null,
                                    width: ResponsiveHelper.isDesktop(context)
                                        ? 180
                                        : null,
                                    buttonText:
                                        ResponsiveHelper.isDesktop(context)
                                            ? 'login'.tr
                                            : 'Get OTP',
                                    onPressed: () {
                                      //  _login(authController, _countryDialCode!);
                                      String number =
                                          _phoneController.text.trim();
                                      String fullPhoneNumber =
                                          "$_countryDialCode$number";

// Basic numeric check (only digits)
                                      final RegExp phoneRegex =
                                          RegExp(r'^[0-9]{10}$');

                                      if (number.isEmpty) {
                                        showCustomSnackBar(
                                            'Please enter your phone number'
                                                .tr);
                                        return;
                                      } else if (!phoneRegex.hasMatch(number)) {
                                        showCustomSnackBar(
                                            'Enter a valid phone number (10 digits)'
                                                .tr);
                                        return;
                                      } else {
                                        verify(authController);
                                        // Get.toNamed(RouteHelper.otpScreen);

                                        // controller.fetchOtpFromApi(
                                        //   phone: fullPhoneNumber,
                                        //   rawPhone: number,
                                        //   countryDialCode:
                                        //       _countryDialCode ?? '+91',
                                        // );
                                      }
                                    },
                                    isLoading: authController.isLoading,
                                    radius: ResponsiveHelper.isDesktop(context)
                                        ? Dimensions.radiusSmall
                                        : Dimensions.radiusDefault,
                                    isBold:
                                        !ResponsiveHelper.isDesktop(context),
                                    fontSize:
                                        ResponsiveHelper.isDesktop(context)
                                            ? Dimensions.fontSizeDefault
                                            : null,
                                  ),
                                  const SizedBox(
                                      height: Dimensions.paddingSizeSmall),

                                  ResponsiveHelper.isDesktop(context)
                                      ? const SizedBox()
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                              // Text('do_not_have_account'.tr, style: robotoRegular.copyWith(color: Theme.of(context).hintColor)),

                                              //   Row(
                                              //     mainAxisAlignment:
                                              //         MainAxisAlignment.center,
                                              //     children: [
                                              //       Material(
                                              //         color: Colors.transparent,
                                              //         child: SizedBox(
                                              //           width: 300,
                                              //           height: 45,
                                              //           child: Ink(
                                              //             decoration:
                                              //                 BoxDecoration(
                                              //               color: Colors.white,
                                              //               borderRadius:
                                              //                   BorderRadius
                                              //                       .circular(12),
                                              //               border: Border.all(
                                              //                 color: Theme.of(
                                              //                         context)
                                              //                     .primaryColor,
                                              //                 width: 1,
                                              //               ),
                                              //             ),
                                              //             child: InkWell(
                                              //               borderRadius:
                                              //                   BorderRadius
                                              //                       .circular(12),
                                              //               onTap: () {
                                              //                 if (ResponsiveHelper
                                              //                     .isDesktop(
                                              //                         context)) {
                                              //                   Get.back();
                                              //                   Get.dialog(
                                              //                       const SignUpScreen());
                                              //                 } else {
                                              //                   Get.toNamed(
                                              //                       RouteHelper
                                              //                           .getSignUpRoute());
                                              //                 }
                                              //               },
                                              //               child: Center(
                                              //                 child: Text(
                                              //                   'sign_up'.tr,
                                              //                   style:
                                              //                       robotoMedium
                                              //                           .copyWith(
                                              //                     color: Theme.of(
                                              //                             context)
                                              //                         .primaryColor,
                                              //                     fontSize: 15,
                                              //                   ),
                                              //                 ),
                                              //               ),
                                              //             ),
                                              //           ),
                                              //         ),
                                              //       ),
                                              //     ],
                                              //   ),
                                            ]),
                                  const SizedBox(
                                      height: Dimensions.paddingSizeSmall),
                                  // const SocialLoginWidget(),
                                  // ResponsiveHelper.isDesktop(context) ? const SizedBox() : const GuestButtonWidget(),
                                  ResponsiveHelper.isDesktop(context)
                                      ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            InkWell(
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                    Dimensions
                                                        .paddingSizeExtraSmall),
                                                child: Text(
                                                  'sign_up'.tr,
                                                  style: robotoMedium.copyWith(
                                                    color: Theme.of(context)
                                                        .primaryColor,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      : const SizedBox(),
                                ]),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  void verify(AuthController authController) async {
    String number = _phoneController.text.trim();
    String fullPhoneNumber = "$_countryDialCode$number";
    PhoneValid phoneValid = await CustomValidator.isPhoneValid(fullPhoneNumber);
    String numberWithCountryCode = phoneValid.phone;

    if (_formKeyLogin!.currentState!.validate()) {
      // Move this if needed
      authController.login(numberWithCountryCode).then((status) async {
        print("API_Response: ${status.message}");
        final controller = Get.put(OtpController());
        controller.status = status;
        controller.authController = authController;
      });
    }
  }
}

void exitsUser(ResponseModel status, AuthController authController,
    String numberWithCountryCode) {
  String number = numberWithCountryCode.substring(3);
  if (status.isSuccess) {
    String? token = status.token == 'N/A' ? '' : status.token;
    int? userId = status.userId;
    bool isPhoneVerified = status.isPhoneVerified;

    print("UserId: $userId");
    print("Token: $token");

    if (!Get.find<SplashController>().configModel!.customerVerification! &&
        isPhoneVerified) {
      Get.find<CartController>().getCartDataOnline();
    }

    if (!authController.isActiveRememberMe) {
      authController.clearUserNumberAndPassword();
    }

    if (Get.find<SplashController>().configModel!.customerVerification! &&
        !isPhoneVerified) {
      if (Get.find<SplashController>().configModel!.firebaseOtpVerification!) {
        Get.find<AuthController>().firebaseVerifyPhoneNumber(
            numberWithCountryCode, token!,
            fromSignUp: true);
      } else {
        String data = base64Encode(utf8.encode(number));
        Get.toNamed(RouteHelper.getVerificationRoute(
            numberWithCountryCode, token!, RouteHelper.signUp, data));
      }
    } else {
      Get.offNamed(RouteHelper.getInitialRoute(fromSplash: true));
    }
  } else {
    showCustomSnackBar(status.message);
  }
}
