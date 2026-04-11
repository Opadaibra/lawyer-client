import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/file_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/file_upload_dialog.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  final fileCtrl = Get.find<FileController>();
  int? caseId;
  int? minuteId;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    caseId = args?['caseId'];
    minuteId = args?['minuteId'];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (caseId != null) {
        fileCtrl.fetchFilesByCase(caseId!);
      } else if (minuteId != null) {
        fileCtrl.fetchFilesByMinute(minuteId!);
      } else {
        fileCtrl.fetchFiles();
      }
    });
  }

  Future<void> _refresh() async {
    if (caseId != null) {
      await fileCtrl.fetchFilesByCase(caseId!);
    } else if (minuteId != null) {
      await fileCtrl.fetchFilesByMinute(minuteId!);
    } else {
      await fileCtrl.fetchFiles();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Files / الملفات',
        showBack: false,
      ),
      body: Obx(() {
        if (fileCtrl.isLoading.value) return const LoadingWidget();
        final canMutate =
            auth.currentUser.value?.canMutateOfficeContent ?? true;
        if (fileCtrl.files.isEmpty) {
          return EmptyStateWidget(
            title: 'No files uploaded\nلم يتم رفع ملفات',
            icon: Icons.folder_open_outlined,
            onAction: canMutate
                ? () async {
                    final fields = await Get.dialog<Map<String, String>?>(
                        const FileUploadDialog());
                    final Map<String, String> uploadFields = fields ?? {};
                    if (caseId != null) {
                      uploadFields['case_id'] = caseId.toString();
                    }
                    if (minuteId != null) {
                      uploadFields['minute_id'] = minuteId.toString();
                    }
                    await fileCtrl.pickAndUpload(extraFields: uploadFields);
                  }
                : null,
            actionLabel: 'Upload File / رفع ملف',
          );
        }
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            itemCount: fileCtrl.files.length,
            padding: const EdgeInsets.only(bottom: 80),
            itemBuilder: (_, i) {
              final file = fileCtrl.files[i];
              return Card(
                child: ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      AppHelpers.getFileIcon(file.displayName),
                      color: AppTheme.primary,
                    ),
                  ),
                  title: Text(
                    file.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (file.size != null)
                        Text(AppHelpers.formatFileSize(file.size!),
                            style: const TextStyle(fontSize: 11)),
                      Text(AppHelpers.formatDateHuman(file.createdAt),
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.open_in_new_outlined,
                            color: AppTheme.primary),
                        onPressed: () => _openFile(context, file),
                        tooltip: 'View / عرض',
                      ),
                      if (canMutate)
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          onPressed: () => _confirmDelete(fileCtrl, file.id),
                          tooltip: 'Delete / حذف',
                        ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        );
      }),
      floatingActionButton: Obx(() {
        final canMutate =
            auth.currentUser.value?.canMutateOfficeContent ?? true;
        if (!canMutate) return const SizedBox.shrink();
        return FloatingActionButton.extended(
          onPressed: fileCtrl.isUploading.value
              ? null
              : () async {
                  final fields = await Get.dialog<Map<String, String>?>(
                      const FileUploadDialog());
                  final Map<String, String> uploadFields = fields ?? {};
                  if (caseId != null) {
                    uploadFields['case_id'] = caseId.toString();
                  }
                  if (minuteId != null) {
                    uploadFields['minute_id'] = minuteId.toString();
                  }
                  await fileCtrl.pickAndUpload(extraFields: uploadFields);
                },
          icon: fileCtrl.isUploading.value
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.upload_file_outlined),
          label: Text(fileCtrl.isUploading.value
              ? 'Uploading... / جاري الرفع'
              : 'Upload File / رفع ملف'),
        );
      }),
    );
  }

  void _openFile(BuildContext context, dynamic file) async {
    if (file.absoluteUrl == null) {
      Get.snackbar('Error', 'No file URL available');
      return;
    }
    // Navigate to in-app viewer
    Get.toNamed('/file-viewer', arguments: {'file': file});
  }

  void _confirmDelete(FileController ctrl, int id) {
    Get.dialog(AlertDialog(
      title: const Text('Delete File / حذف الملف'),
      content: const Text('Are you sure? / هل أنت متأكد؟'),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            Get.back();
            ctrl.deleteFile(id);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Delete'),
        ),
      ],
    ));
  }
}
