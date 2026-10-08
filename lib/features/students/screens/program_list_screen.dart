import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/program.dart';
import '../../../core/services/supabase_service.dart';
import '../../../widgets/swipeable_action_card.dart';
import '../../../core/utils/currency_formatter.dart';

class ProgramListScreen extends StatefulWidget {
  const ProgramListScreen({super.key});

  @override
  State<ProgramListScreen> createState() => _ProgramListScreenState();
}

class _ProgramListScreenState extends State<ProgramListScreen> {
  List<Program> _programs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPrograms();
  }

  Future<void> _loadPrograms({bool forceRefresh = false}) async {
    if (_programs.isEmpty) setState(() => _loading = true);
    try {
      final programs = await SupabaseService.instance.getPrograms(forceRefresh: forceRefresh);
      if (mounted) setState(() => _programs = programs);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải danh sách: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteProgram(String id) async {
    try {
      await SupabaseService.instance.deleteProgram(id);
      setState(() => _programs.removeWhere((p) => p.id == id));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xóa CTĐT: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showAddProgramDialog([Program? program]) {
    final nameCtrl = TextEditingController(text: program?.name);
    final rateCtrl = TextEditingController(text: program?.defaultHourlyRate.toStringAsFixed(0));
    String colorHex = program?.colorHex ?? '#3D5AFE';
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(program == null ? 'Thêm CTĐT' : 'Sửa CTĐT'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Tên CTĐT'),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: rateCtrl,
                  decoration: const InputDecoration(labelText: 'Mức lương/giờ (VND)'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      final name = nameCtrl.text.trim();
                      final rateStr = rateCtrl.text.trim();
                      if (name.isEmpty || rateStr.isEmpty) return;
                      final rate = double.tryParse(rateStr) ?? 0;
                      
                      setState(() => isLoading = true);
                      try {
                        if (program == null) {
                          await SupabaseService.instance.createProgram(
                            name: name,
                            hourlyRate: rate,
                            colorHex: '#3D5AFE',
                          );
                        } else {
                          final updated = program.copyWith(
                            name: name,
                            defaultHourlyRate: rate,
                          );
                          await SupabaseService.instance.updateProgram(updated);
                        }
                        if (mounted) {
                          Navigator.pop(context);
                          _loadPrograms();
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
                          );
                        }
                        setState(() => isLoading = false);
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProgramDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? _buildSkeleton()
          : _programs.isEmpty
              ? const Center(child: Text('Chưa có CTĐT nào', style: TextStyle(color: AppColors.textSecondary)))
              : RefreshIndicator(
                  onRefresh: () => _loadPrograms(forceRefresh: true),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _programs.length,
                    itemBuilder: (context, index) {
                      final program = _programs[index];
                      return SwipeableActionCard(
                        margin: const EdgeInsets.only(bottom: 8),
                        deleteLabel: 'CTĐT "${program.name}"',
                        onDeleteConfirmed: () => _deleteProgram(program.id),
                        child: Card(
                          margin: EdgeInsets.zero,
                          child: ListTile(
                            title: Text(program.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(CurrencyFormatter.format(program.defaultHourlyRate)),
                            onTap: () => _showAddProgramDialog(program),
                            trailing: const Icon(Icons.edit, size: 20, color: AppColors.textSecondary),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
