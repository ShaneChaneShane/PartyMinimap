// https://www.geeksforgeeks.org/flutter/how-to-get-users-current-location-on-google-maps-in-flutter/
// https://fernandoptr.medium.com/how-to-get-users-current-location-address-in-flutter-geolocator-geocoding-be563ad6f66a
// https://stackoverflow.com/questions/56597739/how-to-customize-google-maps-marker-icon-in-flutter

import 'package:flutter/material.dart';
import 'map_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // title of the app
      title: 'Party Minimap',
      debugShowCheckedModeBanner: true,
      theme: ThemeData(
        // theme
        primarySwatch: Colors.purple,
      ),
      // First screen
      home: MapView(),
    );
  }
}
