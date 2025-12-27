class NotifikasiModel {
  final int idNotifikasi;
  final String idUser;
  final String title;
  final String body;
  final DateTime createdAt;
  final int isRead;

  NotifikasiModel({
    required this.idNotifikasi,
    required this.idUser,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
  });

  factory NotifikasiModel.fromJson(Map<String, dynamic> json) {
    return NotifikasiModel(
      idNotifikasi: json['id_notifikasi'] as int,
      idUser: json['id_user'] as String,
      title: (json['title'] ?? '') as String,
      body: (json['body'] ?? '') as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isRead: (json['is_read'] ?? 0) as int,
    );
  }
}
