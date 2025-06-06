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
import 'package:final_flutter/data/models/email.dart';

class ForwardEmailScreen extends StatefulWidget {
  final UserModel user;
  final Email originalEmail;

  const ForwardEmailScreen({
    super.key, 
    required this.user, 
    required this.originalEmail
  });

  @override
  State<ForwardEmailScreen> createState() => _ForwardEmailScreenState();
}

class _ForwardEmailScreenState extends State<ForwardEmailScreen>
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
  bool _includeOriginalAttachments = true;
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

    _initializeForwardFields();
    _startAutoSave();
    _animationController.forward();
  }

  void _initializeForwardFields() {
    // Set subject with Fwd: prefix
    _subjectController.text = widget.originalEmail.subject.startsWith('Fwd:')
        ? widget.originalEmail.subject
        : 'Fwd: ${widget.originalEmail.subject}';

    // Add forwarded message content
    final forwardedContent = '''


---------- Forwarded message ----------
From: ${widget.originalEmail.sender}
Date: ${_formatDateTime(widget.originalEmail.time)}
Subject: ${widget.originalEmail.subject}
To: ${widget.originalEmail.to.join(', ')}
${widget.originalEmail.cc.isNotEmpty ? 'Cc: ${widget.originalEmail.cc.join(', ')}\n' : ''}

${widget.originalEmail.plainTextContent ?? ''}''';

    _contentController.document.insert(
      _contentController.document.length,
      forwardedContent,
    );

    _contentController.updateSelection(
      TextSelection.collapsed(offset: 0),
      ChangeSource.local,
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
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
        sender: widget.user.email!,
        to: _parseEmails(_toController.text),
        cc: _parseEmails(_ccController.text),
        bcc: _parseEmails(_bccController.text),
        subject: _subjectController.text,
        content: _contentController.document.toDelta().toJson(),
        plainTextContent: _contentController.document.toPlainText(),
        time: DateTime.now(),
        isDraft: true,
        attachments: _getAttachmentPaths(),
        originalEmailId: widget.originalEmail.id,
      );

      setState(() {
        _isDraft = true;
      });

      // Show subtle feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Draft saved'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(bottom: 100, left: 16, right: 16),
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

  List<String> _getAttachmentPaths() {
    List<String> paths = _attachments.map((file) => file.path ?? '').toList();
    
    if (_includeOriginalAttachments && widget.originalEmail.attachments != null) {
      paths.addAll(List<String>.from(widget.originalEmail.attachments!));
    }
    
    return paths;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking files: $e')),
      );
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
        sender: widget.user.email!,
        to: _parseEmails(_toController.text),
        cc: _parseEmails(_ccController.text),
        bcc: _parseEmails(_bccController.text),
        subject: _subjectController.text,
        content: _contentController.document.toDelta().toJson(),
        plainTextContent: _contentController.document.toPlainText(),
        time: DateTime.now(),
        attachments: _getAttachmentPaths(),
        originalEmailId: widget.originalEmail.id,
        isForwarded: true,
      );

      // Dispatch send email event to BLoC
      context.read<EmailBloc>().add(SendEmail(email));

      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email forwarded successfully!')),
      );

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
        title: const Text('Forward Email'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
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
              icon: const Icon(Icons.forward, size: 18, color: AppColors.surface),
              label: const Text('Forward'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.surface,
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
              // Original Email Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha((255 * 0.1).toInt()),
                  border: Border(
                    bottom: BorderSide(color: theme.dividerColor, width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.forward,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Forwarding: ${widget.originalEmail.subject}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'From: ${widget.originalEmail.sender}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.surface.withAlpha((255 * 0.7).toInt()),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

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

              // Attachments Section
              if (_attachments.isNotEmpty || 
                  (widget.originalEmail.attachments?.isNotEmpty ?? false))
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Attachments',
                            style: theme.textTheme.titleSmall,
                          ),
                          if (widget.originalEmail.attachments?.isNotEmpty ?? false)
                            Row(
                              children: [
                                Checkbox(
                                  value: _includeOriginalAttachments,
                                  onChanged: (value) {
                                    setState(() {
                                      _includeOriginalAttachments = value ?? false;
                                    });
                                  },
                                ),
                                Text(
                                  'Include original',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Original attachments
                      if (_includeOriginalAttachments && 
                          (widget.originalEmail.attachments?.isNotEmpty ?? false))
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'From original email:',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.surface.withAlpha((255 * 0.7).toInt()),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: widget.originalEmail.attachments!
                                  .map((attachment) => Chip(
                                        avatar: Icon(
                                          _getFileIcon(_getFileExtension(attachment)),
                                          size: 18,
                                        ),
                                        label: Text(
                                          _getFileName(attachment),
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ))
                                  .toList(),
                            ),
                            if (_attachments.isNotEmpty) const SizedBox(height: 12),
                          ],
                        ),
                      
                      // New attachments
                      if (_attachments.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_includeOriginalAttachments && 
                                (widget.originalEmail.attachments?.isNotEmpty ?? false))
                              Text(
                                'Additional attachments:',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.surface.withAlpha((255 * 0.7).toInt()),
                                ),
                              ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _attachments.asMap().entries.map((entry) {
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
                              sharedConfigurations: const QuillSharedConfigurations(
                                locale: Locale('en'),
                              ),
                              placeholder: 'Add your message above the forwarded content...',
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
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
        ),
        validator: isRequired
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter at least one recipient';
                }
                // Basic email validation
                final emails = _parseEmails(value);
                for (final email in emails) {
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(email)) {
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

  String _getFileExtension(String filePath) {
    return filePath.split('.').last;
  }

  String _getFileName(String filePath) {
    return filePath.split('/').last;
  }
}