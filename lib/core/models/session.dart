enum SessionStatus { pending, completed, cancelled }

extension SessionStatusExt on SessionStatus {
  String get value {
    switch (this) {
      case SessionStatus.pending: return 'PENDING';
      case SessionStatus.completed: return 'COMPLETED';
      case SessionStatus.cancelled: return 'CANCELLED';
    }
  }

  static SessionStatus fromString(String s) {
    switch (s.toUpperCase()) {
      case 'COMPLETED': return SessionStatus.completed;
      case 'CANCELLED': return SessionStatus.cancelled;
      default: return SessionStatus.pending;
    }
  }
}

class Session {
  final String id;
  final String userId;
  final String? studentId;
  final String branchName;
  final String programName;
  final String studentName;
  final DateTime date;
  final String timeSlot;
  final double durationHours;
  final double hourlyRate;
  final double totalAmount;
  final SessionStatus status;
  final bool isMakeup;
  final String colorHex;
  final DateTime createdAt;

  const Session({
    required this.id,
    required this.userId,
    this.studentId,
    required this.branchName,
    required this.programName,
    required this.studentName,
    required this.date,
    required this.timeSlot,
    required this.durationHours,
    required this.hourlyRate,
    required this.totalAmount,
    required this.status,
    required this.isMakeup,
    required this.colorHex,
    required this.createdAt,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      studentId: json['student_id'] as String?,
      branchName: json['branch_name'] as String,
      programName: json['program_name'] as String,
      studentName: json['student_name'] as String,
      date: DateTime.parse(json['date'] as String),
      timeSlot: json['time_slot'] as String,
      durationHours: (json['duration_hours'] as num).toDouble(),
      hourlyRate: (json['hourly_rate'] as num).toDouble(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: SessionStatusExt.fromString(json['status'] as String? ?? 'PENDING'),
      isMakeup: json['is_makeup'] as bool? ?? false,
      colorHex: json['color_hex'] as String? ?? '#3D5AFE',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'student_id': studentId,
      'branch_name': branchName,
      'program_name': programName,
      'student_name': studentName,
      'date': date.toIso8601String().split('T').first,
      'time_slot': timeSlot,
      'duration_hours': durationHours,
      'hourly_rate': hourlyRate,
      'total_amount': totalAmount,
      'status': status.value,
      'is_makeup': isMakeup,
      'color_hex': colorHex,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Session copyWith({
    String? id,
    String? userId,
    String? studentId,
    String? branchName,
    String? programName,
    String? studentName,
    DateTime? date,
    String? timeSlot,
    double? durationHours,
    double? hourlyRate,
    double? totalAmount,
    SessionStatus? status,
    bool? isMakeup,
    String? colorHex,
    DateTime? createdAt,
  }) {
    return Session(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      studentId: studentId ?? this.studentId,
      branchName: branchName ?? this.branchName,
      programName: programName ?? this.programName,
      studentName: studentName ?? this.studentName,
      date: date ?? this.date,
      timeSlot: timeSlot ?? this.timeSlot,
      durationHours: durationHours ?? this.durationHours,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      isMakeup: isMakeup ?? this.isMakeup,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

