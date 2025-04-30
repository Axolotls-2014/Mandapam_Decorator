import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/features/media/functions.dart';
import 'package:sixam_mart/features/media/view_media.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/common/widgets/not_logged_in_screen.dart';

class BatchListScreen extends StatefulWidget {
  final SharedPreferences sharedPreferences;
  final bool fromDashboard;
  BatchListScreen({required this.sharedPreferences, this.fromDashboard = false});

  @override
  _BatchListScreenState createState() => _BatchListScreenState();
}

class _BatchListScreenState extends State<BatchListScreen> {
  late ApiService apiService;
  List<dynamic>? batches;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    apiService = ApiService(sharedPreferences: widget.sharedPreferences);
    fetchBatches();
  }

  Future<void> fetchBatches() async {
    final response = await apiService.getMediaByUserAndEvent(userId: 3, batchId: null);
    if (response != null && response['data'] != null) {
      setState(() {
        batches = response['data'];
        isLoading = false;
      });
    } else {
      setState(() {
        batches = [];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: CustomAppBar(title: 'View Media', backButton: widget.fromDashboard ? false : true),
      body: AuthHelper.isLoggedIn()
          ? isLoading
          ? _buildShimmerEffect()
          : batches!.isEmpty
          ? Center(child: Text('No batch found'))
          : ListView.builder(
        itemCount: batches!.length,
        itemBuilder: (context, index) {
          final batch = batches![index];
          return GestureDetector(
            onTap: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) => ViewMediaScreen(batchId: batch['batch_id'], sharedPreferences: prefs),
              //   ),
              // );
            },
            child: Container(
              margin: EdgeInsets.all(8),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Batch ID : ${batch['batch_id']}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        },
      )
          : NotLoggedInScreen(callBack: (value) {
        setState(() {});
      }),
    );
  }

  Widget _buildShimmerEffect() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.all(8),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                  width: 100,
                  height: 16,
                  color: Colors.grey[300]),
              // SizedBox(height: 8),
              // Container(
              //     width: 150,
              //     height: 14,
              //     color: Colors.grey[300]),
            ],
          ),
        );
      },
    );
  }
}
