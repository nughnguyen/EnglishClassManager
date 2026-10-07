class Profile {
  final String id;
  final String? fullName;
  final String organizationName;
  final String? bankName;
  final String? bankAccountName;
  final String? bankAccountNumber;
  final String? salaryNote;
  final DateTime? updatedAt;

  const Profile({
    required this.id,
    this.fullName,
    required this.organizationName,
    this.bankName,
    this.bankAccountName,
    this.bankAccountNumber,
    this.salaryNote,
    this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      organizationName: json['organization_name'] as String? ?? 'TKCA VN',
      bankName: json['bank_name'] as String?,
      bankAccountName: json['bank_account_name'] as String?,
      bankAccountNumber: json['bank_account_number'] as String?,
      salaryNote: json['salary_note'] as String?,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'organization_name': organizationName,
      'bank_name': bankName,
      'bank_account_name': bankAccountName,
      'bank_account_number': bankAccountNumber,
      'salary_note': salaryNote,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Profile copyWith({
    String? id,
    String? fullName,
    String? organizationName,
    String? bankName,
    String? bankAccountName,
    String? bankAccountNumber,
    String? salaryNote,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      organizationName: organizationName ?? this.organizationName,
      bankName: bankName ?? this.bankName,
      bankAccountName: bankAccountName ?? this.bankAccountName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      salaryNote: salaryNote ?? this.salaryNote,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
