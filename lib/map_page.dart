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

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<StatefulWidget> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final Completer<GoogleMapController> _controller = Completer();

  static final CameraPosition _kGoogle = const CameraPosition(
    target: LatLng(13.8, 100.5),
    zoom: 14.4746,
  );
  BitmapDescriptor? friendMarkerIcon;
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
  void initState() {
    super.initState();
    loadFriendMarkerIcon();
  }

  Future<void> loadFriendMarkerIcon() async {
    final icon = await getMarkerIcon(
      "assets/userIconTest.png",
      const Size(50.0, 50.0),
      Colors.orange,
    );

    setState(() {
      friendMarkerIcon = icon;
    });
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
            final friendsLocations = viewModel.friendsLocations;
            Set<Marker> markers = <Marker>{};
            if (friendsLocations != null) {
              debugPrint("FRIENDS LOCATION = ${friendsLocations.toString()}");
              markers = friendsLocations
                  .asMap()
                  .entries
                  .map((entry) {
                    final int index = entry.key;
                    final LatLng pos = entry.value;

                    return Marker(
                      markerId: MarkerId("$index"),
                      position: pos,
                      anchor: const Offset(0.5, 0.5),
                      icon: friendMarkerIcon ?? BitmapDescriptor.defaultMarker,
                      infoWindow: InfoWindow(title: 'TEST FIRESTORE #$index'),
                    );
                  })
                  .nonNulls
                  .toSet();
            }
            debugPrint("MARKERS = ${markers.toString()}");
            return GoogleMap(
              initialCameraPosition: _kGoogle,
              // markers on the map
              markers: markers,
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
