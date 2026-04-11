import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/case_controller.dart';
import '../../../controllers/client_controller.dart';
import '../../../core/theme/app_theme.dart';

class FileUploadDialog extends StatefulWidget {
  const FileUploadDialog({super.key});

  @override
  State<FileUploadDialog> createState() => _FileUploadDialogState();
}

class _FileUploadDialogState extends State<FileUploadDialog> {
  final caseCtrl = Get.find<CaseController>();
  final clientCtrl = Get.find<ClientController>();

  String? selectedType; // 'case', 'client'
  int? selectedId;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Upload File / رفع ملف'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Link to (Optional): / ربط بـ (اختياري):',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            
            // Type Selector
            DropdownButtonFormField<String>(
              value: selectedType,
              decoration: const InputDecoration(
                labelText: 'Entity Type / نوع الربط',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'case', child: Text('Case / قضية')),
                DropdownMenuItem(value: 'client', child: Text('Client / موكل')),
                DropdownMenuItem(value: null, child: Text('None / بدون ربط')),
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
                    labelText: 'Select Case / اختر القضية',
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
                    labelText: 'Select Client / اختر الموكل',
                    border: OutlineInputBorder(),
                  ),
                  items: clientCtrl.clients.map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.name),
                  )).toList(),
                  onChanged: (v) => setState(() => selectedId = v),
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            Map<String, String>? fields;
            if (selectedType != null && selectedId != null) {
              fields = {
                '${selectedType}_id': selectedId.toString(),
              };
            }
            Get.back(result: fields);
          },
          child: const Text('Select File & Upload'),
        ),
      ],
    );
  }
}
