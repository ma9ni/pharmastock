import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pharmacy_wms/Services/api_config.dart';
import 'package:pharmacy_wms/Models/UserRoleModel.dart';
import 'package:pharmacy_wms/Services/MockService.dart';

class DashboardService {
  static String get _baseUrl => '${ApiConfig.baseUrl}/Dashboard';

  static Future<List<Map<String, dynamic>>> fetchActivity({int limit = 10}) async {
    if (ApiConfig.useMock) {
      await Future.delayed(const Duration(milliseconds: 200));
      return MockService.getDashboardActivity(limit: limit);
    }
    final response = await http
        .get(Uri.parse('$_baseUrl/activity?limit=$limit'), headers: AuthService.authHeaders)
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) return decoded.cast<Map<String, dynamic>>();
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> fetchStockMovement({int days = 30}) async {
    if (ApiConfig.useMock) {
      await Future.delayed(const Duration(milliseconds: 200));
      return MockService.getStockMovement(days: days);
    }
    final response = await http
        .get(Uri.parse('$_baseUrl/stock-movement?days=$days'), headers: AuthService.authHeaders)
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) return decoded.cast<Map<String, dynamic>>();
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> fetchTopConsumed({int? month, int? year}) async {
    if (ApiConfig.useMock) {
      await Future.delayed(const Duration(milliseconds: 200));
      return MockService.getTopConsumed(month: month, year: year);
    }
    final m = month ?? DateTime.now().month;
    final y = year ?? DateTime.now().year;
    final response = await http
        .get(Uri.parse('$_baseUrl/top-consumed?month=$m&year=$y'), headers: AuthService.authHeaders)
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) return decoded.cast<Map<String, dynamic>>();
    }
    return [];
  }
}
