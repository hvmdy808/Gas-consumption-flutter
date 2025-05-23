import 'package:flutter/material.dart';
import 'package:gas_app/settings_screen.dart';
import 'package:gas_app/location_services.dart';
import 'package:gas_app/preferences_services.dart';
import 'package:gas_app/location_input.dart';
import 'package:gas_app/result_card.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';

// Controller class to hold all the state and logic
class HomeController extends GetxController {
  final startLocController = TextEditingController();
  final secLocController = TextEditingController();
  final thrLocController = TextEditingController();
  final fouLocController = TextEditingController();

  final isCalculating = false.obs;
  final isLocationFetching = false.obs;
  final returnToStart = false.obs;
  final wantBestRoute = false.obs;
  final resultText = ''.obs;
  final errorText = ''.obs;
  final isError = false.obs;
  final cc = 0.obs;
  final gasType = 0.obs;
  final locationsEnabled = false.obs;
  var enableDetails = false.obs;
  var enableMaps = false.obs;
  var originalMap = false.obs;
  var bestMap = false.obs;
  final locationsViewed = <Location>[];

  @override
  void onInit() {
    super.onInit();
    _loadVehicleDetails();
  }

  @override
  void onClose() {
    // Dispose controllers when the controller is removed
    startLocController.dispose();
    secLocController.dispose();
    thrLocController.dispose();
    fouLocController.dispose();
    super.onClose();
  }

  Future<void> _loadVehicleDetails() async {
    final vehicleDetails = await PreferencesService.getVehicleDetails();
    final current_cc = vehicleDetails['cc'];
    final current_gasType = vehicleDetails['gasType'];
    if (current_cc != null && current_gasType != null) {
      cc.value = current_cc;
      gasType.value = current_gasType;
    }
  }

  void getCurrentLocation() async {
    isLocationFetching.value = true;
    errorText.value = '';
    locationsViewed.clear();
    enableMaps.value = false;

    try {
      final position = await LocationService.getCurrentLocation();
      final address = await LocationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      startLocController.text = address;
      isLocationFetching.value = false;
      locationsEnabled.value = true;
    } catch (e) {
      isLocationFetching.value = false;
      enableMaps.value = false;
      errorText.value = e.toString();
      isError.value = true;
    }
  }

