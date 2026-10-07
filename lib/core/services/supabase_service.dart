import 'package:supabase_flutter/supabase_flutter.dart' hide Session;
import 'package:uuid/uuid.dart';
import '../models/branch.dart';
import '../models/program.dart';
import '../models/student.dart';
import '../models/session.dart';
import '../models/profile.dart';
import '../../core/utils/date_utils.dart';

class SupabaseService {
  final SupabaseClient _client;

  SupabaseService(this._client);

  static SupabaseService get instance =>
      SupabaseService(Supabase.instance.client);

  String get _userId => _client.auth.currentUser!.id;

  // ============================================================
  // AUTH
  // ============================================================

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ============================================================
  // PROFILE
  // ============================================================

  Future<Profile?> getProfile() async {
    try {
      final data =
          await _client.from('profiles').select().eq('id', _userId).single();
      return Profile.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateProfile(Profile profile) async {
    await _client.from('profiles').upsert({
      'id': _userId,
      'full_name': profile.fullName,
      'organization_name': profile.organizationName,
      'bank_name': profile.bankName,
      'bank_account_name': profile.bankAccountName,
      'bank_account_number': profile.bankAccountNumber,
      'salary_note': profile.salaryNote,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  // ============================================================
  // BRANCHES
  // ============================================================

  Future<List<Branch>> getBranches() async {
    final data = await _client
        .from('branches')
        .select()
        .eq('user_id', _userId)
        .order('created_at');
    return data.map((j) => Branch.fromJson(j)).toList();
  }

  Future<Branch> createBranch(String name) async {
    final data = await _client
        .from('branches')
        .insert({
          'user_id': _userId,
          'name': name,
        })
        .select()
        .single();
    return Branch.fromJson(data);
  }

  Future<void> updateBranch(String id, String name) async {
    await _client.from('branches').update({'name': name}).eq('id', id);
  }

  Future<void> deleteBranch(String id) async {
    await _client.from('branches').delete().eq('id', id);
  }

  // ============================================================
  // PROGRAMS
  // ============================================================

  Future<List<Program>> getPrograms() async {
    final data = await _client
        .from('programs')
        .select()
        .eq('user_id', _userId)
        .order('created_at');
    return data.map((j) => Program.fromJson(j)).toList();
  }

  Future<Program> createProgram({
    required String name,
    required double hourlyRate,
    required String colorHex,
  }) async {
    final data = await _client
        .from('programs')
        .insert({
          'user_id': _userId,
          'name': name,
          'default_hourly_rate': hourlyRate,
          'color_hex': colorHex,
        })
        .select()
        .single();
    return Program.fromJson(data);
  }

  Future<void> updateProgram(Program program) async {
    await _client.from('programs').update({
      'name': program.name,
      'default_hourly_rate': program.defaultHourlyRate,
      'color_hex': program.colorHex,
    }).eq('id', program.id);
  }

  Future<void> deleteProgram(String id) async {
    await _client.from('programs').delete().eq('id', id);
  }

  // ============================================================
  // STUDENTS
  // ============================================================

  Future<List<Student>> getStudents() async {
    final data = await _client
        .from('students')
        .select()
        .eq('user_id', _userId)
        .order('created_at');
    return data.map((j) => Student.fromJson(j)).toList();
  }

  Future<Student> createStudent(Student student) async {
    final data = await _client
        .from('students')
        .insert({
          'user_id': _userId,
          'branch_id': student.branchId,
          'program_id': student.programId,
          'name': student.name,
          'color_hex': student.colorHex,
          'schedule_days': student.scheduleDays,
          'start_time': student.startTime,
          'end_time': student.endTime,
        })
        .select()
        .single();
    return Student.fromJson(data);
  }

  Future<void> updateStudent(Student student) async {
    await _client.from('students').update({
      'branch_id': student.branchId,
      'program_id': student.programId,
      'name': student.name,
      'color_hex': student.colorHex,
      'schedule_days': student.scheduleDays,
      'start_time': student.startTime,
      'end_time': student.endTime,
    }).eq('id', student.id);
  }

  Future<void> deleteStudent(String id) async {
    // Delete ALL sessions related to this student
    await _client.from('sessions').delete().eq('student_id', id);

    // Xóa học sinh
    await _client.from('students').delete().eq('id', id);
  }

  // ============================================================
  // SESSIONS
  // ============================================================

  Future<List<Session>> getSessionsForMonth(DateTime month) async {
    final start = AppDateUtils.startOfMonth(month);
    final end = AppDateUtils.endOfMonth(month);
    final data = await _client
        .from('sessions')
        .select()
        .eq('user_id', _userId)
        .gte('date', start.toIso8601String().split('T').first)
        .lte('date', end.toIso8601String().split('T').first)
        .order('date')
        .order('time_slot');

    List<Session> existingSessions =
        data.map((j) => Session.fromJson(j)).toList();

    // Auto-generate missing regular sessions for this month based on students' schedules
    try {
      final students = await getStudents();
      final branches = await getBranches();
      final programs = await getPrograms();

      print(
          'DEBUG: Found ${students.length} students, ${branches.length} branches, ${programs.length} programs');

      List<Session> missingSessions = [];
      for (final student in students) {
        print(
            'DEBUG: Checking student ${student.name} (branch: ${student.branchId}, program: ${student.programId})');
        if (student.branchId == null || student.programId == null) continue;
        final branch = branches
            .cast<Branch?>()
            .firstWhere((b) => b?.id == student.branchId, orElse: () => null);
        final program = programs
            .cast<Program?>()
            .firstWhere((p) => p?.id == student.programId, orElse: () => null);
        if (branch == null || program == null) {
          print(
              'DEBUG: Branch or program not found for student ${student.name}');
          continue;
        }

        print(
            'DEBUG: Generating sessions for ${student.name} (days: ${student.scheduleDays}, start: ${student.startTime}, end: ${student.endTime})');
        final expectedSessions = generateSessionsForStudent(
          student: student,
          branchName: branch.name,
          programName: program.name,
          hourlyRate: program.defaultHourlyRate,
          month: month,
        );

        print('DEBUG: Expected sessions count: ${expectedSessions.length}');

        for (final expected in expectedSessions) {
          // Check if session exists (by studentId and date, and not a makeup session)
          final exists = existingSessions.any((s) =>
              s.studentId == student.id &&
              s.date.year == expected.date.year &&
              s.date.month == expected.date.month &&
              s.date.day == expected.date.day &&
              !s.isMakeup);
          if (!exists) {
            missingSessions.add(expected);
          }
        }
      }

      print(
          'DEBUG: Total missing sessions to create: ${missingSessions.length}');

      if (missingSessions.isNotEmpty) {
        await bulkCreateSessions(missingSessions);
        // Re-fetch sessions to get them with proper IDs from DB
        final newData = await _client
            .from('sessions')
            .select()
            .eq('user_id', _userId)
            .gte('date', start.toIso8601String().split('T').first)
            .lte('date', end.toIso8601String().split('T').first)
            .order('date')
            .order('time_slot');
        existingSessions = newData.map((j) => Session.fromJson(j)).toList();
      }
    } catch (e, stack) {
      print('Error auto-generating sessions: $e\n$stack');
      throw Exception('Lỗi tạo ca học tự động: $e');
    }

    return existingSessions;
  }

  Future<List<Session>> getSessionsForDate(DateTime date) async {
    final dateStr = date.toIso8601String().split('T').first;
    final data = await _client
        .from('sessions')
        .select()
        .eq('user_id', _userId)
        .eq('date', dateStr)
        .order('time_slot');
    return data.map((j) => Session.fromJson(j)).toList();
  }

  Future<void> createSession(Session session) async {
    await _client.from('sessions').insert({
      'id': session.id,
      'user_id': _userId,
      'student_id': session.studentId,
      'branch_name': session.branchName,
      'program_name': session.programName,
      'student_name': session.studentName,
      'date': session.date.toIso8601String().split('T').first,
      'time_slot': session.timeSlot,
      'duration_hours': session.durationHours,
      'hourly_rate': session.hourlyRate,
      'total_amount': session.totalAmount,
      'status': session.status.value,
      'is_makeup': session.isMakeup,
      'color_hex': session.colorHex,
    });
  }

  Future<void> bulkCreateSessions(List<Session> sessions) async {
    if (sessions.isEmpty) return;
    final data = sessions
        .map((s) => {
              'id': s.id,
              'user_id': _userId,
              'student_id': s.studentId,
              'branch_name': s.branchName,
              'program_name': s.programName,
              'student_name': s.studentName,
              'date': s.date.toIso8601String().split('T').first,
              'time_slot': s.timeSlot,
              'duration_hours': s.durationHours,
              'hourly_rate': s.hourlyRate,
              'total_amount': s.totalAmount,
              'status': s.status.value,
              'is_makeup': s.isMakeup,
              'color_hex': s.colorHex,
            })
        .toList();
    await _client.from('sessions').insert(data);
  }

  Future<void> updateSessionStatus(String id, SessionStatus status) async {
    await _client.from('sessions').update({
      'status': status.value,
    }).eq('id', id);
  }

  Future<void> deleteSession(String id) async {
    await _client.from('sessions').delete().eq('id', id);
  }

  // ============================================================
  // GENERATE SESSIONS FROM STUDENT SCHEDULE
  // ============================================================

  /// Generates sessions for a given student for the given month
  List<Session> generateSessionsForStudent({
    required Student student,
    required String branchName,
    required String programName,
    required double hourlyRate,
    required DateTime month,
  }) {
    if (student.scheduleDays.isEmpty ||
        student.startTime == null ||
        student.endTime == null) {
      return [];
    }

    final durationHours = AppDateUtils.hoursFromTimeRange(
      student.startTime!,
      student.endTime!,
    );
    final totalAmount = durationHours * hourlyRate;
    final timeSlot = '${student.startTime} - ${student.endTime}';
    final dates = AppDateUtils.getDatesInMonth(month, student.scheduleDays);
    const uuid = Uuid();

    return dates
        .map((date) => Session(
              id: uuid.v4(),
              userId: _userId,
              studentId: student.id,
              branchName: branchName,
              programName: programName,
              studentName: student.name,
              date: date,
              timeSlot: timeSlot,
              durationHours: durationHours,
              hourlyRate: hourlyRate,
              totalAmount: totalAmount,
              status: SessionStatus.pending,
              isMakeup: false,
              colorHex: student.colorHex,
              createdAt: DateTime.now(),
            ))
        .toList();
  }
}
