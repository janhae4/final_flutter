import 'dart:async';
import 'dart:convert';

import 'package:final_flutter/config/app_theme.dart';
import 'package:final_flutter/data/models/email.dart';
import 'package:final_flutter/data/models/email_attachment_model.dart';
import 'package:final_flutter/logic/email/email_bloc.dart';
import 'package:final_flutter/logic/email/email_event.dart';
import 'package:final_flutter/logic/email/email_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart'
    show Document, QuillController, QuillEditor, QuillSimpleToolbar, QuillEditorConfig;
import 'package:final_flutter/logic/settings/settings_bloc.dart';
import 'package:final_flutter/logic/settings/settings_state.dart';

class ComposeEmailScreen extends StatefulWidget {
  final dynamic user;
  final dynamic replyTo;
  final dynamic forward;
  final dynamic emailId;

  const ComposeEmailScreen({
    super.key,
    required this.user,
    this.replyTo,
    this.forward,
    this.emailId,
  });

  @override
  State<ComposeEmailScreen> createState() => _ComposeEmailScreenState();
}

class _ComposeEmailScreenState extends State<ComposeEmailScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Controllers
  final _toController = TextEditingController();
  final _ccController = TextEditingController();
  final _bccController = TextEditingController();
  final _subjectController = TextEditingController();
  late QuillController _contentController;

  // State
  bool _showCc = false;
  bool _showBcc = false;
  bool _isDraft = false;
  final bool _isExpanded = false;
  Timer? _autoSaveTimer;
  final List<PlatformFile> _attachments = [];

  // Animations
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _bounceController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  Email? _email;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();

    _toController.addListener(_onFieldChanged);
    _ccController.addListener(_onFieldChanged);
    _bccController.addListener(_onFieldChanged);
    _subjectController.addListener(_onFieldChanged);

    if (widget.emailId != null) {
      context.read<EmailBloc>().add(LoadEmailDetail(widget.emailId));
    }

    _initializeEditor();
    _playEntranceAnimation();
  }

  void _onFieldChanged() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 5), () {
      _isDraft = true;
      _sendEmail(true);
    });
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.bounceOut),
    );
  }

  void _playEntranceAnimation() {
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 100), () {
      _slideController.forward();
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      _bounceController.forward();
    });
  }

  void _initializeEditor() {
    if (widget.replyTo != null) {
      _toController.text = widget.replyTo!.sender;
      _subjectController.text =
          widget.replyTo!.subject.startsWith('Re:')
              ? widget.replyTo!.subject
              : 'Re: ${widget.replyTo!.subject}';
    } else if (widget.forward != null) {
      _subjectController.text =
          widget.forward!.subject.startsWith('Fwd:')
              ? widget.forward!.subject
              : 'Fwd: ${widget.forward!.subject}';
    }
    _contentController = QuillController.basic();
  }

  void _showFloatingMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface.withAlpha((255 * 0.2).toInt()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.check_circle,
                color: AppColors.surface,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
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
        _showFloatingMessage(
          '${result.files.length} files attached',
          AppColors.info.withAlpha((255 * 0.8).toInt()),
        );
      }
    } catch (e) {
      _showFloatingMessage(
        'Error selecting files',
        AppColors.accent.withAlpha((255 * 0.8).toInt()),
      );
    }
  }

  void _sendEmail(bool isDraft) {
    if (!isDraft && !_formKey.currentState!.validate()) {
      return;
    }
    if (!isDraft && _toController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter at least one recipient')),
      );
      return;
    }

    final email = Email(
      id: _email?.id ?? '',
      sender: widget.user!.email!,
      to: _parseEmails(_toController.text),
      cc: _parseEmails(_ccController.text),
      bcc: _parseEmails(_bccController.text),
      subject: _subjectController.text,
      content: _contentController.document.toDelta().toJson(),
      plainTextContent: _contentController.document.toPlainText(),
      time: DateTime.now(),
      attachments:
          _attachments.map((file) {
            return EmailAttachment(
              name: file.name,
              path: kIsWeb ? null : file.path,
              bytes: kIsWeb ? base64Encode(file.bytes!) : null,
            );
          }).toList(),
      attachmentCount: _attachments.length,
      isReplied: widget.replyTo != null ? true : false,
      isForwarded: widget.forward != null ? true : false,
      originalEmailId: widget.replyTo?.id ?? widget.forward?.id ?? '',
      isDraft: isDraft,
    );

    if (isDraft) {
      context.read<EmailBloc>().add(DraftEmail(email));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draft saved successfully!')),
      );
    } else {
      context.read<EmailBloc>().add(SendEmail(email));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Email sent successfully!')));
      Navigator.of(context).pop();
    }
  }

  List<String> _parseEmails(String text) {
    return text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary:
                  settingsState.isDarkMode
                      ? AppColors.primaryDark
                      : AppColors.primary,
              secondary:
                  settingsState.isDarkMode
                      ? AppColors.primaryLight
                      : AppColors.primaryLight,
            ),
          ),
          child: BlocConsumer<EmailBloc, EmailState>(
            listener: (context, state) {
              if (state is EmailDetailLoaded) {
                setState(() {
                  _email = state.emailThread.email;
                  _toController.text = _email!.to.join(', ');
                  _ccController.text = _email!.cc.join(', ');
                  _bccController.text = _email!.bcc.join(', ');
                  _subjectController.text = _email!.subject;
                  _contentController = QuillController(
                    document:
                        _isValidQuillContent(_email!.content)
                            ? Document.fromJson(_email!.content)
                            : Document(),
                    selection: const TextSelection.collapsed(offset: 0),
                  );
                });
              }
            },
            builder:
                (context, state) => Scaffold(
                  backgroundColor:
                      settingsState.isDarkMode
                          ? AppColors.backgroundDark
                          : AppColors.background,
                  extendBodyBehindAppBar: true,
                  appBar: _buildModernAppBar(settingsState),
                  body: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: _buildBody(settingsState),
                      ),
                    ),
                  ),
                  floatingActionButton: _buildFloatingActionButton(
                    settingsState,
                  ),
                ),
          ),
        );
      },
    );
  }

  bool _isValidQuillContent(dynamic content) {
    return content is List &&
        content.isNotEmpty &&
        content.every((e) => e is Map<String, dynamic>);
  }

  PreferredSizeWidget _buildModernAppBar(SettingsState settingsState) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              settingsState.isDarkMode
                  ? AppColors.primaryDark.withAlpha((255 * 0.8).toInt())
                  : AppColors.primary.withAlpha((255 * 0.8).toInt()),
              settingsState.isDarkMode
                  ? AppColors.primaryLight.withAlpha((255 * 0.8).toInt())
                  : AppColors.primaryLight.withAlpha((255 * 0.8).toInt()),
            ],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  settingsState.isDarkMode
                      ? AppColors.surfaceDark.withAlpha((255 * 0.2).toInt())
                      : AppColors.surface.withAlpha((255 * 0.2).toInt()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.replyTo != null
                  ? Icons.reply
                  : widget.forward != null
                  ? Icons.forward
                  : Icons.edit,
              color:
                  settingsState.isDarkMode
                      ? AppColors.textPrimaryDark
                      : AppColors.surface,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            widget.replyTo != null
                ? 'Reply'
                : widget.forward != null
                ? 'Forward'
                : 'Compose',
            style: TextStyle(
              color:
                  settingsState.isDarkMode
                      ? AppColors.textPrimaryDark
                      : AppColors.surface,
              fontWeight: FontWeight.w600,
              fontSize: settingsState.fontSize + 2,
              fontFamily: settingsState.fontFamily,
            ),
          ),
        ],
      ),
      actions: [
        if (_isDraft)
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    settingsState.isDarkMode
                        ? AppColors.surfaceDark.withAlpha((255 * 0.2).toInt())
                        : AppColors.surface.withAlpha((255 * 0.2).toInt()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.save,
                color:
                    settingsState.isDarkMode
                        ? AppColors.textPrimaryDark
                        : AppColors.surface,
                size: 20,
              ),
            ),
            onPressed: () => _sendEmail(true),
          ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  settingsState.isDarkMode
                      ? AppColors.surfaceDark.withAlpha((255 * 0.2).toInt())
                      : AppColors.surface.withAlpha((255 * 0.2).toInt()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.attach_file,
              color:
                  settingsState.isDarkMode
                      ? AppColors.textPrimaryDark
                      : AppColors.surface,
              size: 20,
            ),
          ),
          onPressed: _pickAttachments,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody(SettingsState settingsState) {
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.only(top: 100),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildRecipientsCard(settingsState),
              if (_attachments.isNotEmpty) _buildAttachmentsCard(settingsState),
              _buildEditorCard(settingsState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecipientsCard(SettingsState settingsState) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            settingsState.isDarkMode
                ? AppColors.surfaceDark
                : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                settingsState.isDarkMode
                    ? AppColors.textPrimaryDark.withAlpha((255 * 0.05).toInt())
                    : AppColors.textPrimary.withAlpha((255 * 0.05).toInt()),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildModernTextField(
              controller: _toController,
              label: 'To',
              icon: Icons.person,
              isRequired: true,
              settingsState: settingsState,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  _buildToggleButton(
                    'Cc',
                    _showCc,
                    () => setState(() => _showCc = !_showCc),
                    settingsState,
                  ),
                  const SizedBox(width: 12),
                  _buildToggleButton(
                    'Bcc',
                    _showBcc,
                    () => setState(() => _showBcc = !_showBcc),
                    settingsState,
                  ),
                ],
              ),
            ),
            if (_showCc)
              _buildModernTextField(
                controller: _ccController,
                label: 'Cc',
                icon: Icons.people,
                settingsState: settingsState,
              ),
            if (_showBcc)
              _buildModernTextField(
                controller: _bccController,
                label: 'Bcc',
                icon: Icons.people_outline,
                settingsState: settingsState,
              ),
            _buildModernTextField(
              controller: _subjectController,
              label: 'Subject',
              icon: Icons.subject,
              isRequired: true,
              settingsState: settingsState,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(
    String text,
    bool isActive,
    VoidCallback onTap,
    SettingsState settingsState,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isActive
                  ? (settingsState.isDarkMode
                      ? AppColors.primaryDark
                      : AppColors.primary)
                  : (settingsState.isDarkMode
                          ? AppColors.surfaceDark
                          : AppColors.surfaceVariant)
                      .withAlpha((255 * 0.1).toInt()),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isActive
                    ? (settingsState.isDarkMode
                        ? AppColors.primaryDark
                        : AppColors.primary)
                    : (settingsState.isDarkMode
                            ? AppColors.surfaceDark
                            : AppColors.surfaceVariant)
                        .withAlpha((255 * 0.2).toInt()),
          ),
        ),
        child: Text(
          isActive ? 'Hide $text' : 'Add $text',
          style: TextStyle(
            color:
                isActive
                    ? (settingsState.isDarkMode
                        ? AppColors.textPrimaryDark
                        : AppColors.surface)
                    : (settingsState.isDarkMode
                            ? AppColors.textSecondaryDark
                            : AppColors.textPrimary)
                        .withAlpha((255 * 0.8).toInt()),
            fontWeight: FontWeight.w500,
            fontSize: settingsState.fontSize - 2,
            fontFamily: settingsState.fontFamily,
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isRequired = false,
    required SettingsState settingsState,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        style: TextStyle(
          fontSize: settingsState.fontSize,
          fontFamily: settingsState.fontFamily,
          color:
              settingsState.isDarkMode
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: settingsState.fontSize,
            fontFamily: settingsState.fontFamily,
            color:
                settingsState.isDarkMode
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  settingsState.isDarkMode
                      ? AppColors.primaryDark.withAlpha((255 * 0.1).toInt())
                      : AppColors.primary.withAlpha((255 * 0.1).toInt()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color:
                  settingsState.isDarkMode
                      ? AppColors.primaryDark
                      : AppColors.primary,
              size: 20,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color:
                  settingsState.isDarkMode
                      ? AppColors.surfaceDark.withAlpha((255 * 0.3).toInt())
                      : AppColors.surfaceVariant.withAlpha((255 * 0.3).toInt()),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color:
                  settingsState.isDarkMode
                      ? AppColors.surfaceDark.withAlpha((255 * 0.3).toInt())
                      : AppColors.surfaceVariant.withAlpha((255 * 0.3).toInt()),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color:
                  settingsState.isDarkMode
                      ? AppColors.primaryDark
                      : AppColors.primary,
              width: 2,
            ),
          ),
          filled: true,
          fillColor:
              settingsState.isDarkMode
                  ? AppColors.surfaceDark.withAlpha((255 * 0.1).toInt())
                  : AppColors.surfaceVariant.withAlpha((255 * 0.1).toInt()),
        ),
        validator: null,
      ),
    );
  }

  Widget _buildAttachmentsCard(SettingsState settingsState) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color:
            settingsState.isDarkMode
                ? AppColors.surfaceDark
                : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                settingsState.isDarkMode
                    ? AppColors.textPrimaryDark.withAlpha((255 * 0.05).toInt())
                    : AppColors.textPrimary.withAlpha((255 * 0.05).toInt()),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        settingsState.isDarkMode
                            ? AppColors.warning.withAlpha((255 * 0.1).toInt())
                            : AppColors.warning.withAlpha((255 * 0.1).toInt()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.attach_file,
                    color:
                        settingsState.isDarkMode
                            ? AppColors.warning
                            : AppColors.warning,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Attachments (${_attachments.length})',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: settingsState.fontSize,
                    fontFamily: settingsState.fontFamily,
                    color:
                        settingsState.isDarkMode
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _attachments.asMap().entries.map((entry) {
                    final index = entry.key;
                    final file = entry.value;
                    return _buildAttachmentChip(file, index, settingsState);
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentChip(
    PlatformFile file,
    int index,
    SettingsState settingsState,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            settingsState.isDarkMode
                ? AppColors.info.withAlpha((255 * 0.1).toInt())
                : AppColors.info.withAlpha((255 * 0.1).toInt()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              settingsState.isDarkMode
                  ? AppColors.info.withAlpha((255 * 0.3).toInt())
                  : AppColors.info.withAlpha((255 * 0.3).toInt()),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getFileIcon(file.extension ?? ''),
            color: settingsState.isDarkMode ? AppColors.info : AppColors.info,
            size: 18,
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              file.name,
              style: TextStyle(
                fontSize: settingsState.fontSize - 2,
                fontFamily: settingsState.fontFamily,
                fontWeight: FontWeight.w500,
                color:
                    settingsState.isDarkMode
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _attachments.removeAt(index)),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color:
                    settingsState.isDarkMode
                        ? AppColors.accent.withAlpha((255 * 0.1).toInt())
                        : AppColors.accent.withAlpha((255 * 0.1).toInt()),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.close,
                color:
                    settingsState.isDarkMode
                        ? AppColors.accent
                        : AppColors.accent,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorCard(SettingsState settingsState) {
    return Container(
      margin: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color:
            settingsState.isDarkMode
                ? AppColors.surfaceDark
                : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                settingsState.isDarkMode
                    ? AppColors.textPrimaryDark.withAlpha((255 * 0.05).toInt())
                    : AppColors.textPrimary.withAlpha((255 * 0.05).toInt()),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color:
                      settingsState.isDarkMode
                          ? AppColors.surfaceDark.withAlpha((255 * 0.2).toInt())
                          : AppColors.surfaceVariant.withAlpha(
                            (255 * 0.2).toInt(),
                          ),
                ),
              ),
            ),
            child: QuillSimpleToolbar(controller: _contentController),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: QuillEditor(
                controller: _contentController,
                scrollController: ScrollController(),
                focusNode: FocusNode(),
                config: QuillEditorConfig(
                  autoFocus: false,
                  expands: true,
                  padding: const EdgeInsets.all(16),
                  placeholder: 'Write your message here...',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(SettingsState settingsState) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            settingsState.isDarkMode
                ? AppColors.primaryDark
                : AppColors.primary,
            settingsState.isDarkMode
                ? AppColors.primaryLight
                : AppColors.primaryLight,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                settingsState.isDarkMode
                    ? AppColors.primaryDark.withAlpha((255 * 0.2).toInt())
                    : AppColors.primaryDark.withAlpha((255 * 0.2).toInt()),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => _sendEmail(false),
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: Icon(
          Icons.send,
          color:
              settingsState.isDarkMode
                  ? AppColors.textPrimaryDark
                  : AppColors.surface,
        ),
        label: Text(
          'Send Email',
          style: TextStyle(
            color:
                settingsState.isDarkMode
                    ? AppColors.textPrimaryDark
                    : AppColors.surface,
            fontWeight: FontWeight.w600,
            fontSize: settingsState.fontSize,
            fontFamily: settingsState.fontFamily,
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

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _slideController.dispose();
    _fadeController.dispose();
    _bounceController.dispose();
    _scrollController.dispose();
    _toController.dispose();
    _ccController.dispose();
    _bccController.dispose();
    _subjectController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
