import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/case_controller.dart';
import '../../../controllers/client_controller.dart';
import '../../../controllers/minute_controller.dart';
import '../../../controllers/task_controller.dart';
import '../../../core/theme/app_theme.dart';

class FileUploadDialog extends StatefulWidget {
  final String? initialType;
  final int? initialId;

  const FileUploadDialog({super.key, this.initialType, this.initialId});

  @override
  State<FileUploadDialog> createState() => _FileUploadDialogState();
}

class _FileUploadDialogState extends State<FileUploadDialog> {
  final caseCtrl = Get.find<CaseController>();
  final clientCtrl = Get.find<ClientController>();
  final minuteCtrl = Get.find<MinuteController>();
  final taskCtrl = Get.find<TaskController>();

  String? selectedType; // 'case', 'client', 'minute', 'task'
  int? selectedId;

  @override
  void initState() {
    super.initState();
    selectedType = widget.initialType;
    selectedId = widget.initialId;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('رفع ملف'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ربط بـ (اختياري):',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            
            // Type Selector
            DropdownButtonFormField<String>(
              value: selectedType,
              decoration: const InputDecoration(
                labelText: 'نوع الربط',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'case', child: Text('قضية')),
                DropdownMenuItem(value: 'client', child: Text('موكل')),
                DropdownMenuItem(value: 'minute', child: Text('ضبط')),
                DropdownMenuItem(value: 'task', child: Text('مهمة')),
                DropdownMenuItem(value: null, child: Text('بدون ربط')),
              ],
              onChanged: (v) {
                setState(() {
                  selectedType = v;
                  selectedId = null;
                });
              },
            ),

            if (selectedType != null) ...[
              const SizedBox(height: 16),
              // ID Selector
              if (selectedType == 'case')
                DropdownButtonFormField<int>(
                  value: selectedId,
                  decoration: const InputDecoration(
                    labelText: 'اختر القضية',
                    border: OutlineInputBorder(),
                  ),
                  items: caseCtrl.cases.map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.caseNumber),
                  )).toList(),
                  onChanged: (v) => setState(() => selectedId = v),
                )
              else if (selectedType == 'client')
                DropdownButtonFormField<int>(
                  value: selectedId,
                  decoration: const InputDecoration(
                    labelText: 'اختر الموكل',
                    border: OutlineInputBorder(),
                  ),
                  items: clientCtrl.clients.map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.name),
                  )).toList(),
                  onChanged: (v) => setState(() => selectedId = v),
                )
              else if (selectedType == 'minute')
                DropdownButtonFormField<int>(
                  value: selectedId,
                  decoration: const InputDecoration(
                    labelText: 'اختر الضبط',
                    border: OutlineInputBorder(),
                  ),
                  items: minuteCtrl.minutes.map((m) => DropdownMenuItem(
                    value: m.id,
                    child: Text(m.title.isNotEmpty ? m.title : 'ضبط #${m.id}'),
                  )).toList(),
                  onChanged: (v) => setState(() => selectedId = v),
                )
              else if (selectedType == 'task')
                DropdownButtonFormField<int>(
                  value: selectedId,
                  decoration: const InputDecoration(
                    labelText: 'اختر المهمة',
                    border: OutlineInputBorder(),
                  ),
                  items: taskCtrl.tasks.map((t) => DropdownMenuItem(
                    value: t.id,
                    child: Text(t.title),
                  )).toList(),
                  onChanged: (v) => setState(() => selectedId = v),
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () {
            Map<String, String> fields = {};
            if (selectedType != null && selectedId != null) {
              fields['${selectedType}_id'] = selectedId.toString();
            }
            Get.back(result: fields);
          },
          child: const Text('متابعة'),
        ),
      ],
    );
  }
}

