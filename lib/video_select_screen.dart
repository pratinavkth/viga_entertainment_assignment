import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:viga_entertainment_assignment/navigation.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VideoSelectScreen extends StatefulWidget {
  const VideoSelectScreen({Key? key}) : super(key: key);
  @override
  State<VideoSelectScreen> createState() => VideoSelectScreenState();
}

class VideoSelectScreenState extends State<VideoSelectScreen> {
  // for adding the local video
  Future<void> selectLocalVideo() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null && result.files.single.path != null) {
      String localvideoPath = result.files.single.path!;
      Navigator.pushNamed(context, '/director', arguments: {
        'videoType': 'local',
        'videoId': localvideoPath,
      });
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No Video Selected')));
    }
  }

  Future<void> youtubeVideo() async {
    String? youtubeLink = await showDialog<String>(
      context: context,
      builder: (context) {
        String link = '';
        return AlertDialog(
          title: const Text('Enter Youtube Link'),
          content: TextField(
            onChanged: (value) {
              link = value;
            },
            decoration:
                const InputDecoration(hintText: 'Paste YouTube Link Here'),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('cancel')),
            TextButton(
              onPressed: () => Navigator.pop(context, link),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (youtubeLink != null && youtubeLink.isNotEmpty) {
      // Extract YouTube video ID from the link
      String? videoId = YoutubePlayer.convertUrlToId(youtubeLink);
      if (videoId != null) {
        Navigator.pushNamed(
          context,
          '/director',
          arguments: {
            'videoType': 'network',
            'videoId': videoId,
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid YouTube link')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ScreenHeight = MediaQuery.of(context).size.height;
    final ScreenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            SizedBox(height: ScreenHeight * 0.2),
            ElevatedButton(
                onPressed: selectLocalVideo,
                style: ButtonStyle(
                  minimumSize: WidgetStateProperty.all(const Size(10, 2)),
                  backgroundColor: WidgetStateProperty.all(Colors.blue),
                ),
                child: const Text(
                  'Select Local Video',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                )),
            ElevatedButton(
                onPressed: () {
                  youtubeVideo();
                },
                style: ButtonStyle(
                  minimumSize: WidgetStateProperty.all(const Size(10, 2)),
                  backgroundColor: WidgetStateProperty.all(Colors.blue),
                ),
                child: const Text(
                  'Select youtube Video',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
