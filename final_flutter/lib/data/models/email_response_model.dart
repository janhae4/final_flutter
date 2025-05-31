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
      json['_id'],
      json['sender'],
      json['subject'],
      json['plainTextContent'],
      json['attachments'],
      json['labels'],
      json['starred'],
      json['isRead'],
      json['isDraft'],
      json['isInTrash'],
      DateTime.parse(json['createdAt']),
    );
  }
}


