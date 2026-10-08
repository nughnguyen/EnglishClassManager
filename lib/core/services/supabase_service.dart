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

  static final Map<String, Profile?> _profileCache = {};
  static final Map<String, Future<Profile?>> _profileRequests = {};
  static final Map<String, List<Branch>> _branchCache = {};
  static final Map<String, Future<List<Branch>>> _branchRequests = {};
  static final Map<String, List<Program>> _programCache = {};
  static final Map<String, Future<List<Program>>> _programRequests = {};
  static final Map<String, List<Student>> _studentCache = {};
  static final Map<String, Future<List<Student>>> _studentRequests = {};
  static final Map<String, List<Session>> _sessionCache = {};
  static final Map<String, Future<List<Session>>> _sessionRequests = {};
  static final Map<String, int> _cacheVersions = {};

  SupabaseService(this._client);

  static SupabaseService get instance =>
      SupabaseService(Supabase.instance.client);

  String get _userId => _client.auth.currentUser!.id;

  String _cacheKey(String type, [String? suffix]) =>
      '$_userId:$type${suffix == null ? '' : ':$suffix'}';

  int _cacheVersion(String key) => _cacheVersions[key] ?? 0;

  void _bumpCacheVersion(String key) {
    _cacheVersions[key] = _cacheVersion(key) + 1;
  }

  void _invalidateProfile() {
    final key = _cacheKey('profile');
    _bumpCacheVersion(key);
    _profileCache.remove(key);
    _profileRequests.remove(key);
  }

  void _invalidateBranches() {
    final key = _cacheKey('branches');
    _bumpCacheVersion(key);
    _branchCache.remove(key);
    _branchRequests.remove(key);
  }

  void _invalidatePrograms() {
    final key = _cacheKey('programs');
    _bumpCacheVersion(key);
    _programCache.remove(key);
    _programRequests.remove(key);
  }

  void _invalidateStudents() {
    final key = _cacheKey('students');
    _bumpCacheVersion(key);
    _studentCache.remove(key);
    _studentRequests.remove(key);
    _invalidateSessions();
  }

  void _invalidateSessions() {
    final prefix = _cacheKey('sessions:');
    for (final key in _sessionCache.keys.where((key) => key.startsWith(prefix))) {
      _bumpCacheVersion(key);
    }
    for (final key in _sessionRequests.keys.where((key) => key.startsWith(prefix))) {
      _bumpCacheVersion(key);
    }
    _sessionCache.removeWhere((key, _) => key.startsWith(prefix));
    _sessionRequests.removeWhere((key, _) => key.startsWith(prefix));
  }

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
    final userId = _userId;
    _profileCache.removeWhere((key, _) => key.startsWith('$userId:'));
    _profileRequests.removeWhere((key, _) => key.startsWith('$userId:'));
    _branchCache.removeWhere((key, _) => key.startsWith('$userId:'));
    _branchRequests.removeWhere((key, _) => key.startsWith('$userId:'));
    _programCache.removeWhere((key, _) => key.startsWith('$userId:'));
    _programRequests.removeWhere((key, _) => key.startsWith('$userId:'));
    _studentCache.removeWhere((key, _) => key.startsWith('$userId:'));
    _studentRequests.removeWhere((key, _) => key.startsWith('$userId:'));
    _sessionCache.removeWhere((key, _) => key.startsWith('$userId:'));
    _sessionRequests.removeWhere((key, _) => key.startsWith('$userId:'));
    _cacheVersions.removeWhere((key, _) => key.startsWith('$userId:'));
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ============================================================
  // PROFILE
  // ============================================================

  Future<Profile?> getProfile({bool forceRefresh = false}) async {
    final key = _cacheKey('profile');
    if (forceRefresh) {
      _bumpCacheVersion(key);
      _profileCache.remove(key);
      _profileRequests.remove(key);
    }
    if (_profileCache.containsKey(key)) return _profileCache[key];
    final pending = _profileRequests[key];
    if (pending != null) return pending;

    final version = _cacheVersion(key);
    final request = _fetchProfile();
    _profileRequests[key] = request;
    try {
      final profile = await request;
      if (profile != null && _cacheVersion(key) == version) {
        _profileCache[key] = profile;
      }
      return profile;
    } finally {
      if (identical(_profileRequests[key], request)) _profileRequests.remove(key);
    }
  }

  Future<Profile?> _fetchProfile() async {
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
    _invalidateProfile();
  }

  // ============================================================
  // BRANCHES
  // ============================================================

  Future<List<Branch>> getBranches({bool forceRefresh = false}) async {
    final key = _cacheKey('branches');
    if (forceRefresh) {
      _bumpCacheVersion(key);
      _branchCache.remove(key);
      _branchRequests.remove(key);
    }
    final cached = _branchCache[key];
    if (cached != null) return List.of(cached);
    final pending = _branchRequests[key];
    if (pending != null) return List.of(await pending);

    final version = _cacheVersion(key);
    final request = _fetchBranches();
    _branchRequests[key] = request;
    try {
      final branches = await request;
      if (_cacheVersion(key) == version) _branchCache[key] = branches;
      return List.of(branches);
    } finally {
      if (identical(_branchRequests[key], request)) _branchRequests.remove(key);
    }
  }

  Future<List<Branch>> _fetchBranches() async {
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
    _invalidateBranches();
    _invalidateSessions();
    return Branch.fromJson(data);
  }

  Future<void> updateBranch(String id, String name) async {
    await _client.from('branches').update({'name': name}).eq('id', id);
    _invalidateBranches();
    _invalidateSessions();
  }

  Future<void> deleteBranch(String id) async {
    await _client.from('branches').delete().eq('id', id);
    _invalidateBranches();
    _invalidateSessions();
  }

  // ============================================================
  // PROGRAMS
  // ============================================================

  Future<List<Program>> getPrograms({bool forceRefresh = false}) async {
    final key = _cacheKey('programs');
    if (forceRefresh) {
      _bumpCacheVersion(key);
      _programCache.remove(key);
      _programRequests.remove(key);
    }
    final cached = _programCache[key];
    if (cached != null) return List.of(cached);
    final pending = _programRequests[key];
    if (pending != null) return List.of(await pending);

    final version = _cacheVersion(key);
    final request = _fetchPrograms();
    _programRequests[key] = request;
    try {
      final programs = await request;
      if (_cacheVersion(key) == version) _programCache[key] = programs;
      return List.of(programs);
    } finally {
      if (identical(_programRequests[key], request)) _programRequests.remove(key);
    }
  }

  Future<List<Program>> _fetchPrograms() async {
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
    _invalidatePrograms();
    _invalidateSessions();
    return Program.fromJson(data);
  }

  Future<void> updateProgram(Program program) async {
    await _client.from('programs').update({
      'name': program.name,
      'default_hourly_rate': program.defaultHourlyRate,
      'color_hex': program.colorHex,
    }).eq('id', program.id);
    _invalidatePrograms();
    _invalidateSessions();
  }

  Future<void> deleteProgram(String id) async {
    await _client.from('programs').delete().eq('id', id);
    _invalidatePrograms();
    _invalidateSessions();
  }

  // ============================================================
  // STUDENTS
  // ============================================================

  Future<List<Student>> getStudents({bool forceRefresh = false}) async {
    final key = _cacheKey('students');
    if (forceRefresh) {
      _bumpCacheVersion(key);
      _studentCache.remove(key);
      _studentRequests.remove(key);
    }
    final cached = _studentCache[key];
    if (cached != null) return List.of(cached);
    final pending = _studentRequests[key];
    if (pending != null) return List.of(await pending);

    final version = _cacheVersion(key);
    final request = _fetchStudents();
    _studentRequests[key] = request;
    try {
      final students = await request;
      if (_cacheVersion(key) == version) _studentCache[key] = students;
      return List.of(students);
    } finally {
      if (identical(_studentRequests[key], request)) _studentRequests.remove(key);
    }
  }

  Future<List<Student>> _fetchStudents() async {
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
    _invalidateStudents();
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
    _invalidateStudents();
  }

  Future<List<String>> deleteStudent(String id) async {
    final linkedSessions = await _client
        .from('sessions')
        .select('id')
        .eq('student_id', id)
        .eq('user_id', _userId);
    final deletedSessionIds = linkedSessions
        .map<String>((row) => row['id'].toString())
        .toList();

    // Xóa tất cả các ca học liên quan đến học sinh này
    await _client
        .from('sessions')
        .delete()
        .eq('student_id', id)
        .eq('user_id', _userId);

    // Xóa học sinh
    await _client.from('students').delete().eq('id', id);
    _invalidateStudents();
    _invalidateSessions();
    return deletedSessionIds;
  }

  // ============================================================
  // SESSIONS
  // ============================================================

  Future<List<Session>> getSessionsForMonth(
    DateTime month, {
    bool forceRefresh = false,
  }) async {
    final monthKey = '${month.year}-${month.month.toString().padLeft(2, '0')}';
    final key = _cacheKey('sessions', monthKey);
    if (forceRefresh) {
      _bumpCacheVersion(key);
      _sessionCache.remove(key);
      _sessionRequests.remove(key);
    }
    final cached = _sessionCache[key];
    if (cached != null) return List.of(cached);
    final pending = _sessionRequests[key];
    if (pending != null) return List.of(await pending);

    final version = _cacheVersion(key);
    final request = _fetchSessionsForMonth(month);
    _sessionRequests[key] = request;
    try {
      final sessions = await request;
      if (_cacheVersion(key) == version) _sessionCache[key] = sessions;
      return List.of(sessions);
    } finally {
      if (identical(_sessionRequests[key], request)) _sessionRequests.remove(key);
    }
  }

  Future<List<Session>> _fetchSessionsForMonth(DateTime month) async {
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

    final now = DateTime.now();
    final previousMonthStart = DateTime(now.year, now.month - 1);
    final nextMonthStart = DateTime(now.year, now.month + 1);
    final targetMonthStart = DateTime(month.year, month.month);

    if (targetMonthStart.isBefore(previousMonthStart) ||
        targetMonthStart.isAfter(nextMonthStart)) {
      return existingSessions;
    }

    // Tự động tạo các ca học còn thiếu trong tháng dựa trên lịch học sinh
    try {
      final students = await getStudents();
      final branches = await getBranches();
      final programs = await getPrograms();

      List<Session> missingSessions = [];
      for (final student in students) {
        if (student.branchId == null || student.programId == null) continue;
        final branch = branches
            .cast<Branch?>()
            .firstWhere((b) => b?.id == student.branchId, orElse: () => null);
        final program = programs
            .cast<Program?>()
            .firstWhere((p) => p?.id == student.programId, orElse: () => null);
        if (branch == null || program == null) {
          continue;
        }

        final expectedSessions = generateSessionsForStudent(
          student: student,
          branchName: branch.name,
          programName: program.name,
          hourlyRate: program.defaultHourlyRate,
          month: month,
        );

        for (final expected in expectedSessions) {
          // Kiểm tra xem ca học đã tồn tại chưa (theo studentId, ngày và không phải ca học bù)
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

      if (missingSessions.isNotEmpty) {
        await bulkCreateSessions(missingSessions, invalidateCache: false);
        // Tải lại danh sách ca học kèm ID từ database
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
    } catch (e) {
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
    _invalidateSessions();
  }

  Future<void> bulkCreateSessions(
    List<Session> sessions, {
    bool invalidateCache = true,
  }) async {
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
    if (invalidateCache) _invalidateSessions();
  }

  Future<void> updateSessionStatus(String id, SessionStatus status) async {
    await _client.from('sessions').update({
      'status': status.value,
    }).eq('id', id);
    _invalidateSessions();
  }

  Future<void> deleteSession(String id) async {
    await _client.from('sessions').delete().eq('id', id);
    _invalidateSessions();
  }

  // ============================================================
  // GENERATE SESSIONS FROM STUDENT SCHEDULE
  // ============================================================

  /// Tạo danh sách ca học định kỳ cho học sinh trong tháng được chỉ định
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
