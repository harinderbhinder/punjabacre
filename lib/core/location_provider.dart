import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationProvider extends ChangeNotifier {
  double? lat;
  double? lng;
  bool _fetched = false;

  bool get hasLocation => lat != null && lng != null;

  Future<void> fetchLocation() async {
    if (_fetched) return;
    _fetched = true;
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.whileInUse ||
          perm == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 10),
          ),
        );
        lat = pos.latitude;
        lng = pos.longitude;
        notifyListeners();
      }
    } catch (_) {}
  }
}
