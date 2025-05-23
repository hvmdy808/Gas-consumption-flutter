import 'package:flutter/material.dart';
import 'package:gas_app/preferences_services.dart';
import 'package:get/get.dart';

// Controller for managing Settings state
class SettingsController extends GetxController {
  final ccController = TextEditingController();
  final gasTypeController = TextEditingController();
  final errorText = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadSavedValues();
  }

  @override
  void onClose() {
    ccController.dispose();
    gasTypeController.dispose();
    super.onClose();
  }

  Future<void> loadSavedValues() async {
    final vehicleDetails = await PreferencesService.getVehicleDetails();
    if (vehicleDetails['cc'] != null) {
      ccController.text = vehicleDetails['cc'].toString();
    }
    if (vehicleDetails['gasType'] != null) {
      gasTypeController.text = vehicleDetails['gasType'].toString();
    }
  }

  void validateAndSave() {
    // Reset error text
    errorText.value = '';

    // Check if fields are empty
    if (ccController.text.isEmpty || gasTypeController.text.isEmpty) {
      errorText.value = 'You must enter cc and gasoline type numbers';
      return;
    }

    try {
      final cc = int.parse(ccController.text);
      final gasType = int.parse(gasTypeController.text);

      // Validate CC range
      if (cc < 50 || cc > 7000) {
        errorText.value = 'Invalid cc (must be between 50 and 7000)';
        return;
      }

      // Validate gas type
      if (![80, 92, 95].contains(gasType)) {
        errorText.value = 'Invalid gasoline type (must be 80, 92, or 95)';
        return;
      }

      // Save and navigate back
      PreferencesService.saveVehicleDetails(cc, gasType).then((_) {
        Get.back();
      });
    } catch (e) {
      errorText.value = 'Please enter valid numbers';
    }
  }
}

// Stateless SettingsScreen widget
class SettingsScreen extends StatelessWidget {
  SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize controller
    final SettingsController controller = Get.put(SettingsController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Settings'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Engine Size Input
            Text(
              'Add your vehicle cc',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.ccController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Cubic capacity here',
                prefixIcon: Icon(Icons.directions_car),
              ),
            ),
            const SizedBox(height: 24),

            // Gasoline Type Input
            Text(
              'Add the type of gasoline you use (like 80, 92, etc)',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.gasTypeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Type of gasoline here',
                prefixIcon: Icon(Icons.local_gas_station),
              ),
            ),
            const SizedBox(height: 24),

            // Error Text
            Obx(
              () =>
                  controller.errorText.value.isNotEmpty
                      ? Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Text(
                          controller.errorText.value,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                      : const SizedBox.shrink(),
            ),

            // Save Button
            ElevatedButton(
              onPressed: controller.validateAndSave,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Save',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
