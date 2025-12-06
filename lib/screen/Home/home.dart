import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../controller/currentlocation.dart';

class MapScreen extends StatefulWidget {
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final mapController = Get.put(MapControllerAll());
  String mapTheme = "";

  @override
  void initState() {
    super.initState();
    DefaultAssetBundle.of(context)
        .loadString("assets/mapStyle/mapStyle.json")
        .then((value) => mapTheme = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Live Tracking Map")),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.my_location),
        onPressed: () {
          if (mapController.currentLatLng != null) {
            mapController.animateCameraTo(mapController.currentLatLng!);
          }
        },
      ),
      body: Obx(() {
        return GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: CameraPosition(
            target: LatLng(23.8103, 90.4125),
            zoom: 14,
          ),
          onMapCreated: (controller) {
            mapController.setMapController(controller);
            controller.setMapStyle(mapTheme);
            mapController.startLiveLocation();  // <-- LIVE TRACKING STARTS
          },
          myLocationEnabled: true,
          markers: mapController.markers.toSet(),
          polylines: mapController.polylines.toSet(),
          circles: mapController.circles.toSet(),
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
        );
      }),
    );
  }
}
