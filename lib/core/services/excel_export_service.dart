import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';

import '../models/profile.dart';
import '../models/session.dart';

class ExcelExportService {
  static const _reportsFolderName = 'ExcelReports';
  static const _totalSheetName = 'TOTAL';

  Future<File> exportSalaryReport({
    required Profile profile,
    required List<Session> sessions,
    required DateTime month,
    required bool overwriteExisting,
  }) async {
    final completedSessions = sessions
        .where((session) => session.status == SessionStatus.completed)
        .toList();
    final sessionsByBranch = <String, List<Session>>{};
    for (final session in completedSessions) {
      sessionsByBranch.putIfAbsent(session.branchName, () => []).add(session);
    }
    final branchNames = sessionsByBranch.keys.toList()..sort();

    final excel = Excel.createExcel();
    final totalSheet = excel[_totalSheetName];
    // Keep the report sheet first and remove the workbook's default sheet.
    excel.delete('Sheet1');
    excel.setDefaultSheet(_totalSheetName);

    final blackBorder = Border(
      borderStyle: BorderStyle.Thin,
      borderColorHex: ExcelColor.black,
    );
    final bordered = CellStyle(
      leftBorder: blackBorder,
      rightBorder: blackBorder,
      topBorder: blackBorder,
      bottomBorder: blackBorder,
      verticalAlign: VerticalAlign.Center,
    );
    final summaryHeaderStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      leftBorder: blackBorder,
      rightBorder: blackBorder,
      topBorder: blackBorder,
      bottomBorder: blackBorder,
    );
    final moneyStyle = CellStyle(
      numberFormat: NumFormat.custom(formatCode: '#,##0" đ"'),
      horizontalAlign: HorizontalAlign.Right,
    );
    final grandTotalStyle = CellStyle(
      fontColorHex: ExcelColor.blue,
      bold: true,
      numberFormat: NumFormat.custom(formatCode: '#,##0"đ"'),
      horizontalAlign: HorizontalAlign.Center,
      leftBorder: blackBorder,
      rightBorder: blackBorder,
      topBorder: blackBorder,
      bottomBorder: blackBorder,
    );

    // TOTAL sheet layout follows the supplied template (columns B–E).
    const summaryHeaders = ['STT', 'CHI NHÁNH', 'TIỀN', 'TỔNG TIỀN'];
    for (var column = 0; column < summaryHeaders.length; column++) {
      _setCell(totalSheet, 0, column + 1, summaryHeaders[column],
          style: summaryHeaderStyle);
    }

    var grandTotal = 0.0;
    for (var index = 0; index < branchNames.length; index++) {
      final branchName = branchNames[index];
      final branchSessions = sessionsByBranch[branchName]!;
      final branchTotal = branchSessions.fold<double>(
        0,
        (sum, session) => sum + session.totalAmount,
      );
      grandTotal += branchTotal;
      final row = index + 1;
      _setCell(totalSheet, row, 1, index + 1, style: bordered);
      _setCell(totalSheet, row, 2, branchName, style: bordered);
      _setCell(totalSheet, row, 3, branchTotal, style: moneyStyle);
      if (index == 0) {
        _setCell(totalSheet, row, 4, grandTotal, style: grandTotalStyle);
      }
    }
    if (branchNames.isEmpty) {
      _setCell(totalSheet, 1, 4, 0, style: grandTotalStyle);
    }

    final bankLabelStyle = CellStyle(
      fontColorHex: ExcelColor.red,
      bold: true,
      leftBorder: blackBorder,
      rightBorder: blackBorder,
      topBorder: blackBorder,
      bottomBorder: blackBorder,
    );
    const bankLabels = ['TÊN NGÂN HÀNG', 'TÊN TÀI KHOẢN', 'SỐ TÀI KHOẢN'];
    final bankValues = [
      profile.bankName ?? '',
      profile.bankAccountName ?? '',
      profile.bankAccountNumber ?? '',
    ];
    for (var index = 0; index < bankLabels.length; index++) {
      final row = index + 14; // Excel rows 15–17.
      _setCell(totalSheet, row, 1, index + 1, style: bankLabelStyle);
      _setCell(totalSheet, row, 2, bankLabels[index], style: bankLabelStyle);
      _setCell(totalSheet, row, 3, bankValues[index], style: bordered);
    }
    _setCell(totalSheet, 14, 4, 'Ghi chú:', style: CellStyle(bold: true));
    _setCell(totalSheet, 14, 5, profile.salaryNote ?? '');

