import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:path/path.dart' as path;

class Artist extends StatefulWidget {
  final String videoType;
  final String videoId;

  const Artist({Key? key, required this.videoId, required this.videoType})
      : super(key: key);

  @override
  State<Artist> createState() => _ArtistState();
}

class _ArtistState extends State<Artist> {
  final storage = FlutterSecureStorage();
  late VideoPlayerController localController;
  late YoutubePlayerController networkController;
  List<dynamic> comments = []; // List to store comments

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => RoleCheck());
    print("videoId${widget.videoId}");
    loadVideoData();
    loadComments(); // Load comments when screen initializes
  }

  // Role check to ensure only Artists can access this screen
  Future<String?> getRole() async {
    return await storage.read(key: 'role');
  }

  void RoleCheck() async {
    String? role = await getRole();
    if (role != 'Artist') {
      Navigator.pushNamed(context, '/rolebase');
    }
  }

  // Load the video based on its type
  void loadVideoData() {
    if (widget.videoType == 'local') {
      localController =
          VideoPlayerController.networkUrl(Uri.parse(widget.videoId));
      localController.initialize().then((_) => setState(() {}));
    } else if (widget.videoType == 'network') {
      networkController = YoutubePlayerController(
        initialVideoId: widget.videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          controlsVisibleAtStart: false,
          hideControls: true,
        ),
      );
    } else {
      throw UnsupportedError('Unsupported video type: ${widget.videoType}');
    }
  }

  // Load comments from secure storage
  Future<void> loadComments() async {
    String videoFileName =
        path.basename(widget.videoId); // Extract the file name
    print("Extracted file name: $videoFileName");
    String key = getStorageKey(widget.videoId, widget.videoType);
    String? commentsJson = await storage.read(key: 'comments');
    print("commentsJson Retrived$commentsJson");
    if (commentsJson != null) {
      try {
        print("commentsJson : $commentsJson");
        var decodedData = jsonDecode(commentsJson);
        print("decodedData : $decodedData");
        if (decodedData is Map<String, dynamic>) {
          print("Available keys: ${decodedData.keys}");
          print("videoId: ${widget.videoId}");
          print("widgetvideo id :${decodedData[videoFileName]}");
          List<dynamic>? loadedcomments = decodedData[videoFileName];
          print("loadedcomments : $loadedcomments");
          if (loadedcomments != null) {
            setState(() {
              comments = loadedcomments
                  .where(
                      (comment) => comment['role']?.toLowerCase() == 'director')
                  .toList();
              print("comments of the director : $comments");
            });
          } else {
            setState(() {
              comments = [];
            });
          }
        } else {
          print("Unexpected data type: ${decodedData.runtimeType}");

          setState(() {
            comments = [];
          });
        }
      } catch (e) {
        print('Error parsing comments: $e');
        setState(() {
          comments = []; // Default to an empty list if parsing fails
        });
      }
    } else {
      setState(() {
        comments = [];
      });
    }
  }

  // Save updated comments to secure storage
  Future<void> saveComments() async {
    String key = getStorageKey(widget.videoId, widget.videoType);
    Map<String, dynamic> allComments = {};

    String? existingData = await storage.read(key: key);
    if (existingData != null) {
      allComments = jsonDecode(existingData);
    }
    // Update or create comments for the current video ID
    allComments[widget.videoId] = comments;

    await storage.write(key: 'comments', value: jsonEncode(allComments));
    print("Saved comments: ${jsonEncode(allComments)}");
  }

  // Add a reply to a director's comment
  Future<void> addReply(
      Map<String, dynamic> parentComment, String replyText) async {
    Map<String, dynamic> reply = {
      'role': 'Artist',
      'commentText': replyText,
      'videoTimeStamp': 0, // Replies do not have specific timestamps
      'videoId': widget.videoId,
      'replies': [],
    };

    setState(() {
      parentComment['replies'] = parentComment['replies'] ?? [];
      parentComment['replies'].add(reply);
    });

    await saveComments();
  }

  // Get a unique key for storage
  String getStorageKey(String videoId, String videoType) {
    return 'comments_${videoType}_$videoId';
  }

  // Build the UI for each comment (including replies)
  Widget buildCommentTree(Map<String, dynamic> comment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text('${comment['role']}: ${comment['commentText']}'),
          trailing: comment['role'] == 'Director'
              ? IconButton(
                  icon: const Icon(Icons.reply),
                  onPressed: () {
                    showReplyDialog(context, comment);
                  },
                )
              : null,
        ),
        if (comment['replies'] != null)
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Column(
              children: (comment['replies'] as List<dynamic>)
                  .map((reply) => buildCommentTree(reply))
                  .toList(),
            ),
          ),
      ],
    );
  }

  // Show dialog to reply to a comment
  void showReplyDialog(
      BuildContext context, Map<String, dynamic> parentComment) {
    final TextEditingController replyController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reply to Comment'),
        content: TextField(
          controller: replyController,
          decoration: const InputDecoration(hintText: 'Enter your reply'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (replyController.text.trim().isNotEmpty) {
                await addReply(parentComment, replyController.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Reply'),
          ),
        ],
      ),
    );
  }

  void forward() {
    final currentPosition = localController.value.position;
    final duration = localController.value.duration;
    final newPosition = currentPosition + const Duration(seconds: 10);

    if (newPosition < duration) {
      localController.seekTo(newPosition);
    } else {
      localController.seekTo(duration);
    }
  }

  void backward() {
    final currentPosition = localController.value.position;
    // final duration = localController.value.duration;
    final newPosition = currentPosition - const Duration(seconds: 10);

    if (newPosition > Duration.zero) {
      localController.seekTo(newPosition);
    } else {
      localController.seekTo(Duration.zero);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final TextEditingController replyController = TextEditingController();

    return Scaffold(
      body: Center(
        child: Column(
          children: [
            SizedBox(height: screenHeight * 0.1),
            Container(
              margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black),
              ),
              height: screenHeight * 0.3,
              width: screenWidth * 0.9,
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: widget.videoType == 'local'
                      ? localController.value.isInitialized
                          ? FittedBox(
                              fit: BoxFit.fill,
                              child: SizedBox(
                                width: localController.value.size.width,
                                height: localController.value.size.height,
                                child: VideoPlayer(localController),
                              ),
                            )
                          : Center(
                              child: Column(
                                children: [
                                  Text('Loading...'),
                                ],
                              ),
                            )
                      : YoutubePlayer(controller: networkController)),
            ),
            if (widget.videoType == 'local')
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: backward,
                    icon: Icon(Icons.replay_10),
                    tooltip: 'Backward 10s',
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        localController.value.isPlaying
                            ? localController.pause()
                            : localController.play();
                      });
                    },
                    icon: Icon(
                      localController.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                    ),
                    tooltip: 'Play/Pause',
                  ),
                  IconButton(
                    onPressed: forward,
                    icon: Icon(Icons.forward_10),
                    tooltip: 'Forward 10s',
                  ),
                ],
              ),
            SizedBox(height: screenHeight * 0.05),
            Expanded(
              child: ListView.builder(
                itemCount: comments.length,
                itemBuilder: (context, index) =>
                    buildCommentTree(comments[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
