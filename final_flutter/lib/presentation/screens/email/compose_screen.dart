import 'package:final_flutter/config/app_theme.dart';
import 'package:final_flutter/data/models/user_model.dart';
import 'package:final_flutter/logic/email/email_bloc.dart';
import 'package:final_flutter/logic/email/email_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'dart:async';

// Assuming you have these imports for your BLoC
// import 'package:final_flutter/bloc/email_bloc.dart';
// import 'package:final_flutter/bloc/email_event.dart';
// import 'package:final_flutter/bloc/email_state.dart';
import 'package:final_flutter/data/models/email.dart';

class ComposeEmailScreen extends StatefulWidget {
  final UserModel? user;
  final Email? replyTo;
  final Email? forward;

  const ComposeEmailScreen({super.key, required this.user, this.replyTo, this.forward});

  @override
  State<ComposeEmailScreen> createState() => _ComposeEmailScreenState();
}

class _ComposeEmailScreenState extends State<ComposeEmailScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final _toController = TextEditingController();
  final _ccController = TextEditingController();
  final _bccController = TextEditingController();
  final _subjectController = TextEditingController();

  // WYSIWYG Editor
  late QuillController _contentController;

  // State variables
  bool _showCc = false;
  bool _showBcc = false;
  bool _isDraft = false;
  Timer? _autoSaveTimer;
  final List<PlatformFile> _attachments = [];

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _contentController = QuillController.basic();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _initializeFields();

    _startAutoSave();

    _animationController.forward();
  }

  void _initializeFields() {
    if (widget.replyTo != null) {
      _toController.text = widget.replyTo!.sender;
      _subjectController.text =
          widget.replyTo!.subject.startsWith('Re:')
              ? widget.replyTo!.subject
              : 'Re: ${widget.replyTo!.subject}';

      // Add quoted original message
      final originalContent =
          '\n\n--- Original Message ---\n'
          'From: ${widget.replyTo!.sender}\n'
          'Subject: ${widget.replyTo!.subject}\n'
          'Date: ${widget.replyTo!.time}\n\n'
          '${widget.replyTo!.content}';

      _contentController.document.insert(
        _contentController.document.length,
        originalContent,
      );
    } else if (widget.forward != null) {
      _subjectController.text =
          widget.forward!.subject.startsWith('Fwd:')
              ? widget.forward!.subject
              : 'Fwd: ${widget.forward!.subject}';

      // Add forwarded message
      final forwardContent =
          '\n\n--- Forwarded Message ---\n'
          'From: ${widget.forward!.sender}\n'
          'To: ${widget.forward!.to.join(', ')}\n'
          'Subject: ${widget.forward!.subject}\n'
          'Date: ${widget.forward!.time}\n\n'
          '${widget.forward!.content}';

      _contentController.document.insert(
        _contentController.document.length,
        forwardContent,
      );
    }
  }

  void _startAutoSave() {
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _saveAsDraft();
    });
  }

  void _saveAsDraft() {
    if (_toController.text.isNotEmpty ||
        _subjectController.text.isNotEmpty ||
        _contentController.document.toPlainText().trim().isNotEmpty) {
      final email = Email(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: widget.user!.email!, 
        to: _parseEmails(_toController.text),
        cc: _parseEmails(_ccController.text),
        bcc: _parseEmails(_bccController.text),
        subject: _subjectController.text,
        content: _contentController.document.toDelta().toJson(),
        plainTextContent: _contentController.document.toPlainText(),
        time: DateTime.now(),
        isDraft: true,
        attachments: _attachments.map((file) => file.path ?? '').toList(),
      );

      // Dispatch save draft event to BLoC
      // context.read<EmailBloc>().add(SaveDraftEvent(email));

      setState(() {
        _isDraft = true;
      });

      // Show subtle feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Draft saved'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
        ),
      );
    }
  }

  List<String> _parseEmails(String text) {
    return text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _pickAttachments() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null) {
        setState(() {
          _attachments.addAll(result.files);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking files: $e')));
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  void _sendEmail() {
    if (_formKey.currentState!.validate()) {
      if (_toController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter at least one recipient')),
        );
        return;
      }

      final email = Email(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: widget.user!.email!, 
        to: _parseEmails(_toController.text),
        cc: _parseEmails(_ccController.text),
        bcc: _parseEmails(_bccController.text),
        subject: _subjectController.text,
        content: _contentController.document.toDelta().toJson(),
        plainTextContent: _contentController.document.toPlainText(),
        time: DateTime.now(),
        attachments: _attachments.map((file) => file.path ?? '').toList(),
      );

            print('''
      To: ${email.to}
      CC: ${email.cc}
      BCC: ${email.bcc}
      Subject: ${email.subject}
      Content: ${_contentController.document.toDelta().toJson()}
      ''');

      // Dispatch send email event to BLoC
      context.read<EmailBloc>().add(SendEmail(email));

      // Show confirmation
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Email sent successfully!')));

      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _toController.dispose();
    _ccController.dispose();
    _bccController.dispose();
    _subjectController.dispose();
    _contentController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.replyTo != null
              ? 'Reply'
              : widget.forward != null
              ? 'Forward'
              : 'Compose',
        ),
        actions: [
          // Draft indicator
          if (_isDraft)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.secondary.withAlpha((255 * 0.2).toInt()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Draft',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          // Attachment button
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: _pickAttachments,
            tooltip: 'Add attachments',
          ),
          // Send button
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              onPressed: _sendEmail,
              icon: const Icon(Icons.send, size: 18, color: AppColors.surface),
              label: const Text('Send'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Recipients Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    bottom: BorderSide(color: theme.dividerColor, width: 0.5),
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    // To field
                    TextFormField(
                      controller: _toController,
                      decoration: InputDecoration(
                        labelText: 'To',
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.pink),
                        prefixIcon: const Icon(Icons.person_outline, color: Colors.pink),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter at least one recipient';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    // CC field
                    TextFormField(
                      controller: _ccController,
                      decoration: InputDecoration(
                        labelText: 'Cc',
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.pink),
                        prefixIcon: const Icon(Icons.group_outlined, color: Colors.pink),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // BCC field
                    TextFormField(
                      controller: _bccController,
                      decoration: InputDecoration(
                        labelText: 'Bcc',
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.pink),
                        prefixIcon: const Icon(Icons.lock_outline, color: Colors.pink),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Subject field
                    TextFormField(
                      controller: _subjectController,
                      decoration: const InputDecoration(
                        labelText: 'Subject',
                        hintText: 'Enter subject',
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                        filled: true,
                        fillColor: Color(0xFFF4F5FB),
                        contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a subject';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              // Attachments
              if (_attachments.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border(
                      bottom: BorderSide(color: theme.dividerColor, width: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attachments (${_attachments.length})',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            _attachments.asMap().entries.map((entry) {
                              final index = entry.key;
                              final file = entry.value;
                              return Chip(
                                avatar: Icon(
                                  _getFileIcon(file.extension ?? ''),
                                  size: 18,
                                ),
                                label: Text(
                                  file.name,
                                  style: theme.textTheme.bodySmall,
                                ),
                                deleteIcon: const Icon(Icons.close, size: 18),
                                onDeleted: () => _removeAttachment(index),
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                ),

              // Content Editor
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Toolbar
                      QuillToolbar.simple(
                        configurations: QuillSimpleToolbarConfigurations(
                          controller: _contentController,
                          sharedConfigurations: const QuillSharedConfigurations(
                            locale: Locale('en'),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Editor
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: theme.dividerColor),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: QuillEditor.basic(
                            configurations: QuillEditorConfigurations(
                              controller: _contentController,
                              // r: false,
                              sharedConfigurations:
                                  const QuillSharedConfigurations(
                                    locale: Locale('en'),
                                  ),
                              placeholder: 'Write your message...',
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
        return Icons.audio_file;
      default:
        return Icons.attach_file;
    }
  }
}
