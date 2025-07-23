import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../controller/currentlocation.dart';

class MapScreen extends StatefulWidget {
  MapScreen({super.key});

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(23.8103, 90.4125), // Dhaka
    zoom: 12,
  );

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final mapController = Get.put(MapControllerAll());

  final Marker _dhakaMarker = Marker(
    markerId: MarkerId("_dhakaLocation"),
    position: LatLng(23.8103, 90.4125),
    infoWindow: InfoWindow(title: "Dhaka", snippet: "Capital of Bangladesh"),
    icon: BitmapDescriptor.defaultMarker,
  );
  String MapTheme='';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    DefaultAssetBundle.of(context).loadString("assets/mapStyle/mapStyle.json").then((value){
      MapTheme = value;
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Google Map")),
      floatingActionButton: FloatingActionButton(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18)
        ),
        backgroundColor: Colors.white,
        child: Icon(Icons.my_location, color: Colors.black),
        onPressed: () async {
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          final latLng = LatLng(position.latitude, position.longitude);
          mapController.animateCameraTo(latLng);  // Use new method here
        },
      ),

      body: Obx(() => GoogleMap(
        onMapCreated: (controller) {
          mapController.setMapController(controller);
          mapController.currentLocation();
          controller.setMapStyle(MapTheme);
        },
      initialCameraPosition: CameraPosition(
          target: LatLng(23.7806, 90.4265),
        // or any fallback
        zoom: 14,
      ),
        markers: Set<Marker>.from(mapController.markers),
        polylines: mapController.polylines.toSet(),
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        zoomGesturesEnabled: true,
        zoomControlsEnabled: false,
        circles: mapController.circles.toSet(),

      )),
    );
  }
}
