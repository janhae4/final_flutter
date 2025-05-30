class Email {
  final String id;
  final String sender;
  final List<String> to;
  final List<String> cc;
  final List<String> bcc;
  final String subject;
  final String content;
  final DateTime time;
  bool starred;
  bool isRead;
  bool isDraft;
  List<String> attachments;
  List<String> labels;

  Email({
    required this.id,
    required this.sender,
    required this.to,
    required this.cc,
    required this.bcc,
    required this.subject,
    required this.content,
    required this.time,
    this.starred = false,
    this.isRead = false,
    this.isDraft = false,
    this.attachments = const [],
    this.labels = const [],
  });
} 