  // Show detailed distance breakdown between each location
  Future<void> showDetails() async {
    _loadVehicleDetails();
    isCalculating.value = true;
    resultText.value = '';
    errorText.value = '';
    isError.value = false;
    locationsViewed.clear();
    enableMaps.value = false;

    // Check for duplicates
    final locations =
        [
          startLocController.text.trim().toLowerCase(),
          secLocController.text.trim().toLowerCase(),
          thrLocController.text.trim().toLowerCase(),
          fouLocController.text.trim().toLowerCase(),
        ].where((text) => text.isNotEmpty).toList();

    final uniqueLocations = locations.toSet().toList();
    if (locations.length != uniqueLocations.length) {
      errorText.value = 'All locations must be different.';
      isError.value = true;
      isCalculating.value = false;
      enableMaps.value = false;
      return;
    }

    try {
      final add1 = '${startLocController.text.trim().toLowerCase()} Egypt';
      final add2 = '${secLocController.text.trim().toLowerCase()} Egypt';
      var add3 = '${thrLocController.text.trim().toLowerCase()} Egypt';
      var add4 = '${fouLocController.text.trim().toLowerCase()} Egypt';

      // Verify at least two locations are entered
      if (startLocController.text.isEmpty || secLocController.text.isEmpty) {
        throw 'Add at least starting and second location.';
      }

      var result = '';

      // Get coordinates for starting location
      final startLoc = await LocationService.getCoordinatesFromAddress(add1);
      if (startLoc == null ||
          (startLoc.latitude == 26.820553 &&
              startLoc.longitude == 30.802498000000003 &&
              add1.trim().toLowerCase() != 'egypt egypt')) {
        throw 'The first location is not valid';
      }
      locationsViewed.add(startLoc);

      // Get coordinates for second location
      final secLoc = await LocationService.getCoordinatesFromAddress(add2);
      if (secLoc == null ||
          (secLoc.latitude == 26.820553 &&
              secLoc.longitude == 30.802498000000003 &&
              add2.trim().toLowerCase() != 'egypt egypt')) {
        throw 'The second location is not valid';
      }

      // Calculate distance between start and second location
      final dist1 = LocationService.calculateDistance(
        startLoc.latitude,
        startLoc.longitude,
        secLoc.latitude,
        secLoc.longitude,
      );

      // Add the distance to the result
      result +=
          'Distance between ${startLocController.text} to ${secLocController.text} = ${dist1.toStringAsFixed(2)} km';

      var lastLoc = secLoc;
      var lastAdd = add2;
      locationsViewed.add(secLoc);

      // Process third location if provided
      if (thrLocController.text.isNotEmpty) {
        final thrLoc = await LocationService.getCoordinatesFromAddress(add3);
        if (thrLoc == null ||
            (thrLoc.latitude == 26.820553 &&
                thrLoc.longitude == 30.802498000000003 &&
                add3.trim().toLowerCase() != 'egypt egypt')) {
          throw 'The third location is not valid';
        }

        final dist2 = LocationService.calculateDistance(
          secLoc.latitude,
          secLoc.longitude,
          thrLoc.latitude,
          thrLoc.longitude,
        );

        result +=
            '\nDistance between $lastAdd to ${thrLocController.text} = ${dist2.toStringAsFixed(2)} km';
        lastLoc = thrLoc;
        lastAdd = add3;
        locationsViewed.add(thrLoc);
      }
      // Process fourth location if provided
      if (fouLocController.text.isNotEmpty) {
        final fouLoc = await LocationService.getCoordinatesFromAddress(add4);
        if (fouLoc == null ||
            (fouLoc.latitude == 26.820553 &&
                fouLoc.longitude == 30.802498000000003 &&
                add4.trim().toLowerCase() != 'egypt egypt')) {
          throw 'The fourth location is not valid';
        }

        final dist3 = LocationService.calculateDistance(
          lastLoc.latitude,
          lastLoc.longitude,
          fouLoc.latitude,
          fouLoc.longitude,
        );

        result +=
            '\nDistance between $lastAdd to ${fouLocController.text} = ${dist3.toStringAsFixed(2)} km';
        lastLoc = fouLoc;
        lastAdd = add4;
        locationsViewed.add(fouLoc);
      }

      // Add return trip if selected
      if (returnToStart.value) {
        final dist4 = LocationService.calculateDistance(
          lastLoc.latitude,
          lastLoc.longitude,
          startLoc.latitude,
          startLoc.longitude,
        );
        locationsViewed.add(startLoc);
        result +=
            '\nDistance between $lastAdd to ${startLocController.text} = ${dist4.toStringAsFixed(2)} km';
      }
      resultText.value = result;
      isCalculating.value = false;
      enableDetails.value = false;
      enableMaps.value = true;
      originalMap.value = true;
      bestMap.value = false;
    } catch (e) {
      resultText.value = '';
      errorText.value = e.toString();
      isError.value = true;
      isCalculating.value = false;
      enableMaps.value = false;
    }
  }

