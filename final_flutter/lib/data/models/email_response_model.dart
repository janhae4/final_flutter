class EmailResponseModel {
  final String? id;
  final String? sender;
  final String? subject;
  final String? plainTextContent;
  final List<dynamic> attachments;
  final List<dynamic> labels;
  late final bool starred;
  final bool isRead;
  final bool isDraft;
  final bool isInTrash;
  final DateTime? createdAt;

  EmailResponseModel(
    this.id,
    this.sender,
    this.subject,
    this.plainTextContent,
    this.attachments,
    this.labels,
    this.starred,
    this.isRead,
    this.isDraft,
    this.isInTrash,
    this.createdAt,
  );

  factory EmailResponseModel.fromJson(Map<String, dynamic> json) {
    return EmailResponseModel(
      json['_id'] ?? json['id'],
      json['sender'],
      json['subject'],
      json['plainTextContent'],
      json['attachments'] ?? [],
      json['labels'] ?? [],
      json['starred'] ?? false,
      json['isRead'] ?? false,
      json['isDraft'] ?? false,
      json['isInTrash'] ?? false,
      DateTime.tryParse(json['createdAt'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sender': sender,
    'subject': subject,
    'plainTextContent': plainTextContent,
    'attachments': attachments,
    'labels': labels,
    'starred': starred,
    'isRead': isRead,
    'isDraft': isDraft,
    'isInTrash': isInTrash,
    'createdAt': createdAt?.toIso8601String(),
  };
}
