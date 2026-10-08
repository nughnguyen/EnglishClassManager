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
          bottom: TabBar(
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

