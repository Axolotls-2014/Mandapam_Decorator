import 'dart:developer';

import 'package:sixam_mart/features/auth/screens/image_picker.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/common/models/response_model.dart';
import 'package:sixam_mart/features/profile/domain/models/userinfo_model.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/common/widgets/image_picker_widget.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:sixam_mart/common/widgets/my_text_field.dart';
import 'package:sixam_mart/common/widgets/not_logged_in_screen.dart';
import 'package:sixam_mart/common/widgets/web_menu_bar.dart';
import 'package:sixam_mart/features/profile/widgets/profile_bg_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final FocusNode _firstNameFocus = FocusNode();
  final FocusNode _lastNameFocus = FocusNode();
  final FocusNode _firmNameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _descriptionFocus = FocusNode();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _firmNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    initCall();
  }

  void initCall() {
    if (AuthHelper.isLoggedIn() &&
        Get.find<ProfileController>().userInfoModel == null) {
      Get.find<ProfileController>().getUserInfo();
    }
    Get.find<ProfileController>().initData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      appBar: ResponsiveHelper.isDesktop(context) ? const WebMenuBar() : null,
      endDrawer: const MenuDrawer(),
      endDrawerEnableOpenDragGesture: false,
      body: GetBuilder<ProfileController>(builder: (profileController) {
        bool isLoggedIn = AuthHelper.isLoggedIn();
        if (profileController.userInfoModel != null &&
            _phoneController.text.isEmpty) {
          _firstNameController.text =
              profileController.userInfoModel!.fName ?? '';
          _lastNameController.text =
              profileController.userInfoModel!.lName ?? '';
          _phoneController.text = profileController.userInfoModel!.phone ?? '';
          _emailController.text = profileController.userInfoModel!.email ?? '';
          _descriptionController.text =
              profileController.userInfoModel!.aboutUs ?? '';
          _firmNameController.text =
              profileController.userInfoModel!.firmName ?? 'NA';
        }
        log('${profileController.userInfoModel!.firmName}');

        return isLoggedIn
            ? profileController.userInfoModel != null
            ? ProfileBgWidget(
          backButton: true,
          circularImage: ImagePickerWidget(
            image: '${profileController.userInfoModel!.imageFullUrl}',
            onTap: () => profileController.showPickOptions(context),
            rawFile: profileController.rawFile,
          ),
          mainWidget: Column(children: [
            Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: ResponsiveHelper.isDesktop(context)
                      ? EdgeInsets.zero
                      : const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  child: Center(
                      child: FooterView(
                        minHeight: 0.45,
                        child: SizedBox(
                            width: Dimensions.webMaxWidth,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'first_name'.tr,
                                    style: robotoRegular.copyWith(
                                        fontSize: Dimensions.fontSizeSmall,
                                        color:
                                        Theme.of(context).disabledColor),
                                  ),
                                  const SizedBox(
                                      height:
                                      Dimensions.paddingSizeExtraSmall),
                                  MyTextField(
                                    hintText: 'first_name'.tr,
                                    controller: _firstNameController,
                                    focusNode: _firstNameFocus,
                                    nextFocus: _lastNameFocus,
                                    inputType: TextInputType.name,
                                    capitalization:
                                    TextCapitalization.words,
                                    maxLength: 20,
                                  ),
                                  const SizedBox(
                                      height:
                                      Dimensions.paddingSizeExtraSmall),
                                  Text(
                                    'last_name'.tr,
                                    style: robotoRegular.copyWith(
                                        fontSize: Dimensions.fontSizeSmall,
                                        color:
                                        Theme.of(context).disabledColor),
                                  ),
                                  const SizedBox(
                                      height:
                                      Dimensions.paddingSizeExtraSmall),
                                  MyTextField(
                                    hintText: 'last_name'.tr,
                                    controller: _lastNameController,
                                    focusNode: _lastNameFocus,
                                    nextFocus: _emailFocus,
                                    inputType: TextInputType.name,
                                    capitalization:
                                    TextCapitalization.words,
                                    maxLength: 20,
                                  ),
                                  const SizedBox(
                                      height:
                                      Dimensions.paddingSizeExtraSmall),
                                  Text(
                                    'email'.tr,
                                    style: robotoRegular.copyWith(
                                        fontSize: Dimensions.fontSizeSmall,
                                        color:
                                        Theme.of(context).disabledColor),
                                  ),
                                  const SizedBox(
                                      height:
                                      Dimensions.paddingSizeExtraSmall),
                                  MyTextField(
                                    hintText: 'email'.tr,
                                    controller: _emailController,
                                    focusNode: _emailFocus,
                                    inputAction: TextInputAction.done,
                                    inputType: TextInputType.emailAddress,
                                    maxLength: 30,
                                  ),
                                  const SizedBox(
                                      height:
                                      Dimensions.paddingSizeExtraSmall),
                                  Row(children: [
                                    Text(
                                      'phone'.tr,
                                      style: robotoRegular.copyWith(
                                          fontSize:
                                          Dimensions.fontSizeSmall,
                                          color: Theme.of(context)
                                              .disabledColor),
                                    ),
                                    const SizedBox(
                                        width: Dimensions
                                            .paddingSizeExtraSmall),
                                    Text('(${'non_changeable'.tr})',
                                        style: robotoRegular.copyWith(
                                          fontSize: Dimensions
                                              .fontSizeExtraSmall,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error,
                                        )),
                                  ]),
                                  const SizedBox(
                                      height:
                                      Dimensions.paddingSizeExtraSmall),
                                  MyTextField(
                                    hintText: 'phone'.tr,
                                    controller: _phoneController,
                                    focusNode: _phoneFocus,
                                    inputType: TextInputType.phone,
                                    isEnabled: false,
                                    maxLength: 10,
                                  ),
                                  const SizedBox(
                                      height:
                                      Dimensions.paddingSizeExtraSmall),
                                  Text(
                                    'About Us',
                                    style: robotoRegular.copyWith(
                                        fontSize: Dimensions.fontSizeSmall,
                                        color:
                                        Theme.of(context).disabledColor),
                                  ),
                                  const SizedBox(
                                      height:
                                      Dimensions.paddingSizeExtraSmall),
                                  MyTextField(
                                    hintText: 'About Us',
                                    controller: _descriptionController,
                                    focusNode: _descriptionFocus,
                                    inputType: TextInputType.text,
                                    capitalization:
                                    TextCapitalization.sentences,
                                    maxLength: 50,
                                  ),
                                  const SizedBox(
                                      height:
                                      Dimensions.paddingSizeExtraSmall),
                                  Text(
                                    'Firm Name',
                                    style: robotoRegular.copyWith(
                                        fontSize: Dimensions.fontSizeSmall,
                                        color:
                                        Theme.of(context).disabledColor),
                                  ),
                                  const SizedBox(
                                      height:
                                      Dimensions.paddingSizeExtraSmall),
                                  MyTextField(
                                    hintText: 'Firm Name',
                                    controller: _firmNameController,
                                    focusNode: _firmNameFocus,
                                    inputType: TextInputType.name,
                                    capitalization:
                                    TextCapitalization.words,
                                    maxLength: 300,
                                  ),
                                  const SizedBox(
                                      height:
                                      Dimensions.paddingSizeExtraSmall),
                                  Text('Firm Image',
                                      style: robotoRegular.copyWith(
                                          fontSize: Dimensions.fontSizeSmall,
                                          color: Theme.of(context).disabledColor)),
                                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                                  GestureDetector(
                                    onTap: () => profileController.showFirmPickOptions(context),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      margin: const EdgeInsets.all(10),
                                      width: 160,
                                      height: 160,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(12),
                                        color: Colors.grey.shade100,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: profileController.firmRawFile != null
                                            ? Image.memory(
                                          profileController.firmRawFile!,
                                          fit: BoxFit.cover,
                                        )
                                            : (profileController.userInfoModel!.firmImageFullUrl != null
                                            ? Image.network(
                                          profileController.userInfoModel!.firmImageFullUrl!,
                                          fit: BoxFit.cover,
                                        )
                                            : const Icon(Icons.add_a_photo, color: Colors.grey)),
                                      ),
                                    ),
                                  ),

                                ])),
                      )),
                )),
            ResponsiveHelper.isDesktop(context)
                ? const SizedBox.shrink()
                : Padding(
              padding: EdgeInsets.only(
                  bottom: GetPlatform.isIOS
                      ? Dimensions.paddingSizeLarge
                      : 0),
              child: UpdateProfileButton(
                  isLoading: profileController.isLoading,
                  onPressed: () =>
                      _updateProfile(profileController)),
            ),
          ]),
        )
            : const Center(child: CircularProgressIndicator())
            : NotLoggedInScreen(callBack: (value) {
          initCall();
          setState(() {});
        });
      }),
    );
  }

  void _updateProfile(ProfileController profileController) async {
    String firstName = _firstNameController.text.trim();
    String lastName = _lastNameController.text.trim();
    String email = _emailController.text.trim();
    String phoneNumber = _phoneController.text.trim();
    String description = _descriptionController.text.trim();
    String firmName = _firmNameController.text.trim();

    if (firstName.isEmpty) {
      showCustomSnackBar('enter_your_first_name'.tr);
    } else if (lastName.isEmpty) {
      showCustomSnackBar('enter_your_last_name'.tr);
    } else if (email.isEmpty) {
      showCustomSnackBar('enter_email_address'.tr);
    } else if (!GetUtils.isEmail(email)) {
      showCustomSnackBar('enter_a_valid_email_address'.tr);
    } else if (phoneNumber.isEmpty) {
      showCustomSnackBar('enter_phone_number'.tr);
    } else if (phoneNumber.length < 6) {
      showCustomSnackBar('enter_a_valid_phone_number'.tr);
    } else if (description.isEmpty) {
      showCustomSnackBar('Enter a valid description in about us');
    } else {
      UserInfoModel updatedUser = UserInfoModel(
          fName: firstName,
          lName: lastName,
          email: email,
          phone: phoneNumber,
          firmName: firmName,
          aboutUs: description);

      ResponseModel responseModel = await profileController.updateUserInfo(
        updatedUser,
        Get.find<AuthController>().getUserToken(),
      );

      if (responseModel.isSuccess) {
        showCustomSnackBar('profile_updated_successfully'.tr, isError: false);
      } else {
        showCustomSnackBar(responseModel.message);
      }
    }
  }
}

class UpdateProfileButton extends StatelessWidget {
  final bool isLoading;
  final Function onPressed;
  const UpdateProfileButton(
      {super.key, required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return !isLoading
        ? CustomButton(
      onPressed: onPressed,
      margin: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      buttonText: 'update'.tr,
    )
        : const Center(child: CircularProgressIndicator());
  }
}



