
class NotificationItem {
  final String id;
  final String sender;
  final String subject;
  final DateTime time;
  final bool isRead;

  NotificationItem({
    required this.id,
    required this.sender,
    required this.subject,
    required this.time,
    required this.isRead,
  });

  NotificationItem copyWith({
    String? id,
    String? sender,
    String? subject,
    DateTime? time,
    bool? isRead,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      subject: subject ?? this.subject,
      time: time ?? this.time,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NotificationItem &&
        other.id == id &&
        other.sender == sender &&
        other.subject == subject &&
        other.time == time &&
        other.isRead == isRead;
  }

  @override
  int get hashCode => Object.hash(id, sender, subject, time, isRead);
}
