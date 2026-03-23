// https://www.geeksforgeeks.org/flutter/integrating-maps-and-geolocation-services-flutter/
// https://medium.com/@nacaryusuf/usage-google-maps-geolocator-in-flutter-db601b2f5a26

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<StatefulWidget> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final MapController _mapController = MapController();
  Position? _currentlocation;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  void _getCurrentLocation() async {
    Position position = await _determinePosition();
    setState(() {
      _currentlocation = position;
    });
    print(_currentlocation.toString());
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
    return await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(accuracy: LocationAccuracy.best),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialZoom: 13.0,
          initialCenter: LatLng(
            _currentlocation!.latitude,
            _currentlocation!.longitude,
          ),
        ),
        children: _currentlocation != null
            ? [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: ['a', 'b', 'c'],
                  userAgentPackageName:
                      "party_minimap/0.0(contact: wannasut.chane@gmail.com)",
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 80.0,
                      height: 80.0,
                      point: LatLng(
                        _currentlocation!.latitude,
                        _currentlocation!.longitude,
                      ),
                      child: Icon(
                        Icons.location_on,
                        size: 48.0,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                Center(child: Text(_currentlocation.toString())),
              ]
            : [Text('No location data')],
      ),
    );
  }
}
