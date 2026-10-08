import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/session.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/excel_export_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/models/profile.dart';

class SalaryReportScreen extends StatefulWidget {
  const SalaryReportScreen({super.key});

  @override
  State<SalaryReportScreen> createState() => SalaryReportScreenState();
}

class SalaryReportScreenState extends State<SalaryReportScreen> with WidgetsBindingObserver {
  DateTime _currentMonth = DateTime.now();
  List<Session> _sessions = [];
  bool _loading = true;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      loadData(showLoading: false);
    }
  }

  Future<void> loadData({bool showLoading = true, bool forceRefresh = false}) async {
    if (showLoading && _sessions.isEmpty) {
      setState(() => _loading = true);
    }
    try {
      final sessions = await SupabaseService.instance.getSessionsForMonth(
        _currentMonth,
        forceRefresh: forceRefresh,
      );
      if (mounted) setState(() => _sessions = sessions);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _prevMonth() {
    setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1));
    loadData();
  }

  void _nextMonth() {
    setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1));
    loadData();
  }

  List<Session> get _completedSessions =>
      _sessions.where((s) => s.status == SessionStatus.completed).toList();

  double get _totalSalary =>
      _completedSessions.fold(0.0, (sum, s) => sum + s.totalAmount);

  Map<String, List<Session>> get _sessionsByBranch {
    final Map<String, List<Session>> result = {};
    for (final s in _completedSessions) {
      result.putIfAbsent(s.branchName, () => []).add(s);
    }
    return result;
  }

  Future<void> _exportExcel() async {
    if (_completedSessions.isEmpty) return;
    setState(() => _exporting = true);
    try {
      final profile = await SupabaseService.instance.getProfile();
      if (profile == null || profile.fullName == null || profile.fullName!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vui lòng cập nhật hồ sơ trước khi xuất báo cáo'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
        return;
      }

      final exporter = ExcelExportService();
      final existingFile = await exporter.getReportFile(
        profile: profile,
        month: _currentMonth,
      );
      var overwriteExisting = false;
      if (await existingFile.exists()) {
        final choice = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Báo cáo đã tồn tại'),
            content: Text(
              'Đã có file ${existingFile.uri.pathSegments.last}. Bạn muốn ghi đè hay lưu thành file mới?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Lưu thành file mới'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Ghi đè'),
              ),
            ],
          ),
        );
        if (choice == null) return;
        overwriteExisting = choice;
      }
      await exporter.exportSalaryReport(
        profile: profile,
        sessions: _sessions,
        month: _currentMonth,
        overwriteExisting: overwriteExisting,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xuất Excel: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            // Month selector
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _prevMonth,
                  icon: const Icon(Icons.chevron_left_rounded, color: AppColors.primary),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${AppDateUtils.monthName(_currentMonth.month)} ${_currentMonth.year}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _nextMonth,
                  icon: const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _loading
                ? ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'THEO CHI NHÁNH',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(
                        3,
                        (index) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : RefreshIndicator(
                    onRefresh: () => loadData(showLoading: false, forceRefresh: true),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                      // Total Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primaryLight, AppColors.primary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'TỔNG LƯƠNG THÁNG',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              CurrencyFormatter.format(_totalSalary),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_completedSessions.length} ca đã hoàn thành / ${_sessions.length} ca tổng',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // By Branch
                      if (_sessionsByBranch.isNotEmpty) ...[
                        const Text(
                          'THEO CHI NHÁNH',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._sessionsByBranch.entries.map((e) {
                          final branchName = e.key;
                          final branchSessions = e.value;
                          final branchTotal = branchSessions.fold(0.0, (sum, s) => sum + s.totalAmount);
                          
                          // Sort sessions by date descending
                          branchSessions.sort((a, b) => b.date.compareTo(a.date));

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: AppColors.cardShadow,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                dividerColor: Colors.transparent, // Remove ExpansionTile borders
                              ),
                              child: ExpansionTile(
                                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                title: Text(
                                  branchName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    CurrencyFormatter.format(branchTotal),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ),
                                children: branchSessions.map((session) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: const BoxDecoration(
                                      border: Border(top: BorderSide(color: AppColors.divider)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${session.studentName} - ${session.programName}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${AppDateUtils.formatDate(session.date)} • ${session.timeSlot}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          CurrencyFormatter.format(session.totalAmount),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        }),
                      ],
                    ],
                    ),
                  ), // closes RefreshIndicator
          ),
        ],
      ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: (_loading || _exporting || _completedSessions.isEmpty) ? null : _exportExcel,
        backgroundColor: AppColors.success,
        icon: _exporting
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.file_download, color: Colors.white),
        label: Text(_exporting ? 'Đang xuất...' : 'Xuất báo cáo Excel', style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      color: AppColors.primary,
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Lương & Báo cáo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.manage_accounts, color: Colors.white),
            onPressed: () => _showProfileBottomSheet(context),
            tooltip: 'Cập nhật thông tin',
          ),
        ],
      ),
    );
  }

  Future<void> _showProfileBottomSheet(BuildContext context) async {
    // Show loading indicator while fetching profile
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final profile = await SupabaseService.instance.getProfile();
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (profile != null) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => _ProfileFormSheet(profile: profile),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
      );
    }
  }
}

