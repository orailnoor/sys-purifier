import 'package:flutter_test/flutter_test.dart';
import 'package:degoogle_tool/models/package_risk.dart';

void main() {
  test('PackageRisk correctly parses from JSON', () {
    final json = {
      "package": "com.test.app",
      "name": "Test Application",
      "riskLevel": "High",
      "description": "A test app."
    };

    final risk = PackageRisk.fromJson(json);

    expect(risk.package, "com.test.app");
    expect(risk.name, "Test Application");
    expect(risk.riskLevel, "High");
    expect(risk.description, "A test app.");
    expect(risk.isHighRisk, true);
  });
  
  test('PackageRisk identifies non-high risk', () {
    final json = {
      "package": "com.test.app2",
      "name": "Test Application 2",
      "riskLevel": "Low",
      "description": "A test app."
    };

    final risk = PackageRisk.fromJson(json);
    expect(risk.isHighRisk, false);
  });
}
