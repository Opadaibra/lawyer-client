import '../../core/constants/app_constants.dart';

class FileModel {
  final int id;
  final String? fileName;
  final String? originalName;
  final String? path;
  final String? url;
  final String? mimeType;
  final int? size;
  final String? createdAt;

  FileModel({
    required this.id,
    this.fileName,
    this.originalName,
    this.path,
    this.url,
    this.mimeType,
    this.size,
    this.createdAt,
  });

  factory FileModel.fromJson(Map<String, dynamic> json) => FileModel(
        id: json['id'] as int? ?? 0,
        fileName: json['file_name'] as String?,
        originalName: json['original_name'] as String? ?? json['file_name'] as String?,
        path: json['file_path'] as String?,
        url: null, // Computed via getter
        mimeType: json['file_type'] as String?,
        size: json['file_size'] as int?,
        createdAt: json['created_at'] as String?,
      );

  String get displayName => originalName ?? fileName ?? 'File $id';

  String? get absoluteUrl {
    if (path == null) return null;
    if (path!.startsWith('http')) return path;
    
    // Base URL is https://.../api, extract the root domain
    final root = AppConstants.baseUrl.split('/api').first;
    
    // Laravel 'public' disk files are served via the /storage symlink
    // If path is 'uploads/file.pdf', URL should be 'root/storage/uploads/file.pdf'
    final cleanPath = path!.startsWith('/') ? path : '/$path';
    return '$root/storage$cleanPath';
  }
}
