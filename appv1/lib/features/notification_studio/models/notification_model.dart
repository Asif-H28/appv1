class NotificationModel {
  final String id;
  final String title;
  final String body;
  final bool isRead;
  final Map<String, dynamic> data;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    required this.data,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      isRead: json['isRead'] ?? false,
      data: json['data'] ?? {},
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}
