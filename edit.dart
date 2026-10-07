import 'dart:io';

void main() {
  final file = File('lib/features/students/screens/add_student_screen.dart');
  var content = file.readAsStringSync();
  
  final startStr = "const SizedBox(height: 12);\n              TextFormField(";
  final endStr = "onChanged: (v) => setState(() => _selectedProgram = v),\n              ),";
  
  final startIndex = content.indexOf(startStr);
  final endIndex = content.indexOf(endStr) + endStr.length;
  
  if (startIndex == -1 || endIndex == -1) {
    print("Could not find bounds.");
    return;
  }
  
  final newContent = '''const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  return DropdownMenu<String>(
                    controller: _nameCtrl,
                    label: const Text('Tên l?p h?c / H?c viên'),
                    width: constraints.maxWidth,
                    textStyle: const TextStyle(fontSize: 14),
                    inputDecorationTheme: InputDecorationTheme(
                      filled: true,
                      fillColor: AppColors.surface,
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.black45),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    dropdownMenuEntries: _students.map((s) {
                      return DropdownMenuEntry<String>(
                        value: s.name,
                        label: s.name,
                      );
                    }).toList(),
                    onSelected: (String? selection) {
                      if (selection != null) {
                        _nameCtrl.text = selection;
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
                      }
                    },
                  );
                }
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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.black45),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: _branches.map((b) => DropdownMenuItem(value: b, child: Text(b.name, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) => setState(() => _selectedBranch = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Program>(
                value: _selectedProgram,
                isExpanded: true,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                decoration: InputDecoration(
                    labelText: 'Chuong trình dào t?o', 
                    filled: true, 
                    fillColor: AppColors.surface,
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.black45),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: _programs.map((p) => DropdownMenuItem(value: p, child: Text(p.name, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) => setState(() => _selectedProgram = v),
              ),''';
  
  content = content.replaceRange(startIndex, endIndex, newContent);
  file.writeAsStringSync(content);
  print("Done!");
}
