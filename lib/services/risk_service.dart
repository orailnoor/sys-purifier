import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/package_risk.dart';

class RiskService {
  static List<PackageRisk>? _riskDatabase;

  static Future<void> loadDatabase() async {
    try {
      final jsonString = await rootBundle.loadString('assets/risk_db.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      _riskDatabase = jsonList.map((json) => PackageRisk.fromJson(json)).toList();
    } catch (e) {
      print('Error loading risk database: $e');
      _riskDatabase = [];
    }
  }

  static PackageRisk? getRisk(String packageName) {
    if (_riskDatabase == null) return null;
    try {
      return _riskDatabase!.firstWhere((risk) => risk.package == packageName);
    } catch (_) {
      return null;
    }
  }

  static bool isCoreSpyware(String packageName) {
    final risk = getRisk(packageName);
    return risk != null && (risk.riskLevel == 'High' || risk.riskLevel == 'Critical');
  }
}
