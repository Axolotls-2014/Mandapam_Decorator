import 'package:flutter/material.dart';
import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
//import 'package:file_picker/file_picker.dart';

class SubmitAssignmentController extends GetxController {
  final ImagePicker _picker = ImagePicker();

  Rx<File?> file = Rx<File?>(null);
  RxString fileName = ''.obs;

  Future<void> pickFile(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 75,
    );

    if (pickedFile != null) {
      file.value = File(pickedFile.path);
      fileName.value = pickedFile.name;
    }
  }

  Future<void> pickDocumentFromFileManager() async {
    // FilePickerResult? result = await FilePicker.platform.pickFiles(
    //   type: FileType.any,
    // );

    // if (result != null && result.files.single.path != null) {
    //   file.value = File(result.files.single.path!);
    //   fileName.value = result.files.single.name;
    // }
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
                  pickFile(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.teal),
                title: const Text("Choose from Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  pickFile(ImageSource.gallery);
                },
              ),
              // ListTile(
              //   leading:
              //       const Icon(Icons.insert_drive_file, color: Colors.blue),
              //   title: const Text("Choose from Files"),
              //   onTap: () {
              //     Navigator.pop(context);
              //     pickDocumentFromFileManager();
              //   },
              // ),
            ],
          ),
        );
      },
    );
  }
}
