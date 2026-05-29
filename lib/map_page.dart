import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:party_minimap/location.dart';
import 'dart:ui' as ui;
import 'utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

class MapModel {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<LatLng>> getFriendsLocationsStream() {
    try {
      return _db
          .collection("testLocation")
          .withConverter(
            fromFirestore: Location.fromFirestore,
            toFirestore: (Location location, _) => location.toFirestore(),
          )
          .snapshots()
          .map((snapshot) {
            debugPrint("Successfully get testLocation from firestore");
            return snapshot.docs
                .map((docSnapshot) {
                  debugPrint("${docSnapshot.id} => ${docSnapshot.data()}");
                  Location location = docSnapshot.data();
                  if (location.pos?.latitude != null &&
                      location.pos?.longitude != null) {
                    debugPrint(
                      "Adding friends' location succeeded. The location from firestore is $location",
                    );
                    return LatLng(
                      location.pos!.latitude,
                      location.pos!.longitude,
                    );
                  } else {
                    debugPrint(
                      "Adding friends' location failed. The location from firestore is empty, = $location",
                    );
                    return null;
                  }
                })
                .whereType<LatLng>()
                .toList();
          });
    } catch (e) {
      debugPrint("Error getting testLocation from firestore: $e");
      rethrow;
    }
  }
}

class MapViewModel extends ChangeNotifier {
  final MapModel model;
  List<LatLng>? friendsLocations;
  String? errorMessage;
  bool isLoading = false;

  MapViewModel(this.model) {
    getFriendsLocations();
  }

  Future<void> getFriendsLocations() async {
    isLoading = true;
    model.getFriendsLocationsStream().listen((friendsLocationsList) {
      friendsLocations = friendsLocationsList;
      isLoading = false;
      notifyListeners();
    });
  }
}

class MapView extends StatelessWidget {
  final List<Marker> _markers = [];
  final Completer<GoogleMapController> _controller = Completer();

  static final CameraPosition _kGoogle = const CameraPosition(
    target: LatLng(13.8, 100.5),
    zoom: 14.4746,
  );
  Future<BitmapDescriptor> getMarkerIcon(
    String imagePath,
    Size size,
    Color shadowColor,
  ) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    final Radius radius = Radius.circular(size.width / 2);
    final Paint shadowPaint = Paint()..color = shadowColor.withAlpha(100);
    final double shadowWidth = 7.0;

    final Paint borderPaint = Paint()..color = Colors.white;
    final double borderWidth = 3.0;

    final double imageOffset = shadowWidth + borderWidth;

    // Add shadow circle
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(0.0, 0.0, size.width, size.height),
        topLeft: radius,
        topRight: radius,
        bottomLeft: radius,
        bottomRight: radius,
      ),
      shadowPaint,
    );

    // Add border circle
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(
          shadowWidth,
          shadowWidth,
          size.width - (shadowWidth * 2),
          size.height - (shadowWidth * 2),
        ),
        topLeft: radius,
        topRight: radius,
        bottomLeft: radius,
        bottomRight: radius,
      ),
      borderPaint,
    );

    // Oval for the image
    Rect oval = Rect.fromLTWH(
      imageOffset,
      imageOffset,
      size.width - (imageOffset * 2),
      size.height - (imageOffset * 2),
    );
    // Add image
    ui.Image image = await getImageFromPath(imagePath);
    paintImage(
      canvas: canvas,
      image: image,
      rect: oval,
      fit: BoxFit.fitWidth,
      filterQuality: FilterQuality.high,
      isAntiAlias: true,
    );

    // canvas.scale(MediaQuery.of(context).devicePixelRatio);
    // Convert canvas to image
    final ui.Image markerAsImage = await pictureRecorder.endRecording().toImage(
      size.width.toInt(),
      size.height.toInt(),
    );

    // Convert image to bytes
    final ByteData? byteData = await markerAsImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    final Uint8List uint8List = byteData!.buffer.asUint8List();
    return BitmapDescriptor.bytes(uint8List);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ChangeNotifierProvider(
        create: (context) => MapViewModel(MapModel()),
        child: Consumer<MapViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return Center(child: CircularProgressIndicator());
            }
            final locations = viewModel.friendsLocations;
            // FOR TEST
            int i = 0;
            if (locations != null) {
              for (LatLng? pos in locations) {
                if (pos != null) {
                  getMarkerIcon(
                    "assets/userIconTest.png",
                    Size(50.0, 50.0),
                    Colors.orange.shade400,
                  ).then((marker) {
                    _markers.add(
                      Marker(
                        markerId: MarkerId("$i"),
                        position: pos,
                        anchor: const Offset(0.5, 0.5),
                        icon: marker,
                        infoWindow: InfoWindow(title: 'TEST FIRESTORE #$i'),
                      ),
                    );
                    i++;
                  });
                }
              }
            }
            return GoogleMap(
              initialCameraPosition: _kGoogle,
              // markers on the map
              markers: Set<Marker>.of(_markers),
              // map type
              mapType: MapType.normal,
              myLocationEnabled: true,
              compassEnabled: true,
              indoorViewEnabled: true,
              // set controller on map complete
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
            );
          },
        ),
      ),
    );
  }
}

