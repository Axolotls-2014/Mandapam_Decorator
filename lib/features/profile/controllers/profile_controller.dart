import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:sixam_mart/features/favourite/controllers/favourite_controller.dart';
import 'package:sixam_mart/features/chat/domain/models/conversation_model.dart';
import 'package:sixam_mart/common/models/response_model.dart';
import 'package:sixam_mart/features/profile/domain/models/userinfo_model.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/profile/domain/services/profile_service_interface.dart';

class ProfileController extends GetxController implements GetxService {
  final ProfileServiceInterface profileServiceInterface;
  ProfileController({required this.profileServiceInterface});

  UserInfoModel? _userInfoModel;
  UserInfoModel? get userInfoModel => _userInfoModel;

  XFile? _pickedFile; // Profile image file
  XFile? get pickedFile => _pickedFile;

  Uint8List? _rawFile; // Profile raw image
  Uint8List? get rawFile => _rawFile;

  XFile? _firmPickedFile; // Firm image file
  XFile? get firmPickedFile => _firmPickedFile;

  Uint8List? _firmRawFile; // Firm raw image
  Uint8List? get firmRawFile => _firmRawFile;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> getUserInfo() async {
    _pickedFile = null;
    _rawFile = null;
    _firmPickedFile = null;
    _firmRawFile = null;
    UserInfoModel? userInfoModel = await profileServiceInterface.getUserInfo();
    if (userInfoModel != null) {
      _userInfoModel = userInfoModel;
    }
    update();
  }

  void setForceFullyUserEmpty() {
    _userInfoModel = null;
  }

  Future<ResponseModel> updateUserInfo(
      UserInfoModel updateUserModel, String token) async {
    _isLoading = true;
    update();
    ResponseModel responseModel = await profileServiceInterface.updateProfile(
        updateUserModel, _pickedFile, _firmPickedFile, token);
    _isLoading = false;
    if (responseModel.isSuccess) {
      Get.back();
      responseModel = ResponseModel(true, responseModel.message);
      _pickedFile = null;
      _rawFile = null;
      _firmPickedFile = null;
      _firmRawFile = null;
      getUserInfo();
    } else {
      responseModel = ResponseModel(false, responseModel.message);
    }
    update();
    return responseModel;
  }

  Future<ResponseModel> changePassword(UserInfoModel updatedUserModel) async {
    _isLoading = true;
    update();
    ResponseModel responseModel =
    await profileServiceInterface.changePassword(updatedUserModel);
    _isLoading = false;
    if (responseModel.isSuccess) {
      responseModel = ResponseModel(true, responseModel.message);
    } else {
      responseModel = ResponseModel(false, responseModel.message);
    }
    update();
    return responseModel;
  }

  void updateUserWithNewData(User? user) {
    _userInfoModel!.userInfo = user;
  }

  void pickImage(ImageSource source) async {
    _pickedFile = await ImagePicker().pickImage(source: source);
    if (_pickedFile != null) {
      _rawFile = await _pickedFile!.readAsBytes();
    }
    update();
  }

  void pickFirmImage(ImageSource source) async {
    _firmPickedFile = await ImagePicker().pickImage(source: source);
    if (_firmPickedFile != null) {
      _firmRawFile = await _firmPickedFile!.readAsBytes();
    }
    update();
  }

  void initData({bool isUpdate = false}) {
    _pickedFile = null;
    _rawFile = null;
    _firmPickedFile = null;
    _firmRawFile = null;
    if (isUpdate) {
      update();
    }
  }

  Future deleteUser() async {
    _isLoading = true;
    update();
    ResponseModel responseModel = await profileServiceInterface.deleteUser();
    _isLoading = false;
    if (responseModel.isSuccess) {
      showCustomSnackBar(responseModel.message, isError: false);
      Get.find<AuthController>().clearSharedData();
      Get.find<FavouriteController>().removeFavourite();
      Get.offAllNamed(RouteHelper.getSignInRoute(RouteHelper.splash));
    } else {
      Get.back();
      showCustomSnackBar(responseModel.message, isError: true);
    }
  }

  void clearUserInfo() {
    _userInfoModel = null;
    update();
  }

  void showPickOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Wrap(
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 40,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              ListTile(
                leading:
                const Icon(Icons.photo_camera, color: Colors.deepPurple),
                title: const Text("Take a Photo"),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.teal),
                title: const Text("Choose from Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void showFirmPickOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Wrap(
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 40,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              ListTile(
                leading:
                const Icon(Icons.photo_camera, color: Colors.deepPurple),
                title: const Text("Take a Photo"),
                onTap: () {
                  Navigator.pop(context);
                  pickFirmImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.teal),
                title: const Text("Choose from Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  pickFirmImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

}

