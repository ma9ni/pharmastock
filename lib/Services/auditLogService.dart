import 'dart:convert';
import 'package:pharmacy_wms/Models/UserRoleModel.dart';
import 'package:pharmacy_wms/Models/auditLogModel.dart';
import 'package:pharmacy_wms/Services/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:pharmacy_wms/Services/MockService.dart';

class AuditLogService {
  static String get _baseUrl => '${ApiConfig.baseUrl}/AuditLog';

  static Future<List<AuditLogModel>> getAll() async {
    if (ApiConfig.useMock) {
      await Future.delayed(const Duration(milliseconds: 300));
      return MockService.getAuditLogs()
          .map((e) => AuditLogModel.fromJson(e))
          .toList();
    }
    final response = await http
        .get(Uri.parse(_baseUrl), headers: AuthService.authHeaders)
        .timeout(const Duration(seconds: 45));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List<dynamic> items =
          decoded is Map ? (decoded['data'] as List<dynamic>? ?? []) : [];
      return items
          .map((e) => AuditLogModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load audit logs (${response.statusCode})');
  }
}
