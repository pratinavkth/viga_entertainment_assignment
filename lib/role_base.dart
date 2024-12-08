import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class RoleBase extends StatelessWidget {
  final FlutterSecureStorage storage = FlutterSecureStorage();

  Future<void> saveRole(String role) async {
    await storage.write(key: 'role', value: role);
    print('Role saved : $role');
  }

  @override
  Widget build(BuildContext context) {
    final ScreenWidth = MediaQuery.of(context).size.width;
    final ScreenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: ScreenHeight * 0.2),
            const Text(
              "Select the Role",
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ScreenHeight * 0.02),
            ElevatedButton(
              style: ButtonStyle(
                minimumSize: WidgetStateProperty.all(
                    Size(ScreenWidth * 0.8, ScreenHeight * 0.05)),
                backgroundColor: WidgetStateProperty.all(Colors.blue),
              ),
              onPressed: () async {
                saveRole('Director');
                Navigator.pushNamed(context, '/videoselection');
              },
              child: const Text(
                'Director',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: ScreenHeight * 0.02),
            ElevatedButton(
              style: ButtonStyle(
                minimumSize: WidgetStateProperty.all(
                    Size(ScreenWidth * 0.8, ScreenHeight * 0.05)),
                backgroundColor: WidgetStateProperty.all(Colors.blue),
              ),
              onPressed: () async {
                saveRole('Artist');
                Navigator.pushNamed(context, '/artistvideoselection');
              },
              child: const Text(
                'Artist',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