class _ProfileFormSheet extends StatefulWidget {
  final Profile profile;
  const _ProfileFormSheet({required this.profile});

  @override
  State<_ProfileFormSheet> createState() => _ProfileFormSheetState();
}

class _ProfileFormSheetState extends State<_ProfileFormSheet> {
  late final TextEditingController _orgNameCtrl;
  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _bankNameCtrl;
  late final TextEditingController _bankAccountNameCtrl;
  late final TextEditingController _bankAccountNumberCtrl;
  late final TextEditingController _salaryNoteCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _orgNameCtrl = TextEditingController(text: widget.profile.organizationName);
    _fullNameCtrl = TextEditingController(text: widget.profile.fullName ?? '');
    _bankNameCtrl = TextEditingController(text: widget.profile.bankName ?? '');
    _bankAccountNameCtrl = TextEditingController(text: widget.profile.bankAccountName ?? '');
    _bankAccountNumberCtrl = TextEditingController(text: widget.profile.bankAccountNumber ?? '');
    _salaryNoteCtrl = TextEditingController(text: widget.profile.salaryNote ?? '');
  }

  @override
  void dispose() {
    _orgNameCtrl.dispose();
    _fullNameCtrl.dispose();
    _bankNameCtrl.dispose();
    _bankAccountNameCtrl.dispose();
    _bankAccountNumberCtrl.dispose();
    _salaryNoteCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      final p = widget.profile.copyWith(
        fullName: _fullNameCtrl.text.trim(),
        organizationName: _orgNameCtrl.text.trim().isEmpty ? 'TKCA VN' : _orgNameCtrl.text.trim(),
        bankName: _bankNameCtrl.text.trim(),
        bankAccountName: _bankAccountNameCtrl.text.trim(),
        bankAccountNumber: _bankAccountNumberCtrl.text.trim(),
        salaryNote: _salaryNoteCtrl.text.trim(),
      );
      await SupabaseService.instance.updateProfile(p);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lưu thông tin thành công'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Cập nhật thông tin',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _buildSection(
                  title: 'THÔNG TIN CHUNG',
                  children: [
                    _buildTextField(label: 'Tên trung tâm/Tổ chức', controller: _orgNameCtrl, icon: Icons.business),
                    const SizedBox(height: 12),
                    _buildTextField(label: 'Tên giáo viên', controller: _fullNameCtrl, icon: Icons.person),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSection(
                  title: 'THÔNG TIN THANH TOÁN (Xuất Excel)',
                  children: [
                    _buildTextField(label: 'Ngân hàng (VD: Vietcombank)', controller: _bankNameCtrl, icon: Icons.account_balance),
                    const SizedBox(height: 12),
                    _buildTextField(label: 'Tên chủ tài khoản', controller: _bankAccountNameCtrl, icon: Icons.badge),
                    const SizedBox(height: 12),
                    _buildTextField(label: 'Số tài khoản', controller: _bankAccountNumberCtrl, icon: Icons.numbers, isNumber: true),
                    const SizedBox(height: 12),
                    _buildTextField(label: 'Ghi chú thêm', controller: _salaryNoteCtrl, icon: Icons.note),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _saving ? null : _saveProfile,
              child: _saving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Lưu thông tin', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

}
