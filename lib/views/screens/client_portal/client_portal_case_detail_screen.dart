import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/case_model.dart';
import '../../../data/models/file_model.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';

/// تفاصيل قضية لعرض الموكل فقط (قراءة من بيانات `/client-portal/cases`).
class ClientPortalCaseDetailScreen extends StatelessWidget {
  const ClientPortalCaseDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.arguments?['case'];
    if (c is! CaseModel) {
      return Scaffold(
        appBar: AppBar(title: const Text('تفاصيل القضية')),
        body: const Center(child: Text('بيانات القضية غير متوفرة')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('تفاصيل القضية'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _headerCard(context, c),
            const SizedBox(height: 16),
            _sectionTitle('المعلومات الأساسية'),
            _infoCard(context, c),
            const SizedBox(height: 20),
            _sectionTitle('الجلسات'),
            _sessionsCard(c),
            const SizedBox(height: 20),
            _sectionTitle('المحاضر'),
            _minutesCard(c),
            const SizedBox(height: 20),
            _sectionTitle('المهام'),
            _tasksCard(c),
            const SizedBox(height: 20),
            _sectionTitle('المرفقات'),
            _filesCard(c),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        t,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppTheme.primary,
        ),
      ),
    );
  }

  Widget _headerCard(BuildContext context, CaseModel c) {
    final statusColor = _statusColor(c.status);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.folder_open, color: AppTheme.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'دعوى رقم ${c.caseNumber}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (c.caseType != null && c.caseType!.isNotEmpty)
                        Text(
                          c.caseType!,
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _statusLabel(c.status),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'إجمالي الأتعاب المسدّدة: ${c.totalFeesPaid.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[800],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(BuildContext context, CaseModel c) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            if (c.subject != null && c.subject!.isNotEmpty)
              _tile(Icons.subject_outlined, 'الموضوع', c.subject!),
            if (c.court != null && c.court!.isNotEmpty)
              _tile(Icons.account_balance_outlined, 'المحكمة', c.court!),
            if (c.department != null && c.department!.isNotEmpty)
              _tile(Icons.meeting_room_outlined, 'الدائرة / الغرفة', c.department!),
            if (c.clientCapacity != null && c.clientCapacity!.isNotEmpty)
              _tile(Icons.person_outline, 'صفة الموكل', c.clientCapacity!),
            if (c.opponent != null && c.opponent!.isNotEmpty)
              _tile(Icons.person_off_outlined, 'الخصم', c.opponent!),
            if (c.opponentCapacity != null && c.opponentCapacity!.isNotEmpty)
              _tile(Icons.badge_outlined, 'صفة الخصم', c.opponentCapacity!),
            if (c.notes != null && c.notes!.isNotEmpty)
              _tile(Icons.notes_outlined, 'ملاحظات', c.notes!),
            if (c.createdAt != null)
              _tile(
                Icons.calendar_today_outlined,
                'تاريخ التسجيل',
                AppHelpers.formatDateHuman(c.createdAt),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary, size: 22),
      title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }

  Widget _sessionsCard(CaseModel c) {
    if (c.sessions.isEmpty) {
      return _emptyBox('لا توجد جلسات مسجّلة لهذه القضية بعد.');
    }
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: c.sessions.map((s) {
          return ListTile(
            leading: const Icon(Icons.gavel_outlined, color: AppTheme.accent),
            title: Text(
              AppHelpers.formatDateHuman(s.date),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (s.decisions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('القرارات: ${s.decisions}'),
                  ),
                if (s.notes != null && s.notes!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('ملاحظات: ${s.notes}'),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _minutesCard(CaseModel c) {
    if (c.minutes.isEmpty) {
      return _emptyBox('لا توجد محاضر مرتبطة بهذه القضية.');
    }
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: c.minutes.map((m) {
          return ListTile(
            leading: const Icon(Icons.article_outlined, color: AppTheme.primary),
            title: Text(m.title, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              AppHelpers.formatDateHuman(
                  m.date.isNotEmpty ? m.date : m.createdAt),
              style: const TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => Get.toNamed(AppRoutes.minuteDetail,
                arguments: {'minute': m}),
          );
        }).toList(),
      ),
    );
  }

  Widget _tasksCard(CaseModel c) {
    if (c.tasks.isEmpty) {
      return _emptyBox('لا توجد مهام مسجّلة لهذه القضية.');
    }
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: c.tasks.map((t) {
          return ListTile(
            leading: Icon(
              t.status == 'completed' ? Icons.check_circle_outline : Icons.task_alt_outlined,
              color: AppTheme.getStatusColor(t.status),
            ),
            title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              t.dueDate != null
                  ? 'الاستحقاق: ${AppHelpers.formatDateHuman(t.dueDate)} · ${t.status}'
                  : t.status,
              style: const TextStyle(fontSize: 12),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _filesCard(CaseModel c) {
    if (c.linkedFiles.isEmpty) {
      return _emptyBox('لا توجد مرفقات لهذه القضية.');
    }
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: c.linkedFiles.map((f) {
          return ListTile(
            leading: Icon(
              AppHelpers.getFileIcon(f.displayName),
              color: AppTheme.primary,
            ),
            title: Text(
              f.displayName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: f.size != null
                ? Text(AppHelpers.formatFileSize(f.size!),
                    style: const TextStyle(fontSize: 11))
                : null,
            trailing: const Icon(Icons.open_in_new_outlined),
            onTap: () => _openFile(f),
          );
        }).toList(),
      ),
    );
  }

  void _openFile(FileModel f) {
    if (f.absoluteUrl == null) {
      Get.snackbar('تنبيه', 'لا يتوفر رابط لعرض هذا الملف');
      return;
    }
    Get.toNamed(AppRoutes.fileViewer, arguments: {'file': f});
  }

  Widget _emptyBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey[600], fontSize: 13),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return AppTheme.statusOpen;
      case 'closed':
        return AppTheme.statusClosed;
      case 'pending':
        return AppTheme.statusPending;
      case 'archived':
        return AppTheme.statusArchived;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return 'مفتوحة';
      case 'closed':
        return 'مغلقة';
      case 'pending':
        return 'معلقة';
      case 'archived':
        return 'مؤرشفة';
      default:
        return status;
    }
  }
}
