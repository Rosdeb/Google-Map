import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

class MapControllerAll extends GetxController {
  GoogleMapController? _mapController; // use nullable
  LatLng? _currentPosition;
  LatLng? _secondPosition = LatLng(23.8103, 90.4125);

  final RxSet<Marker> markers = <Marker>{}.obs;
  final RxSet<Polyline> polylines = <Polyline>{}.obs;
  final RxSet<Circle> circles = <Circle>{}.obs;  // Add circles obs set

  BitmapDescriptor? carIcon;

  @override
  void onInit() {
    super.onInit();
    BitmapDescriptor.fromAssetImage(
        ImageConfiguration(size: Size(48, 48)),
        'assets/icons/car_sport.png'
    ).then((icon) {
      carIcon = icon;
      print("Car icon loaded: $carIcon");
      // Optionally notify listeners or update markers here
    });
  }


  setMapController(GoogleMapController controller) {
    _mapController = controller;
  }
  void animateCameraTo(LatLng latLng, {double zoom = 17}) {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: latLng, zoom: zoom),
        ),
      );
    }
  }

  Future<void> currentLocation() async {
    var permission = await Permission.location.request();

    if (!permission.isGranted) {
      print("Location permission denied");
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    _currentPosition = LatLng(position.latitude, position.longitude);

    // Clear previous markers, polylines and circles
    markers.clear();
    polylines.clear();
    circles.clear();

    // Add circle for accuracy
    circles.add(Circle(
      circleId: CircleId("user_accuracy_circle"),
      center: _currentPosition!,
      radius: position.accuracy,
      fillColor: Colors.blue.withOpacity(0.2),
      strokeColor: Colors.blue.withOpacity(0.5),
      strokeWidth: 2,
    ));

    // Add user marker
    markers.add(Marker(
      markerId: MarkerId("user_marker"),
      position: _currentPosition!,
      infoWindow: InfoWindow(title: "You are here"),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
    ));

    // Add car marker with unique ID and check icon loading
    // Wait until carIcon is loaded

    markers.add(Marker(
      markerId: MarkerId("car_marker_1"),
      position: LatLng(23.7806, 90.4265),
      infoWindow: InfoWindow(title: "Car"),
      icon:  BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
    ));

    markers.add(Marker(
      markerId: MarkerId("Dhaka"),
      position: LatLng(23.8103, 90.4125),
      infoWindow: InfoWindow(title: "Car"),
      icon:  BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
    ));

    markers.refresh();
    circles.refresh();

    // Optional: comment this out temporarily to check marker visibility
    await drawRoute(_currentPosition!, _secondPosition!);
    polylines.refresh();

    if (_mapController != null) {
      // Animate camera to include both points if possible
      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(
          min(_currentPosition!.latitude, _secondPosition!.latitude),
          min(_currentPosition!.longitude, _secondPosition!.longitude),
        ),
        northeast: LatLng(
          max(_currentPosition!.latitude, _secondPosition!.latitude),
          max(_currentPosition!.longitude, _secondPosition!.longitude),
        ),
      );
      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
    }
  }

  // Future<void> currentLocation() async {
  //   var permission = await Permission.location.request();
  //
  //   if (permission.isGranted) {
  //     Position position = await Geolocator.getCurrentPosition(
  //       desiredAccuracy: LocationAccuracy.high,
  //     );
  //
  //     _currentPosition = LatLng(position.latitude, position.longitude);
  //
  //     // Clear previous markers, polylines and circles
  //     markers.clear();
  //     polylines.clear();
  //     circles.clear();
  //
  //     // Add a circle showing accuracy radius (for example 100 meters)
  //     circles.add(Circle(
  //       circleId: CircleId("user_accuracy_circle"),
  //       center: _currentPosition!,
  //       radius: position.accuracy,  // accuracy in meters
  //       fillColor: Colors.blue.withOpacity(0.2),
  //       strokeColor: Colors.blue.withOpacity(0.5),
  //       strokeWidth: 2,
  //     ));
  //
  //     // Add user location marker (could be default or custom)
  //     markers.add(Marker(
  //       markerId: MarkerId("user_marker"),
  //       position: _currentPosition!,
  //       infoWindow: InfoWindow(title: "You are here"),
  //       icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
  //     ));
  //
  //     // Add car marker at second position using custom icon (if loaded)
  //     // Add car marker at second position using custom icon (if loaded)
  //     if (carIcon != null) {
  //       markers.add(Marker(
  //         markerId: MarkerId("car_marker"),
  //         position: _secondPosition!,
  //         infoWindow: InfoWindow(title: "Car"),
  //         icon: carIcon!,
  //         rotation: 90,
  //       ));
  //     } else {
  //       // fallback default marker
  //       markers.add(Marker(
  //         markerId: MarkerId("car_marker"),
  //         position: _secondPosition!,
  //         infoWindow: InfoWindow(title: "Car"),
  //       ));
  //     }
  //
  //
  //     markers.refresh();
  //     circles.refresh();
  //
  //     await drawRoute(_currentPosition!, _secondPosition!);
  //     polylines.refresh();
  //
  //     if (_mapController != null) {
  //       _mapController!.animateCamera(
  //         CameraUpdate.newCameraPosition(
  //           CameraPosition(target: _currentPosition!, zoom: 17),
  //         ),
  //       );
  //     }
  //   } else {
  //     print("Location permission denied");
  //   }
  // }


  Future<List<LatLng>> getRoutePolyLine(LatLng origin, LatLng destination) async {
    final apiKey = "AIzaSyC-cav2pg_TmVcECLUi4_YYx7GTaAUfFGc";
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      print("Directions API failed: ${response.statusCode}");
      return [];
    }

    final data = json.decode(response.body);
    if (data['routes'].isEmpty) {
      print("No routes found in API response");
      print(response.body);
      return [];
    }

    final points = data['routes'][0]['overview_polyline']['points'];
    return decodePolyline(points);
  }


  List<LatLng> decodePolyline (String encoded){

    List<LatLng> polyline = [];
    int index = 0,len=encoded.length;
    int lat = 0,lng=0;
    while(index<len){
      int b =0,shift=0,result=0;
      do{
        b=encoded.codeUnitAt(index++) +63;
        result |=(b & 0x1f) <<shift;
        shift+=5;
      }while(b>=0x20);
      int dlat = ((result & 1) !=0 ? ~(result >>1):(result>>1));
      lat +=dlat;
      shift=0;
      result=0;
      do{
        b=encoded.codeUnitAt(index++) -63;
        result |=(b & 0x1f) << shift;
        shift+=5;
      }while(b>=0x20);
      int dlng = ((result & 1) !=0 ? ~(result >>1):(result>>1));
      lng += dlng;
      polyline.add(LatLng(lat / 1E5, lng / 1E5));
      }
      return polyline;
    }


  Future<void> drawRoute(LatLng origin, LatLng destination) async {
    final points = await getRoutePolyLine(origin, destination);

    polylines.add(
      Polyline(
        polylineId: PolylineId("route"),
        points: points,
        color: Colors.blue,
        width: 5,
      ),
    );

    polylines.refresh(); // 🔴 This was missing
  }


}


