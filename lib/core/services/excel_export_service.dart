import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/session.dart';
import '../models/profile.dart';

class ExcelExportService {
  Future<void> exportSalaryReport({
    required Profile profile,
    required List<Session> sessions,
    required DateTime month,
    required bool overwriteExisting,
  }) async {
    // Filter only COMPLETED sessions
    final completedSessions = sessions
        .where((s) => s.status == SessionStatus.completed)
        .toList();

    // Group by branch name
    final Map<String, List<Session>> byBranch = {};
    for (final s in completedSessions) {
      byBranch.putIfAbsent(s.branchName, () => []).add(s);
    }

    final excel = Excel.createExcel();
    excel.delete('Sheet1'); // Remove default sheet

    // ---- TOTAL SHEET ----
    final totalSheet = excel['TOTAL'];
    _setCell(totalSheet, 0, 0, 'BÁO CÁO LƯƠNG THÁNG ${month.month.toString().padLeft(2, '0')} / ${month.year}');
    _setCell(totalSheet, 1, 0, 'STT');
    _setCell(totalSheet, 1, 1, 'CHI NHÁNH');
    _setCell(totalSheet, 1, 2, 'TIỀN');
    _setCell(totalSheet, 1, 3, 'TỔNG TIỀN');

    int rowIdx = 2;
    double grandTotal = 0;
    int stt = 1;
    for (final entry in byBranch.entries) {
      final branchTotal = entry.value.fold(0.0, (sum, s) => sum + s.totalAmount);
      grandTotal += branchTotal;
      _setCell(totalSheet, rowIdx, 0, stt.toString());
      _setCell(totalSheet, rowIdx, 1, entry.key);
      _setCell(totalSheet, rowIdx, 2, branchTotal);
      rowIdx++;
      stt++;
    }
    _setCell(totalSheet, rowIdx, 2, 'TỔNG CỘNG');
    _setCell(totalSheet, rowIdx, 3, grandTotal);
    rowIdx++;

    // Bank info section
    rowIdx += 2;
    _setCell(totalSheet, rowIdx, 0, 'Ngân hàng');
    _setCell(totalSheet, rowIdx, 1, profile.bankName ?? '');
    rowIdx++;
    _setCell(totalSheet, rowIdx, 0, 'Chủ TK');
    _setCell(totalSheet, rowIdx, 1, profile.bankAccountName ?? '');
    rowIdx++;
    _setCell(totalSheet, rowIdx, 0, 'Số TK');
    _setCell(totalSheet, rowIdx, 1, profile.bankAccountNumber ?? '');
    rowIdx++;
    _setCell(totalSheet, rowIdx, 0, 'Ghi chú');
    _setCell(totalSheet, rowIdx, 1, profile.salaryNote ?? '');

    // ---- BRANCH SHEETS ----
    for (final entry in byBranch.entries) {
      final sheetName = entry.key.length > 31 ? entry.key.substring(0, 31) : entry.key;
      final sheet = excel[sheetName];

      // Headers
      final headers = [
        'NGÀY', 'THÁNG', 'NĂM', 'CA HỌC', 'TÊN GIÁO VIÊN',
        'SỐ LƯỢNG HỌC VIÊN', 'TÊN HỌC VIÊN', 'CHƯƠNG TRÌNH ĐÀO TẠO',
        'SỐ GIỜ', 'MỨC LƯƠNG DẠY/GIỜ', 'THÀNH TIỀN'
      ];
      for (int c = 0; c < headers.length; c++) {
        _setCell(sheet, 0, c, headers[c]);
      }

      // Data rows
      final sortedSessions = List<Session>.from(entry.value)
        ..sort((a, b) => a.date.compareTo(b.date));

      for (int i = 0; i < sortedSessions.length; i++) {
        final s = sortedSessions[i];
        final r = i + 1;
        _setCell(sheet, r, 0, s.date.day);
        _setCell(sheet, r, 1, s.date.month);
        _setCell(sheet, r, 2, s.date.year);
        _setCell(sheet, r, 3, s.timeSlot);
        _setCell(sheet, r, 4, profile.fullName ?? 'Giáo viên');
        _setCell(sheet, r, 5, 1); // 1 student per session
        _setCell(sheet, r, 6, s.studentName);
        _setCell(sheet, r, 7, s.programName);
        _setCell(sheet, r, 8, s.durationHours);
        _setCell(sheet, r, 9, s.hourlyRate);
        _setCell(sheet, r, 10, s.totalAmount);
      }

      // Total row
      final totalRow = sortedSessions.length + 1;
      _setCell(sheet, totalRow, 9, 'TỔNG CỘNG');
      _setCell(sheet, totalRow, 10,
          sortedSessions.fold(0.0, (sum, s) => sum + s.totalAmount));
      sheet.setColumnWidth(0, 10);
      sheet.setColumnWidth(1, 10);
      sheet.setColumnWidth(2, 10);
      sheet.setColumnWidth(3, 18);
      sheet.setColumnWidth(4, 24);
      sheet.setColumnWidth(5, 18);
      sheet.setColumnWidth(6, 26);
      sheet.setColumnWidth(7, 28);
      sheet.setColumnWidth(8, 12);
      sheet.setColumnWidth(9, 22);
      sheet.setColumnWidth(10, 18);
    }

    // Save and share
    final dir = await getApplicationDocumentsDirectory();
    final mm = month.month.toString().padLeft(2, '0');
    final yyyy = month.year.toString();

    final fileBytes = excel.save();
    if (fileBytes == null) throw Exception('Không thể tạo file Excel');

    final reportsDirectory = Directory('${dir.path}/ExcelReports');
    await reportsDirectory.create(recursive: true);
    final reportName = _reportFileName(profile, month);
    final baseFile = File('${reportsDirectory.path}/$reportName');
    var file = baseFile;
    if (await baseFile.exists() && !overwriteExisting) {
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(RegExp(r'[-:.]'), '')
          .substring(0, 18);
      file = File('${reportsDirectory.path}/${reportName.replaceFirst('.xlsx', ' ($timestamp).xlsx')}');
    }
    await file.writeAsBytes(fileBytes);
    final savedFileName = file.uri.pathSegments.last;

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: savedFileName,
      text: 'Báo cáo lương tháng $mm/$yyyy',
    );
  }

  Future<File> getReportFile({required Profile profile, required DateTime month}) async {
    final documents = await getApplicationDocumentsDirectory();
    final reportsDirectory = Directory('${documents.path}/ExcelReports');
    await reportsDirectory.create(recursive: true);
    return File('${reportsDirectory.path}/${_reportFileName(profile, month)}');
  }

  String _reportFileName(Profile profile, DateTime month) {
    final orgName = _safeFilePart(profile.organizationName);
    final teacherName = _safeFilePart(profile.fullName ?? 'Giáo viên');
    final mm = month.month.toString().padLeft(2, '0');
    return '$orgName - $teacherName - BÁO CÁO LƯƠNG THÁNG $mm - ${month.year}.xlsx';
  }

  String _safeFilePart(String value) =>
      value.replaceAll(RegExp(r'[<>:"/\\|?*]'), '').trim();

  void _setCell(Sheet sheet, int row, int col, dynamic value) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    if (value is int) {
      cell.value = IntCellValue(value);
    } else if (value is double) {
      cell.value = DoubleCellValue(value);
    } else if (value is String) {
      cell.value = TextCellValue(value);
    } else if (value == '') {
      cell.value = TextCellValue('');
    }
  }
}
