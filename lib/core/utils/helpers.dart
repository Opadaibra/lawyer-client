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
      final date = DateTime.parse(dateStr).toLocal();
      return DateFormat('dd MMM yyyy – HH:mm').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  /// Check if a date is overdue
  static bool isOverdue(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return false;
    try {
      final date = DateTime.parse(dateStr);
      return date.isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  /// Days until a date
  static int daysUntil(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 0;
    try {
      final date = DateTime.parse(dateStr);
      return date.difference(DateTime.now()).inDays;
    } catch (_) {
      return 0;
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
