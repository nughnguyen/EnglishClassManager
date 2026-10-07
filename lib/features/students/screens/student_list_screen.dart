import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../main.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/student.dart';
import '../../../core/models/branch.dart';
import '../../../core/models/program.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/date_utils.dart';
import '../../../widgets/swipeable_action_card.dart';
import 'add_student_screen.dart';

class StudentListScreen extends StatefulWidget {
  final bool isTab;
  const StudentListScreen({super.key, this.isTab = false});

  @override
  State<StudentListScreen> createState() => StudentListScreenState();
}

class StudentListScreenState extends State<StudentListScreen> {
  List<Student> _students = [];
  List<Branch> _branches = [];
  List<Program> _programs = [];
  String? _selectedBranchId;
  String _searchQuery = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void loadStudents() {
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final students = await SupabaseService.instance.getStudents();
      final branches = await SupabaseService.instance.getBranches();
      final programs = await SupabaseService.instance.getPrograms();
      if (mounted) {
        setState(() {
          _students = students;
          _branches = branches;
          _programs = programs;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải dữ liệu: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _deleteStudent(String id) async {
    try {
      await SupabaseService.instance.deleteStudent(id);
      setState(() {
        _students.removeWhere((s) => s.id == id);
      });
      scheduleKey.currentState?.loadSessions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xoá học sinh: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _navigateToAdd({Student? student}) async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddStudentScreen(student: student)),
    );
    if (added == true) {
      _loadData();
      scheduleKey.currentState?.loadSessions();
    }
  }

  List<Student> get _filteredStudents {
    return _students.where((s) {
      final matchSearch =
          s.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchBranch =
          _selectedBranchId == null || s.branchId == _selectedBranchId;
      return matchSearch && matchBranch;
    }).toList();
  }

  String _getBranchName(String? branchId) {
    if (branchId == null) return '';
    try {
      return _branches.firstWhere((b) => b.id == branchId).name;
    } catch (_) {
      return '';
    }
  }

  String _getProgramName(String? programId) {
    if (programId == null) return '';
    try {
      return _programs.firstWhere((p) => p.id == programId).name;
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: widget.isTab
          ? FloatingActionButton(
              onPressed: _navigateToAdd,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            if (!widget.isTab) _buildHeader(),
            _buildSearchBar(),
            _buildFilterChips(),
            Expanded(
              child: _loading
                  ? _buildSkeleton()
                  : _filteredStudents.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            itemCount: _filteredStudents.length,
                            itemBuilder: (context, index) {
                              final student = _filteredStudents[index];
                              return SwipeableActionCard(
                                key: ValueKey(student.id),
                                margin: const EdgeInsets.only(bottom: 12),
                                deleteLabel: 'h?c sinh "${student.name}"',
                                onDeleteConfirmed: () =>
                                    _deleteStudent(student.id),
                                onEdit: () => _navigateToAdd(student: student),
                                child: _StudentCard(
                                  student: student,
                                  branchName: _getBranchName(student.branchId),
                                  programName:
                                      _getProgramName(student.programId),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      color: AppColors.primary,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'H?c sinh',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _navigateToAdd(),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Thêm',
                style: TextStyle(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm học sinh...',
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildChip('Tất cả', null),
          ..._branches.map((b) => _buildChip(b.name, b.id)),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String? branchId) {
    final isSelected = _selectedBranchId == branchId;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedBranchId = selected ? branchId : null;
          });
        },
        backgroundColor: Colors.white,
        selectedColor: AppColors.primaryLight.withOpacity(0.2),
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? AppColors.primaryLight : AppColors.divider,
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 6,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline,
              size: 72, color: AppColors.textSecondary.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text(
            'Chưa có học sinh nào',
            style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final Student student;
  final String branchName;
  final String programName;

  const _StudentCard({
    required this.student,
    required this.branchName,
    required this.programName,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.fromHex(student.colorHex);
    final days = student.scheduleDays
        .map((d) => AppDateUtils.formatDayOfWeek(d))
        .join(', ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                student.name.isNotEmpty ? student.name[0].toUpperCase() : 'H',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  student.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        branchName.isNotEmpty
                            ? branchName
                            : 'Chưa có chi nhánh',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.school_outlined,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        programName.isNotEmpty
                            ? programName
                            : 'Chưa có chương trình đào tạo',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time, size: 11, color: color),
                      const SizedBox(width: 4),
                      Text(
                        '$days ${student.startTime != null ? "� ${student.startTime}" : ""}',
                        style: TextStyle(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
