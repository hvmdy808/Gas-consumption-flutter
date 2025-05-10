import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  // Get current location
  static Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Location services are disabled.';
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Location permissions are denied.';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Location permissions are permanently denied.';
    }

    return await Geolocator.getCurrentPosition();
  }

  // Get address from coordinates
  static Future<String> getAddressFromCoordinates(
    double lat,
    double lng,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.street}, ${place.locality}, ${place.country}';
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  // Convert address to coordinates
  static Future<Location?> getCoordinatesFromAddress(String address) async {
    // try {
    //   List<Location> locations = await locationFromAddress("$address Egypt");
    //   if (locations.isNotEmpty) {
    //     return locations[0];
    //   }
    //   return null;
    // } catch (e) {
    //   return null;
    // }
    try {
      // First try the address as provided
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return locations[0];
      }

      // If that fails, try with Egypt appended
      if (!address.toLowerCase().contains("egypt")) {
        locations = await locationFromAddress("$address, Egypt");
        if (locations.isNotEmpty) {
          return locations[0];
        }
      }

      return null;
    } catch (e) {
      print("Geocoding error: $e");
      return null;
    }
  }

  // Calculate distance between two points in kilometers
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }
}
