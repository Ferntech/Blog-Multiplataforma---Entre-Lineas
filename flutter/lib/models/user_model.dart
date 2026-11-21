class UserModel {
  final int id;
  final String fullName;
  final String email;
  final String role;
  final String? avatarUrl;
  final String? bio;
  final String? phone;
  final String? addressLine;
  final String? city;
  final String? state;
  final String? postalCode;
  final String country;
  final bool isActive;
  final int karma;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.role = 'reader',
    this.avatarUrl,
    this.bio,
    this.phone,
    this.addressLine,
    this.city,
    this.state,
    this.postalCode,
    this.country = 'México',
    this.isActive = true,
    this.karma = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] as num).toInt(),
      fullName: json['full_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'reader',
      avatarUrl: json['avatar_url']?.toString(),
      bio: json['bio']?.toString(),
      phone: json['phone']?.toString(),
      addressLine: json['address_line']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      postalCode: json['postal_code']?.toString(),
      country: json['country']?.toString() ?? 'México',
      isActive: json['is_active'] == true || json['is_active'] == 1,
      karma: (json['karma'] as num?)?.toInt() ?? 0,
    );
  }

  String get roleLabel {
    switch (role) {
      case 'admin':
        return 'Administrador';
      case 'author':
        return 'Autor / Reseñador';
      default:
        return 'Lector';
    }
  }
}

class UserSummaryModel {
  final int id;
  final String fullName;
  final String role;
  final String? avatarUrl;
  final int karma;

  const UserSummaryModel({
    required this.id,
    required this.fullName,
    required this.role,
    this.avatarUrl,
    this.karma = 0,
  });

  factory UserSummaryModel.fromJson(Map<String, dynamic> json) {
    return UserSummaryModel(
      id: (json['id'] as num).toInt(),
      fullName: json['full_name']?.toString() ?? 'Usuario',
      role: json['role']?.toString() ?? 'reader',
      avatarUrl: json['avatar_url']?.toString(),
      karma: (json['karma'] as num?)?.toInt() ?? 0,
    );
  }
}
