import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'branch_list_screen.dart';
import 'program_list_screen.dart';
import 'student_list_screen.dart';
import '../../../../main.dart';
import '../../../widgets/compact_header_action.dart';

class ClassManagementScreen extends StatefulWidget {
  const ClassManagementScreen({super.key});

  @override
  State<ClassManagementScreen> createState() => _ClassManagementScreenState();
}

class _ClassManagementScreenState extends State<ClassManagementScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final GlobalKey<StudentListScreenState> _studentsKey = studentListKey;
  final GlobalKey<BranchListScreenState> _branchesKey =
      GlobalKey<BranchListScreenState>();
  final GlobalKey<ProgramListScreenState> _programsKey =
      GlobalKey<ProgramListScreenState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this)
      ..addListener(_handleTabChanged);
  }

  void _handleTabChanged() {
    if (!_tabController.indexIsChanging && mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_handleTabChanged)
      ..dispose();
    super.dispose();
  }

  void _addCurrentItem() {
    switch (_tabController.index) {
      case 0:
        _studentsKey.currentState?.openAddStudent();
      case 1:
        _branchesKey.currentState?.openAddBranch();
      case 2:
        _programsKey.currentState?.openAddProgram();
    }
  }

  String get _addTooltip => switch (_tabController.index) {
        0 => 'Thêm lớp học',
        1 => 'Thêm chi nhánh',
        _ => 'Thêm chương trình đào tạo',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 68,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quản lý lớp học'),
            SizedBox(height: 2),
            Text('Học sinh, chi nhánh và chương trình',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CompactHeaderAction(
              icon: Icons.add_rounded,
              tooltip: _addTooltip,
              onPressed: _addCurrentItem,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          tabs: const [
            Tab(text: 'Học sinh'),
            Tab(text: 'Chi nhánh'),
            Tab(text: 'Chương trình'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          StudentListScreen(key: _studentsKey, isTab: true),
          BranchListScreen(key: _branchesKey),
          ProgramListScreen(key: _programsKey),
        ],
      ),
    );
  }
}
