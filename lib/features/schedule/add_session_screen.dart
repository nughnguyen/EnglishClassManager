import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/branch.dart';
import '../../core/models/program.dart';
import '../../core/models/session.dart';
import '../../core/models/student.dart';
import '../../core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Session;
import 'package:uuid/uuid.dart';

class AddSessionScreen extends StatefulWidget {
  final Session? session;
  const AddSessionScreen({super.key, this.session});

  @override
  State<AddSessionScreen> createState() => _AddSessionScreenState();
}

class _AddSessionScreenState extends State<AddSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _studentNameCtrl = TextEditingController();

  List<Branch> _branches = [];
  List<Program> _programs = [];
  List<Student> _students = [];
  Branch? _selectedBranch;
  Program? _selectedProgram;

  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  bool _loading = false;
  bool _loadingData = true;

  @override
  void initState() {
    super.initState();
    _loadData();
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

          if (widget.session != null) {
            _studentNameCtrl.text = widget.session!.studentName;
            _selectedDate = widget.session!.date;

            try {
              _selectedBranch = _branches
                  .firstWhere((b) => b.name == widget.session!.branchName);
            } catch (_) {}
            try {
              _selectedProgram = _programs
                  .firstWhere((p) => p.name == widget.session!.programName);
            } catch (_) {}

            final times = widget.session!.timeSlot.split(' - ');
            if (times.length == 2) {
              _startTime = _parseTime(times[0]);
              _endTime = _parseTime(times[1]);
            }
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingData = false);
    }
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _timeStr(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (isStart ? _startTime : _endTime) ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart)
          _startTime = picked;
        else
          _endTime = picked;
      });
    }
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
    if (_studentNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vui lòng nhập hoặc chọn tên học sinh'),
            backgroundColor: AppColors.error),
      );
      return;
    }
    if (_selectedBranch == null || _selectedProgram == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vui lòng chọn chi nhánh và CTĐT'),
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
      if (widget.session != null) {
        // Update session
        // Wait, supabase_service doesn't have updateSession() yet. Let's assume we can just do raw update or we need to add it.
        // I will add a raw update here.
        await Supabase.instance.client.from('sessions').update({
          'branch_name': _selectedBranch!.name,
          'program_name': _selectedProgram!.name,
          'student_name': _studentNameCtrl.text.trim(),
          'date': _selectedDate.toIso8601String().split('T').first,
          'time_slot': '${_timeStr(_startTime!)} - ${_timeStr(_endTime!)}',
          'duration_hours': _durationHours,
          'hourly_rate': _selectedProgram!.defaultHourlyRate,
          'total_amount': _durationHours * _selectedProgram!.defaultHourlyRate,
        }).eq('id', widget.session!.id);
      } else {
        String sessionColor = _selectedProgram!.colorHex;
        try {
          final student = _students.firstWhere((s) => s.name == _studentNameCtrl.text.trim());
          sessionColor = student.colorHex;
        } catch (_) {}

        const uuid = Uuid();
        final session = Session(
          id: uuid.v4(),
          userId: '',
          studentId: null, // manual
          branchName: _selectedBranch!.name,
          programName: _selectedProgram!.name,
          studentName: _studentNameCtrl.text.trim(),
          date: _selectedDate,
          timeSlot: '${_timeStr(_startTime!)} - ${_timeStr(_endTime!)}',
          durationHours: _durationHours,
          hourlyRate: _selectedProgram!.defaultHourlyRate,
          totalAmount: _durationHours * _selectedProgram!.defaultHourlyRate,
          status: SessionStatus.pending,
          isMakeup: true, // It's manual / makeup
          colorHex: sessionColor,
          createdAt: DateTime.now(),
        );

        await SupabaseService.instance.createSession(session);
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
    if (_loadingData)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.session == null
            ? 'Thêm ca học thủ công'
            : 'Cập nhật ca học'),
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
              TextFormField(
                controller: _studentNameCtrl,
                decoration: InputDecoration(
                  labelText: 'Tên học sinh / Tên lớp',
                  filled: true,
                  fillColor: AppColors.surface,
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black45),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  suffixIcon: PopupMenuButton<String>(
                    icon: const Icon(Icons.arrow_drop_down),
                    onSelected: (String selection) {
                      _studentNameCtrl.text = selection;
                      try {
                        final student = _students.firstWhere((s) => s.name == selection);
                        if (student.branchId != null) {
                          _selectedBranch = _branches.firstWhere((b) => b.id == student.branchId);
                        }
                        if (student.programId != null) {
                          _selectedProgram = _programs.firstWhere((p) => p.id == student.programId);
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
              const SizedBox(height: 16),
              DropdownButtonFormField<Branch>(
                value: _selectedBranch,
                isExpanded: true,
                decoration: InputDecoration(
                    labelText: 'Chi nhánh',
                    filled: true,
                    isDense: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.black45),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: _branches
                    .map((b) => DropdownMenuItem(value: b, child: Text(b.name, overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedBranch = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Program>(
                value: _selectedProgram,
                isExpanded: true,
                decoration: InputDecoration(
                    labelText: 'Chương trình đào tạo',
                    filled: true,
                    isDense: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.black45),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: _programs
                    .map((p) => DropdownMenuItem(value: p, child: Text(p.name, overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedProgram = v),
              ),
              const SizedBox(height: 16),
              ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                tileColor: AppColors.surface,
                title: Text(
                    'Ngày: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                trailing:
                    const Icon(Icons.calendar_today, color: AppColors.primary),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickTime(true),
                      child: InputDecorator(
                        decoration: InputDecoration(
                            labelText: 'Giờ bắt đầu',
                            filled: true,
                            fillColor: AppColors.surface,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.black45),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        child: Text(_startTime == null
                            ? 'Chọn giờ'
                            : _timeStr(_startTime!)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickTime(false),
                      child: InputDecorator(
                        decoration: InputDecoration(
                            labelText: 'Giờ kết thúc',
                            filled: true,
                            fillColor: AppColors.surface,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.black45),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        child: Text(_endTime == null
                            ? 'Chọn giờ'
                            : _timeStr(_endTime!)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)
                      : Text(widget.session == null ? 'Lưu ca học' : 'Cập nhật',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
