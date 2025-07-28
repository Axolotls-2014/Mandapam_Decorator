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
import 'package:sixam_mart/features/media/view_media.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/common/widgets/not_logged_in_screen.dart';

class AddMediaScreen extends StatefulWidget {
  final SharedPreferences sharedPreferences;
  final bool fromDashboard;
  final int? eventId;
  final String? eventName;

  AddMediaScreen({
    required this.sharedPreferences,
    this.fromDashboard = false,
    required this.eventId,
    required this.eventName,
  });

  @override
  _AddMediaScreenState createState() => _AddMediaScreenState();
}

class _AddMediaScreenState extends State<AddMediaScreen> {
  late ApiService apiService;
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
            const int maxSize = 50 * 1024 * 1024;

            if (fileSize > maxSize) {
              _showAutoDismissDialog("File Too Large", "The selected image exceeds the 50MB limit.");
              return;
            }

            bool alreadyExists = _selectedImages.any((image) => image.name == file.name);
            if (!alreadyExists && _selectedImages.length < 20) {
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
      final List<XFile>? pickedFiles = await ImagePicker().pickMultipleMedia();
      if (pickedFiles != null) {
        List<XFile> videoFiles = pickedFiles.where((file) =>
            file.path.toLowerCase().endsWith(".mp4")).toList();

        for (var file in videoFiles) {
          final File videoFile = File(file.path);
          final int fileSize = await videoFile.length();
          const int maxSize = 50 * 1024 * 1024;

          if (fileSize > maxSize) {
            _showAutoDismissDialog("File Too Large", "The selected video exceeds the 50MB limit.");
            return;
          }

          bool alreadyExists = _selectedVideos.any((video) => video.name == file.name);
          if (!alreadyExists && _selectedVideos.length < 20) {
            setState(() {
              _selectedVideos.add(file);
            });
          }
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

  Future<bool> _onWillPop() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ViewMediaScreen(
          sharedPreferences: widget.sharedPreferences,
          fromDashboard: widget.fromDashboard,
        ),
      ),
    );
    return Future.value(false);
  }

  void _submitMedia() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add hashtags')),
      );
      return;
    }

    if (_selectedImages.isEmpty && _selectedVideos.isEmpty) {
      _showAutoDismissDialog("Error", "Please select at least one image or video.");
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    int userId = int.parse(globalUserId!);
    Map<String, dynamic> requestBody = {
      "event_id": widget.eventId,
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
      eventId: widget.eventId!,
      userId: userId,
      media: requestBody,
    );

    setState(() {
      _isSubmitting = false;
    });

    if (response != null) {
      _showAutoDismissDialog("Success", "Media added successfully.");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ViewMediaScreen(
            sharedPreferences: widget.sharedPreferences,
            fromDashboard: widget.fromDashboard,
          ),
        ),
      );
    } else {
      _showAutoDismissDialog("Error", "Failed to add media.");
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
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: CustomAppBar(title: 'Add Media', backButton: widget.fromDashboard ? false : true),
        body: AuthHelper.isLoggedIn()
            ? SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                  children: [
              Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.eventName ?? 'Event',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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
                    });
                  },
                ),
                Text('Select Video'),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Max 20 files can be selected at a time (Max 50MB each)',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
            SizedBox(height: 16),
            if (_selectedOption == 'image')
        Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (_selectedImages.length >= 20) {
                        _showAutoDismissDialog("Error", "Maximum 20 files allowed");
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
                  SizedBox(height: 0),
                  Column(
                    children: List.generate(_selectedImages.length, (index) {
                      return SizedBox(
                        height: 25,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _selectedImages[index].name,
                                style: TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
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
                ],
              ),
            ),
          ],
        ),

            if (_selectedOption == 'video')
              Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_selectedVideos.length >= 20) {
                          _showAutoDismissDialog("Error", "Maximum 20 files allowed");
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
                            Expanded(
                              child: Text(
                                _selectedVideos[index].name,
                                style: TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
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
                ],
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
            SizedBox(height: 20),
            Container(
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
                  )
                      : Text(
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
            SizedBox(height: 20),
          ],
        ),
      ),
    )
        : NotLoggedInScreen(callBack: (value) {
    setState(() {});
    }),
    ),
    );
  }
}