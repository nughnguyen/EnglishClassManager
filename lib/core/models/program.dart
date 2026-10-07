class Program {
  final String id;
  final String userId;
  final String name;
  final double defaultHourlyRate;
  final String colorHex;
  final DateTime createdAt;

  const Program({
    required this.id,
    required this.userId,
    required this.name,
    required this.defaultHourlyRate,
    required this.colorHex,
    required this.createdAt,
  });

  factory Program.fromJson(Map<String, dynamic> json) {
    return Program(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      defaultHourlyRate: (json['default_hourly_rate'] as num).toDouble(),
      colorHex: json['color_hex'] as String? ?? '#3D5AFE',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'default_hourly_rate': defaultHourlyRate,
      'color_hex': colorHex,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Program copyWith({
    String? id,
    String? userId,
    String? name,
    double? defaultHourlyRate,
    String? colorHex,
    DateTime? createdAt,
  }) {
    return Program(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      defaultHourlyRate: defaultHourlyRate ?? this.defaultHourlyRate,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

