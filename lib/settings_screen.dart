import 'package:flutter/material.dart';
import 'package:gas_app/home_screen.dart';
import 'package:gas_app/preferences_services.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _ccController = TextEditingController();
  final TextEditingController _gasTypeController = TextEditingController();
  String _errorText = '';

  @override
  void initState() {
    super.initState();
    _loadSavedValues();
  }

  Future<void> _loadSavedValues() async {
    final vehicleDetails = await PreferencesService.getVehicleDetails();
    setState(() {
      if (vehicleDetails['cc'] != null) {
        _ccController.text = vehicleDetails['cc'].toString();
      }
      if (vehicleDetails['gasType'] != null) {
        _gasTypeController.text = vehicleDetails['gasType'].toString();
      }
    });
  }

  void _validateAndSave() {
    setState(() {
      _errorText = '';
    });

    // Check if fields are empty
    if (_ccController.text.isEmpty || _gasTypeController.text.isEmpty) {
      setState(() {
        _errorText = 'You must enter cc and gasoline type numbers';
      });
      return;
    }

    try {
      final cc = int.parse(_ccController.text);
      final gasType = int.parse(_gasTypeController.text);

      // Validate CC range
      if (cc < 50 || cc > 7000) {
        setState(() {
          _errorText = 'Invalid cc (must be between 50 and 7000)';
        });
        return;
      }

      // Validate gas type
      if (![80, 92, 95].contains(gasType)) {
        setState(() {
          _errorText = 'Invalid gasoline type (must be 80, 92, or 95)';
        });
        return;
      }

      // Save and navigate back
      PreferencesService.saveVehicleDetails(cc, gasType).then((_) {
        Get.back();
      });
    } catch (e) {
      setState(() {
        _errorText = 'Please enter valid numbers';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
              controller: _ccController,
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
              controller: _gasTypeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Type of gasoline here',
                prefixIcon: Icon(Icons.local_gas_station),
              ),
            ),
            const SizedBox(height: 24),

            // Error Text
            if (_errorText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  _errorText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // Next Button
            ElevatedButton(
              onPressed: _validateAndSave,
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

  @override
  void dispose() {
    _ccController.dispose();
    _gasTypeController.dispose();
    super.dispose();
  }
}
