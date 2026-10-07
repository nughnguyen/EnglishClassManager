class Student {
  final String id;
  final String userId;
  final String? branchId;
  final String? programId;
  final String name;
  final String colorHex;
  final List<int> scheduleDays; // 1=Mon..7=Sun
  final String? startTime; // 'HH:mm'
  final String? endTime;   // 'HH:mm'
  final DateTime createdAt;

  const Student({
    required this.id,
    required this.userId,
    this.branchId,
    this.programId,
    required this.name,
    required this.colorHex,
    required this.scheduleDays,
    this.startTime,
    this.endTime,
    required this.createdAt,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      branchId: json['branch_id'] as String?,
      programId: json['program_id'] as String?,
      name: json['name'] as String,
      colorHex: json['color_hex'] as String? ?? '#3D5AFE',
      scheduleDays: (json['schedule_days'] as List<dynamic>? ?? [])
          .map((e) => e as int)
          .toList(),
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'branch_id': branchId,
      'program_id': programId,
      'name': name,
      'color_hex': colorHex,
      'schedule_days': scheduleDays,
      'start_time': startTime,
      'end_time': endTime,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Student copyWith({
    String? id,
    String? userId,
    String? branchId,
    String? programId,
    String? name,
    String? colorHex,
    List<int>? scheduleDays,
    String? startTime,
    String? endTime,
    DateTime? createdAt,
  }) {
    return Student(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      branchId: branchId ?? this.branchId,
      programId: programId ?? this.programId,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      scheduleDays: scheduleDays ?? this.scheduleDays,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

