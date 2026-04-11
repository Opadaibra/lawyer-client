class ClientModel {
  final int id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? notes;
  final String? powerOfAttorneyNumber;
  final bool isStarred;
  final String? createdAt;
  // حقل مؤقت فقط عند الإنشاء - لا يحفظ من السيرفر
  final String? password;

  ClientModel({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.notes,
    this.powerOfAttorneyNumber,
    this.isStarred = false,
    this.createdAt,
    this.password,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) => ClientModel(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        address: json['address'] as String?,
        notes: json['notes'] as String?,
        powerOfAttorneyNumber: json['power_of_attorney_number'] as String?,
        isStarred: json['is_starred'] as bool? ?? false,
        createdAt: json['created_at'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'notes': notes,
        'power_of_attorney_number': powerOfAttorneyNumber,
        'is_starred': isStarred,
        'created_at': createdAt,
      };

  Map<String, dynamic> toCreateJson() => {
        'name': name,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        if (address != null) 'address': address,
        if (notes != null) 'notes': notes,
        if (powerOfAttorneyNumber != null) 'power_of_attorney_number': powerOfAttorneyNumber,
        if (password != null && password!.isNotEmpty) 'password': password,
      };
}