    totalSheet.setColumnWidth(0, 3);
    totalSheet.setColumnWidth(1, 6);
    totalSheet.setColumnWidth(2, 34);
    totalSheet.setColumnWidth(3, 28);
    totalSheet.setColumnWidth(4, 42);
    totalSheet.setColumnWidth(5, 34);

    final usedSheetNames = <String>{_totalSheetName.toLowerCase()};
    for (final branchName in branchNames) {
      final sheetName = _uniqueSheetName(branchName, usedSheetNames);
      final sheet = excel[sheetName];
      final headerStyle = CellStyle(
        fontColorHex: ExcelColor.white,
        backgroundColorHex: ExcelColor.green700,
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        textWrapping: TextWrapping.WrapText,
      );
      const headers = [
        'NGÀY',
        'THÁNG',
        'NĂM',
        'CA HỌC',
        'TÊN GIÁO VIÊN',
        'SỐ LƯỢNG HỌC VIÊN',
        'TÊN HỌC VIÊN',
        'CHƯƠNG TRÌNH ĐÀO TẠO',
        'SỐ GIỜ',
        'MỨC LƯƠNG DẠY/GIỜ',
        'THÀNH TIỀN',
      ];
      for (var column = 0; column < headers.length; column++) {
        _setCell(sheet, 0, column, headers[column], style: headerStyle);
      }

      final branchSessions = List<Session>.from(sessionsByBranch[branchName]!)
        ..sort((a, b) {
          final studentCompare = a.studentName.compareTo(b.studentName);
          if (studentCompare != 0) return studentCompare;
          final dateCompare = a.date.compareTo(b.date);
          return dateCompare != 0
              ? dateCompare
              : a.timeSlot.compareTo(b.timeSlot);
        });

      var groupIndex = -1;
      String? previousStudent;
      for (var index = 0; index < branchSessions.length; index++) {
        final session = branchSessions[index];
        if (session.studentName != previousStudent) {
          groupIndex++;
          previousStudent = session.studentName;
        }
        final row = index + 1;
        final groupStyle = CellStyle(
          backgroundColorHex:
              groupIndex.isEven ? ExcelColor.blue50 : ExcelColor.pink50,
          verticalAlign: VerticalAlign.Center,
        );
        final rowMoneyStyle = CellStyle(
          backgroundColorHex:
              groupIndex.isEven ? ExcelColor.blue50 : ExcelColor.pink50,
          numberFormat: NumFormat.custom(formatCode: '#,##0" đ"'),
          horizontalAlign: HorizontalAlign.Right,
          verticalAlign: VerticalAlign.Center,
        );
        _setCell(sheet, row, 0, session.date.day, style: groupStyle);
        _setCell(sheet, row, 1, session.date.month, style: groupStyle);
        _setCell(sheet, row, 2, session.date.year, style: groupStyle);
        _setCell(sheet, row, 3, session.timeSlot, style: groupStyle);
        _setCell(sheet, row, 4, profile.fullName ?? 'Giáo viên',
            style: groupStyle);
        _setCell(sheet, row, 5, 1, style: groupStyle);
        _setCell(sheet, row, 6, session.studentName, style: groupStyle);
        _setCell(sheet, row, 7, session.programName, style: groupStyle);
        _setCell(sheet, row, 8, session.durationHours, style: groupStyle);
        _setCell(sheet, row, 9, session.hourlyRate, style: rowMoneyStyle);
        _setCell(sheet, row, 10, session.totalAmount, style: rowMoneyStyle);
      }

      final branchTotal = branchSessions.fold<double>(
        0,
        (sum, session) => sum + session.totalAmount,
      );
      final branchTotalHeader = CellStyle(
        fontColorHex: ExcelColor.white,
        backgroundColorHex: ExcelColor.green700,
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );
      _setCell(sheet, 0, 12, 'TỔNG TIỀN/THÁNG', style: branchTotalHeader);
      _setCell(sheet, 1, 12, branchTotal, style: moneyStyle);

      const columnWidths = [10, 10, 10, 18, 24, 18, 26, 28, 12, 22, 20];
      for (var column = 0; column < columnWidths.length; column++) {
        sheet.setColumnWidth(column, columnWidths[column].toDouble());
      }
      sheet.setColumnWidth(11, 3);
      sheet.setColumnWidth(12, 22);
    }

