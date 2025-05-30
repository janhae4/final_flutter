import 'package:flutter/material.dart';
import 'package:final_flutter/data/mock_email_repository.dart';
import 'package:final_flutter/models/email.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart' show VerticalSpacing;
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ComposeScreen extends StatefulWidget {
  final MockEmailRepository repository;
  final Email? draft;
  final String fontFamily;
  final double fontSize;
  const ComposeScreen({super.key, required this.repository, this.draft, this.fontFamily = 'Roboto', this.fontSize = 16});

  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen> {
  final _toController = TextEditingController();
  final _ccController = TextEditingController();
  final _bccController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  List<String> _attachments = [];
  Timer? _autoSaveTimer;
  quill.QuillController _quillController = quill.QuillController.basic();

  @override
  void initState() {
    super.initState();
    if (widget.draft != null) {
      _toController.text = widget.draft!.to.join(', ');
      _ccController.text = widget.draft!.cc.join(', ');
      _bccController.text = widget.draft!.bcc.join(', ');
      _subjectController.text = widget.draft!.subject;
      // Nếu có nội dung rich text, parse từ JSON, nếu không thì plain text
      try {
        if (widget.draft!.content.trim().startsWith('[')) {
          final List<dynamic> json = jsonDecode(widget.draft!.content);
          _quillController = quill.QuillController(
            document: quill.Document.fromJson(json),
            selection: const TextSelection.collapsed(offset: 0),
          );
        } else {
          _quillController = quill.QuillController(
            document: quill.Document()..insert(0, widget.draft!.content),
            selection: const TextSelection.collapsed(offset: 0),
          );
        }
      } catch (_) {
        _quillController = quill.QuillController.basic();
      }
      _attachments = List.from(widget.draft!.attachments);
    }
    _toController.addListener(_onFieldChanged);
    _ccController.addListener(_onFieldChanged);
    _bccController.addListener(_onFieldChanged);
    _subjectController.addListener(_onFieldChanged);
    _quillController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), _autoSaveDraft);
  }

  void _autoSaveDraft() async {
    List<String> savedAttachments = [];
    for (final path in _attachments) {
      final file = File(path);
      if (await file.exists()) {
        final dir = await getApplicationDocumentsDirectory();
        final fileName = path.split(Platform.pathSeparator).last;
        final newPath = '${dir.path}/$fileName';
        if (!File(newPath).existsSync()) {
          await file.copy(newPath);
        }
        savedAttachments.add(newPath);
      }
    }
    final draft = Email(
      id: widget.draft?.id ?? const Uuid().v4(),
      sender: 'me@example.com',
      to: _toController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      cc: _ccController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      bcc: _bccController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      subject: _subjectController.text,
      content: jsonEncode(_quillController.document.toDelta().toJson()),
      time: DateTime.now(),
      isDraft: true,
      attachments: savedAttachments,
    );
    widget.repository.saveDraft(draft);
    // Có thể show SnackBar hoặc log nếu muốn
  }

  void _sendEmail() async {
    List<String> savedAttachments = [];
    for (final path in _attachments) {
      final file = File(path);
      if (await file.exists()) {
        final dir = await getApplicationDocumentsDirectory();
        final fileName = path.split(Platform.pathSeparator).last;
        final newPath = '${dir.path}/$fileName';
        await file.copy(newPath);
        savedAttachments.add(newPath);
      }
    }
    widget.repository.sendEmail(
      sender: 'me@example.com',
      to: _toController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      cc: _ccController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      bcc: _bccController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      subject: _subjectController.text,
      content: jsonEncode(_quillController.document.toDelta().toJson()),
      attachments: savedAttachments,
    );
    Navigator.pop(context);
  }

  void _attachFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        _attachments.add(result.files.single.path!);
      });
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _toController.dispose();
    _ccController.dispose();
    _bccController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Soạn Email')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _toController,
                    decoration: InputDecoration(
                      labelText: 'To',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(icon: Icon(Icons.contacts, color: Colors.blueAccent), onPressed: () {}),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ccController,
                    decoration: InputDecoration(
                      labelText: 'CC',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _bccController,
                    decoration: InputDecoration(
                      labelText: 'BCC',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            SizedBox(height: 14),
            Text('Nội dung:', style: TextStyle(fontWeight: FontWeight.bold)),
            quill.QuillToolbar.simple(
              configurations: quill.QuillSimpleToolbarConfigurations(
                controller: _quillController,
              ),
            ),
            Container(
              height: 200,
              decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
              child: quill.QuillEditor.basic(
                configurations: quill.QuillEditorConfigurations(
                  controller: _quillController,
                  padding: EdgeInsets.all(8),
                  customStyles: quill.DefaultStyles(
                    paragraph: quill.DefaultTextBlockStyle(
                      TextStyle(fontFamily: widget.fontFamily, fontSize: widget.fontSize),
                      VerticalSpacing(0, 0),
                      VerticalSpacing(0, 0),
                      null,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 14),
            if (_attachments.isNotEmpty)
              Wrap(
                spacing: 8,
                children: _attachments.map((f) => Chip(label: Text(f.split(Platform.pathSeparator).last))).toList(),
              ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _attachFile,
                    icon: Icon(Icons.attach_file),
                    label: Text('Đính kèm'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _sendEmail,
                    icon: Icon(Icons.send),
                    label: Text('Gửi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 