import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/dashboard/screens/dashboard_screen.dart';
import 'package:sixam_mart/features/media/add_media.dart';
import 'package:sixam_mart/features/media/functions.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/common/widgets/not_logged_in_screen.dart';
import 'package:video_player/video_player.dart';
import 'package:get/get.dart';

class ViewMediaScreen extends StatefulWidget {
  final SharedPreferences sharedPreferences;
  final bool fromDashboard;

  ViewMediaScreen({
    required this.sharedPreferences,
    this.fromDashboard = false,
  });

  @override
  _ViewMediaScreenState createState() => _ViewMediaScreenState();
}

class _ViewMediaScreenState extends State<ViewMediaScreen> {
  late ApiService apiService;
  List<Map<String, dynamic>>? events;
  Map<String, dynamic>? selectedEvent;
  bool isDropdownOpen = false;
  List<int> eventIds = [];
  List<String> eventNames = [];
  bool isLoading = true;
  String? selectedEventName;
  int? selectedEventIndex;
  List<dynamic> mediaList = [];
  List<dynamic> filteredMediaList = [];
  bool isFetchingMedia = false;
  int? selectedMediaIndex;
  late AuthController authController;
  String? globalUserId;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    apiService = ApiService(sharedPreferences: widget.sharedPreferences);
    _fetchUserId();
    fetchEventList();
    selectedEventIndex = 0;
    searchController.addListener(_filterMedia);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _filterMedia() {
    final query = searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredMediaList = List.from(mediaList);
      } else {
        filteredMediaList = mediaList.where((media) {
          final title = media['title']?.toString().toLowerCase() ?? '';
          return title.contains(query);
        }).toList();
      }
    });
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
    if (events != null && events!.isNotEmpty) {
      eventIds = events!.map((event) => event['id'] as int).toList();
      eventNames = events!.map((event) => event['title'] as String).toList();
      if (eventIds.isNotEmpty) {
        selectedEventIndex = 0;
        if (globalUserId != null) {
          try {
            int userId = int.parse(globalUserId!);
            fetchMediaByUserAndEvent(userId, eventIds[selectedEventIndex!]);
          } catch (e) {
            print("Error: Could not convert globalUserId to int");
          }
        } else {
          print("Error: globalUserId is null.");
        }
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchMediaByUserAndEvent(int userId, int eventId) async {
    setState(() {
      isFetchingMedia = true;
    });
    final response = await apiService.getMediaByUserAndEvent(
      userId: userId,
      eventId: eventId,
    );

    if (response != null) {
      List<dynamic> allMedia = [];
      for (var batch in response['data']) {
        for (var mediaItem in batch['media']) {
          mediaItem['title'] = mediaItem['title'];
        }
        allMedia.addAll(batch['media']);
      }
      setState(() {
        mediaList = allMedia;
        filteredMediaList = List.from(mediaList);
        isFetchingMedia = false;
      });
    } else {
      setState(() {
        mediaList = [];
        filteredMediaList = [];
        isFetchingMedia = false;
      });
    }
  }

  void _showMediaFullScreen(int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenMediaViewer(
          mediaList: filteredMediaList,
          initialIndex: index,
          sharedPreferences: widget.sharedPreferences,
        ),
      ),
    ).then((value) {
      if (value == true && globalUserId != null && selectedEventIndex != null) {
        try {
          int userId = int.parse(globalUserId!);
          fetchMediaByUserAndEvent(userId, eventIds[selectedEventIndex!]);
        } catch (e) {
          print("Error: Could not convert globalUserId to int");
        }
      }
    });
  }

  void _openAddMediaScreen() {
    if (selectedEventIndex != null &&
        selectedEventIndex! < eventIds.length &&
        selectedEventIndex! < eventNames.length) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddMediaScreen(
            sharedPreferences: widget.sharedPreferences,
            eventId: eventIds[selectedEventIndex!],
            eventName: eventNames[selectedEventIndex!],
          ),
        ),
      ).then((value) {
        if (value == true && globalUserId != null && selectedEventIndex != null) {
          try {
            int userId = int.parse(globalUserId!);
            fetchMediaByUserAndEvent(userId, eventIds[selectedEventIndex!]);
          } catch (e) {
            print("Error: Could not convert globalUserId to int");
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.grey.shade200,
      appBar: CustomAppBar(
        title: 'View Media',
        backButton: !widget.fromDashboard,
        onBackPressed: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => const DashboardScreen(pageIndex: 4),
            ),
                (route) => false,
          );
        },
      ),
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
      ) : SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Search media by name...',
                        hintStyle: TextStyle(fontSize: 14),
                        prefixIcon: Icon(Icons.search),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            searchController.clear();
                          },
                        )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  if (AuthHelper.isLoggedIn() && eventIds.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: ElevatedButton(
                        onPressed: _openAddMediaScreen,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_circle_outline_outlined, size: 18, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Add Media', style: TextStyle(fontSize: 12, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: eventNames.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedEventIndex = index;
                        searchController.clear();
                      });
                      if (globalUserId != null) {
                        try {
                          int userId = int.parse(globalUserId!);
                          fetchMediaByUserAndEvent(userId, eventIds[selectedEventIndex!]);
                        } catch (e) {
                          print("Error: Could not convert globalUserId to int");
                        }
                      }
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      decoration: BoxDecoration(
                        color: selectedEventIndex == index ? Color(0xFF0D6EFD) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          eventNames[index],
                          style: TextStyle(
                              color: selectedEventIndex == index ? Colors.white : Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            isFetchingMedia
                ? GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4),
              itemCount: 10,
              itemBuilder: (context, index) {
                return Container(color: Colors.white);
              },
            )
                : filteredMediaList.isEmpty
                ? Container(
              height: 350,
              child: Center(
                child: Text(
                  searchController.text.isEmpty
                      ? 'No media available'
                      : 'No media found for "${searchController.text}"',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            )
                : GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4),
              itemCount: filteredMediaList.length,
              itemBuilder: (context, index) {
                final media = filteredMediaList[index];
                return GestureDetector(
                  onTap: () {
                    _showMediaFullScreen(index);
                  },
                  child: Container(
                    decoration: BoxDecoration(color: Colors.white),
                    child: media['media_type'] == 'photo'
                        ? Image.network(media['image_full_url'], fit: BoxFit.cover)
                        : VideoPreviewWidget(videoUrl: media['image_full_url']),
                  ),
                );
              },
            ),
          ],
        ),
      )
          : NotLoggedInScreen(callBack: (value) {
        setState(() {});
        fetchEventList();
      }),
    );
  }
}