    final bytes = excel.save();
    if (bytes == null) throw Exception('Không thể tạo file Excel.');

    final directory = await _getReportsDirectory();
    final reportName = _reportFileName(profile, month);
    final baseFile = File('${directory.path}/$reportName');
    var savedFile = baseFile;
    if (await baseFile.exists() && !overwriteExisting) {
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(RegExp(r'[-:.]'), '')
          .substring(0, 18);
      savedFile = File(
        '${directory.path}/${reportName.replaceFirst('.xlsx', ' ($timestamp).xlsx')}',
      );
    }
    await savedFile.writeAsBytes(bytes, flush: true);
    return savedFile;
  }

  Future<List<File>> listReports() async {
    final directory = await _getReportsDirectory();
    final files = directory
        .listSync(followLinks: false)
        .whereType<File>()
        .where((file) => file.path.toLowerCase().endsWith('.xlsx'))
        .toList();
    final datedFiles = <MapEntry<File, DateTime>>[];
    for (final file in files) {
      datedFiles.add(MapEntry(file, await file.lastModified()));
    }
    datedFiles.sort((a, b) => b.value.compareTo(a.value));
    return datedFiles.map((entry) => entry.key).toList();
  }

  Future<File> getReportFile({
    required Profile profile,
    required DateTime month,
  }) async {
    final directory = await _getReportsDirectory();
    return File('${directory.path}/${_reportFileName(profile, month)}');
  }

  Future<Directory> _getReportsDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory('${documents.path}/$_reportsFolderName');
    await directory.create(recursive: true);
    return directory;
  }

  String _uniqueSheetName(String branchName, Set<String> usedNames) {
    var baseName = branchName
        .replaceAll(RegExp(r'[\\/?:*\[\]]'), ' ')
        .replaceAll("'", '')
        .trim();
    if (baseName.isEmpty) baseName = 'Chi nhánh';
    if (baseName.toLowerCase() == _totalSheetName.toLowerCase()) {
      baseName = '$_totalSheetName - Chi nhánh';
    }
    if (baseName.length > 31) baseName = baseName.substring(0, 31);

    var candidate = baseName;
    var suffixNumber = 2;
    while (usedNames.contains(candidate.toLowerCase())) {
      final suffix = ' ($suffixNumber)';
      final maxBaseLength = 31 - suffix.length;
      final prefix = baseName.length > maxBaseLength
          ? baseName.substring(0, maxBaseLength)
          : baseName;
      candidate = '$prefix$suffix';
      suffixNumber++;
    }
    usedNames.add(candidate.toLowerCase());
    return candidate;
  }

  String _reportFileName(Profile profile, DateTime month) {
    final organization = _safeFilePart(profile.organizationName);
    final teacher = _safeFilePart(profile.fullName ?? 'Giáo viên');
    final monthNumber = month.month.toString().padLeft(2, '0');
    return '$organization - $teacher - BÁO CÁO LƯƠNG THÁNG $monthNumber - ${month.year}.xlsx';
  }

  String _safeFilePart(String value) =>
      value.replaceAll(RegExp(r'[<>:"/\\|?*]'), '').trim();

  void _setCell(
    Sheet sheet,
    int row,
    int column,
    dynamic value, {
    CellStyle? style,
  }) {
    final cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row),
    );
    if (value is int) {
      cell.value = IntCellValue(value);
    } else if (value is double) {
      cell.value = DoubleCellValue(value);
    } else if (value is String) {
      cell.value = TextCellValue(value);
    }
    if (style != null) cell.cellStyle = style;
  }
}
