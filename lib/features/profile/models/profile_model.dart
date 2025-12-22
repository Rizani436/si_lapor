class ProfileModel {
  final String id;
  final String? fotoProfile;
  final String? namaLengkap;
  final String? email;
  final String? noHp;
  final String? role;
  final bool? isActive;

  const ProfileModel({
    required this.id,
    required this.fotoProfile,
    required this.namaLengkap,
    required this.email,
    required this.noHp,
    required this.role,
    required this.isActive,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: (json['id'] ?? '').toString(),
      fotoProfile: json['foto_profile'] as String?,
      namaLengkap: json['nama_lengkap'] as String?,
      email: json['email'] as String?,
      noHp: json['no_hp'] as String?,
      role: json['role'] as String?,
      isActive: json['is_active'] as bool?,
    );
  }

  ProfileModel copyWith({
    String? fotoProfile,
    String? namaLengkap,
    String? email,
    String? noHp,
    String? role,
    bool? isActive,
  }) {
    return ProfileModel(
      id: id,
      fotoProfile: fotoProfile ?? this.fotoProfile,
      namaLengkap: namaLengkap ?? this.namaLengkap,
      email: email ?? this.email,
      noHp: noHp ?? this.noHp,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
    );
  }
}
