import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'map_screen.dart';
// reference code materials
// https://pub.dev/packages/geolocator
// https://www.dhiwise.com/post/maximizing-user-experience-integrating-flutter-geolocator
// https://medium.com/unitechie/flutter-tutorial-geolocation-1d07808f1bb9

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      // home: LocationDisplayWidget()
      home: MapScreen()
    );
  }
}


// ---- test ----
class LocationDisplayWidget extends StatefulWidget {
  const LocationDisplayWidget({super.key});

  @override
  State<StatefulWidget> createState() => _LocationDisplayState();
}

class _LocationDisplayState extends State<LocationDisplayWidget> {
  Position? _position;

  void _getCurrentLocation() async {
    Position position = await _determinePosition();
    setState(() {
      _position = position;
    });
  }

  Future<Position> _determinePosition() async {
    LocationPermission permission;
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    } // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition(locationSettings: LocationSettings(accuracy: LocationAccuracy.best));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _position != null
            ? Text('Current Location: ${_position.toString()}')
            : Text('No location data'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }
}
