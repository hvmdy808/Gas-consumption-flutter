import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _ccKey = 'ccNum';
  static const String _gasTypeKey = 'gasType';

  // Save vehicle details
  static Future<void> saveVehicleDetails(int cc, int gasType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_ccKey, cc);
    await prefs.setInt(_gasTypeKey, gasType);
  }

  // Get vehicle details
  static Future<Map<String, int?>> getVehicleDetails() async {
    final prefs = await SharedPreferences.getInstance();
    return {'cc': prefs.getInt(_ccKey), 'gasType': prefs.getInt(_gasTypeKey)};
  }
}
