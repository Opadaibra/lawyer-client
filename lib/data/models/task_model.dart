class TaskModel {
  final int id;
  final int? caseFileId; // case_file_id in API
  final String? caseNumber;
  final String title;
  final String? description;
  final String? taskType;
  final String? nextSessionDate;
  final String? notes;
  final int? fileId;
  final String? dueDate;
  final String status; // pending, in_progress, completed, overdue
  final bool isArchived;
  final String? createdAt;

  TaskModel({
    required this.id,
    this.caseFileId,
    this.caseNumber,
    required this.title,
    this.description,
    this.taskType,
    this.nextSessionDate,
    this.notes,
    this.fileId,
    this.dueDate,
    required this.status,
    this.isArchived = false,
    this.createdAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
        id: json['id'] as int? ?? 0,
        caseFileId: json['case_file_id'] as int?,
        caseNumber: json['case']?['case_number'] as String?,
        title: json['title'] as String? ?? '',
        description: json['description'] as String?,
        taskType: json['task_type'] as String?,
        nextSessionDate: json['next_session_date'] as String?,
        notes: json['notes'] as String?,
        fileId: json['file_id'] as int?,
        dueDate: json['due_date'] != null
            ? (json['due_date'].toString().endsWith('Z')
                ? json['due_date']
                : '${json['due_date']}Z')
            : null,
        status: json['status'] as String? ?? 'pending',
        isArchived: json['archived_at'] != null,
        createdAt: json['created_at'] != null
            ? (json['created_at'].toString().endsWith('Z')
                ? json['created_at']
                : '${json['created_at']}Z')
            : null,
      );

  Map<String, dynamic> toCreateJson() => {
        if (caseFileId != null) 'case_file_id': caseFileId,
        'title': title,
        if (description != null) 'description': description,
        if (taskType != null) 'task_type': taskType,
        if (nextSessionDate != null) 'next_session_date': nextSessionDate,
        if (notes != null) 'notes': notes,
        if (fileId != null) 'file_id': fileId,
        if (dueDate != null) 'due_date': dueDate,
        'status': status,
      };
}
