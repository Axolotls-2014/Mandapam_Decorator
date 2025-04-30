// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as https;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
// import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
// import 'package:sixam_mart/features/media/functions.dart';
// import 'package:sixam_mart/util/app_constants.dart';
// import 'package:sixam_mart/util/dimensions.dart';
// import 'package:get/get.dart';
// import 'package:sixam_mart/helper/auth_helper.dart';
// import 'package:sixam_mart/common/widgets/not_logged_in_screen.dart';
// import 'package:get/get.dart';
//
// class AddMediaScreen extends StatefulWidget {
//   final SharedPreferences sharedPreferences;
//   final bool fromDashboard;
//   AddMediaScreen({required this.sharedPreferences,this.fromDashboard = false});
//
//   @override
//   _AddMediaScreenState createState() => _AddMediaScreenState();
// }
//
// class _AddMediaScreenState extends State<AddMediaScreen> {
//   late ApiService apiService;
//   List<Map<String, dynamic>>? events;
//   Map<String, dynamic>? selectedEvent;
//   bool isDropdownOpen = false;
//   final LayerLink _layerLink = LayerLink();
//   OverlayEntry? _overlayEntry;
//   List<int> eventIds = [];
//   List<String> eventNames = [];
//   bool isLoading = true;
//   String? selectedEventName;
//   List<XFile> _selectedImages = [];
//   List<XFile> _selectedVideos = [];
//   bool _isSubmitting = false;
//   final TextEditingController _titleController = TextEditingController();
//   String _selectedOption = 'image';
//   String? globalUserId;
//   late AuthController authController;
//
//   @override
//   void initState() {
//     super.initState();
//     apiService = ApiService(sharedPreferences: widget.sharedPreferences);
//     _fetchUserId();
//     fetchEventList();
//   }
//
//   Future<void> _fetchUserId() async {
//     authController = Get.find<AuthController>();
//     globalUserId = await authController.getUserId();
//     if (globalUserId != null) {
//       print("Stored_User_ID: $globalUserId");
//     } else {
//       print("Error: Could not fetch User ID");
//     }
//   }
//
//   void fetchEventList() async {
//     events = await apiService.fetchEvents();
//     if (events != null) {
//       eventIds = events!.map((event) => event['id'] as int).toList();
//       eventNames = events!.map((event) => event['title'] as String).toList();
//     }
//     setState(() {
//       isLoading = false;
//     });
//   }
//
//   void toggleDropdown() {
//     if (isDropdownOpen) {
//       _removeDropdown();
//     } else {
//       _overlayEntry = _createOverlayEntry();
//       Overlay.of(context).insert(_overlayEntry!);
//       setState(() {
//         isDropdownOpen = true;
//       });
//     }
//   }
//
//   void _removeDropdown() {
//     _overlayEntry?.remove();
//     _overlayEntry = null;
//     setState(() {
//       isDropdownOpen = false;
//     });
//   }
//
//   OverlayEntry _createOverlayEntry() {
//     return OverlayEntry(
//       builder: (context) {
//         return Stack(
//           children: [
//             Positioned.fill(
//               child: GestureDetector(
//                 onTap: _removeDropdown,
//                 behavior: HitTestBehavior.opaque,
//                 child: Container(),
//               ),
//             ),
//             Positioned(
//               width: MediaQuery.of(context).size.width * 0.9,
//               child: CompositedTransformFollower(
//                 link: _layerLink,
//                 offset: Offset(0, 50),
//                 child: Material(
//                   elevation: 4.0,
//                   borderRadius: BorderRadius.circular(8),
//                   child: Container(
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     constraints: BoxConstraints(
//                       maxHeight: 180,
//                     ),
//                     child: SingleChildScrollView(
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: eventNames.map((event) {
//                           return GestureDetector(
//                             onTap: () {
//                               setState(() {
//                                 selectedEventName = event;
//                                 _removeDropdown();
//                               });
//                             },
//                             child: Container(
//                               width: double.infinity,
//                               padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
//                               alignment: Alignment.centerLeft,
//                               child: Text(
//                                 event,
//                                 style: TextStyle(fontSize: 16),
//                                 textAlign: TextAlign.start,
//                                 overflow: TextOverflow.ellipsis,
//                                 maxLines: 1,
//                               ),
//                             ),
//                           );
//                         }).toList(),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   Future<void> _pickImage() async {
//     PermissionStatus status;
//     if (Platform.isAndroid) {
//       if (await Permission.storage.isRestricted) {
//         status = await Permission.manageExternalStorage.request();
//       } else {
//         status = await Permission.storage.request();
//         if (!status.isGranted) {
//           status = await Permission.photos.request();
//         }
//       }
//     } else if (Platform.isIOS) {
//       status = await Permission.photos.request();
//     } else {
//       return;
//     }
//
//     if (status.isGranted) {
//       final List<XFile>? pickedFiles = await ImagePicker().pickMultiImage(
//         requestFullMetadata: false,
//       );
//       if (pickedFiles != null) {
//         for (var file in pickedFiles) {
//           if (file.path.toLowerCase().endsWith(".png") ||
//               file.path.toLowerCase().endsWith(".jpg") ||
//               file.path.toLowerCase().endsWith(".jpeg")) {
//
//             final File imageFile = File(file.path);
//             final int fileSize = await imageFile.length();
//             const int maxSize = 10 * 1024 * 1024;
//
//             if (fileSize > maxSize) {
//               _showAutoDismissDialog("File Too Large", "The selected image exceeds the 10MB limit.");
//               return;
//             }
//
//             bool alreadyExists = _selectedImages.any((image) => image.name == file.name);
//             if (!alreadyExists && _selectedImages.length < 4) {
//               setState(() {
//                 _selectedImages.add(file);
//               });
//             }
//           }
//         }
//       }
//     } else if (status.isPermanentlyDenied) {
//       openAppSettings();
//     }
//   }
//
//   Future<void> _pickVideo() async {
//     PermissionStatus status;
//     if (Platform.isAndroid) {
//       if (await Permission.storage.isRestricted) {
//         status = await Permission.manageExternalStorage.request();
//       } else {
//         status = await Permission.storage.request();
//         if (!status.isGranted) {
//           status = await Permission.photos.request();
//         }
//       }
//     } else if (Platform.isIOS) {
//       status = await Permission.photos.request();
//     } else {
//       return;
//     }
//
//     if (status.isGranted) {
//       final XFile? pickedFile = await ImagePicker().pickVideo(
//         source: ImageSource.gallery,
//       );
//       if (pickedFile != null && pickedFile.path.toLowerCase().endsWith(".mp4")) {
//         final File file = File(pickedFile.path);
//         final int fileSize = await file.length();
//         const int maxSize = 10 * 1024 * 1024;
//
//         if (fileSize > maxSize) {
//           _showAutoDismissDialog("File Too Large", "The selected video exceeds the 10MB limit.");
//           return;
//         }
//
//         bool alreadyExists = _selectedVideos.any((video) => video.name == pickedFile.name);
//         if (!alreadyExists && _selectedVideos.length < 4) {
//           setState(() {
//             _selectedVideos.add(pickedFile);
//           });
//         }
//       }
//     } else if (status.isPermanentlyDenied) {
//       openAppSettings();
//     }
//   }
//
//   // Future<void> _pickImage() async {
//   //   PermissionStatus status;
//   //   if (Platform.isAndroid) {
//   //     status = await Permission.storage.status;
//   //   } else if (Platform.isIOS) {
//   //     status = await Permission.photos.status;
//   //   } else {
//   //     return;
//   //   }
//   //
//   //   if (!status.isGranted) {
//   //     if (Platform.isAndroid) {
//   //       status = await Permission.storage.request();
//   //     } else if (Platform.isIOS) {
//   //       status = await Permission.photos.request();
//   //     }
//   //   }
//   //
//   //   if (status.isGranted) {
//   //     final List<XFile>? pickedFiles = await ImagePicker().pickMultiImage();
//   //     if (pickedFiles != null) {
//   //       for (var file in pickedFiles) {
//   //         if (file.path.toLowerCase().endsWith(".png") ||
//   //             file.path.toLowerCase().endsWith(".jpg") ||
//   //             file.path.toLowerCase().endsWith(".jpeg")) {
//   //
//   //           final File imageFile = File(file.path);
//   //           final int fileSize = await imageFile.length();
//   //           const int maxSize = 10 * 1024 * 1024;
//   //
//   //           if (fileSize > maxSize) {
//   //             _showAutoDismissDialog("File Too Large", "The selected image exceeds the 10MB limit.");
//   //             return;
//   //           }
//   //
//   //           bool alreadyExists = _selectedImages.any((image) => image.name == file.name);
//   //           if (!alreadyExists && _selectedImages.length < 4) {
//   //             setState(() {
//   //               _selectedImages.add(file);
//   //             });
//   //           }
//   //         }
//   //       }
//   //     }
//   //   } else if (status.isPermanentlyDenied) {
//   //     _showAutoDismissDialog("Permission Required", "Please enable photos access in the app settings.");
//   //   }
//   // }
//   //
//   // Future<void> _pickVideo() async {
//   //   PermissionStatus status;
//   //   if (Platform.isAndroid) {
//   //     status = await Permission.storage.status;
//   //   } else if (Platform.isIOS) {
//   //     status = await Permission.photos.status;
//   //   } else {
//   //     return;
//   //   }
//   //
//   //   if (!status.isGranted) {
//   //     if (Platform.isAndroid) {
//   //       status = await Permission.storage.request();
//   //     } else if (Platform.isIOS) {
//   //       status = await Permission.photos.request();
//   //     }
//   //   }
//   //
//   //   if (status.isGranted) {
//   //     final XFile? pickedFile = await ImagePicker().pickVideo(source: ImageSource.gallery);
//   //     if (pickedFile != null && pickedFile.path.toLowerCase().endsWith(".mp4")) {
//   //       final File file = File(pickedFile.path);
//   //       final int fileSize = await file.length();
//   //       const int maxSize = 10 * 1024 * 1024;
//   //
//   //       if (fileSize > maxSize) {
//   //         _showAutoDismissDialog("File Too Large", "The selected video exceeds the 10MB limit.");
//   //         return;
//   //       }
//   //
//   //       bool alreadyExists = _selectedVideos.any((image) => image.name == pickedFile.name);
//   //       if (!alreadyExists && _selectedVideos.length < 4) {
//   //         setState(() {
//   //           _selectedVideos.add(pickedFile);
//   //         });
//   //       }
//   //     }
//   //   } else if (status.isPermanentlyDenied) {
//   //     _showAutoDismissDialog("Permission Required", "Please enable photos access in the app settings.");
//   //   }
//   // }
//
//   void _showAutoDismissDialog(String title, String message) {
//     showDialog(
//       context: context,
//       builder: (context) {
//         Timer(Duration(seconds: 3), () {
//           Navigator.of(context).pop();
//         });
//         return AlertDialog(
//           title: Text(
//             title,
//             style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//           ),
//           content: Text(
//             message,
//             style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
//           ),
//         );
//       },
//     );
//   }
//
//   void _submitMedia() async {
//     if (_titleController.text.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Please add a title')),
//       );
//       return;
//     }
//
//     if (selectedEventName == null) {
//       _showAutoDismissDialog("Error", "Please select an event.");
//       return;
//     }
//
//     if (_selectedImages.isEmpty && _selectedVideos.isEmpty) {
//       _showAutoDismissDialog("Error", "Please select at least one image or video.");
//       return;
//     }
//
//     setState(() {
//       _isSubmitting = true;
//     });
//
//     int eventId = eventIds[eventNames.indexOf(selectedEventName!)];
//     int userId = int.parse(globalUserId!);
//     Map<String, dynamic> requestBody = {
//       "event_id": eventId,
//       "user_id": userId,
//     };
//
//     for (int i = 0; i < _selectedImages.length; i++) {
//       requestBody["media[$i][type]"] = "photo";
//       requestBody["media[$i][file_path]"] = _selectedImages[i].path;
//       requestBody["media[$i][title]"] = _titleController.text;
//     }
//
//     for (int i = 0; i < _selectedVideos.length; i++) {
//       int index = _selectedImages.length + i;
//       requestBody["media[$index][type]"] = "video";
//       requestBody["media[$index][file_path]"] = _selectedVideos[i].path;
//       requestBody["media[$index][title]"] = _titleController.text;
//     }
//
//     print('Request Body: $requestBody');
//     final response = await apiService.addMedia(
//       eventId: eventId,
//       userId: userId,
//       media: requestBody,
//     );
//
//     setState(() {
//       _isSubmitting = false;
//     });
//
//     if (response != null) {
//       _showAutoDismissDialog("Success", "Media added successfully.");
//       setState(() {
//         _selectedImages.clear();
//         _selectedVideos.clear();
//         selectedEventName = null;
//         _titleController.clear();
//       });
//     } else {
//       _showAutoDismissDialog("Error", "Failed to add media.");
//       setState(() {
//         _selectedImages.clear();
//         _selectedVideos.clear();
//         selectedEventName = null;
//         _titleController.clear();
//       });
//     }
//   }
//
//   void _removeImage(int index) {
//     setState(() {
//       _selectedImages.removeAt(index);
//     });
//   }
//
//   void _removeVideo(int index) {
//     setState(() {
//       _selectedVideos.removeAt(index);
//     });
//   }
//
//   @override
//   void dispose() {
//     _removeDropdown();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       resizeToAvoidBottomInset: false,
//       appBar: CustomAppBar(title: 'Add Media', backButton: widget.fromDashboard ? false : true),
//       body: AuthHelper.isLoggedIn()
//           ? isLoading
//           ? Container(
//         // color: Colors.black.withOpacity(0.5),
//         child: Center(
//           child: SizedBox(
//             width: 25,
//             height: 25,
//             child: CircularProgressIndicator(),
//           ),
//         ),
//       ) : Stack(
//         children: [
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
//             child: Column(
//               children: [
//                 TextField(
//                   controller: _titleController,
//                   decoration: InputDecoration(
//                     labelText: 'Media Title',
//                     border: OutlineInputBorder(),
//                   ),
//                   maxLines: 1,
//                   textInputAction: TextInputAction.done,
//                 ),
//                 SizedBox(height: 16),
//                 CompositedTransformTarget(
//                   link: _layerLink,
//                   child: GestureDetector(
//                     onTap: toggleDropdown,
//                     child: Container(
//                       padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//                       decoration: BoxDecoration(
//                         border: Border.all(color: Colors.grey),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             selectedEventName ?? "Select Event",
//                             style: TextStyle(
//                               fontSize: 16,
//                             ),
//                           ),
//                           Icon(Icons.arrow_drop_down),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 16),
//
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Radio(
//                       value: 'image',
//                       groupValue: _selectedOption,
//                       onChanged: (value) {
//                         setState(() {
//                           _selectedOption = value.toString();
//                           _selectedImages.clear();
//                           _selectedVideos.clear();
//                         });
//                       },
//                     ),
//                     Text('Select Image'),
//                     SizedBox(width: 20),
//                     Radio(
//                       value: 'video',
//                       groupValue: _selectedOption,
//                       onChanged: (value) {
//                         setState(() {
//                           _selectedOption = value.toString();
//                           _selectedImages.clear();
//                           _selectedVideos.clear();
//                         });
//                       },
//                     ),
//                     Text('Select Video'),
//                   ],
//                 ),
//
//                 if (_selectedOption == 'image')
//                 Align(
//                   alignment: Alignment.centerLeft,
//                   child: ElevatedButton(
//                     onPressed: () {
//                       if (_selectedImages.length >= 1) {
//                         _showAutoDismissDialog("Error", "Maximum 1 file allowed at a time.");
//                         return;
//                       }
//                       _pickImage();
//                     },
//                     child: Text(
//                       "Select Image",
//                       style: TextStyle(color: Colors.white),
//                     ),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Color(0xFF0D6EFD),
//                       padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 2),
//                 Column(
//                   children: List.generate(_selectedImages.length, (index) {
//                     return SizedBox(
//                       height: 25,
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             _selectedImages[index].name,
//                             style: TextStyle(fontSize: 14),
//                           ),
//                           IconButton(
//                             icon: Icon(Icons.cancel, size: 15),
//                             padding: EdgeInsets.zero,
//                             constraints: BoxConstraints(),
//                             onPressed: () => _removeImage(index),
//                           ),
//                         ],
//                       ),
//                     );
//                   }),
//                 ),
//
//                 if (_selectedOption == 'video')
//                 Align(
//                   alignment: Alignment.centerLeft,
//                   child: ElevatedButton(
//                     onPressed: () {
//                       if (_selectedVideos.length >= 1) {
//                         _showAutoDismissDialog("Error", "Maximum 1 file allowed at a time.");
//                         return;
//                       }
//                       _pickVideo();
//                     },
//                     child: Text(
//                       "Select Video",
//                       style: TextStyle(color: Colors.white),
//                     ),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Color(0xFF0D6EFD),
//                       padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 8),
//                 Column(
//                   children: List.generate(_selectedVideos.length, (index) {
//                     return SizedBox(
//                       height: 25,
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             _selectedVideos[index].name,
//                             style: TextStyle(fontSize: 14),
//                           ),
//                           IconButton(
//                             icon: Icon(Icons.cancel, size: 15),
//                             padding: EdgeInsets.zero,
//                             constraints: BoxConstraints(),
//                             onPressed: () => _removeVideo(index),
//                           ),
//                         ],
//                       ),
//                     );
//                   }),
//                 ),
//               ],
//             ),
//           ),
//           Positioned(
//             bottom: 16,
//             left: 16,
//             right: 16,
//             child: Container(
//               width: double.infinity,
//               height: 45,
//               decoration: BoxDecoration(
//                 color: Color(0xFF0D6EFD),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: TextButton(
//                 onPressed: _isSubmitting ? null : _submitMedia,
//                 style: TextButton.styleFrom(
//                   padding: EdgeInsets.zero,
//                   backgroundColor: Colors.transparent,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 child: Center(
//                   child: _isSubmitting
//                       ? SizedBox(
//                     width: 20,
//                     height: 20,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2,
//                       color: Colors.white,
//                     ),
//                   ) : Text(
//                     'Submit',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 14,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ) : NotLoggedInScreen(callBack: (value) {
//         setState(() {});
//         fetchEventList();
//       }),
//     );
//   }
// }


import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as https;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/media/functions.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/common/widgets/not_logged_in_screen.dart';
import 'package:get/get.dart';

class AddMediaScreen extends StatefulWidget {
  final SharedPreferences sharedPreferences;
  final bool fromDashboard;
  AddMediaScreen({required this.sharedPreferences,this.fromDashboard = false});

  @override
  _AddMediaScreenState createState() => _AddMediaScreenState();
}

class _AddMediaScreenState extends State<AddMediaScreen> {
  late ApiService apiService;
  List<Map<String, dynamic>>? events;
  Map<String, dynamic>? selectedEvent;
  bool isDropdownOpen = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<int> eventIds = [];
  List<String> eventNames = [];
  bool isLoading = true;
  String? selectedEventName;
  List<XFile> _selectedImages = [];
  List<XFile> _selectedVideos = [];
  bool _isSubmitting = false;
  final TextEditingController _titleController = TextEditingController();
  String _selectedOption = 'image';
  String? globalUserId;
  late AuthController authController;

  @override
  void initState() {
    super.initState();
    apiService = ApiService(sharedPreferences: widget.sharedPreferences);
    _fetchUserId();
    fetchEventList();
  }

  Future<void> _fetchUserId() async {
    authController = Get.find<AuthController>();
    globalUserId = await authController.getUserId();
    if (globalUserId != null) {
      print("Stored_User_ID: $globalUserId");
    } else {
      print("Error: Could not fetch User ID");
    }
  }

  void fetchEventList() async {
    events = await apiService.fetchEvents();
    if (events != null) {
      eventIds = events!.map((event) => event['id'] as int).toList();
      eventNames = events!.map((event) => event['title'] as String).toList();
    }
    setState(() {
      isLoading = false;
    });
  }

  void toggleDropdown() {
    if (isDropdownOpen) {
      _removeDropdown();
    } else {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
      setState(() {
        isDropdownOpen = true;
      });
    }
  }

  void _removeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      isDropdownOpen = false;
    });
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _removeDropdown,
                behavior: HitTestBehavior.opaque,
                child: Container(),
              ),
            ),
            Positioned(
              width: MediaQuery.of(context).size.width * 0.9,
              child: CompositedTransformFollower(
                link: _layerLink,
                offset: Offset(0, 50),
                child: Material(
                  elevation: 4.0,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: BoxConstraints(
                      maxHeight: 180,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: eventNames.map((event) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedEventName = event;
                                _removeDropdown();
                              });
                            },
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                              alignment: Alignment.centerLeft,
                              child: Text(
                                event,
                                style: TextStyle(fontSize: 16),
                                textAlign: TextAlign.start,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImage() async {
    PermissionStatus status;
    if (Platform.isAndroid) {
      if (await Permission.storage.isRestricted) {
        status = await Permission.manageExternalStorage.request();
      } else {
        status = await Permission.storage.request();
        if (!status.isGranted) {
          status = await Permission.photos.request();
        }
      }
    } else if (Platform.isIOS) {
      status = await Permission.photos.request();
    } else {
      return;
    }

    if (status.isGranted) {
      final List<XFile>? pickedFiles = await ImagePicker().pickMultiImage(
        requestFullMetadata: false,
      );
      if (pickedFiles != null) {
        for (var file in pickedFiles) {
          if (file.path.toLowerCase().endsWith(".png") ||
              file.path.toLowerCase().endsWith(".jpg") ||
              file.path.toLowerCase().endsWith(".jpeg")) {

            final File imageFile = File(file.path);
            final int fileSize = await imageFile.length();
            const int maxSize = 10 * 1024 * 1024;

            if (fileSize > maxSize) {
              _showAutoDismissDialog("File Too Large", "The selected image exceeds the 10MB limit.");
              return;
            }

            bool alreadyExists = _selectedImages.any((image) => image.name == file.name);
            if (!alreadyExists && _selectedImages.length < 4) {
              setState(() {
                _selectedImages.add(file);
              });
            }
          }
        }
      }
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  Future<void> _pickVideo() async {
    PermissionStatus status;
    if (Platform.isAndroid) {
      if (await Permission.storage.isRestricted) {
        status = await Permission.manageExternalStorage.request();
      } else {
        status = await Permission.storage.request();
        if (!status.isGranted) {
          status = await Permission.photos.request();
        }
      }
    } else if (Platform.isIOS) {
      status = await Permission.photos.request();
    } else {
      return;
    }

    if (status.isGranted) {
      final XFile? pickedFile = await ImagePicker().pickVideo(
        source: ImageSource.gallery,
      );
      if (pickedFile != null && pickedFile.path.toLowerCase().endsWith(".mp4")) {
        final File file = File(pickedFile.path);
        final int fileSize = await file.length();
        const int maxSize = 10 * 1024 * 1024;

        if (fileSize > maxSize) {
          _showAutoDismissDialog("File Too Large", "The selected video exceeds the 10MB limit.");
          return;
        }

        bool alreadyExists = _selectedVideos.any((video) => video.name == pickedFile.name);
        if (!alreadyExists && _selectedVideos.length < 4) {
          setState(() {
            _selectedVideos.add(pickedFile);
          });
        }
      }
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  void _showAutoDismissDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) {
        Timer(Duration(seconds: 3), () {
          Navigator.of(context).pop();
        });
        return AlertDialog(
          title: Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Text(
            message,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }

  void _submitMedia() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add hashtags')),
      );
      return;
    }

    if (selectedEventName == null) {
      _showAutoDismissDialog("Error", "Please select an event.");
      return;
    }

    if (_selectedImages.isEmpty && _selectedVideos.isEmpty) {
      _showAutoDismissDialog("Error", "Please select at least one image or video.");
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    int eventId = eventIds[eventNames.indexOf(selectedEventName!)];
    int userId = int.parse(globalUserId!);
    Map<String, dynamic> requestBody = {
      "event_id": eventId,
      "user_id": userId,
    };

    for (int i = 0; i < _selectedImages.length; i++) {
      requestBody["media[$i][type]"] = "photo";
      requestBody["media[$i][file_path]"] = _selectedImages[i].path;
      requestBody["media[$i][title]"] = _titleController.text;
    }

    for (int i = 0; i < _selectedVideos.length; i++) {
      int index = _selectedImages.length + i;
      requestBody["media[$index][type]"] = "video";
      requestBody["media[$index][file_path]"] = _selectedVideos[i].path;
      requestBody["media[$index][title]"] = _titleController.text;
    }

    print('Request Body: $requestBody');
    final response = await apiService.addMedia(
      eventId: eventId,
      userId: userId,
      media: requestBody,
    );

    setState(() {
      _isSubmitting = false;
    });

    if (response != null) {
      _showAutoDismissDialog("Success", "Media added successfully.");
      setState(() {
        _selectedImages.clear();
        _selectedVideos.clear();
        selectedEventName = null;
        _titleController.clear();
      });
    } else {
      _showAutoDismissDialog("Error", "Failed to add media.");
      setState(() {
        _selectedImages.clear();
        _selectedVideos.clear();
        selectedEventName = null;
        _titleController.clear();
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _removeVideo(int index) {
    setState(() {
      _selectedVideos.removeAt(index);
    });
  }

  @override
  void dispose() {
    _removeDropdown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: CustomAppBar(title: 'Add Media', backButton: widget.fromDashboard ? false : true),
      body: AuthHelper.isLoggedIn()
          ? isLoading
          ? Container(
        child: Center(
          child: SizedBox(
            width: 25,
            height: 25,
            child: CircularProgressIndicator(),
          ),
        ),
      ) : Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              children: [
                CompositedTransformTarget(
                  link: _layerLink,
                  child: GestureDetector(
                    onTap: toggleDropdown,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedEventName ?? "Select Event",
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                          Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Radio(
                      value: 'image',
                      groupValue: _selectedOption,
                      onChanged: (value) {
                        setState(() {
                          _selectedOption = value.toString();
                          _selectedImages.clear();
                          _selectedVideos.clear();
                        });
                      },
                    ),
                    Text('Select Image'),
                    SizedBox(width: 20),
                    Radio(
                      value: 'video',
                      groupValue: _selectedOption,
                      onChanged: (value) {
                        setState(() {
                          _selectedOption = value.toString();
                          _selectedImages.clear();
                          _selectedVideos.clear();
                        });
                      },
                    ),
                    Text('Select Video'),
                  ],
                ),
                SizedBox(height: 16),
                if (_selectedOption == 'image')
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_selectedImages.length >= 1) {
                          _showAutoDismissDialog("Error", "Maximum 1 file allowed at a time.");
                          return;
                        }
                        _pickImage();
                      },
                      child: Text(
                        "Select Image",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF0D6EFD),
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                SizedBox(height: 8),
                Column(
                  children: List.generate(_selectedImages.length, (index) {
                    return SizedBox(
                      height: 25,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedImages[index].name,
                            style: TextStyle(fontSize: 14),
                          ),
                          IconButton(
                            icon: Icon(Icons.cancel, size: 15),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                            onPressed: () => _removeImage(index),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
                if (_selectedOption == 'video')
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_selectedVideos.length >= 1) {
                          _showAutoDismissDialog("Error", "Maximum 1 file allowed at a time.");
                          return;
                        }
                        _pickVideo();
                      },
                      child: Text(
                        "Select Video",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF0D6EFD),
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                SizedBox(height: 8),
                Column(
                  children: List.generate(_selectedVideos.length, (index) {
                    return SizedBox(
                      height: 25,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedVideos[index].name,
                            style: TextStyle(fontSize: 14),
                          ),
                          IconButton(
                            icon: Icon(Icons.cancel, size: 15),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                            onPressed: () => _removeVideo(index),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Hashtags',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                  maxLength: 100,
                  textInputAction: TextInputAction.done,
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              width: double.infinity,
              height: 45,
              decoration: BoxDecoration(
                color: Color(0xFF0D6EFD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                onPressed: _isSubmitting ? null : _submitMedia,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Center(
                  child: _isSubmitting
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ) : Text(
                    'Submit',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ) : NotLoggedInScreen(callBack: (value) {
        setState(() {});
        fetchEventList();
      }),
    );
  }
}