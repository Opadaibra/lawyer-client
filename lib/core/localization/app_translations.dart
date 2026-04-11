import 'package:get/get.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'ar': {
          // ── عام ──────────────────────────────────────────
          'app_name': 'إدارة مكتب المحاماة',
          'yes': 'نعم',
          'no': 'لا',
          'cancel': 'إلغاء',
          'confirm': 'تأكيد',
          'edit': 'تعديل',
          'delete': 'حذف',
          'add': 'إضافة',
          'save': 'حفظ',
          'done': 'تم بنجاح',
          'error': 'خطأ',
          'success': 'نجاح',
          'loading': 'جاري التحميل...',
          'search': 'بحث',
          'all': 'الكل',
          'are_you_sure': 'هل أنت متأكد؟',
          'see_all': 'الكل',
          'general': 'عام',
          'details': 'التفاصيل',
          'important': 'مهم',
          'no_important_items': 'لا توجد عناصر هامة',
          'no_archived_items': 'لا توجد عناصر مؤرشفة',
          'no_notifications': 'لا توجد تنبيهات',
          'no_featured_items': 'لا توجد عناصر مميزة',

          // ── التنقل والقوائم ───────────────────────────────
          'home': 'الرئيسية',
          'menu': 'القائمة',
          'dashboard': 'لوحة التحكم',
          'featured': 'المميزة',
          'archive': 'الأرشيف',
          'calendar': 'التقويم',
          'notifications': 'التنبيهات',
          'open_calendar': 'فتح التقويم',

          // ── المصادقة ──────────────────────────────────────
          'logout': 'تسجيل الخروج',
          'login': 'تسجيل الدخول',
          'register': 'إنشاء حساب',
          'welcome': 'أهلاً وسهلاً',
          'password': 'كلمة المرور',
          'current_password': 'كلمة المرور الحالية',
          'new_password': 'كلمة المرور الجديدة',
          'change_password': 'تغيير كلمة المرور',
          'change': 'تغيير',
          'password_change_backend': 'تغيير كلمة المرور يتطلب تحديث الباك-إند',

          // ── الملف الشخصي ─────────────────────────────────
          'profile': 'الملف الشخصي',
          'account': 'الحساب',
          'appearance': 'المظهر',
          'dark_mode': 'الوضع الداكن',
          'language': 'اللغة',
          'app_language': 'لغة التطبيق',
          'name': 'الاسم',
          'email': 'البريد الإلكتروني',
          'phone': 'رقم الهاتف',
          'address': 'العنوان',
          'notes': 'الملاحظات',

          // ── الأدوار ───────────────────────────────────────
          'role': 'الدور الوظيفي',
          'lawyer': 'محامي',
          'lawyer_role': 'محامي',
          'editor_role': 'محرر',
          'manager_role': 'مدير',
          'viewer_role': 'شاهد',
          'viewer_no_edit_permission':
              'صلاحياتك تسمح بالعرض فقط ولا يمكن الإضافة أو التعديل أو الحذف',
          'client_role': 'موكل',

          // ── معلومات المكتب ────────────────────────────────
          'office_info': 'معلومات المكتب',
          'office_name': 'اسم المكتب',
          'office_address': 'عنوان المكتب',
          'office_phone': 'هاتف المكتب',
          'office_email': 'بريد المكتب الإلكتروني',
          'office_id_label': 'معرّف المكتب',
          'office_team_note': 'جميع أعضاء الفريق المنتمون لهذا المكتب يشاركونك نفس البيانات',

          // ── الفريق ────────────────────────────────────────
          'team': 'الفريق',
          'my_team': 'أعضاء الفريق',
          'add_member': 'إضافة عضو',
          'basic_info': 'المعلومات الأساسية',

          // ── الموكلين ──────────────────────────────────────
          'clients': 'الموكلين',
          'client': 'الموكل',
          'add_client': 'إضافة موكل',
          'edit_client': 'تعديل بيانات الموكل',
          'update_client': 'حفظ التعديلات',
          'delete_client': 'حذف الموكل',
          'client_full_name': 'الاسم الكامل *',
          'client_account_section': 'حساب تسجيل دخول الموكل (اختياري)',
          'client_password_hint': 'كلمة المرور لتفعيل حساب الموكل',
          'recent_clients': 'الموكلون الأخيرون',
          'total_clients': 'إجمالي الموكلين',
          'member_since': 'عضو منذ',
          'power_of_attorney_number': 'رقم وكالة',

          // ── القضايا ───────────────────────────────────────
          'cases': 'القضايا',
          'new_case': 'قضية جديدة',
          'no_cases': 'لا توجد قضايا',
          'delete_case': 'حذف القضية',
          'total_cases': 'إجمالي القضايا',
          'case_number': 'رقم الدعوى',
          'subject': 'الموضوع',
          'department': 'الدائرة / الغرفة',
          'client_capacity': 'صفة الموكل',
          'opponent': 'الخصم',
          'opponent_capacity': 'صفة الخصم',
          'next_session_date': 'تاريخ الجلسة القادمة',
          'parties': 'الأطراف',
          'dates_and_notes': 'التواريخ والملاحظات',
          'history': 'السجل',
          'status': 'الحالة',
          'case_notes': 'ملاحظات القضية',

          // ── الجلسات والسجلات ──────────────────────────────
          'sessions': 'الجلسات',
          'add_session': 'إضافة جلسة',
          'add_note': 'إضافة ملاحظة',
          'add_expense': 'إضافة مصروف',
          'add_fee': 'إضافة أتعاب',
          'expenses': 'المصروفات',
          'fees': 'الأتعاب',
          'entries': 'سجلات',
          'item': 'البند',
          'amount': 'المبلغ',
          'date': 'التاريخ',
          'decisions': 'القرارات',

          // ── الحالات ───────────────────────────────────────
          'active': 'نشطة',
          'archived': 'مؤرشفة',
          'pending': 'معلقة',
          'in_progress': 'جارية',
          'completed': 'مكتملة',
          'overdue': 'متأخرة',
          'open': 'مفتوحة',
          'closed': 'مغلقة',
          'unarchive': 'إلغاء الأرشفة',

          // ── المهام ────────────────────────────────────────
          'tasks': 'المهام',
          'new_task': 'مهمة جديدة',
          'no_tasks': 'لا توجد مهام',
          'pending_tasks': 'مهام معلقة',
          'overdue_tasks': 'مهام متأخرة',
          'recent_tasks': 'المهام الأخيرة',

          // ── المحاضر ───────────────────────────────────────
          'minutes': 'المحاضر',
          'add_minute': 'إضافة محضر',
          'no_minutes': 'لا توجد محاضر بعد',
          'no_minutes_for_client': 'لا توجد محاضر لهذا الموكل',

          // ── الملفات ───────────────────────────────────────
          'files': 'الملفات',
          'upload_file': 'رفع ملف',

          // ── لوحة التحكم ───────────────────────────────────
          'dashboard_subtitle': 'نظرة عامة على مكتبك ومواعيدك',
          'good_morning': 'صباح الخير',
          'good_evening': 'مساء الخير',
          'quick_actions': 'إجراءات سريعة',
        }
      };
}