  // Calculate and show the best route (nearest neighbor algorithm)
  Future<void> showBestRoute() async {
    _loadVehicleDetails();
    isCalculating.value = true;
    errorText.value = '';
    resultText.value = '';
    isError.value = false;
    locationsViewed.clear();
    enableMaps.value = false;

    // Check for duplicates
    final locations =
        [
          startLocController.text.trim().toLowerCase(),
          secLocController.text.trim().toLowerCase(),
          thrLocController.text.trim().toLowerCase(),
          fouLocController.text.trim().toLowerCase(),
        ].where((text) => text.isNotEmpty).toList();

    final uniqueLocations = locations.toSet().toList();
    if (locations.length != uniqueLocations.length) {
      errorText.value = 'All locations must be different.';
      isError.value = true;
      isCalculating.value = false;
      enableMaps.value = false;
      return;
    }

    try {
      // Check that we have enough locations to optimize
      if (startLocController.text.isEmpty) {
        throw 'Add a valid starting location.';
      }

      // Collect all non-empty locations
      final List<String> addresses = [];
      if (startLocController.text.isNotEmpty)
        addresses.add(startLocController.text);
      if (secLocController.text.isNotEmpty)
        addresses.add(secLocController.text);
      if (thrLocController.text.isNotEmpty)
        addresses.add(thrLocController.text);
      if (fouLocController.text.isNotEmpty)
        addresses.add(fouLocController.text);

      if (addresses.length < 3) {
        throw 'Enter at least two locations for route calculation.';
      }

      // Convert all addresses to coordinates
      final locations = <String, Location>{};
      for (final addr in addresses) {
        final loc = await LocationService.getCoordinatesFromAddress(
          '${addr} Egypt',
        );
        if (loc == null ||
            (loc.latitude == 26.820553 &&
                loc.longitude == 30.802498000000003 &&
                addr.trim().toLowerCase() != 'egypt')) {
          throw 'Invalid address: $addr';
        }
        locations[addr] = loc;
      }

      // Start with the first location
      var currentLocation = startLocController.text;
      var routeDesc = currentLocation;
      locationsViewed.add(locations[currentLocation]!);
      var totalDistance = 0.0;

      // Create a set of unvisited locations (excluding the start)
      final unvisited = addresses.where((a) => a != currentLocation).toSet();

      // Nearest neighbor algorithm: always go to the nearest unvisited location
      while (unvisited.isNotEmpty) {
        var nearest = '';
        var minDistance = double.infinity;

        for (final next in unvisited) {
          final distance = LocationService.calculateDistance(
            locations[currentLocation]!.latitude,
            locations[currentLocation]!.longitude,
            locations[next]!.latitude,
            locations[next]!.longitude,
          );

          if (distance < minDistance) {
            minDistance = distance;
            nearest = next;
          }
        }

        // Add this leg to the route
        totalDistance += minDistance;
        routeDesc += ' → (${minDistance.toStringAsFixed(2)} km) → $nearest';

        // Move to the next location
        currentLocation = nearest;
        locationsViewed.add(locations[nearest]!);
        unvisited.remove(nearest);
      }

      // Add return to start if needed
      if (returnToStart.value) {
        final returnDistance = LocationService.calculateDistance(
          locations[currentLocation]!.latitude,
          locations[currentLocation]!.longitude,
          locations[startLocController.text]!.latitude,
          locations[startLocController.text]!.longitude,
        );
        totalDistance += returnDistance;
        routeDesc +=
            ' → (${returnDistance.toStringAsFixed(2)} km) → ${startLocController.text}';
        locationsViewed.add(locations[startLocController.text]!);
      }

      // Add total distance to result
      routeDesc += '\n\nTotal Distance: ${totalDistance.toStringAsFixed(2)} km';

      // Calculate fuel consumption and cost based on engine size
      if (cc.value != null && gasType.value != null) {
        final costPerLiter = _calculateFuelCost();
        final fuelEstimate = _calculateFuelConsumption(totalDistance);

        routeDesc +=
            '\nEstimated fuel consumption: ${fuelEstimate['min']?.toStringAsFixed(2)} - ${fuelEstimate['max']?.toStringAsFixed(2)} L';
        routeDesc +=
            '\nEstimated fuel cost: ${(fuelEstimate['min']! * costPerLiter).toStringAsFixed(2)} - ${(fuelEstimate['max']! * costPerLiter).toStringAsFixed(2)} LE';
      }

      resultText.value = routeDesc;
      isCalculating.value = false;
      enableDetails.value = false;
      enableMaps.value = true;
      originalMap.value = false;
      bestMap.value = true;
    } catch (e) {
      errorText.value = e.toString();
      isError.value = true;
      enableMaps.value = false;
      isCalculating.value = false;
    }
  }

