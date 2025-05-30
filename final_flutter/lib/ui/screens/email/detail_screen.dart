import 'package:flutter/material.dart';
import 'package:final_flutter/models/email.dart';
import 'package:final_flutter/data/mock_email_repository.dart';
import 'package:final_flutter/ui/screens/email/compose_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'dart:convert';

class DetailScreen extends StatefulWidget {
  final Email email;
  final MockEmailRepository repository;
  const DetailScreen({super.key, required this.email, required this.repository});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  @override
  Widget build(BuildContext context) {
    final email = widget.email;
    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết Email'),
        actions: [
          IconButton(
            icon: Icon(email.isRead ? Icons.mark_email_read : Icons.mark_email_unread),
            onPressed: () {
              setState(() {
                widget.repository.markRead(email, !email.isRead);
                widget.repository.notifyListeners();
              });
            },
            tooltip: email.isRead ? 'Đánh dấu chưa đọc' : 'Đánh dấu đã đọc',
          ),
          PopupMenuButton<String>(
            onSelected: (label) {
              setState(() {
                if (email.labels.contains(label)) {
                  widget.repository.removeLabel(email, label);
                } else {
                  widget.repository.assignLabel(email, label);
                }
              });
            },
            itemBuilder: (context) => [
              'Work', 'Personal', 'Important', 'Spam'
            ].map((label) => CheckedPopupMenuItem(
              value: label,
              checked: email.labels.contains(label),
              child: Text(label),
            )).toList(),
            icon: Icon(Icons.label),
            tooltip: 'Gán nhãn',
          ),
          IconButton(
            icon: Icon(email.starred ? Icons.star : Icons.star_border),
            onPressed: () {
              setState(() {
                widget.repository.toggleStar(email);
                widget.repository.notifyListeners();
              });
            },
            tooltip: 'Gắn sao',
          ),
          IconButton(
            icon: Icon(Icons.delete_outline),
            onPressed: () {
              widget.repository.moveToTrash(email);
              Navigator.pop(context);
            },
            tooltip: 'Xóa',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Từ: ${email.sender}'),
            Text('Đến: ${email.to.join(", ")}'),
            if (email.cc.isNotEmpty) Text('CC: ${email.cc.join(", ")}'),
            if (email.bcc.isNotEmpty) Text('BCC: ${email.bcc.join(", ")}'),
            Text('Chủ đề: ${email.subject}'),
            Text('Thời gian: ${_formatTime(email.time)}'),
            if (email.labels.isNotEmpty)
              Wrap(
                spacing: 8,
                children: email.labels.map((l) => Chip(label: Text(l))).toList(),
              ),
            Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: _buildEmailContent(email),
              ),
            ),
            if (email.attachments.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Đính kèm:'),
                  ...email.attachments.map((f) => ListTile(
                        leading: Icon(Icons.attach_file),
                        title: Text(f.split(Platform.pathSeparator).last),
                        trailing: IconButton(
                          icon: Icon(Icons.download),
                          onPressed: () async {
                            try {
                              final downloadsDir = await getDownloadsDirectory();
                              if (downloadsDir == null) throw Exception('Không tìm thấy thư mục Download');
                              final fileName = f.split(Platform.pathSeparator).last;
                              final file = File(f);
                              final newPath = '${downloadsDir.path}/$fileName';
                              await file.copy(newPath);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Đã tải file $fileName về $newPath')),
                              );
                              final result = await OpenFile.open(newPath);
                              if (result.type != ResultType.done) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Không mở được file: \\${result.message}')),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Tải file thất bại: $e')),
                              );
                            }
                          },
                        ),
                      )),
                ],
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    final reply = widget.repository.replyTo(email, 'me@example.com', '');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ComposeScreen(
                          repository: widget.repository,
                          draft: reply,
                        ),
                      ),
                    );
                  },
                  child: Text('Trả lời'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final fwd = widget.repository.forward(email, 'me@example.com', [], '');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ComposeScreen(
                          repository: widget.repository,
                          draft: fwd,
                        ),
                      ),
                    );
                  },
                  child: Text('Chuyển tiếp'),
                ),
                ElevatedButton(
                  onPressed: () {
                    widget.repository.moveToTrash(email);
                    Navigator.pop(context);
                  },
                  child: Text('Xóa'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} ${time.day}/${time.month}/${time.year}";
  }

  Widget _buildEmailContent(Email email) {
    try {
      final content = email.content.trim();
      if (content.startsWith('[')) {
        final List<dynamic> jsonData = jsonDecode(content);
        final doc = quill.Document.fromJson(jsonData);
        final controller = quill.QuillController(document: doc, selection: const TextSelection.collapsed(offset: 0));
        controller.readOnly = true;
        return quill.QuillEditor.basic(
          configurations: quill.QuillEditorConfigurations(
            controller: controller,
            padding: EdgeInsets.zero,
          ),
        );
      } else {
        return Text(content);
      }
    } catch (e) {
      return Text(email.content);
    }
  }
} 