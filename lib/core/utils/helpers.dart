import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppHelpers {
  /// Format date to readable string
  static String formatDate(String? dateStr, {String pattern = 'yyyy-MM-dd'}) {
    if (dateStr == null || dateStr.isEmpty) return '---';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return DateFormat(pattern).format(date);
    } catch (_) {
      return dateStr;
    }
  }

  /// Format date to human readable
  static String formatDateHuman(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '---';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return DateFormat('dd MMM yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  /// Format date-time
  static String formatDateTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '---';
    try {
      final normalized = normalizeApiDateString(dateStr) ?? dateStr;
      final date = DateTime.parse(normalized).toUtc().toLocal();
      return DateFormat('dd MMM yyyy – HH:mm').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  /// تحليل تاريخ السيرفر كـ UTC (يتجنب فرق التوقيت عند غياب Z في النص).
  static DateTime parseApiDateTimeUtc(dynamic raw) {
    final n = normalizeApiDateString(raw);
    if (n == null || n.isEmpty) return DateTime.now().toUtc();
    try {
      return DateTime.parse(n).toUtc();
    } catch (_) {
      return DateTime.now().toUtc();
    }
  }

  /// عرض لحظة UTC بتوقيت الجهاز المحلي.
  static String formatDateTimeLocalFromUtc(DateTime utcInstant) {
    return DateFormat('dd MMM yyyy – HH:mm').format(utcInstant.toLocal());
  }

  /// تطبيع سلسلة التاريخ القادمة من الـ API لمقارنة دقيقة (UTC).
  static String? normalizeApiDateString(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString().trim();
    if (s.isEmpty) return null;
    if (s.endsWith('Z')) return s;
    if (RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(s)) return s;
    if (s.contains('T')) return '${s}Z';
    return s;
  }

  /// لحظة الاستحقاق كـ UTC (للمقارنة مع DateTime.now().toUtc()).
  static DateTime? dueInstantUtc(String? dateStr) {
    final n = normalizeApiDateString(dateStr);
    if (n == null) return null;
    try {
      return DateTime.parse(n).toUtc();
    } catch (_) {
      return null;
    }
  }

  /// Check if a date is overdue
  static bool isOverdue(String? dateStr) {
    final due = dueInstantUtc(dateStr);
    if (due == null) return false;
    return due.isBefore(DateTime.now().toUtc());
  }

  /// Days until a date
  static int daysUntil(String? dateStr) {
    final due = dueInstantUtc(dateStr);
    if (due == null) return 0;
    return due.difference(DateTime.now().toUtc()).inDays;
  }

  /// حالة المهمة للعرض (عربي فقط)
  static String taskStatusArabic(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'معلقة';
      case 'in_progress':
        return 'جارية';
      case 'completed':
        return 'مكتملة';
      case 'overdue':
        return 'متأخرة';
      default:
        return status.replaceAll('_', ' ');
    }
  }

  /// Status display label
  static String statusLabel(String status, BuildContext context) {
    // Bilingual status
    switch (status.toLowerCase()) {
      case 'open':
        return 'Open / مفتوحة';
      case 'closed':
        return 'Closed / مغلقة';
      case 'pending':
        return 'Pending / معلقة';
      case 'archived':
        return 'Archived / مؤرشفة';
      case 'in_progress':
        return 'In Progress / جارية';
      case 'completed':
        return 'Completed / مكتملة';
      case 'overdue':
        return 'Overdue / متأخرة';
      default:
        return status;
    }
  }

  /// Get file icon by extension
  static IconData getFileIcon(String? filename) {
    if (filename == null) return Icons.insert_drive_file;
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  /// Format file size
  static String formatFileSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
