import 'package:flutter/material.dart';
import 'package:viga_entertainment_assignment/navigation.dart';
// import 'package:viga_entertainment_assignment/role_base.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // title: 'Flutter Demo',
      // theme: ThemeData(
      //   colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      //   // fontFamily: 'sans-serif',
      //   useMaterial3: true,
      // ),
      initialRoute: AppRoutes.rolebase,
      onGenerateRoute: AppRoutes.generateRoute,
      // home: RoleBase(),
      // home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

