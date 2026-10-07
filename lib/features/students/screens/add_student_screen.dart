import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/branch.dart';
import '../../../core/models/program.dart';
import '../../../core/models/student.dart';
import '../../../core/services/supabase_service.dart';
import 'package:uuid/uuid.dart';

class AddStudentScreen extends StatefulWidget {
  final Student? student;
  const AddStudentScreen({super.key, this.student});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();

  List<Branch> _branches = [];
  List<Program> _programs = [];
  List<Student> _students = [];
  Branch? _selectedBranch;
  Program? _selectedProgram;
  List<int> _selectedDays = []; // 1=Mon..7=Sun
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _loading = false;
  bool _loadingData = true;

  final List<String> _dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final futures = await Future.wait([
        SupabaseService.instance.getBranches(),
        SupabaseService.instance.getPrograms(),
        SupabaseService.instance.getStudents(),
      ]);
      if (mounted) {
        setState(() {
          _branches = futures[0] as List<Branch>;
          _programs = futures[1] as List<Program>;
          _students = futures[2] as List<Student>;
          _loadingData = false;

          if (widget.student != null) {
            _nameCtrl.text = widget.student!.name;
            _selectedDays = List.from(widget.student!.scheduleDays);

            try {
              _selectedBranch =
                  _branches.firstWhere((b) => b.id == widget.student!.branchId);
            } catch (_) {}
            try {
              _selectedProgram = _programs
                  .firstWhere((p) => p.id == widget.student!.programId);
            } catch (_) {}

            if (widget.student!.startTime != null) {
              _startTime = _parseTime(widget.student!.startTime!);
            }
            if (widget.student!.endTime != null) {
              _endTime = _parseTime(widget.student!.endTime!);
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi tải dữ liệu: $e'),
              backgroundColor: AppColors.error),
        );
        setState(() => _loadingData = false);
      }
    }
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _timeStr(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  double get _durationHours {
    if (_startTime == null || _endTime == null) return 0;
    final startMin = _startTime!.hour * 60 + _startTime!.minute;
    final endMin = _endTime!.hour * 60 + _endTime!.minute;
    final diff = endMin - startMin;
    return diff > 0 ? diff / 60.0 : 0;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBranch == null || _selectedProgram == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vui lòng chọn chi nhánh và chương trình'),
            backgroundColor: AppColors.error),
      );
      return;
    }
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vui lòng chọn ít nhất 1 ngày học'),
            backgroundColor: AppColors.error),
      );
      return;
    }
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vui lòng chọn giờ học'),
            backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final service = SupabaseService.instance;
      if (widget.student != null) {
        final student = widget.student!.copyWith(
          branchId: _selectedBranch!.id,
          programId: _selectedProgram!.id,
          name: _nameCtrl.text.trim(),
          scheduleDays: _selectedDays,
          startTime: _timeStr(_startTime!),
          endTime: _timeStr(_endTime!),
        );
        await service.updateStudent(student);
      } else {
        const uuid = Uuid();
        final allStudents = await service.getStudents();
        final existingColors = allStudents.map((s) => s.colorHex).toList();
        final randomColor = AppColors.generateUniqueColor(existingColors);
        final student = Student(
          id: uuid.v4(),
          userId: '',
          branchId: _selectedBranch!.id,
          programId: _selectedProgram!.id,
          name: _nameCtrl.text.trim(),
          colorHex: AppColors.toHex(randomColor),
          scheduleDays: _selectedDays,
          startTime: _timeStr(_startTime!),
          endTime: _timeStr(_endTime!),
          createdAt: DateTime.now(),
        );
        final createdStudent = await service.createStudent(student);
        // Sessions will be auto-generated by the ScheduleScreen when it loads
      }

      if (mounted) Navigator.pop(context, true);
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

  @override
  Widget build(BuildContext context) {
    if (_loadingData) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title:
            Text(widget.student == null ? 'Thêm lớp học' : 'Cập nhật lớp học'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Thông tin cơ bản
              const Text('Thông tin lớp học',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Tên lớp học / Học viên',
                  filled: true,
                  fillColor: AppColors.surface,
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black45),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  suffixIcon: PopupMenuButton<String>(
                    icon: const Icon(Icons.arrow_drop_down),
                    onSelected: (String selection) {
                      _nameCtrl.text = selection;
                      try {
                        final student =
                            _students.firstWhere((s) => s.name == selection);
                        if (student.branchId != null) {
                          _selectedBranch = _branches
                              .firstWhere((b) => b.id == student.branchId);
                        }
                        if (student.programId != null) {
                          _selectedProgram = _programs
                              .firstWhere((p) => p.id == student.programId);
                        }
                      } catch (_) {}
                      setState(() {});
                    },
                    itemBuilder: (BuildContext context) {
                      return _students.map((s) {
                        return PopupMenuItem<String>(
                          value: s.name,
                          child: Text(s.name),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Branch>(
                value: _selectedBranch,
                isExpanded: true,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Chi nhánh',
                  filled: true,
                  fillColor: AppColors.surface,
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black45),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: _branches
                    .map((b) => DropdownMenuItem(
                        value: b,
                        child: Text(b.name, overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedBranch = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Program>(
                value: _selectedProgram,
                isExpanded: true,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Chương trình đào tạo',
                  filled: true,
                  fillColor: AppColors.surface,
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black45),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: _programs
                    .map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(p.name, overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedProgram = v),
              ),
              const SizedBox(height: 24),
              // Lịch học
              const Text('Lịch học định kỳ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (index) {
                  final day = index + 1;
                  final isSelected = _selectedDays.contains(day);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedDays.remove(day);
                        } else {
                          _selectedDays.add(day);
                        }
                      });
                    },
                    child: Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        _dayLabels[index],
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final t = await showTimePicker(
                            context: context,
                            initialTime: _startTime ??
                                const TimeOfDay(hour: 17, minute: 0));
                        if (t != null) setState(() => _startTime = t);
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Giờ bắt đầu',
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.black45),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        child: Text(_startTime != null
                            ? _timeStr(_startTime!)
                            : 'Chọn giờ'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final t = await showTimePicker(
                            context: context,
                            initialTime: _endTime ??
                                const TimeOfDay(hour: 19, minute: 0));
                        if (t != null) setState(() => _endTime = t);
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Giờ kết thúc',
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.black45),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        child: Text(_endTime != null
                            ? _timeStr(_endTime!)
                            : 'Chọn giờ'),
                      ),
                    ),
                  ),
                ],
              ),
              if (_durationHours > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                      'Thời lượng: ${_durationHours.toStringAsFixed(1)} giờ / buổi',
                      style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold)),
                ),
              const SizedBox(height: 32),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)
                      : Text(
                          widget.student == null
                              ? 'Thêm lớp học & Tạo lịch'
                              : 'Lưu thay đổi',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
