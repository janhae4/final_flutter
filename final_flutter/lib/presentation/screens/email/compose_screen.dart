import 'package:final_flutter/config/app_theme.dart';
import 'package:final_flutter/data/models/user_model.dart';
import 'package:final_flutter/logic/email/email_bloc.dart';
import 'package:final_flutter/logic/email/email_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'dart:async';
import 'dart:io';
import 'package:final_flutter/logic/settings/settings_bloc.dart';
import 'package:dart_quill_delta/dart_quill_delta.dart';

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

  // Font riêng cho compose
  late String _composeFontFamily;
  late double _composeFontSize;

  @override
  void initState() {
    super.initState();

    // Lấy font mặc định từ settings
    final settings = context.read<SettingsBloc>().state;
    final defaultFont = settings.fontFamily;
    final defaultFontSize = settings.fontSize;

    // Font và size riêng cho compose, mặc định lấy từ settings
    _composeFontFamily = defaultFont;
    _composeFontSize = defaultFontSize;

    // Luôn khởi tạo QuillController với Delta có style mặc định
    final delta = Delta()..insert("\n", {"font": defaultFont, "size": defaultFontSize});
    _contentController = QuillController(
      document: Document.fromDelta(delta),
      selection: const TextSelection.collapsed(offset: 0),
    );

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _initializeFields(defaultFont, defaultFontSize);

    _startAutoSave();

    _animationController.forward();
  }

  void _initializeFields(String defaultFont, double defaultFontSize) {
    if (widget.replyTo != null) {
      _toController.text = widget.replyTo!.sender;
      _subjectController.text =
          widget.replyTo!.subject.startsWith('Re:')
              ? widget.replyTo!.subject
              : 'Re: ${widget.replyTo!.subject}';

      // Add quoted original message với style mặc định
      final originalContent =
          '\n\n--- Original Message ---\n'
          'From: ${widget.replyTo!.sender}\n'
          'Subject: ${widget.replyTo!.subject}\n'
          'Date: ${widget.replyTo!.time}\n\n'
          '${widget.replyTo!.content}';

      final styledDelta = Delta()
        ..insert(originalContent, {"font": defaultFont, "size": defaultFontSize});
      _contentController.document.compose(styledDelta, ChangeSource.local);
    } else if (widget.forward != null) {
      _subjectController.text =
          widget.forward!.subject.startsWith('Fwd:')
              ? widget.forward!.subject
              : 'Fwd: ${widget.forward!.subject}';

      // Add forwarded message với style mặc định
      final forwardContent =
          '\n\n--- Forwarded Message ---\n'
          'From: ${widget.forward!.sender}\n'
          'To: ${widget.forward!.to.join(', ')}\n'
          'Subject: ${widget.forward!.subject}\n'
          'Date: ${widget.forward!.time}\n\n'
          '${widget.forward!.content}';

      final styledDelta = Delta()
        ..insert(forwardContent, {"font": defaultFont, "size": defaultFontSize});
      _contentController.document.compose(styledDelta, ChangeSource.local);
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
    final settings = context.read<SettingsBloc>().state;
    final defaultFont = settings.fontFamily;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(
          widget.replyTo != null
              ? 'Reply'
              : widget.forward != null
              ? 'Forward'
              : 'Compose',
          style: Theme.of(context).appBarTheme.titleTextStyle,
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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    bottom: BorderSide(color: theme.dividerColor, width: 0.5),
                  ),
                ),
                child: Column(
                  children: [
                    // To field
                    _buildRecipientField(
                      controller: _toController,
                      label: 'To',
                      hint: 'Enter email addresses',
                      isRequired: true,
                    ),

                    // CC/BCC toggle buttons
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => setState(() => _showCc = !_showCc),
                          child: Text(_showCc ? 'Hide Cc' : 'Add Cc'),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _showBcc = !_showBcc),
                          child: Text(_showBcc ? 'Hide Bcc' : 'Add Bcc'),
                        ),
                      ],
                    ),

                    // CC field
                    if (_showCc)
                      _buildRecipientField(
                        controller: _ccController,
                        label: 'Cc',
                        hint: 'Enter email addresses',
                      ),

                    // BCC field
                    if (_showBcc)
                      _buildRecipientField(
                        controller: _bccController,
                        label: 'Bcc',
                        hint: 'Enter email addresses',
                      ),

                    // Subject field
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _subjectController,
                      decoration: const InputDecoration(
                        labelText: 'Subject',
                        hintText: 'Enter subject',
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
                      QuillSimpleToolbar(
                        controller: _contentController,
                        initialFontFamily: _composeFontFamily,
                        config: QuillSimpleToolbarConfig(
                          buttonOptions: QuillSimpleToolbarButtonOptions(
                            fontFamily: QuillToolbarFontFamilyButtonOptions(
                              items: {
                                'Roboto': 'Roboto',
                                'Montserrat': 'Montserrat',
                                'NotoSans': 'NotoSans',
                                'Lato': 'Lato',
                              },
                              onSelected: (val) {
                                setState(() {
                                  _composeFontFamily = val;
                                  bool insertedTemp = false;
                                  if (_contentController.document.length <= 1) {
                                    _contentController.replaceText(0, 0, 'a', null);
                                    insertedTemp = true;
                                  }
                                  _contentController.formatText(
                                    0,
                                    _contentController.document.length - 1,
                                    Attribute.fromKeyValue('font', val),
                                  );
                                  int offset = 0;
                                  final plainText = _contentController.document.toPlainText();
                                  for (int i = 0; i < plainText.length; i++) {
                                    if (plainText[i] != '\n') {
                                      offset = i;
                                      break;
                                    }
                                  }
                                  _contentController.updateSelection(
                                    TextSelection.collapsed(offset: offset),
                                    ChangeSource.local,
                                  );
                                  _contentController.formatSelection(Attribute.fromKeyValue('font', val));
                                  if (insertedTemp) {
                                    _contentController.replaceText(0, 1, '', null);
                                  }
                                });
                              },
                            ),
                            fontSize: QuillToolbarFontSizeButtonOptions(
                              items: {
                                '14': '14',
                                '16': '16',
                                '18': '18',
                                '20': '20',
                              },
                              onSelected: (val) {
                                setState(() {
                                  _composeFontSize = double.tryParse(val) ?? _composeFontSize;
                                  bool insertedTemp = false;
                                  if (_contentController.document.length <= 1) {
                                    _contentController.replaceText(0, 0, 'a', null);
                                    insertedTemp = true;
                                  }
                                  _contentController.formatText(
                                    0,
                                    _contentController.document.length - 1,
                                    Attribute.fromKeyValue('size', val),
                                  );
                                  int offset = 0;
                                  final plainText = _contentController.document.toPlainText();
                                  for (int i = 0; i < plainText.length; i++) {
                                    if (plainText[i] != '\n') {
                                      offset = i;
                                      break;
                                    }
                                  }
                                  _contentController.updateSelection(
                                    TextSelection.collapsed(offset: offset),
                                    ChangeSource.local,
                                  );
                                  _contentController.formatSelection(Attribute.fromKeyValue('size', val));
                                  if (insertedTemp) {
                                    _contentController.replaceText(0, 1, '', null);
                                  }
                                });
                              },
                            ),
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
                            controller: _contentController,
                            config: QuillEditorConfig(
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

  Widget _buildRecipientField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isRequired = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, hintText: hint),
        validator:
            isRequired
                ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter at least one recipient';
                  }
                  // Basic email validation
                  final emails = _parseEmails(value);
                  for (final email in emails) {
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(email)) {
                      return 'Please enter valid email addresses';
                    }
                  }
                  return null;
                }
                : null,
        keyboardType: TextInputType.emailAddress,
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