  double _calculateFuelCost() {
    switch (gasType.value) {
      case 80:
        return 13.75;
      case 92:
        return 15.25;
      case 95:
        return 17.0;
      default:
        return 15.25; // Default value
    }
  }

  Map<String, double> _calculateFuelConsumption(double distanceInKm) {
    double minConsumption;
    double maxConsumption;

    if (cc.value! >= 50 && cc.value! <= 500) {
      minConsumption = (2 * distanceInKm) / 100;
      maxConsumption = (4 * distanceInKm) / 100;
    } else if (cc.value! >= 501 && cc.value! <= 1500) {
      minConsumption = (4 * distanceInKm) / 100;
      maxConsumption = (8 * distanceInKm) / 100;
    } else if (cc.value! >= 1501 && cc.value! <= 2000) {
      minConsumption = (8 * distanceInKm) / 100;
      maxConsumption = (10 * distanceInKm) / 100;
    } else if (cc.value! >= 2001 && cc.value! <= 4000) {
      minConsumption = (10 * distanceInKm) / 100;
      maxConsumption = (14 * distanceInKm) / 100;
    } else if (cc.value! >= 4001 && cc.value! <= 6000) {
      minConsumption = (14 * distanceInKm) / 100;
      maxConsumption = (19 * distanceInKm) / 100;
    } else {
      minConsumption = (19 * distanceInKm) / 100;
      maxConsumption = (25 * distanceInKm) / 100;
    }

    return {'min': minConsumption, 'max': maxConsumption};
  }

