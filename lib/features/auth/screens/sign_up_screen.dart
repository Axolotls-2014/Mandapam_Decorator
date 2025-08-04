import 'dart:convert';
import 'dart:io';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/auth/screens/image_picker.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/auth/domain/models/signup_body_model.dart';
import 'package:sixam_mart/features/auth/screens/sign_in_screen.dart';
import 'package:sixam_mart/features/auth/widgets/condition_check_box_widget.dart';
import 'package:sixam_mart/helper/custom_validator.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/helper/validate_check.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/custom_text_field.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';

class SignUpScreen extends StatefulWidget {
  final bool exitFromApp;
  const SignUpScreen({super.key, this.exitFromApp = false});

  @override
  SignUpScreenState createState() => SignUpScreenState();
}

class SignUpScreenState extends State<SignUpScreen> {
  final controller = Get.put(SubmitAssignmentController());

  final String apiKey = "AIzaSyB3bs7otrlVeqcKYo3zw2Fn-luzy1Chp14";

  final FocusNode _firstNameFocus = FocusNode();
  final FocusNode _lastNameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _firmNameFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();
  final FocusNode _referCodeFocus = FocusNode();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _firmNameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _referCodeController = TextEditingController();
  final _addressController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  String? _countryDialCode;

  final _searchController = TextEditingController();
  final _formKeySignUp = GlobalKey<FormState>();
  List<String> _placeSuggestions = [];
  LatLng? _currentPosition;
  GoogleMapController? _mapController;
  LatLng? _selectedPosition;
  bool _showLocationText = false;

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _countryDialCode = CountryCode.fromCountryCode(
            Get.find<SplashController>().configModel!.country!)
        .dialCode;
  }

  Future<void> _updateAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String address =
            "${place.name}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
        setState(() {
          _addressController.text = address;
          _latitudeController.text = position.latitude.toString();
          _longitudeController.text = position.longitude.toString();
        });
      }
    } catch (e) {
      print("Error getting address: $e");
    }
  }

  Future<void> _convertAddressToLatLng(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final location = locations.first;
        LatLng newPosition = LatLng(location.latitude, location.longitude);

        String fetchedAddress = await _getAddressFromLatLng(newPosition);

        setState(() {
          _selectedPosition = newPosition;
          _placeSuggestions.clear();
          _addressController.text = fetchedAddress;
          _latitudeController.text = location.latitude.toString();
          _longitudeController.text = location.longitude.toString();
        });

        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(newPosition, 15),
          );
        }
      }
    } catch (e) {
      print("Error converting address to LatLng: $e");

      setState(() {
        _addressController.text = _searchController.text;
      });
    }
  }

  Future<void> _getPlaceSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() {
        _placeSuggestions.clear();
      });
      return;
    }

    final String request =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$apiKey&components=country:${Get.find<SplashController>().configModel!.country!}&types=establishment|geocode&language=${Get.find<LocalizationController>().locale.languageCode}";

    final response = await http.get(Uri.parse(request));
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> predictions = data['predictions'];
      setState(() {
        _placeSuggestions = predictions.map((p) {
          String mainText = p['structured_formatting']?['main_text'] ?? '';
          String secondaryText =
              p['structured_formatting']?['secondary_text'] ?? '';
          return "$mainText, $secondaryText";
        }).toList();
      });
    }
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _showLocationText = true;
      });
      await Geolocator.requestPermission();
      return;
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      setState(() {
        _showLocationText = true;
      });
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _showLocationText = true;
      });
      return;
    }

    setState(() {
      _showLocationText = false;
    });

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _selectedPosition = _currentPosition;
    });

    _updateAddressFromLatLng(_selectedPosition!);

    if (_mapController != null) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_selectedPosition!, 15),
        );
      });
    }
  }

  Future<String> _getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return "${place.street ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}, ${place.country ?? ''}";
      }
    } catch (e) {
      print("Error getting address: $e");
    }
    return "Selected Location (${position.latitude}, ${position.longitude})"; // Fallback
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: (ResponsiveHelper.isDesktop(context)
            ? null
            : !widget.exitFromApp
                ? AppBar(
                    leading: IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(Icons.arrow_back_ios_rounded,
                          color: Theme.of(context).textTheme.bodyLarge!.color),
                    ),
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    actions: const [SizedBox()],
                  )
                : null),
        backgroundColor: ResponsiveHelper.isDesktop(context)
            ? Colors.transparent
            : Theme.of(context).cardColor,
        endDrawer: const MenuDrawer(),
        endDrawerEnableOpenDragGesture: false,
        body: Center(
          child: Container(
            width: context.width > 700 ? 700 : context.width,
            padding: context.width > 700
                ? const EdgeInsets.all(0)
                : const EdgeInsets.all(Dimensions.paddingSizeLarge),
            margin: context.width > 700
                ? const EdgeInsets.all(Dimensions.paddingSizeDefault)
                : null,
            decoration: context.width > 700
                ? BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                  )
                : null,
            child: GetBuilder<AuthController>(builder: (authController) {
              return SingleChildScrollView(
                child: Stack(
                  children: [
                    ResponsiveHelper.isDesktop(context)
                        ? Positioned(
                            top: 0,
                            right: 0,
                            child: Align(
                              alignment: Alignment.topRight,
                              child: IconButton(
                                onPressed: () => Get.back(),
                                icon: const Icon(Icons.clear),
                              ),
                            ),
                          )
                        : const SizedBox(),
                    Form(
                      key: _formKeySignUp,
                      child: Padding(
                        padding: ResponsiveHelper.isDesktop(context)
                            ? const EdgeInsets.all(40)
                            : EdgeInsets.zero,
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Image.asset(Images.logo, width: 125),
                              const SizedBox(
                                  height: Dimensions.paddingSizeExtraLarge),
                              Align(
                                alignment: Alignment.topLeft,
                                child: Text('sign_up'.tr,
                                    style: robotoBold.copyWith(
                                        fontSize:
                                            Dimensions.fontSizeExtraLarge)),
                              ),
                              const SizedBox(
                                  height: Dimensions.paddingSizeDefault),
                              Row(children: [
                                Expanded(
                                  child: CustomTextField(
                                    labelText: 'first_name'.tr,
                                    titleText: 'ex_jhon'.tr,
                                    controller: _firstNameController,
                                    focusNode: _firstNameFocus,
                                    nextFocus: _lastNameFocus,
                                    inputType: TextInputType.name,
                                    capitalization: TextCapitalization.words,
                                    prefixIcon: Icons.person,
                                    required: true,
                                    labelTextSize: Dimensions.fontSizeDefault,
                                    validator: (value) =>
                                        ValidateCheck.validateEmptyText(
                                            value, null),
                                    maxLength: 20,
                                  ),
                                ),
                                const SizedBox(
                                    width: Dimensions.paddingSizeSmall),
                                Expanded(
                                  child: CustomTextField(
                                    labelText: 'last_name'.tr,
                                    titleText: 'ex_doe'.tr,
                                    controller: _lastNameController,
                                    focusNode: _lastNameFocus,
                                    nextFocus:
                                        ResponsiveHelper.isDesktop(context)
                                            ? _emailFocus
                                            : _phoneFocus,
                                    inputType: TextInputType.name,
                                    capitalization: TextCapitalization.words,
                                    prefixIcon: Icons.person,
                                    required: true,
                                    labelTextSize: Dimensions.fontSizeDefault,
                                    validator: (value) =>
                                        ValidateCheck.validateEmptyText(
                                            value, null),
                                    maxLength: 20,
                                  ),
                                )
                              ]),
                              const SizedBox(
                                  height: Dimensions.paddingSizeExtraLarge),
                              Row(children: [
                                ResponsiveHelper.isDesktop(context)
                                    ? Expanded(
                                        child: CustomTextField(
                                          labelText: 'email'.tr,
                                          titleText: 'enter_email'.tr,
                                          controller: _emailController,
                                          focusNode: _emailFocus,
                                          nextFocus: ResponsiveHelper.isDesktop(
                                                  context)
                                              ? _phoneFocus
                                              : _firmNameFocus,
                                          inputType: TextInputType.emailAddress,
                                          prefixImage: Images.mail,
                                          required: true,
                                          validator: (value) =>
                                              ValidateCheck.validateEmail(
                                                  value),
                                          maxLength: 30,
                                        ),
                                      )
                                    : const SizedBox(),
                                SizedBox(
                                    width: ResponsiveHelper.isDesktop(context)
                                        ? Dimensions.paddingSizeSmall
                                        : 0),
                                Expanded(
                                  child: CustomTextField(
                                    labelText: 'phone'.tr,
                                    titleText: 'enter_phone_number'.tr,
                                    controller: _phoneController,
                                    focusNode: _phoneFocus,
                                    nextFocus:
                                        ResponsiveHelper.isDesktop(context)
                                            ? _firmNameFocus
                                            : _emailFocus,
                                    inputType: TextInputType.phone,
                                    isPhone: true,
                                    onCountryChanged:
                                        (CountryCode countryCode) {
                                      _countryDialCode = countryCode.dialCode;
                                    },
                                    countryDialCode: _countryDialCode != null
                                        ? CountryCode.fromCountryCode(
                                                Get.find<SplashController>()
                                                    .configModel!
                                                    .country!)
                                            .code
                                        : Get.find<LocalizationController>()
                                            .locale
                                            .countryCode,
                                    required: true,
                                    validator: (value) =>
                                        ValidateCheck.validatePhone(
                                            value, null),
                                    maxLength: 10,
                                  ),
                                ),
                              ]),
                              const SizedBox(
                                  height: Dimensions.paddingSizeExtraLarge),
                              !ResponsiveHelper.isDesktop(context)
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CustomTextField(
                                          labelText: 'email'.tr,
                                          titleText: 'enter_email'.tr,
                                          controller: _emailController,
                                          focusNode: _emailFocus,
                                          nextFocus: _firmNameFocus,
                                          inputType: TextInputType.emailAddress,
                                          prefixIcon: Icons.mail,
                                          required: true,
                                          validator: (value) =>
                                              ValidateCheck.validateEmptyText(
                                                  value, null),
                                          maxLength: 30,
                                        ),
                                        // const SizedBox(height: 4),
                                        // const Text(
                                        //   "This email ID will be used to send OTPs for password recovery.",
                                        //   style: TextStyle(fontSize: 11, color: Colors.red),
                                        // ),
                                      ],
                                    )
                                  : const SizedBox(),
                              SizedBox(
                                  height: !ResponsiveHelper.isDesktop(context)
                                      ? Dimensions.paddingSizeLarge
                                      : 0),
                              Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(children: [
                                        CustomTextField(
                                          labelText: 'Firm Name',
                                          titleText: 'Firm Name',
                                          controller: _firmNameController,
                                          focusNode: _firmNameFocus,
                                          // nextFocus: _confirmPasswordFocus,
                                          // inputType:
                                          //     TextInputType.visiblePassword,
                                          prefixIcon: Icons.shop,
                                          //isPassword: true,
                                          required: true,
                                          validator: (value) =>
                                              ValidateCheck.validateEmptyText(
                                                  value, null),
                                          maxLength: 12,
                                        ),
                                      ]),
                                    ),
                                    SizedBox(
                                        width:
                                            ResponsiveHelper.isDesktop(context)
                                                ? Dimensions.paddingSizeSmall
                                                : 0),
                                    // ResponsiveHelper.isDesktop(context)
                                    //     ? Expanded(
                                    //         child: CustomTextField(
                                    //         labelText: 'confirm_password'.tr,
                                    //         titleText: '8_character'.tr,
                                    //         controller:
                                    //             _confirmPasswordController,
                                    //         focusNode: _confirmPasswordFocus,
                                    //         nextFocus:
                                    //             Get.find<SplashController>()
                                    //                         .configModel!
                                    //                         .refEarningStatus ==
                                    //                     1
                                    //                 ? _referCodeFocus
                                    //                 : null,
                                    //         inputAction:
                                    //             Get.find<SplashController>()
                                    //                         .configModel!
                                    //                         .refEarningStatus ==
                                    //                     1
                                    //                 ? TextInputAction.next
                                    //                 : TextInputAction.done,
                                    //         inputType:
                                    //             TextInputType.visiblePassword,
                                    //         prefixIcon: Icons.lock,
                                    //         isPassword: true,
                                    //         onSubmit: (text) =>
                                    //             (GetPlatform.isWeb)
                                    //                 ? _register(authController,
                                    //                     _countryDialCode!)
                                    //                 : null,
                                    //         required: true,
                                    //         validator: (value) =>
                                    //             ValidateCheck.validateEmptyText(
                                    //                 value, null),
                                    //         maxLength: 12,
                                    //       ))
                                    //     : const SizedBox()
                                  ]),
                              // const SizedBox(
                              //     height: Dimensions.paddingSizeExtraLarge),
                              // !ResponsiveHelper.isDesktop(context)
                              //     ? CustomTextField(
                              //         labelText: 'confirm_password'.tr,
                              //         titleText: '8_character'.tr,
                              //         controller: _confirmPasswordController,
                              //         focusNode: _confirmPasswordFocus,
                              //         nextFocus: Get.find<SplashController>()
                              //                     .configModel!
                              //                     .refEarningStatus ==
                              //                 1
                              //             ? _referCodeFocus
                              //             : null,
                              //         inputAction: Get.find<SplashController>()
                              //                     .configModel!
                              //                     .refEarningStatus ==
                              //                 1
                              //             ? TextInputAction.next
                              //             : TextInputAction.done,
                              //         inputType: TextInputType.visiblePassword,
                              //         prefixIcon: Icons.lock,
                              //         isPassword: true,
                              //         onSubmit: (text) => (GetPlatform.isWeb)
                              //             ? _register(
                              //                 authController, _countryDialCode!)
                              //             : null,
                              //         required: true,
                              //         validator: (value) =>
                              //             ValidateCheck.validateEmptyText(
                              //                 value, null),
                              //         maxLength: 12,
                              //       )
                              //     : const SizedBox(),
                              // SizedBox(
                              //     height: !ResponsiveHelper.isDesktop(context)
                              //         ? Dimensions.paddingSizeLarge
                              //         : 0),
                              // (Get.find<SplashController>()
                              //             .configModel!
                              //             .refEarningStatus ==
                              //         1)
                              //     ? CustomTextField(
                              //         labelText: 'refer_code'.tr,
                              //         titleText: 'enter_refer_code'.tr,
                              //         controller: _referCodeController,
                              //         focusNode: _referCodeFocus,
                              //         inputAction: TextInputAction.done,
                              //         inputType: TextInputType.text,
                              //         capitalization: TextCapitalization.words,
                              //         prefixImage: Images.referCode,
                              //         prefixSize: 14,
                              //         maxLength: 20,
                              //       )
                              //     : const SizedBox(),
                              const SizedBox(
                                  height: Dimensions.paddingSizeLarge),
                              const Text('Firm Image',
                                  style: TextStyle(color: Colors.black87)),
                              GestureDetector(
                                onTap: () =>
                                    controller.showPickOptions(context),
                                child: Obx(
                                  () => Container(
                                    padding: const EdgeInsets.all(10),
                                    margin: const EdgeInsets.all(10),
                                    width: 160,
                                    height: 160,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.grey.shade100,
                                    ),
                                    child: controller.file.value != null
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Image.file(
                                              controller.file.value!,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                  Icons.add_photo_alternate,
                                                  size: 40,
                                                  color: Colors.grey),
                                              const SizedBox(height: 8),
                                              Text("Add File",
                                                  style: TextStyle(
                                                      color: controller
                                                                  .file.value ==
                                                              null
                                                          ? Colors.red
                                                          : Colors.grey)),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                              controller.file.value == null
                                  ? const Text(
                                      'Firm image is required',
                                      style: TextStyle(color: Colors.red),
                                    )
                                  : const SizedBox.shrink(),

                              const Align(
                                alignment: Alignment.topLeft,
                                child: Text(
                                  'Select Store Address',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                  height: Dimensions.paddingSizeLarge),
                              Stack(
                                children: [
                                  SizedBox(
                                    height: 250,
                                    width: double.infinity,
                                    child: _currentPosition == null
                                        ? Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Center(
                                                child: SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                              ),
                                              if (_showLocationText)
                                                const Padding(
                                                  padding:
                                                      EdgeInsets.only(top: 20),
                                                  child: Text(
                                                    'Enable location of your device',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          )
                                        : GoogleMap(
                                            initialCameraPosition:
                                                CameraPosition(
                                              target: _selectedPosition ??
                                                  _currentPosition!,
                                              zoom: 12,
                                            ),
                                            onMapCreated: (GoogleMapController
                                                controller) {
                                              _mapController = controller;
                                              _mapController!.animateCamera(
                                                CameraUpdate.newLatLng(
                                                    _selectedPosition ??
                                                        _currentPosition!),
                                              );
                                            },
                                            markers: {
                                              if (_selectedPosition != null)
                                                Marker(
                                                  markerId: const MarkerId(
                                                      "selected-location"),
                                                  position: _selectedPosition!,
                                                  icon: BitmapDescriptor
                                                      .defaultMarkerWithHue(
                                                          BitmapDescriptor
                                                              .hueRed),
                                                ),
                                            },
                                            myLocationEnabled: true,
                                            myLocationButtonEnabled: false,
                                            zoomControlsEnabled: false,
                                            gestureRecognizers: const <Factory<
                                                OneSequenceGestureRecognizer>>{},
                                          ),
                                  ),
                                  if (_currentPosition != null)
                                    Positioned(
                                      top: 10,
                                      left: 10,
                                      right: 10,
                                      child: Column(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Colors.black26,
                                                  blurRadius: 4,
                                                  offset: Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: TextField(
                                              controller: _searchController,
                                              onChanged: (query) {
                                                setState(() {
                                                  _getPlaceSuggestions(query);
                                                });
                                              },
                                              decoration: InputDecoration(
                                                hintText:
                                                    'Select store location',
                                                hintStyle: const TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 14.0),
                                                border: InputBorder.none,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 10),
                                                suffixIcon: _searchController
                                                        .text.isNotEmpty
                                                    ? IconButton(
                                                        icon: const Icon(
                                                            Icons.cancel,
                                                            color: Colors.grey),
                                                        onPressed: () {
                                                          _searchController
                                                              .clear();
                                                          setState(() {
                                                            _placeSuggestions
                                                                .clear();
                                                            _selectedPosition =
                                                                _currentPosition;
                                                          });
                                                          _updateAddressFromLatLng(
                                                              _selectedPosition!);
                                                          _mapController!
                                                              .animateCamera(
                                                            CameraUpdate
                                                                .newLatLngZoom(
                                                                    _selectedPosition!,
                                                                    15),
                                                          );
                                                        },
                                                      )
                                                    : null,
                                              ),
                                            ),
                                          ),
                                          if (_placeSuggestions.isNotEmpty)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 8),
                                              child: SizedBox(
                                                height: 160,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    boxShadow: const [
                                                      BoxShadow(
                                                        color: Colors.black26,
                                                        blurRadius: 4,
                                                        offset: Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: ListView.separated(
                                                    padding: EdgeInsets.zero,
                                                    physics:
                                                        const AlwaysScrollableScrollPhysics(),
                                                    itemCount: _placeSuggestions
                                                        .length,
                                                    separatorBuilder: (context,
                                                            index) =>
                                                        const Divider(
                                                            color: Colors.grey,
                                                            height: 1),
                                                    itemBuilder:
                                                        (context, index) {
                                                      return ListTile(
                                                        title: Text(
                                                            _placeSuggestions[
                                                                index]),
                                                        onTap: () async {
                                                          _searchController
                                                                  .text =
                                                              _placeSuggestions[
                                                                  index];
                                                          _placeSuggestions
                                                              .clear();
                                                          setState(() {});
                                                          await _convertAddressToLatLng(
                                                              _searchController
                                                                  .text);
                                                        },
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(
                                  height: Dimensions.paddingSizeLarge),
                              TextField(
                                controller: _addressController,
                                readOnly: true,
                                decoration: InputDecoration(
                                  labelText: 'Address'.tr,
                                  labelStyle:
                                      const TextStyle(color: Colors.grey),
                                  border: OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.grey[200]!),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.grey[200]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.grey[200]!),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 16),
                                ),
                              ),
                              const SizedBox(
                                  height: Dimensions.paddingSizeExtraLarge),
                              const ConditionCheckBoxWidget(
                                  forDeliveryMan: true),
                              const SizedBox(
                                  height: Dimensions.paddingSizeLarge),
                              CustomButton(
                                height: ResponsiveHelper.isDesktop(context)
                                    ? 45
                                    : null,
                                width: ResponsiveHelper.isDesktop(context)
                                    ? 180
                                    : null,
                                radius: ResponsiveHelper.isDesktop(context)
                                    ? Dimensions.radiusSmall
                                    : Dimensions.radiusDefault,
                                isBold: !ResponsiveHelper.isDesktop(context),
                                fontSize: ResponsiveHelper.isDesktop(context)
                                    ? Dimensions.fontSizeExtraSmall
                                    : null,
                                buttonText: 'sign_up'.tr,
                                isLoading: authController.isLoading,
                                onPressed: authController.acceptTerms
                                    ? () => _register(
                                        authController, _countryDialCode!)
                                    : null,
                              ),
                              const SizedBox(
                                  height: Dimensions.paddingSizeExtraLarge),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'already_have_account'.tr,
                                    style: robotoRegular.copyWith(
                                      color: Theme.of(context).hintColor,
                                      fontSize: 16,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      if (ResponsiveHelper.isDesktop(context)) {
                                        Get.back();
                                        Get.dialog(const SignInScreen(
                                            exitFromApp: false,
                                            backFromThis: false));
                                      } else {
                                        if (Get.currentRoute ==
                                            RouteHelper.signUp) {
                                          Get.back();
                                        } else {
                                          Get.toNamed(
                                              RouteHelper.getSignInRoute(
                                                  RouteHelper.signUp));
                                        }
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(
                                          Dimensions.paddingSizeExtraSmall),
                                      child: Text(
                                        'sign_in'.tr,
                                        style: robotoMedium.copyWith(
                                          color: Theme.of(context).primaryColor,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            ]),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  void _register(AuthController authController, String countryCode) async {
    String firstName = _firstNameController.text.trim();
    String lastName = _lastNameController.text.trim();
    String email = _emailController.text.trim();
    String number = _phoneController.text.trim();
    String firmName = _firmNameController.text.trim();
    String? firmImage = controller.fileName.value;
    String referCode = _referCodeController.text.trim();
    String address = _addressController.text.trim();
    String latitude = _latitudeController.text.trim();
    String longitude = _longitudeController.text.trim();
    print("Latitude: $latitude");
    print("Longitude: $longitude");

    String numberWithCountryCode = countryCode + number;
    PhoneValid phoneValid =
        await CustomValidator.isPhoneValid(numberWithCountryCode);
    numberWithCountryCode = phoneValid.phone;

    if (_formKeySignUp.currentState!.validate()) {
      // Additional manual field checks
      if (firstName.isEmpty) {
        showCustomSnackBar('enter_your_first_name'.tr);
        return;
      } else if (lastName.isEmpty) {
        showCustomSnackBar('enter_your_last_name'.tr);
        return;
      } else if (email.isEmpty) {
        showCustomSnackBar('enter_email_address'.tr);
        return;
      } else if (!GetUtils.isEmail(email)) {
        showCustomSnackBar('enter_a_valid_email_address'.tr);
        return;
      } else if (number.isEmpty) {
        showCustomSnackBar('enter_phone_number'.tr);
        return;
      } else if (!phoneValid.isValid) {
        showCustomSnackBar('invalid_phone_number'.tr);
        return;
      } else if (firmName.isEmpty) {
        showCustomSnackBar('Firm name is required');
        return;
      } else if (controller.file.value == null) {
        showCustomSnackBar('Firm image is required');
        return;
      } else if (address.isEmpty) {
        showCustomSnackBar('Please select your store address');
        return;
      }

      // ✅ Passed all validations — proceed to registration
      String? zoneId;
      String? moduleId;

      if (Get.find<ApiClient>()
          .sharedPreferences
          .containsKey(AppConstants.userAddress)) {
        try {
          AddressModel addressModel = AddressModel.fromJson(
            jsonDecode(Get.find<ApiClient>()
                .sharedPreferences
                .getString(AppConstants.userAddress)!),
          );
          if (addressModel.zoneIds != null &&
              addressModel.zoneIds!.isNotEmpty) {
            zoneId = addressModel.zoneIds!.first.toString();
          }
        } catch (_) {}
      }

      if (Get.find<ApiClient>()
          .sharedPreferences
          .containsKey(AppConstants.moduleId)) {
        try {
          moduleId = ModuleModel.fromJson(
            jsonDecode(Get.find<ApiClient>()
                .sharedPreferences
                .getString(AppConstants.moduleId)!),
          ).id.toString();
        } catch (_) {}
      }

      SignUpBodyModel signUpBody = SignUpBodyModel(
        phone: numberWithCountryCode,
        fName: firstName,
        lName: lastName,
        email: email,
        UserType: 'Decorator',
        refCode: referCode,
        firmName: firmName,
        imagePath: firmImage,
        latitude: latitude,
        longitude: longitude,
        zoneId: zoneId,
        moduleId: '2',
        address: address,
      );

      authController.registration(signUpBody).then((status) async {
        if (status.isSuccess) {
          if (Get.find<SplashController>().configModel!.customerVerification!) {
            if (Get.find<SplashController>()
                .configModel!
                .firebaseOtpVerification!) {
              Get.find<AuthController>().firebaseVerifyPhoneNumber(
                numberWithCountryCode,
                status.message,
                fromSignUp: true,
              );
            } else {
              List<int> encoded = utf8.encode(firmName);
              String data = base64Encode(encoded);
              Get.toNamed(RouteHelper.getVerificationRoute(
                numberWithCountryCode,
                status.message,
                RouteHelper.signUp,
                data,
              ));
            }
          } else {
            Get.find<LocationController>()
                .navigateToLocationScreen(RouteHelper.signUp);
            if (ResponsiveHelper.isDesktop(Get.context)) {
              Get.back();
            }
          }
        } else {
          showCustomSnackBar(status.message);
          print("Form validation failed.");
        }
      });
    } else {
      // Form is invalid — do nothing or show a message if needed
      print("Form validation failed.");
    }
  }
}
