import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:path/path.dart' as path;

class Director extends StatefulWidget {
  final String videoType;
  final String videoId;
  const Director({Key? key, required this.videoId, required this.videoType})
      : super(key: key);

  @override
  State<Director> createState() => _DirectorState();
}

class _DirectorState extends State<Director> {
  final storage = FlutterSecureStorage();
  final TextEditingController _commentController = TextEditingController();
  late VideoPlayerController localcontroller;
  late YoutubePlayerController networkcontroller;
  bool showControls = true;
  Timer? hideControlsTimer;

  String currentTime = '00:00';
  String totalTime = '00:00';

  @override
  // for checking weather the role is director or not
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => RoleCheck());
    loadVideoData();
    if (widget.videoType == 'local') {
      localcontroller.addListener(checkTimer);
    }
  }

  @override
  void dispose() {
    if (widget.videoType == 'local') {
      localcontroller.dispose();
    } else if (widget.videoType == 'network') {
      networkcontroller.dispose();
    }
    super.dispose();
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  Future<String?> getRole() async {
    return await storage.read(key: 'role');
  }

  void RoleCheck() async {
    String? role = await getRole();
    if (role != 'Director') {
      Navigator.pushNamed(context, '/rolebase');
    }
  }

  // for videostriming
  void loadVideoData() {
    if (widget.videoType == 'local') {
      localcontroller =
          VideoPlayerController.networkUrl(Uri.parse(widget.videoId));
      localcontroller.initialize().then((_) => setState(() {}));
      localcontroller.addListener(checkTimer);
    } else if (widget.videoType == 'network') {
      networkcontroller = YoutubePlayerController(
        initialVideoId: widget.videoId,
        flags: YoutubePlayerFlags(
          autoPlay: false,
          controlsVisibleAtStart: true,
          hideControls: false,
        ),
      );
    } else {
      throw UnsupportedError('Unsupported video type: ${widget.videoType}');
    }
  }

  void checkTimer() {
    setState(() {
      if (localcontroller.value.isInitialized) {
        currentTime = formatDuration(localcontroller.value.position);
        totalTime = formatDuration(localcontroller.value.duration);
      }
    });
  }

  void forward() {
    final currentPosition = localcontroller.value.position;
    final duration = localcontroller.value.duration;
    final newPosition = currentPosition + const Duration(seconds: 10);

    if (newPosition < duration) {
      localcontroller.seekTo(newPosition);
    } else {
      localcontroller.seekTo(duration);
    }
  }

  void backward() {
    final currentPosition = localcontroller.value.position;
    final newPosition = currentPosition - const Duration(seconds: 10);

    if (newPosition > Duration.zero) {
      localcontroller.seekTo(newPosition);
    } else {
      localcontroller.seekTo(Duration.zero);
    }
  }

  void debugStorage() async {
    String? commentsJson = await storage.read(key: 'comments');
    if (commentsJson == null) {
      print('No comments saved in storage.');
    } else {
      print('Saved Comments JSON: $commentsJson');
    }
  }

  Future<void> addComment(String text) async {
    if (text.trim().isEmpty) return;
    Comment newComment = Comment(
      commentText: text,
      role: 'Director', // Replace with actual user name if available
      videoTimeStamp: widget.videoType == 'local'
          ? localcontroller.value.position
          : Duration.zero,
      videoId: widget.videoId,
    );
    await saveComment('Director', newComment.commentText,
        newComment.videoTimeStamp, widget.videoId);
    _commentController.clear();
    reloadComments();
  }

  Future<void> clearSecureStorage() async {
    await storage.deleteAll();
    print("Secure storage cleared.");
  }

  String getStorageKey(String videoId, String videoType) {
    return videoType == 'local'
        ? Uri.parse(videoId).pathSegments.last
        : videoId;
  }

  // for saving the comment
  Future<void> saveComment(String role, String commentText,
      Duration videoTimeStamp, String videoId) async {
    String key = getStorageKey(videoId, widget.videoType);
    String? commentsJson = await storage.read(key: 'comments');
    print('Raw comments JSON for key $key: $commentsJson');

    Map<String, dynamic> commentsMap = commentsJson != null
        ? jsonDecode(commentsJson) as Map<String, dynamic>
        : {};

    List<dynamic> commentsList = commentsMap[key] ?? [];

    commentsList.add({
      'role': role,
      'commentText': commentText,
      'videoTimeStamp': videoTimeStamp.inSeconds,
      'videoId': key,
    });

    commentsMap[key] = commentsList;

    await storage.write(key: 'comments', value: jsonEncode(commentsMap));
    print('updated comments Saved Comments: ${jsonEncode(commentsMap)}');
    debugStorage();
    reloadComments();
    setState(() {});
  }

  String normalizeVideoId(String videoId) {
    //// Extract only the file name part
    if (widget.videoType == 'local') {
      return Uri.parse(videoId).pathSegments.last;
    }
    return videoId;
  }

  //  for getting the normalized key
  String getNormalizedKey(String videoId) {
    return widget.videoType == 'local'
        ? path.basename(videoId) // Extract file name
        : videoId; // Use full videoId for network videos
  }

  Future<List<Comment>> loadComments(String videoId) async {
    try {
      String key = getNormalizedKey(videoId);
      print('Loading comments for key $key');

      String? commentsJson = await storage.read(key: 'comments');
      print('Comments JSON for key $key: $commentsJson');

      if (commentsJson == null) {
        return [];
      }

      Map<String, dynamic> commentsMap = jsonDecode(commentsJson);
      print('Comments map for key $key: $commentsMap');
      print('Available keys in commentsMap: ${commentsMap.keys}');
      List<dynamic> commentsList = commentsMap[key] ?? [];
      print('Comments list for videofilename : $commentsList');

      return commentsList.map((json) => Comment.fromJson(json)).toList();
    } catch (e) {
      print('Error loading comments: $e');
      return [];
    }
  }

  void reloadComments() {
    setState(() {
      loadComments(widget.videoId);
    });
  }

  void addreplyComment(String commentId, String replyText) async {
    if (replyText.trim().isEmpty) return;

    String? commentsJson = await storage.read(key: 'comments');
    Map<String, dynamic> commentsMap = commentsJson != null
        ? jsonDecode(commentsJson) as Map<String, dynamic>
        : {};
    String key = getNormalizedKey(widget.videoId);
    List<dynamic> commentsList = commentsMap[key] ?? [];
    // Comment? parentComment;
    for (var comment in commentsList) {
      if (comment['videoId'] == commentId) {
        Comment parentComment = Comment.fromJson(comment);
        // if (parentComment != null) {
        Comment newReply = Comment(
          role: 'Artist',
          commentText: replyText,
          videoTimeStamp: widget.videoType == 'local'
              ? localcontroller.value.position
              : Duration.zero,
          videoId: widget.videoId,
        );

        parentComment.replies.add(newReply);
        int index = commentsList.indexOf(comment);
        commentsList[index] = parentComment.toJson();
        commentsMap[key] = commentsList;
        await storage.write(key: 'comments', value: jsonEncode(commentsMap));
        // reloadComments();
        setState(() {});
        return;
        // }
      }
    }
  }

  Widget buildCommentItem(Comment comment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text('${comment.role}: ${comment.commentText}'),
          subtitle: Text(
              'Timestamp: ${comment.videoTimeStamp.inMinutes}:${comment.videoTimeStamp.inSeconds % 60}'),
        ),
        if (comment.replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Column(
              children: comment.replies.map(buildCommentItem).toList(),
            ),
          ),
      ],
    );
  }

  // for displaying the comments
  Widget commentList() {
    return FutureBuilder<List<Comment>>(
      future: loadComments(widget.videoId),
      builder: (context, snapshot) {
        print('Comments from loadComments: ${snapshot.data}');

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: SizedBox(
              height: 50,
              width: 50,
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading comments: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          print('No comments found');
          return Center(
            child: SizedBox(
              height: 100,
              width: 190,
              child: Column(
                children: [
                  Text('No comments found.'),
                  ElevatedButton(
                    onPressed: reloadComments,
                    child: Text('Reload Comments'),
                  ),
                ],
              ), // Placeholder text
            ),
          );
        }

        final comments = snapshot.data!;
        // snapshot.data??[];
        print(
            'comments to display: ${comments.map((c) => c.commentText).toList()}');

        return ListView(
          children: comments.map(buildCommentItem).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: screenHeight * 0.1,
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Container(
                  height: screenHeight * 0.3,
                  width: screenWidth * 0.9,
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: widget.videoType == 'local'
                          ? localcontroller.value.isInitialized
                              ? FittedBox(
                                  fit: BoxFit.fill,
                                  // aspectRatio: localcontroller.value.aspectRatio,
                                  child: SizedBox(
                                    width: localcontroller.value.size.width,
                                    height: localcontroller.value.size.height,
                                    child: VideoPlayer(localcontroller),
                                  ),
                                )
                              : Center(
                                  child: Column(
                                    children: [
                                      Text('Loading...'),
                                    ],
                                  ),
                                )
                          : YoutubePlayer(controller: networkcontroller)),
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
                            localcontroller.value.isPlaying
                                ? localcontroller.pause()
                                : localcontroller.play();
                          });
                        },
                        icon: Icon(
                          localcontroller.value.isPlaying
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
              ],
            ),
          ),
          SizedBox(
            height: screenHeight * 0.02,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => addComment(_commentController.text),
                  child: Text("Post"),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await clearSecureStorage();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Secure storage has been cleared.")),
              );
            },
            child: Text("Clear Secure Storage"),
          ),
          Expanded(
            // height: screenHeight*0.4,
            child: commentList(),
          ),
        ],
      ),
      // ),
    );
  }
}