class VideoPreviewWidget extends StatefulWidget {
  final String videoUrl;

  VideoPreviewWidget({required this.videoUrl});

  @override
  _VideoPreviewWidgetState createState() => _VideoPreviewWidgetState();
}

class _VideoPreviewWidgetState extends State<VideoPreviewWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
          ),
          child: _controller.value.isInitialized
              ? ClipRRect(
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            ),
          )
              : Container(),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Icon(
            Icons.videocam,
            color: Colors.black.withOpacity(0.6),
            size: 16,
          ),
        ),
      ],
    );
  }
}

class VideoFullScreenWidget extends StatefulWidget {
  final String videoUrl;

  VideoFullScreenWidget({required this.videoUrl});

  @override
  _VideoFullScreenWidgetState createState() => _VideoFullScreenWidgetState();
}

class _VideoFullScreenWidgetState extends State<VideoFullScreenWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.pause();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _controller.value.isInitialized
            ? AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        )
            : Container(),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: VideoProgressIndicator(
            _controller,
            allowScrubbing: true,
            colors: VideoProgressColors(
              playedColor: Color(0xFF0D6EFD),
              bufferedColor: Colors.grey,
              backgroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class FullScreenMediaViewer extends StatefulWidget {
  final List<dynamic> mediaList;
  final int initialIndex;
  final SharedPreferences sharedPreferences;

  const FullScreenMediaViewer({
    required this.mediaList,
    required this.initialIndex,
    required this.sharedPreferences,
  });

  @override
  _FullScreenMediaViewerState createState() => _FullScreenMediaViewerState();
}

class _FullScreenMediaViewerState extends State<FullScreenMediaViewer> with WidgetsBindingObserver {
  late PageController _pageController;
  late int currentIndex;
  VideoPlayerController? _videoController;
  late ApiService apiService;
  bool _isLandscape = false;
  bool _isTitleExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: currentIndex);
    _initializeVideoController();
    apiService = ApiService(sharedPreferences: widget.sharedPreferences);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _videoController?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final orientation = WidgetsBinding.instance.window.physicalSize.aspectRatio;
    setState(() {
      _isLandscape = orientation > 1.0;
    });
    super.didChangeMetrics();
  }

  Future<void> _toggleOrientation() async {
    if (_isLandscape) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } else {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  Future<bool> _onWillPop() async {
    if (_isLandscape) {
      await _toggleOrientation();
      return false;
    }
    return true;
  }

  void _initializeVideoController() {
    if (widget.mediaList[currentIndex]['media_type'] == 'video' &&
        widget.mediaList[currentIndex]['image_full_url'] != null) {
      _videoController = VideoPlayerController.network(widget.mediaList[currentIndex]['image_full_url']!)
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
            _videoController?.play();
          }
        });
    }
  }

  Future<void> deleteMediaFromUI(String mediaId) async {
    final response = await apiService.deleteMedia(Id: mediaId);
    if (!mounted) return;

    if (response != null && response['message'] != null) {
      if (response['deleted_count'] == 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'])),
        );
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          Navigator.of(context, rootNavigator: true).pop(true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No media deleted')),
          );
          Navigator.of(context, rootNavigator: true).pop();
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete media')),
        );
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = widget.mediaList[currentIndex];
    final String? rawTitle = media['title'];
    final bool hasValidTitle = rawTitle != null && rawTitle.trim().isNotEmpty;
    final String title = hasValidTitle ? rawTitle.trim() : 'Media';
    final bool isVideo = media['media_type'] == 'video';
    final String mediaId = media['media_id'].toString();
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: IconThemeData(color: Colors.white),
          actions: [
            if (isVideo)
              IconButton(
                icon: Icon(_isLandscape ? Icons.screen_lock_portrait : Icons.screen_lock_landscape, color: Colors.white, size: 20),
                onPressed: _toggleOrientation,
              ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.white, size: 20),
              onPressed: () async {
                final shouldDelete = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text("Confirm Deletion"),
                    content: Text("Are you sure you want to delete this media?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text("Confirm"),
                      ),
                    ],
                  ),
                ) ?? false;
                if (shouldDelete && mounted) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => AlertDialog(
                      content: Row(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(width: 20),
                          Text("Deleting media..."),
                        ],
                      ),
                    ),
                  );
                  await deleteMediaFromUI(mediaId);
                }
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            PageView.builder(
              itemCount: widget.mediaList.length,
              controller: _pageController,
              physics: BouncingScrollPhysics(),
              onPageChanged: (index) {
                if (mounted) {
                  setState(() {
                    currentIndex = index;
                    _videoController?.dispose();
                    _videoController = null;
                    _initializeVideoController();
                    _isTitleExpanded = false;
                  });
                }
              },
              itemBuilder: (context, index) {
                final media = widget.mediaList[index];
                if (media['media_type'] == 'photo' && media['image_full_url'] != null) {
                  return Center(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: MediaQuery.of(context).size.height * 0.8,
                      child: PhotoView(
                        imageProvider: NetworkImage(media['image_full_url']!),
                        initialScale: PhotoViewComputedScale.contained,
                        minScale: PhotoViewComputedScale.contained * 0.5,
                        maxScale: PhotoViewComputedScale.covered * 2,
                        backgroundDecoration: BoxDecoration(color: Colors.black),
                      ),
                    ),
                  );
                } else if (media['media_type'] == 'video' && media['image_full_url'] != null) {
                  double _scale = 1.0;
                  Matrix4 _matrix = Matrix4.identity();

                  return Center(
                    child: _videoController != null && _videoController!.value.isInitialized
                        ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width,
                          height: _isLandscape
                              ? MediaQuery.of(context).size.height * 0.7
                              : MediaQuery.of(context).size.height * 0.5,
                          child: GestureDetector(
                            onTap: _toggleOrientation,
                            onScaleUpdate: (details) {
                              if (mounted) {
                                setState(() {
                                  _scale = details.scale.clamp(1.0, 3.0);
                                  _matrix = Matrix4.identity()..scale(_scale, _scale, 1.0);
                                });
                              }
                            },
                            onDoubleTap: () {
                              if (mounted) {
                                setState(() {
                                  _scale = 1.0;
                                  _matrix = Matrix4.identity();
                                });
                              }
                            },
                            child: ClipRect(
                              child: Transform(
                                transform: _matrix,
                                alignment: Alignment.center,
                                child: VideoPlayer(_videoController!),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                        : CircularProgressIndicator(),
                  );
                }
                return SizedBox.shrink();
              },
            ),
            if (hasValidTitle)
              Positioned(
                bottom: isVideo ? 100 : 20,
                left: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    if (mounted) {
                      setState(() {
                        _isTitleExpanded = !_isTitleExpanded;
                      });
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: Colors.black.withOpacity(0.5),
                    child: AnimatedCrossFade(
                      duration: Duration(milliseconds: 200),
                      firstChild: Text(
                        title,
                        style: TextStyle(color: Colors.white, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      secondChild: Text(
                        title,
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      crossFadeState: _isTitleExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    ),
                  ),
                ),
              ),
            if (_videoController != null && _videoController!.value.isInitialized && isVideo)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanDown: (details) {
                              _seekToPosition(details.localPosition.dx, constraints.maxWidth);
                            },
                            onPanUpdate: (details) {
                              _seekToPosition(details.localPosition.dx, constraints.maxWidth);
                            },
                            child: Container(
                              height: 30,
                              alignment: Alignment.center,
                              child: VideoProgressIndicator(
                                _videoController!,
                                allowScrubbing: false,
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                colors: VideoProgressColors(
                                  playedColor: Colors.blue,
                                  bufferedColor: Colors.grey[300]!,
                                  backgroundColor: Colors.grey[600]!,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(Icons.replay_5, color: Colors.white, size: 30),
                            onPressed: () {
                              _videoController!.seekTo(
                                  _videoController!.value.position - Duration(seconds: 5));
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 36,
                            ),
                            onPressed: () {
                              if (mounted) {
                                setState(() {
                                  _videoController!.value.isPlaying
                                      ? _videoController!.pause()
                                      : _videoController!.play();
                                });
                              }
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.forward_5, color: Colors.white, size: 30),
                            onPressed: () {
                              _videoController!.seekTo(
                                  _videoController!.value.position + Duration(seconds: 5));
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _seekToPosition(double dx, double width) {
    if (_videoController != null && _videoController!.value.isInitialized) {
      final relative = dx.clamp(0.0, width) / width;
      final position = _videoController!.value.duration * relative;
      _videoController!.seekTo(position);
    }
  }
}