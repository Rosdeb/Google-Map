import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

class MapControllerAll extends GetxController {
  GoogleMapController? _mapController;

  final RxSet<Marker> markers = <Marker>{}.obs;
  final RxSet<Polyline> polylines = <Polyline>{}.obs;
  final RxSet<Circle> circles = <Circle>{}.obs;

  LatLng? currentLatLng;
  LatLng secondPosition = LatLng(23.8103, 90.4125);

  Stream<Position>? _positionStream;
  LatLng? lastUpdatedLatLng;

  BitmapDescriptor? carIcon;
  BitmapDescriptor? userIcon;

  @override
  void onInit() {
    super.onInit();
    //loadIcons();
  }

  // Future<void> loadIcons() async {
  //   userIcon = await BitmapDescriptor.fromAssetImage(
  //     ImageConfiguration(size: Size(50, 50)),
  //     "assets/icons/user.png",
  //   );
  //
  //   carIcon = await BitmapDescriptor.fromAssetImage(
  //     ImageConfiguration(size: Size(60, 60)),
  //     "assets/icons/car_sport.png",
  //   );
  // }

  setMapController(GoogleMapController controller) {
    _mapController = controller;
  }

  // ---------------- LIVE LOCATION TRACK ---------------- //

  Future<void> startLiveLocation() async {
    var permission = await Permission.location.request();
    if (!permission.isGranted) return;

    LocationSettings settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // update every 5 meters
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: settings);

    _positionStream!.listen((Position position) {
      LatLng liveLatLng = LatLng(position.latitude, position.longitude);

      // ----- Prevent too many updates (jitter) -----
      if (lastUpdatedLatLng != null) {
        double distance = Geolocator.distanceBetween(
          lastUpdatedLatLng!.latitude,
          lastUpdatedLatLng!.longitude,
          liveLatLng.latitude,
          liveLatLng.longitude,
        );

        if (distance < 10) {
          return; // Ignore small movement (< 10 meters)
        }
      }

      lastUpdatedLatLng = liveLatLng;
      currentLatLng = liveLatLng;

      updateUserMarker(liveLatLng, position.accuracy);
      updateRoute(liveLatLng, secondPosition);

      animateCameraTo(liveLatLng);

      markers.refresh();
      circles.refresh();
      polylines.refresh();
    });

  }

  void updateUserMarker(LatLng pos, double accuracy) {
    markers.removeWhere((m) => m.markerId.value == "user_marker");

    markers.add(
      Marker(
        markerId: MarkerId("user_marker"),
        icon: BitmapDescriptor.defaultMarkerWithHue(200),
        position: pos,
      ),
    );

    circles.removeWhere((c) => c.circleId.value == "user_circle");

    circles.add(
      Circle(
        circleId: CircleId("user_circle"),
        center: pos,
        radius: accuracy,
        fillColor: Colors.blue.withOpacity(0.15),
        strokeColor: Colors.blue.withOpacity(0.3),
        strokeWidth: 2,
      ),
    );
  }

  void animateCameraTo(LatLng latLng, {double zoom = 17}) {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(latLng),
      );
    }
  }


  // ---------------- ROUTE DRAWING ---------------- //

  Future<void> updateRoute(LatLng origin, LatLng destination) async {
    List<LatLng> routePoints = await getRoutePolyline(origin, destination);

    polylines.removeWhere((p) => p.polylineId.value == "route");

    polylines.add(
      Polyline(
        polylineId: PolylineId("route"),
        width: 6,
        color: Colors.blue,
        points: routePoints,
      ),
    );
  }

  Future<List<LatLng>> getRoutePolyline(LatLng origin, LatLng destination) async {
    final apiKey = "AIzaSyBUKgC5i0rzRLbGhndTjM0b6QdWbigR6_E";
    String url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$apiKey";

    var response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) return [];

    var data = jsonDecode(response.body);

    if (data["routes"].isEmpty) return [];

    String encoded = data["routes"][0]["overview_polyline"]["points"];
    return decodePolyline(encoded);
  }

  List<LatLng> decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int shift = 0, result = 0, b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return polyline;
  }
}
