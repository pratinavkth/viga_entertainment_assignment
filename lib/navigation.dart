import 'package:flutter/material.dart';
import 'package:viga_entertainment_assignment/artist.dart';
import 'package:viga_entertainment_assignment/artist_video_selection.dart';
import 'package:viga_entertainment_assignment/director.dart';
import 'package:viga_entertainment_assignment/video_select_screen.dart';
import 'role_base.dart';
class AppRoutes{
  static const String rolebase = '/rolebase';
  static const String videoselection = '/videoselection';
  static const String artistvideoselection = '/artistvideoselection';
  static const String director = '/director';
  static const String artist = '/artist';

static Route<dynamic> generateRoute(RouteSettings settings){
  switch(settings.name){
    case rolebase:
     return MaterialPageRoute(builder: (context)=>RoleBase());
    case videoselection:
     return MaterialPageRoute(builder: (context)=>VideoSelectScreen());
    case artistvideoselection:
      return MaterialPageRoute(builder: (context)=>ArtistVideoSelection());
    
    case director:
    final args = settings.arguments as Map<String, dynamic>?;
    if(args == null || !args.containsKey('videoType') || !args.containsKey('videoId')){
      return MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(
              child: Text('No arguments provided for Director'),
            ),
          ),
        );
    }
    return MaterialPageRoute(builder: (context)=>Director(
      videoType: args['videoType'],
      videoId: args['videoId'],
    ));

    case artist:
    final args = settings.arguments as Map<String, dynamic>?;
    if(args == null || !args.containsKey('videoType') || !args.containsKey('videoId')){
      return MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(
              child: Text('No arguments provided for Artist'),
            ),
          ),
        );
    }
    return MaterialPageRoute(builder: (context)=>Artist(
      videoType: args['videoType'],
      videoId: args['videoId'],
    ));

    default:
    return MaterialPageRoute(builder: (context)=>Scaffold(
      body: Center(
        child: Text('No route defined for ${settings.name}'),
      ),
    ));
  }
}
}