  Future<void> calculate() async {
    _loadVehicleDetails();
    // Reset states
    isCalculating.value = true;
    errorText.value = '';
    resultText.value = '';
    isError.value = false;
    locationsViewed.clear();
    enableMaps.value = false;

    if (startLocController.text.isEmpty || secLocController.text.isEmpty) {
      errorText.value = 'Please enter at least starting and second location.';
      isError.value = true;
      isCalculating.value = false;
      enableMaps.value = false;
      return;
    }

    // Check for duplicates
    final locations =
        [
          startLocController.text.trim().toLowerCase(),
          secLocController.text.trim().toLowerCase(),
          thrLocController.text.trim().toLowerCase(),
          fouLocController.text.trim().toLowerCase(),
        ].where((text) => text.isNotEmpty).toList();

    final uniqueLocations = locations.toSet().toList();
    if (locations.length != uniqueLocations.length) {
      errorText.value = 'All locations must be different.';
      isError.value = true;
      isCalculating.value = false;
      enableMaps.value = false;
      return;
    }

    // Process locations
    try {
      var result = '';
      var totalDistance = 0.0;
      final add1 = '${startLocController.text.trim()} Egypt';
      final add2 = '${secLocController.text.trim()} Egypt';
      var add3 = '${thrLocController.text.trim()} Egypt';
      var add4 = '${fouLocController.text.trim()} Egypt';
      // Convert addresses to coordinates
      final startLoc = await LocationService.getCoordinatesFromAddress(add1);
      if (startLoc == null ||
          (startLoc.latitude == 26.820553 &&
              startLoc.longitude == 30.802498000000003 &&
              add1.trim().toLowerCase() != 'egypt egypt')) {
        throw 'The first location is not valid';
      }
      locationsViewed.add(startLoc);
      final secLoc = await LocationService.getCoordinatesFromAddress(add2);
      if (secLoc == null ||
          (secLoc.latitude == 26.820553 &&
              secLoc.longitude == 30.802498000000003 &&
              add2.trim().toLowerCase() != 'egypt egypt')) {
        throw 'The second location is not valid';
      }
      // Calculate distance between start and second location
      final dist1 = LocationService.calculateDistance(
        startLoc.latitude,
        startLoc.longitude,
        secLoc.latitude,
        secLoc.longitude,
      );
      totalDistance += dist1;
      var lastLoc = secLoc;
      locationsViewed.add(secLoc);

      // Process third location if provided
      if (thrLocController.text.isNotEmpty) {
        final thrLoc = await LocationService.getCoordinatesFromAddress(add3);
        if (thrLoc == null ||
            (thrLoc.latitude == 26.820553 &&
                thrLoc.longitude == 30.802498000000003 &&
                add3.trim().toLowerCase() != 'egypt egypt')) {
          throw 'The third location is not valid';
        }
        final dist2 = LocationService.calculateDistance(
          lastLoc.latitude,
          lastLoc.longitude,
          thrLoc.latitude,
          thrLoc.longitude,
        );
        totalDistance += dist2;
        lastLoc = thrLoc;
        locationsViewed.add(thrLoc);
      }
      // Process fourth location if provided
      if (fouLocController.text.isNotEmpty) {
        final fouLoc = await LocationService.getCoordinatesFromAddress(add4);
        if (fouLoc == null ||
            (fouLoc.latitude == 26.820553 &&
                fouLoc.longitude == 30.802498000000003 &&
                add4.trim().toLowerCase() != 'egypt egypt')) {
          throw 'The fourth location is not valid';
        }
        final dist3 = LocationService.calculateDistance(
          lastLoc.latitude,
          lastLoc.longitude,
          fouLoc.latitude,
          fouLoc.longitude,
        );
        totalDistance += dist3;
        lastLoc = fouLoc;
        locationsViewed.add(fouLoc);
      }

      // Add return trip if selected
      if (returnToStart.value) {
        final dist4 = LocationService.calculateDistance(
          lastLoc.latitude,
          lastLoc.longitude,
          startLoc.latitude,
          startLoc.longitude,
        );
        totalDistance += dist4;
        locationsViewed.add(startLoc);
      }
      result += 'Total distance = ${totalDistance.toStringAsFixed(2)} km';
      final costPerLiter = _calculateFuelCost();
      final fuelEstimate = _calculateFuelConsumption(totalDistance);

      result +=
          '\nEstimated fuel consumption: ${fuelEstimate['min']?.toStringAsFixed(2)} - ${fuelEstimate['max']?.toStringAsFixed(2)} L';
      result +=
          '\nEstimated fuel cost: ${(fuelEstimate['min']! * costPerLiter).toStringAsFixed(2)} - ${(fuelEstimate['max']! * costPerLiter).toStringAsFixed(2)} LE';
      resultText.value = result;
      enableDetails.value = true;
      enableMaps.value = true;
      originalMap.value = true;
      bestMap.value = false;
    } catch (e) {
      errorText.value = e.toString();
      isError.value = true;
      enableMaps.value = false;
    } finally {
      // This ensures isCalculating is always reset
      isCalculating.value = false;
    }
  }

