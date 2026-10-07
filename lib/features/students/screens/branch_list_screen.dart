import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/branch.dart';
import '../../../core/services/supabase_service.dart';
import '../../../widgets/swipeable_action_card.dart';

class BranchListScreen extends StatefulWidget {
  const BranchListScreen({super.key});

  @override
  State<BranchListScreen> createState() => _BranchListScreenState();
}

class _BranchListScreenState extends State<BranchListScreen> {
  List<Branch> _branches = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    setState(() => _loading = true);
    try {
      final branches = await SupabaseService.instance.getBranches();
      if (mounted) setState(() => _branches = branches);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi tải danh sách: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteBranch(String id) async {
    try {
      await SupabaseService.instance.deleteBranch(id);
      setState(() => _branches.removeWhere((b) => b.id == id));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi xóa chi nhánh: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showAddBranchDialog([Branch? branch]) {
    final nameCtrl = TextEditingController(text: branch?.name);
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(branch == null ? 'Thêm chi nhánh' : 'Sửa chi nhánh'),
          content: TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(labelText: 'Tên chi nhánh'),
            autofocus: true,
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
                      if (name.isEmpty) return;
                      setState(() => isLoading = true);
                      try {
                        if (branch == null) {
                          await SupabaseService.instance.createBranch(name);
                        } else {
                          await SupabaseService.instance
                              .updateBranch(branch.id, name);
                        }
                        if (mounted) {
                          Navigator.pop(context);
                          _loadBranches();
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Lỗi: $e'),
                                backgroundColor: AppColors.error),
                          );
                        }
                        setState(() => isLoading = false);
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
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
        onPressed: () => _showAddBranchDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? _buildSkeleton()
          : _branches.isEmpty
              ? const Center(
                  child: Text('Chưa có chi nhánh nào',
                      style: TextStyle(color: AppColors.textSecondary)))
              : RefreshIndicator(
                  onRefresh: _loadBranches,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _branches.length,
                    itemBuilder: (context, index) {
                      final branch = _branches[index];
                      return SwipeableActionCard(
                        margin: const EdgeInsets.only(bottom: 8),
                        deleteLabel: 'chi nhánh "${branch.name}"',
                        onDeleteConfirmed: () => _deleteBranch(branch.id),
                        child: Card(
                          margin: EdgeInsets.zero,
                          child: ListTile(
                            title: Text(branch.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            onTap: () => _showAddBranchDialog(branch),
                            trailing: const Icon(Icons.edit,
                                size: 20, color: AppColors.textSecondary),
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
            height: 56,
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
