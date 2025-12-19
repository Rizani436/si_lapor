class AkunModel {
  final String id;
  final String? email;
  final String? namaLengkap;
  final String? noHp;
  final String? role;
  final bool? isActive;
  final String? fotoProfile;

  const AkunModel({
    required this.id,
    this.email,
    this.namaLengkap,
    this.noHp,
    this.role,
    this.isActive,
    this.fotoProfile,
  });

  factory AkunModel.fromMap(Map<String, dynamic> map) {
    return AkunModel(
      id: (map['id'] ?? '').toString(),
      email: map['email']?.toString(),
      namaLengkap: map['nama_lengkap']?.toString(),
      noHp: map['no_hp']?.toString(),
      role: map['role']?.toString(),
      isActive: map['is_active'] as bool?,
      fotoProfile: map['foto_profile']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'nama_lengkap': namaLengkap,
      'no_hp': noHp,
      'role': role,
      'is_active': isActive,
      'foto_profile': fotoProfile,
    };
  }

  AkunModel copyWith({
    String? email,
    String? namaLengkap,
    String? noHp,
    String? role,
    bool? isActive,
    String? fotoProfile,
  }) {
    return AkunModel(
      id: id,
      email: email ?? this.email,
      namaLengkap: namaLengkap ?? this.namaLengkap,
      noHp: noHp ?? this.noHp,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      fotoProfile: fotoProfile ?? this.fotoProfile,
    );
  }
}