  Future<void> showMap() async {
    if (locationsViewed.length < 2) {
      throw 'At least 2 locations needed.';
    }
    for (Location loc in locationsViewed) {
      if (loc.longitude == 30.802498000000003 && loc.latitude == 26.820553) {
        errorText.value = "Egypt is not a specific location to show in the map";
        resultText.value = "";
        return;
      }
    }

    String origin =
        '${locationsViewed[0].latitude},${locationsViewed[0].longitude}';
    String destination =
        '${locationsViewed[locationsViewed.length - 1].latitude},${locationsViewed[locationsViewed.length - 1].longitude}';

    String waypoints = '';
    for (int i = 1; i < locationsViewed.length - 1; i++) {
      waypoints +=
          '${locationsViewed[i].latitude},${locationsViewed[i].longitude}';
      if (i != locationsViewed.length - 2) {
        waypoints += '|';
      }
    }

    String url =
        'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination';

    if (waypoints.isNotEmpty) {
      url += '&waypoints=$waypoints';
    }
    url += '&travelmode=driving';
    print(url);
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fuel Cost Calculator'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Get.to(SettingsScreen(), transition: Transition.rightToLeft);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Location inputs
            Obx(
              () => LocationInput(
                hint: 'Your starting location',
                controller: controller.startLocController,
                enabled: controller.locationsEnabled.value,
              ),
            ),
            Obx(
              () => LocationInput(
                hint: 'Second place here',
                controller: controller.secLocController,
                enabled: controller.locationsEnabled.value,
              ),
            ),
            Obx(
              () => LocationInput(
                hint: 'Third place here (optional)',
                controller: controller.thrLocController,
                enabled: controller.locationsEnabled.value,
              ),
            ),
            Obx(
              () => LocationInput(
                hint: 'Fourth place here (optional)',
                controller: controller.fouLocController,
                enabled: controller.locationsEnabled.value,
              ),
            ),

            // Return checkbox
            Obx(
              () => CheckboxListTile(
                title: const Text('Will you return to your starting location?'),
                value: controller.returnToStart.value,
                onChanged:
                    controller.locationsEnabled.value
                        ? (value) {
                          controller.returnToStart.value = value ?? false;
                        }
                        : null,
              ),
            ),

            // Best route checkbox
            Obx(
              () => CheckboxListTile(
                title: const Text(
                  'Want suggested best route to minimize fuel costs?',
                ),
                value: controller.wantBestRoute.value,
                onChanged:
                    controller.locationsEnabled.value
                        ? (value) {
                          controller.wantBestRoute.value = value ?? false;
                        }
                        : null,
              ),
            ),

            const SizedBox(height: 16),

            // Results area
            Obx(
              () =>
                  controller.resultText.value.isNotEmpty
                      ? ResultCard(
                        resultText: controller.resultText.value,
                        isError: false,
                      )
                      : const SizedBox.shrink(),
            ),

            Obx(
              () =>
                  controller.errorText.value.isNotEmpty
                      ? ResultCard(
                        resultText: controller.errorText.value,
                        isError: true,
                      )
                      : const SizedBox.shrink(),
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Obx(
                  () => ElevatedButton.icon(
                    onPressed:
                        controller.isLocationFetching.value
                            ? null
                            : controller.getCurrentLocation,
                    icon:
                        controller.isLocationFetching.value
                            ? const SpinKitFadingCircle(
                              color: Colors.white,
                              size: 18,
                            )
                            : const Icon(Icons.my_location),
                    label: const Text('Get My Location'),
                  ),
                ),
                Obx(
                  () => ElevatedButton.icon(
                    onPressed:
                        (controller.locationsEnabled.value &&
                                !controller.isCalculating.value)
                            ? controller.calculate
                            : null,
                    icon:
                        controller.isCalculating.value
                            ? const SpinKitFadingCircle(
                              color: Colors.white,
                              size: 18,
                            )
                            : const Icon(Icons.calculate),
                    label: const Text('Calculate'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Additional action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Obx(
                  () => ElevatedButton(
                    onPressed:
                        controller.locationsEnabled.value &&
                                controller.enableDetails.value
                            ? controller.showDetails
                            : null,
                    child: const Text('Show Details'),
                  ),
                ),
                Obx(
                  () => ElevatedButton(
                    onPressed:
                        (controller.wantBestRoute.value &&
                                controller.locationsEnabled.value &&
                                !(controller.fouLocController.text.isEmpty &&
                                    controller.thrLocController.text.isEmpty))
                            ? controller.showBestRoute
                            : null,
                    child: const Text('Show Best Route'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            //Row(
            //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            //children: [
            Obx(() {
              return TextButton.icon(
                icon: Icon(Icons.map),
                onPressed:
                    controller.enableMaps.value ? controller.showMap : null,
                label: Text('Show map'),
              );
            }),
            //],
            //),
          ],
        ),
      ),
    );
  }
}