class Comment {
  final String role;
  final String commentText;
  final Duration videoTimeStamp;
  final String videoId;
  final List<Comment> replies; // Add replies to comment

  Comment(
      {required this.role,
      required this.commentText,
      required this.videoTimeStamp,
      required this.videoId,
      this.replies = const <Comment>[]
      // this.replyComments
      });
  Map<String, dynamic> toJson() => {
        'role': role,
        'commentText': commentText,
        'videoTimeStamp': videoTimeStamp.inSeconds,
        'videoId': videoId,
        'replies': replies.map((r) => r.toJson()).toList(),
      };

  factory Comment.fromJson(Map<String, dynamic> json) {
    // Validate and handle any potential issues with null or unexpected data
    if (json['role'] == null ||
        json['commentText'] == null ||
        json['videoTimeStamp'] == null ||
        // json['replies'] == null ||
        json['videoId'] == null) {
      throw ArgumentError('Invalid JSON: Missing required fields.');
    }

    // Ensure videoTimeStamp is parsed correctly
    final int? timeStampInSeconds = json['videoTimeStamp'] is int
        ? json['videoTimeStamp']
        : int.tryParse(json['videoTimeStamp'].toString());

    if (timeStampInSeconds == null) {
      throw ArgumentError(
          'Invalid JSON: videoTimeStamp must be an integer or convertible to an integer.');
    }
    List<Comment> replyList = [];
    if (json['replies'] != null) {
      replyList = (json['replies'] as List<dynamic>)
          .map((replyJson) => Comment.fromJson(replyJson))
          .toList();
    }

    return Comment(
      role: json['role'],
      commentText: json['commentText'],
      videoTimeStamp: Duration(seconds: timeStampInSeconds),
      videoId: json['videoId'],
      replies: replyList,
    );
  }
}
