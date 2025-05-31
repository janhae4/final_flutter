import 'package:flutter/foundation.dart';

class Email {
  final String id;
  final String sender;
  final List<dynamic> to;
  List<dynamic> cc;
  List<dynamic> bcc;
  final String subject;
  final List<dynamic> content;
  final String plainTextContent;
  final DateTime time;
  bool starred;
  bool isRead;
  bool isDraft;
  bool isInTrash;
  List<dynamic> attachments;
  List<dynamic> labels;

  Email({
    required this.id,
    required this.sender,
    required this.to,
    this.cc = const [],
    this.bcc = const [],
    required this.subject,
    required this.content,
    required this.plainTextContent,
    required this.time,
    this.starred = false,
    this.isRead = false,
    this.isDraft = false,
    this.isInTrash = false,
    this.attachments = const [],
    this.labels = const [],
  });

  factory Email.fromJson(Map<String, dynamic> json) {
    return Email(
      id: json['_id'] as String,
      sender: json['sender'] as String,
      to: List<dynamic>.from(json['to'] as List<dynamic>),
      cc: List<dynamic>.from(json['cc'] as List<dynamic>),
      bcc: List<dynamic>.from(json['bcc'] as List<dynamic>),
      subject: json['subject'] as String,
      content: json['content'] as List<dynamic>,
      plainTextContent: json['plainTextContent'] as String,
      starred: json['starred'] as bool,
      isRead: json['isRead'] as bool,
      isDraft: json['isDraft'] as bool,
      isInTrash: json['isInTrash'] as bool,
      attachments: List<dynamic>.from(json['attachments'] as List<dynamic>),
      labels: List<dynamic>.from(json['labels'] as List<dynamic>),
      time: DateTime.parse(json['createdAt'] as String),

    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender,
      'to': to,
      'cc': cc,
      'bcc': bcc,
      'subject': subject,
      'content': content,
      'plainTextContent': plainTextContent,
      'time': time.toIso8601String(),
      'attachments': attachments,
      'labels': labels,
    };
  }
}

extension EmailCopy on Email {
  Email copyWith({
    String? id,
    String? sender,
    List<dynamic>? to,
    List<dynamic>? cc,
    List<dynamic>? bcc,
    String? subject,
    List<dynamic>? content,
    String? plainTextContent,
    DateTime? time,
    bool? starred,
    bool? isRead,
    bool? isDraft,
    bool? isInTrash,
    List<dynamic>? attachments,
    List<dynamic>? labels,
  }) {
    return Email(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      to: to ?? this.to,
      cc: cc ?? this.cc,
      bcc: bcc ?? this.bcc,
      subject: subject ?? this.subject,
      content: content ?? this.content,
      plainTextContent: plainTextContent ?? this.plainTextContent,
      time: time ?? this.time,
      starred: starred ?? this.starred,
      isRead: isRead ?? this.isRead,
      isDraft: isDraft ?? this.isDraft,
      isInTrash: isInTrash ?? this.isInTrash,
      attachments: attachments ?? this.attachments,
      labels: labels ?? this.labels,
    );
  }
}
