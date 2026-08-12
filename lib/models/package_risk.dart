class PackageRisk {
  final String package;
  final String name;
  final String riskLevel;
  final String description;

  PackageRisk({
    required this.package,
    required this.name,
    required this.riskLevel,
    required this.description,
  });

  factory PackageRisk.fromJson(Map<String, dynamic> json) {
    return PackageRisk(
      package: json['package'] as String,
      name: json['name'] as String,
      riskLevel: json['riskLevel'] as String,
      description: json['description'] as String,
    );
  }

  bool get isHighRisk => riskLevel == 'High' || riskLevel == 'Critical';
}
