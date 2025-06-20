class EmailResponseModel {
  final String? id;
  final String? sender;
  final String? subject;
  final String? plainTextContent;
  final List<dynamic> attachments;
  final int attachmentsCount;
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
    this.attachmentsCount,
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
      json['attachmentsCount'] ?? 0,
      json['labels'] ?? [],
      json['starred'] ?? false,
      json['isRead'] ?? false,
      json['isDraft'] ?? false,
      json['isInTrash'] ?? false,
      DateTime.tryParse(json['createdAt'] ?? ''),
    );
  }

  EmailResponseModel copyWith({
    String? id,
    String? sender,
    String? subject,
    String? plainTextContent,
    String? htmlContent,
    DateTime? createdAt,
    bool? isRead,
    bool? starred,
    int? attachmentsCount,
    List<Map<String, dynamic>>? labels,
    bool? isInTrash,
  }) {
    return EmailResponseModel(
      id ?? this.id,
      sender ?? this.sender,
      subject ?? this.subject,
      plainTextContent ?? this.plainTextContent,
      attachments,
      attachmentsCount ?? this.attachmentsCount,
      labels ?? this.labels,
      starred ?? this.starred,
      isRead ?? this.isRead,
      isDraft,
      isInTrash ?? this.isInTrash,
      createdAt ?? this.createdAt,
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
