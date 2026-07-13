import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';

class ExportHelper {
  static void exportToCsv(String title, List<String> headers, List<List<dynamic>> rows, {DateTime? startDate, DateTime? endDate, Map<String, String>? filters}) {
    List<List<dynamic>> csvData = [];
    
    // Header Info
    final dateRange = _formatDateRange(startDate, endDate);
    final generated = DateFormat('dd MMM yyyy').format(DateTime.now());
    
    csvData.add([title]);
    csvData.add(['Date Range:', dateRange]);
    csvData.add(['Generated:', generated]);
    csvData.add(['Total Records:', rows.length.toString()]);
    
    if (filters != null && filters.isNotEmpty) {
      csvData.add(['Filters:']);
      filters.forEach((key, value) {
        csvData.add(['  $key = $value']);
      });
    }
    csvData.add([]); // Empty row
    
    csvData.add(headers);
    csvData.addAll(rows);
    
    String csvString = Csv().encode(csvData);
    final bytes = utf8.encode(csvString);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "${title.replaceAll(' ', '_').toLowerCase()}.csv")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  static void exportToExcel(String title, List<String> headers, List<List<dynamic>> rows, {DateTime? startDate, DateTime? endDate, Map<String, String>? filters}) {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sheet1'];
    
    // Header Info
    final dateRange = _formatDateRange(startDate, endDate);
    final generated = DateFormat('dd MMM yyyy').format(DateTime.now());
    
    sheetObject.appendRow([TextCellValue(title)]);
    sheetObject.appendRow([TextCellValue('Date Range:'), TextCellValue(dateRange)]);
    sheetObject.appendRow([TextCellValue('Generated:'), TextCellValue(generated)]);
    sheetObject.appendRow([TextCellValue('Total Records:'), TextCellValue(rows.length.toString())]);
    
    if (filters != null && filters.isNotEmpty) {
      sheetObject.appendRow([TextCellValue('Filters:')]);
      filters.forEach((key, value) {
        sheetObject.appendRow([TextCellValue('  $key = $value')]);
      });
    }
    sheetObject.appendRow([TextCellValue('')]); // Empty row
    
    sheetObject.appendRow(headers.map((h) => TextCellValue(h)).toList());
    
    for (var row in rows) {
      sheetObject.appendRow(row.map((val) {
        if (val == null) return TextCellValue('');
        if (val is num) {
          if (val is int) return IntCellValue(val);
          return DoubleCellValue(val.toDouble());
        }
        return TextCellValue(val.toString());
      }).toList());
    }
    
    final fileBytes = excel.encode();
    if (fileBytes != null) {
      final blob = html.Blob([fileBytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "${title.replaceAll(' ', '_').toLowerCase()}.xlsx")
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }

  static String _formatDateRange(DateTime? startDate, DateTime? endDate) {
    if (startDate == null && endDate == null) return 'All Time';
    if (startDate == null) return 'Up to ${DateFormat('dd MMM yyyy').format(endDate!)}';
    if (endDate == null) return 'Since ${DateFormat('dd MMM yyyy').format(startDate)}';
    return '${DateFormat('dd MMM yyyy').format(startDate)} - ${DateFormat('dd MMM yyyy').format(endDate)}';
  }
}