// class MapPage extends StatefulWidget {
//   const MapPage({super.key});

//   @override
//   State<MapPage> createState() => _MapState();
// }

// class _MapState extends State<MapPage> {
//   Position? _currentPosition;
//   final Completer<GoogleMapController> _controller = Completer();
//   static final CameraPosition _kGoogle = const CameraPosition(
//     target: LatLng(20.42796133580664, 80.885749655962),
//     zoom: 14.4746,
//   );
//   final List<Marker> _markers = <Marker>[];

//   final viewModel = MapViewModel(MapModel());

//   Future<BitmapDescriptor> getMarkerIcon(
//     String imagePath,
//     Size size,
//     Color shadowColor,
//   ) async {
//     final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
//     final Canvas canvas = Canvas(pictureRecorder);

//     final Radius radius = Radius.circular(size.width / 2);
//     final Paint shadowPaint = Paint()..color = shadowColor.withAlpha(100);
//     final double shadowWidth = 7.0;

//     final Paint borderPaint = Paint()..color = Colors.white;
//     final double borderWidth = 3.0;

//     final double imageOffset = shadowWidth + borderWidth;

//     // Add shadow circle
//     canvas.drawRRect(
//       RRect.fromRectAndCorners(
//         Rect.fromLTWH(0.0, 0.0, size.width, size.height),
//         topLeft: radius,
//         topRight: radius,
//         bottomLeft: radius,
//         bottomRight: radius,
//       ),
//       shadowPaint,
//     );

//     // Add border circle
//     canvas.drawRRect(
//       RRect.fromRectAndCorners(
//         Rect.fromLTWH(
//           shadowWidth,
//           shadowWidth,
//           size.width - (shadowWidth * 2),
//           size.height - (shadowWidth * 2),
//         ),
//         topLeft: radius,
//         topRight: radius,
//         bottomLeft: radius,
//         bottomRight: radius,
//       ),
//       borderPaint,
//     );

//     // Oval for the image
//     Rect oval = Rect.fromLTWH(
//       imageOffset,
//       imageOffset,
//       size.width - (imageOffset * 2),
//       size.height - (imageOffset * 2),
//     );

//     // for test
//     // canvas.clipPath(Path()..addOval(oval));
//     // TextPainter painter = TextPainter(textDirection: TextDirection.ltr);
//     // painter.text = TextSpan(
//     //   text: 'Hello world',
//     //   style: TextStyle(
//     //     fontSize: 10.0,
//     //     color: const Color.fromARGB(255, 0, 0, 0),
//     //   ),
//     // );
//     // painter.layout();
//     // painter.paint(
//     //   canvas,
//     //   Offset(
//     //     (size.width * 0.5) - painter.width * 0.5,
//     //     (size.height * 0.5) - painter.height * 0.5,
//     //   ),
//     // );
//     // final img = await pictureRecorder.endRecording().toImage(
//     //   size.width.toInt(),
//     //   size.height.toInt(),
//     // );
//     // final data = await img.toByteData(format: ui.ImageByteFormat.png);
//     // return BitmapDescriptor.bytes(data!.buffer.asUint8List());

//     // Add image
//     ui.Image image = await getImageFromPath(imagePath);
//     paintImage(
//       canvas: canvas,
//       image: image,
//       rect: oval,
//       fit: BoxFit.fitWidth,
//       filterQuality: FilterQuality.high,
//       isAntiAlias: true,
//     );

//     // canvas.scale(MediaQuery.of(context).devicePixelRatio);
//     // Convert canvas to image
//     final ui.Image markerAsImage = await pictureRecorder.endRecording().toImage(
//       size.width.toInt(),
//       size.height.toInt(),
//     );

//     // Convert image to bytes
//     final ByteData? byteData = await markerAsImage.toByteData(
//       format: ui.ImageByteFormat.png,
//     );
//     final Uint8List uint8List = byteData!.buffer.asUint8List();
//     return BitmapDescriptor.bytes(uint8List);
//     // for test
//     // return BitmapDescriptor.asset(
//     //   ImageConfiguration(devicePixelRatio: 0.2),
//     //   imagePath,
//     // );
//   }

