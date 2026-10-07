import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'branch_list_screen.dart';
import 'program_list_screen.dart';
import 'student_list_screen.dart';
import '../../../../main.dart';

class ClassManagementScreen extends StatefulWidget {
  const ClassManagementScreen({super.key});

  @override
  State<ClassManagementScreen> createState() => _ClassManagementScreenState();
}

class _ClassManagementScreenState extends State<ClassManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Lớp học'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Học sinh'),
              Tab(text: 'Chi nhánh'),
              Tab(text: 'CT Đào tạo'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            StudentListScreen(key: studentListKey, isTab: true),
            BranchListScreen(),
            ProgramListScreen(),
          ],
        ),
      ),
    );
  }
}

