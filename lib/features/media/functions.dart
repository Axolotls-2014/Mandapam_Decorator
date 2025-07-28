import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/src/platform/platform.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';

class ApiService {
  final SharedPreferences sharedPreferences;
  ApiService({required this.sharedPreferences});

  Future<dynamic> addMedia({
    required int eventId,
    required int userId,
    required Map<String, dynamic> media,
  }) async {
    final token = sharedPreferences.getString(AppConstants.token);
    const String url = 'https://mandapam.co/api/v1/events/addMedia';

    final Map<String, String> headers = {
      'Authorization': 'Bearer $token',
    };

    var request = http.MultipartRequest('POST', Uri.parse(url));
    request.headers.addAll(headers);

    request.fields['event_id'] = eventId.toString();
    request.fields['user_id'] = userId.toString();
    if (media.containsKey('title')) {
      request.fields['media[0][title]'] = media['title'].toString();
    }

    for (var entry in media.entries) {
      if (entry.key.contains('file_path') && entry.value is String) {
        request.files.add(await http.MultipartFile.fromPath(entry.key, entry.value));
      } else {
        request.fields[entry.key] = entry.value.toString();
      }
    }

    print('URL: $url');
    print('Headers: $headers');
    print('Request Fields: ${request.fields}');
    print('Request Files: ${request.files.map((f) => f.filename).toList()}');

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    print('Response Status Code: ${response.statusCode}');
    print('Response Body: $responseBody');

    if (response.statusCode == 200) {
      return jsonDecode(responseBody);
    } else {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> fetchEvents() async {
    String? deviceToken = sharedPreferences.getString(AppConstants.token);

    if (deviceToken == null) {
      print("Error: Device Token is null");
      return null;
    }

    final url = Uri.parse('${AppConstants.baseUrl}/api/v1/events');
    final headers = {'Authorization': 'Bearer $deviceToken'};

    print("Request URL: $url");
    print("Request Headers: $headers");

    final response = await http.get(url, headers: headers);

    print("Response Status Code: ${response.statusCode}");
    print("Response Body: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("Parsed Response Data: $data");

      if (data['Events'] != null) {
        final List<Map<String, dynamic>> eventsList =
        List<Map<String, dynamic>>.from(
          data['Events']
              .map((event) => {'id': event['id'], 'title': event['title']}),
        );

        print("Extracted Events List: $eventsList");
        return eventsList;
      }
    }
    return null;
  }


  Future<dynamic> getMediaByUserAndEvent({
    required int userId,
    int? eventId,
    int? batchId,
  }) async {
    final token = sharedPreferences.getString(AppConstants.token);
    const String url =
        'https://mandapam.co/api/v1/events/getMediaByUserAndEvent';

    String? latitude;
    String? longitude;
    String? zoneId;

    if (sharedPreferences.containsKey(AppConstants.userAddress)) {
      try {
        AddressModel addressModel = AddressModel.fromJson(
          jsonDecode(sharedPreferences.getString(AppConstants.userAddress)!),
        );
        latitude = addressModel.latitude ?? '';
        longitude = addressModel.longitude ?? '';
        if (addressModel.zoneIds != null && addressModel.zoneIds!.isNotEmpty) {
          zoneId = addressModel.zoneIds!.first.toString();
        }
      } catch (_) {}
    }

    final Map<String, String> headers = {
      'latitude': latitude ?? '',
      'longitude': longitude ?? '',
      'zoneId': zoneId ?? '',
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    final Map<String, dynamic> body = {
      'user_id': userId.toString(),
    };

    if (eventId != null) {
      body['event_id'] = eventId.toString();
    }

    print('URL: $url');
    print('Headers: $headers');
    print('Request Body: $body');

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );

    print('Response Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return null;
    }
  }


  // Future<dynamic> getMediaByUserAndEvent({
  //   required int userId,
  //   int? eventId,
  //   int? batchId,
  // }) async {
  //   final token = sharedPreferences.getString(AppConstants.token);
  //   const String url =
  //       'https://mandapam.co/api/v1/events/getMediaByUserAndEvent';
  //   final Map<String, String> headers = {
  //     'Authorization': 'Bearer $token',
  //   };
  //
  //   final Map<String, dynamic> body = {
  //     'user_id': userId.toString(),
  //   };
  //
  //   if (eventId != null) {
  //     body['event_id'] = eventId.toString();
  //   }
  //
  //   print('URL: $url');
  //   print('Headers: $headers');
  //   print('Request Body: $body');
  //
  //   final response = await http.post(
  //     Uri.parse(url),
  //     headers: headers,
  //     body: body,
  //   );
  //
  //   print('Response Status Code: ${response.statusCode}');
  //   print('Response Body: ${response.body}');
  //
  //   if (response.statusCode == 200) {
  //     return jsonDecode(response.body);
  //   } else {
  //     return null;
  //   }
  // }

  Future<String?> getDeviceToken() async {
    try {
      if (!GetPlatform.isWeb) {
        String? deviceToken = await FirebaseMessaging.instance.getToken();
        if (deviceToken != null && kDebugMode) {
          print("Device Token: $deviceToken");
        }
        return deviceToken;
      }
    } catch (e) {
      print("Error: Failed to get device token - $e");
    }
    return null;
  }

  Future<dynamic> deleteMedia({required String Id}) async {
    final token = sharedPreferences.getString(AppConstants.token);
    const String url = 'https://mandapam.co/api/v1/events/delete-media-by-batch';
    final Map<String, String> headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    final Map<String, dynamic> body = {
      'id': Id,
    };

    print('URL: $url');
    print('Headers: $headers');
    print('Request Body: $body');

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );

    print('Response Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return null;
    }
  }

  Future<Map<String, String>?> getAppVersion() async {
    const String url = 'https://mandapam.co/api/v1/auth/app_version';

    try {
      final response = await http.get(Uri.parse(url));

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['version'] != null) {
          final Map<String, String> versionMap = {};
          for (var version in data['version']) {
            versionMap[version['key']] = version['value'];
          }
          print('App Versions: $versionMap');
          return versionMap;
        }
      }
    } catch (e) {
      print("Error fetching app version: $e");
    }
    return null;
  }


}