//   Future<bool> _handleLocationPermission() async {
//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       debugPrint("service is disabled. Requesting permissions");
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         if (!mounted) return false;
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text(
//               'Location permissions are denied. Please allow location permissions.',
//             ),
//           ),
//         );
//         return Future.error('Location permissions are denied');
//       }
//     }
//     if (permission == LocationPermission.deniedForever) {
//       if (!mounted) return false;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Location permissions are denied. Please allow location permissions.',
//           ),
//         ),
//       );
//       return Future.error(
//         'Location permissions are permanently denied, we cannot request permissions.',
//       );
//     }
//     return true;
//   }

//   Future<void> getUserCurrentLocation() async {
//     try {
//       await _handleLocationPermission();
//       await Geolocator.getCurrentPosition(
//         locationSettings: LocationSettings(accuracy: LocationAccuracy.best),
//       ).then((Position position) {
//         setState(() => _currentPosition = position);
//       });
//     } catch (e) {
//       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
//         if (!mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Please enable location service')),
//         );
//       }
//       debugPrint(e.toString());
//     }
//   }

//   @override
//   void initState() {
//     super.initState();

//     getMarkerIcon(
//       "assets/userIconTest.png",
//       Size(50.0, 50.0),
//       Colors.blue.shade400,
//     ).then((marker) {
//       setState(() {
//         _markers.add(
//           Marker(
//             markerId: MarkerId('1'),
//             position: LatLng(13.879441, 100.455692),
//             anchor: const Offset(0.5, 0.5),
//             icon: marker,
//             infoWindow: InfoWindow(title: 'Test Position'),
//           ),
//         );
//       });
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: ListenableBuilder(
//           listenable: viewModel,
//           builder: (context, child) {
//             return switch ((
//               viewModel.loading,
//               viewModel.friendsLocations,
//               viewModel.errorMessage,
//             )) {
//               (true, _, _) => Center(child: CircularProgressIndicator()),
//               (false, _, String message) => Center(
//                 child: Text("An error has occurred. $message"),
//               ),
//               (false, null, null) => Center(
//                 child: Text("An unknown error has occurred"),
//               ),
//               (false, List<LatLng> locations, null) => () {
//                 // FOR TEST
//                 int i = 3;
//                 for (LatLng? pos in locations) {
//                   if (pos != null) {
//                     getMarkerIcon(
//                       "assets/userIconTest.png",
//                       Size(50.0, 50.0),
//                       Colors.orange.shade400,
//                     ).then((marker) {
//                       _markers.add(
//                         Marker(
//                           markerId: MarkerId("$i"),
//                           position: pos,
//                           anchor: const Offset(0.5, 0.5),
//                           icon: marker,
//                           infoWindow: InfoWindow(title: 'TEST FIRESTORE #$i'),
//                         ),
//                       );
//                       i++;
//                     });
//                   }
//                 }

//                 return GoogleMap(
//                   initialCameraPosition: _kGoogle,
//                   // markers on the map
//                   markers: Set<Marker>.of(_markers),
//                   // map type
//                   mapType: MapType.normal,
//                   myLocationEnabled: true,
//                   compassEnabled: true,
//                   indoorViewEnabled: true,
//                   // set controller on map complete
//                   onMapCreated: (GoogleMapController controller) {
//                     _controller.complete(controller);
//                   },
//                 );
//               }(),
//             };
//           },
//         ),
//       ),
//       // take to user current location
//       floatingActionButton: FloatingActionButton(
//         onPressed: () async {
//           getUserCurrentLocation().then((value) async {
//             if (_currentPosition == null) {
//               debugPrint("Current position is still null");
//               return;
//             }

//             debugPrint(
//               "${_currentPosition!.latitude.toString()} ${_currentPosition!.longitude.toString()}",
//             );

//             // marker added for current users location
//             _markers.add(
//               Marker(
//                 markerId: MarkerId("2"),
//                 position: LatLng(
//                   _currentPosition!.latitude,
//                   _currentPosition!.longitude,
//                 ),
//                 anchor: const Offset(0.5, 0.5),
//                 icon: await getMarkerIcon(
//                   "assets/userIconTest.png",
//                   Size(50.0, 50.0),
//                   Colors.purple.shade400,
//                 ),
//                 infoWindow: InfoWindow(title: 'My Current Location'),
//               ),
//             );

//             // specified current users location
//             CameraPosition cameraPosition = CameraPosition(
//               target: LatLng(
//                 _currentPosition!.latitude,
//                 _currentPosition!.longitude,
//               ),
//               zoom: 15,
//             );
//             final GoogleMapController controller = await _controller.future;
//             controller.animateCamera(
//               CameraUpdate.newCameraPosition(cameraPosition),
//             );
//             setState(() {});
//           });
//         },
//         child: Icon(Icons.gps_fixed),
//       ),
//     );
//   }
// }
