import 'dart:convert';
import 'dart:typed_data';

class EmailAttachment {
  final String name;
  final String? path;
  final String? bytes;

  EmailAttachment({
    required this.name,
    this.path,
    this.bytes,
  });

  factory EmailAttachment.fromJson(Map<String, dynamic> json) {
    return EmailAttachment(
      name: json['name'],
      bytes: json['data']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'data': bytes,
    };
  }
}
