import 'dart:convert';
import 'dart:io';
// import 'dart:js_interop';

import 'package:final_flutter/config/app_theme.dart';
import 'package:final_flutter/data/models/email.dart';
import 'package:final_flutter/data/models/email_attachment_model.dart';
import 'package:final_flutter/data/models/email_response_model.dart';
import 'package:final_flutter/data/models/label_model.dart';
import 'package:final_flutter/data/models/user_model.dart';
import 'package:final_flutter/logic/email/email_bloc.dart';
import 'package:final_flutter/logic/email/email_event.dart';
import 'package:final_flutter/logic/email/email_state.dart';
import 'package:final_flutter/logic/settings/settings_bloc.dart';
import 'package:final_flutter/logic/settings/settings_state.dart';
import 'package:final_flutter/presentation/screens/email/compose_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart'
    show
        Document,
        QuillController,
        QuillEditor,
        QuillEditorConfig,
        QuillEditorConfigurations;
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:web/web.dart' as html;

class EmailDetailScreen extends StatefulWidget {
  final UserModel? user;
  final List<LabelModel>? labels;
  final String id;

  const EmailDetailScreen({
    super.key,
    required this.user,
    required this.id,
    this.labels,
  });

  @override
  State<EmailDetailScreen> createState() => _EmailDetailScreenState();
}

class _EmailDetailScreenState extends State<EmailDetailScreen>
    with TickerProviderStateMixin {
  Email? currentEmail;
  List<EmailResponseModel>? threadEmail;
  QuillController? _quillController;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _floatingController;
  bool _showMetadata = false;
  final bool _showConversation = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    context.read<EmailBloc>().add(LoadEmailDetail(widget.id));
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
    _floatingController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _floatingController.dispose();
    _quillController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        return Scaffold(
          body: BlocConsumer<EmailBloc, EmailState>(
            listener: _handleBlocState,
            builder: (context, state) {
              if (currentEmail == null) {
                return _buildLoadingScreen(settingsState);
              }
              return _buildEmailContent(settingsState);
            },
          ),
          floatingActionButton: _buildFloatingActions(settingsState),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }

  void _handleBlocState(BuildContext context, EmailState state) {
    if (state is EmailDetailLoaded) {
      setState(() {
        currentEmail = state.emailThread.email;
        threadEmail = state.emailThread.replies;
        final document = Document.fromJson(state.emailThread.email.content);
        _quillController = QuillController(
          document: document,
          selection: const TextSelection.collapsed(offset: 0),
          readOnly: true,
        );
      });
      _markAsRead();
      _slideController.forward();
      _fadeController.forward();
      _floatingController.forward();
    } else if (state is EmailError) {
      _showErrorSnackBar(state.message);
    }
  }

  Widget _buildLoadingScreen(SettingsState settingsState) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            settingsState.isDarkMode
                ? AppColors.primaryDark
                : AppColors.primary,
            settingsState.isDarkMode
                ? AppColors.primaryLight
                : AppColors.primaryDark,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                settingsState.isDarkMode
                    ? AppColors.textPrimaryDark
                    : AppColors.surface,
              ),
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading email...',
              style: TextStyle(
                color:
                    settingsState.isDarkMode
                        ? AppColors.textPrimaryDark
                        : AppColors.surface,
                fontSize: settingsState.fontSize,
                fontWeight: FontWeight.w500,
                fontFamily: settingsState.fontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailContent(SettingsState settingsState) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            settingsState.isDarkMode
                ? AppColors.primaryDark
                : AppColors.primary,
            settingsState.isDarkMode
                ? AppColors.primaryLight
                : AppColors.primaryDark,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildModernHeader(settingsState),
            Expanded(child: _buildScrollableContent(settingsState)),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader(SettingsState settingsState) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -1),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              settingsState.isDarkMode
                  ? AppColors.surfaceDark.withAlpha((0.2 * 255).toInt())
                  : AppColors.surface.withAlpha((0.2 * 255).toInt()),
              settingsState.isDarkMode
                  ? AppColors.surfaceDark.withAlpha((0.1 * 255).toInt())
                  : AppColors.surface.withAlpha((0.1 * 255).toInt()),
            ],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderActions(settingsState),
            const SizedBox(height: 16),
            _buildSubjectTitle(settingsState),
            const SizedBox(height: 8),
            _buildEmailMeta(settingsState),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderActions(SettingsState settingsState) {
    return Row(
      children: [
        _buildBackButton(settingsState),
        const Spacer(),
        _buildStarButton(settingsState),
        const SizedBox(width: 8),
        _buildMoreButton(settingsState),
      ],
    );
  }

  Widget _buildBackButton(SettingsState settingsState) {
    return Container(
      decoration: BoxDecoration(
        color:
            settingsState.isDarkMode
                ? AppColors.surfaceDark.withAlpha((255 * 0.2).toInt())
                : AppColors.surface.withAlpha((255 * 0.2).toInt()),
        borderRadius: BorderRadius.circular(16),
      ),
      child: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(
          Icons.arrow_back_ios_new,
          color:
              settingsState.isDarkMode
                  ? AppColors.textPrimaryDark
                  : AppColors.surface,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildStarButton(SettingsState settingsState) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color:
            currentEmail!.starred
                ? AppColors.warning.withAlpha((255 * 0.3).toInt())
                : settingsState.isDarkMode
                ? AppColors.surfaceDark.withAlpha((255 * 0.2).toInt())
                : AppColors.surface.withAlpha((255 * 0.2).toInt()),
        borderRadius: BorderRadius.circular(16),
      ),
      child: IconButton(
        onPressed: _toggleStar,
        icon: Icon(
          currentEmail!.starred ? Icons.star : Icons.star_border,
          color:
              currentEmail!.starred
                  ? AppColors.warning
                  : settingsState.isDarkMode
                  ? AppColors.textPrimaryDark
                  : AppColors.surface,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildMoreButton(SettingsState settingsState) {
    return Container(
      decoration: BoxDecoration(
        color:
            settingsState.isDarkMode
                ? AppColors.surfaceDark.withAlpha((255 * 0.2).toInt())
                : AppColors.surface.withAlpha((255 * 0.2).toInt()),
        borderRadius: BorderRadius.circular(16),
      ),
      child: PopupMenuButton<String>(
        icon: Icon(
          Icons.more_vert,
          color:
              settingsState.isDarkMode
                  ? AppColors.textPrimaryDark
                  : AppColors.surface,
        ),
        onSelected: _handleMenuAction,
        itemBuilder:
            (context) => [
              _buildPopupMenuItem(
                'metadata',
                _showMetadata ? Icons.visibility_off : Icons.visibility,
                _showMetadata ? 'Hide details' : 'Show details',
                settingsState,
              ),
              _buildPopupMenuItem(
                'labels',
                Icons.label_outline,
                'Manage labels',
                settingsState,
              ),
              const PopupMenuDivider(),
              _buildPopupMenuItem(
                'trash',
                Icons.delete_outline,
                'Move to trash',
                settingsState,
                isDestructive: true,
              ),
            ],
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(
    String value,
    IconData icon,
    String text,
    SettingsState settingsState, {
    bool isDestructive = false,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color:
                isDestructive
                    ? AppColors.accent
                    : settingsState.isDarkMode
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color:
                  isDestructive
                      ? AppColors.accent
                      : settingsState.isDarkMode
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
              fontSize: settingsState.fontSize,
              fontFamily: settingsState.fontFamily,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectTitle(SettingsState settingsState) {
    return FadeTransition(
      opacity: _fadeController,
      child: Text(
        currentEmail!.subject.isEmpty ? 'No Subject' : currentEmail!.subject,
        style: TextStyle(
          color:
              settingsState.isDarkMode
                  ? AppColors.textPrimaryDark
                  : AppColors.surface,
          fontSize: settingsState.fontSize + 10,
          fontWeight: FontWeight.bold,
          fontFamily: settingsState.fontFamily,
          height: 1.2,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildEmailMeta(SettingsState settingsState) {
    return FadeTransition(
      opacity: _fadeController,
      child: Text(
        'From ${currentEmail!.sender} • ${_formatDate(currentEmail!.time)} • ${currentEmail!.attachments.length} attachment${currentEmail!.attachments.length != 1 ? 's' : ''}',
        style: TextStyle(
          color:
              settingsState.isDarkMode
                  ? AppColors.textPrimaryDark.withAlpha((0.8 * 255).toInt())
                  : AppColors.surface.withAlpha((0.8 * 255).toInt()),
          fontSize: settingsState.fontSize,
          fontWeight: FontWeight.w500,
          fontFamily: settingsState.fontFamily,
        ),
      ),
    );
  }

  Widget _buildScrollableContent(SettingsState settingsState) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(32),
        topRight: Radius.circular(32),
      ),
      child: Container(
        color:
            settingsState.isDarkMode
                ? AppColors.backgroundDark
                : AppColors.background,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildSenderCard(settingsState),
                  const SizedBox(height: 20),
                  _buildEmailBodyCard(settingsState),
                  const SizedBox(height: 20),
                  if (_showMetadata) ...[
                    _buildMetadataCard(settingsState),
                    const SizedBox(height: 20),
                  ],
                  if (currentEmail!.attachments.isNotEmpty) ...[
                    _buildAttachmentsCard(settingsState),
                    const SizedBox(height: 20),
                  ],
                  if (threadEmail!.isNotEmpty) ...[
                    _buildConversationCard(settingsState),
                    const SizedBox(height: 20),
                  ],
                  _buildStatusBadges(settingsState),
                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSenderCard(SettingsState settingsState) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _slideController,
          curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
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
                      ? AppColors.textPrimaryDark.withAlpha(
                        (255 * 0.05).toInt(),
                      )
                      : AppColors.textPrimary.withAlpha((255 * 0.05).toInt()),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildSenderAvatar(settingsState),
            const SizedBox(width: 16),
            Expanded(child: _buildSenderInfo(settingsState)),
            _buildQuickActions(settingsState),
          ],
        ),
      ),
    );
  }

  Widget _buildSenderAvatar(SettingsState settingsState) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            settingsState.isDarkMode
                ? AppColors.primaryDark
                : AppColors.primary,
            settingsState.isDarkMode
                ? AppColors.primaryLight
                : AppColors.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                settingsState.isDarkMode
                    ? AppColors.primaryDark.withAlpha((255 * 0.3).toInt())
                    : AppColors.primary.withAlpha((255 * 0.3).toInt()),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          currentEmail!.sender.substring(0, 1).toUpperCase(),
          style: TextStyle(
            color:
                settingsState.isDarkMode
                    ? AppColors.textPrimaryDark
                    : AppColors.surface,
            fontSize: settingsState.fontSize + 6,
            fontWeight: FontWeight.bold,
            fontFamily: settingsState.fontFamily,
          ),
        ),
      ),
    );
  }

  Widget _buildSenderInfo(SettingsState settingsState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          currentEmail!.sender,
          style: TextStyle(
            fontSize: settingsState.fontSize + 2,
            fontWeight: FontWeight.w600,
            color:
                settingsState.isDarkMode
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
            fontFamily: settingsState.fontFamily,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'to ${currentEmail!.to.join(', ')}',
          style: TextStyle(
            fontSize: settingsState.fontSize,
            color:
                settingsState.isDarkMode
                    ? AppColors.textSecondaryDark
                    : AppColors.textPrimary.withAlpha((255 * 0.8).toInt()),
            fontFamily: settingsState.fontFamily,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('MMM d, yyyy at h:mm a').format(currentEmail!.time),
          style: TextStyle(
            fontSize: settingsState.fontSize - 2,
            color:
                settingsState.isDarkMode
                    ? AppColors.textSecondaryDark
                    : AppColors.textPrimary.withAlpha((255 * 0.8).toInt()),
            fontFamily: settingsState.fontFamily,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(SettingsState settingsState) {
    return Column(
      children: [
        _buildActionButton(
          Icons.reply,
          () => _replyToEmail(),
          AppColors.info,
          settingsState,
        ),
        const SizedBox(height: 8),
        _buildActionButton(
          Icons.forward,
          () => _forwardEmail(),
          AppColors.secondary,
          settingsState,
        ),
      ],
    );
  }

  Widget _buildActionButton(
    IconData icon,
    VoidCallback onPressed,
    Color color,
    SettingsState settingsState,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).toInt()),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: color, size: 20),
        iconSize: 20,
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      ),
    );
  }

  Widget _buildEmailBodyCard(SettingsState settingsState) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _slideController,
          curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
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
                      ? AppColors.textPrimaryDark.withAlpha(
                        (255 * 0.05).toInt(),
                      )
                      : AppColors.textPrimary.withAlpha((255 * 0.05).toInt()),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.2,
              child: QuillEditor(
                controller: _quillController!,
                scrollController: ScrollController(),
                focusNode: FocusNode(),
                config: QuillEditorConfig(
                  scrollable: true,
                  autoFocus: false,
                  expands: false,
                  padding: const EdgeInsets.all(16),
                  placeholder: 'No content',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentsCard(SettingsState settingsState) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _slideController,
          curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
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
                      ? AppColors.textPrimaryDark.withAlpha(
                        (255 * 0.05).toInt(),
                      )
                      : AppColors.textPrimary.withAlpha((255 * 0.05).toInt()),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.attach_file,
                  size: 20,
                  color:
                      settingsState.isDarkMode
                          ? AppColors.primaryDark
                          : AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Attachments (${currentEmail!.attachments.length})',
                  style: TextStyle(
                    fontSize: settingsState.fontSize,
                    fontWeight: FontWeight.w600,
                    color:
                        settingsState.isDarkMode
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                    fontFamily: settingsState.fontFamily,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...currentEmail!.attachments.map(
              (attachment) => _buildAttachmentItem(attachment, settingsState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentItem(
    EmailAttachment attachment,
    SettingsState settingsState,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            settingsState.isDarkMode
                ? AppColors.backgroundDark
                : AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              settingsState.isDarkMode
                  ? AppColors.surfaceDark
                  : AppColors.surfaceVariant,
        ),
      ),
      child: Row(
        children: [
          _buildAttachmentIcon(attachment, settingsState),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.name,
                  style: TextStyle(
                    fontSize: settingsState.fontSize,
                    fontWeight: FontWeight.w500,
                    color:
                        settingsState.isDarkMode
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                    fontFamily: settingsState.fontFamily,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getFileType(attachment.name),
                  style: TextStyle(
                    fontSize: settingsState.fontSize - 2,
                    color:
                        settingsState.isDarkMode
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                    fontFamily: settingsState.fontFamily,
                  ),
                ),
              ],
            ),
          ),
          _buildDownloadButton(attachment, settingsState),
        ],
      ),
    );
  }

  Widget _buildAttachmentIcon(
    EmailAttachment attachment,
    SettingsState settingsState,
  ) {
    IconData icon;
    Color color;

    if (attachment.name.toLowerCase().endsWith('.pdf')) {
      icon = Icons.picture_as_pdf;
      color = AppColors.accentDark;
    } else if (attachment.name.toLowerCase().contains(
      RegExp(r'\.(jpg|jpeg|png|gif)$'),
    )) {
      icon = Icons.image;
      color = AppColors.secondary;
    } else if (attachment.name.toLowerCase().contains(
      RegExp(r'\.(doc|docx)$'),
    )) {
      icon = Icons.description;
      color = AppColors.info;
    } else {
      icon = Icons.insert_drive_file;
      color =
          settingsState.isDarkMode
              ? AppColors.textSecondaryDark
              : AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).toInt()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildDownloadButton(
    EmailAttachment attachment,
    SettingsState settingsState,
  ) {
    return IconButton(
      onPressed: () {
        // if (kIsWeb) {
        //   downloadAttachmentWeb(attachment);
        // } else {
        //   downloadAttachment(attachment);
        // }
        downloadAttachment(attachment);
      },
      icon: Icon(
        Icons.download,
        color:
            settingsState.isDarkMode
                ? AppColors.primaryDark
                : AppColors.primary,
        size: 20,
      ),
    );
  }

  Widget _buildConversationCard(SettingsState settingsState) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _slideController,
          curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
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
                      ? AppColors.textPrimaryDark.withAlpha(
                        (255 * 0.05).toInt(),
                      )
                      : AppColors.textPrimary.withAlpha((255 * 0.05).toInt()),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.forum_outlined,
                  size: 20,
                  color:
                      settingsState.isDarkMode
                          ? AppColors.primaryDark
                          : AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Conversation Thread',
                  style: TextStyle(
                    fontSize: settingsState.fontSize,
                    fontWeight: FontWeight.w600,
                    color:
                        settingsState.isDarkMode
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                    fontFamily: settingsState.fontFamily,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildConversationMessage(settingsState),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationMessage(SettingsState settingsState) {
    return Column(
      children:
          threadEmail!.map((email) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    settingsState.isDarkMode
                        ? AppColors.backgroundDark
                        : AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      settingsState.isDarkMode
                          ? AppColors.surfaceDark
                          : AppColors.surfaceVariant,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          settingsState.isDarkMode
                              ? AppColors.primaryDark
                              : AppColors.primary,
                          settingsState.isDarkMode
                              ? AppColors.primaryLight
                              : AppColors.primaryDark,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        email.sender!.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          color:
                              settingsState.isDarkMode
                                  ? AppColors.textPrimaryDark
                                  : AppColors.surface,
                          fontSize: settingsState.fontSize,
                          fontWeight: FontWeight.bold,
                          fontFamily: settingsState.fontFamily,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              email.sender!,
                              style: TextStyle(
                                fontSize: settingsState.fontSize,
                                fontWeight: FontWeight.w600,
                                color:
                                    settingsState.isDarkMode
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimary,
                                fontFamily: settingsState.fontFamily,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat(
                                'MMM d, h:mm a',
                              ).format(email.createdAt!),
                              style: TextStyle(
                                fontSize: settingsState.fontSize - 2,
                                color:
                                    settingsState.isDarkMode
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondary,
                                fontFamily: settingsState.fontFamily,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              email.plainTextContent!.trim().isEmpty
                                  ? 'No content.'
                                  : email.plainTextContent!.trim(),
                              style: TextStyle(
                                fontSize: settingsState.fontSize,
                                color:
                                    settingsState.isDarkMode
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondary,
                                height: 1.5,
                                fontFamily: settingsState.fontFamily,
                              ),
                            ),
                            const SizedBox(width: 8),
                            (email.attachmentsCount) > 0
                                ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.info.withAlpha(
                                      (255 * 0.1).toInt(),
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.attach_file,
                                        size: 14,
                                        color: AppColors.info,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${email.attachmentsCount ?? 0}',
                                        style: TextStyle(
                                          fontSize: settingsState.fontSize - 4,
                                          fontFamily: settingsState.fontFamily,
                                          color: AppColors.info,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                : SizedBox(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildStatusBadges(SettingsState settingsState) {
    final badges = <Widget>[];

    if (currentEmail!.isRead) {
      badges.add(_buildStatusBadge('Read', AppColors.secondary, settingsState));
    }

    if (currentEmail!.starred) {
      badges.add(
        _buildStatusBadge('Starred', const Color(0xFFF59E0B), settingsState),
      );
    }

    if (currentEmail!.isDraft) {
      badges.add(
        _buildStatusBadge('Draft', const Color(0xFF6B7280), settingsState),
      );
    }

    if (currentEmail!.isInTrash) {
      badges.add(
        _buildStatusBadge('In Trash', const Color(0xFFEF4444), settingsState),
      );
    } else {
      badges.add(_buildStatusBadge('Normal', AppColors.info, settingsState));
    }

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _slideController,
          curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic),
        ),
      ),
      child: Wrap(spacing: 8, runSpacing: 8, children: badges),
    );
  }

  Widget _buildStatusBadge(
    String label,
    Color color,
    SettingsState settingsState,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).toInt()),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: settingsState.fontSize - 2,
          fontWeight: FontWeight.w500,
          fontFamily: settingsState.fontFamily,
        ),
      ),
    );
  }

  Widget _buildMetadataCard(SettingsState settingsState) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _slideController,
          curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
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
                      ? AppColors.textPrimaryDark.withAlpha(
                        (255 * 0.05).toInt(),
                      )
                      : AppColors.textPrimary.withAlpha((255 * 0.05).toInt()),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color:
                      settingsState.isDarkMode
                          ? AppColors.primaryDark
                          : AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Email Details',
                  style: TextStyle(
                    fontSize: settingsState.fontSize,
                    fontWeight: FontWeight.w600,
                    color:
                        settingsState.isDarkMode
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                    fontFamily: settingsState.fontFamily,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMetadataRow('From', currentEmail!.sender, settingsState),
            _buildMetadataRow('To', currentEmail!.to.join(', '), settingsState),
            if (currentEmail!.cc.isNotEmpty)
              _buildMetadataRow(
                'CC',
                currentEmail!.cc.join(', '),
                settingsState,
              ),
            if (currentEmail!.bcc.isNotEmpty)
              _buildMetadataRow(
                'BCC',
                currentEmail!.bcc.join(', '),
                settingsState,
              ),
            _buildMetadataRow(
              'Date',
              DateFormat(
                'EEEE, MMMM d, y \'at\' h:mm a',
              ).format(currentEmail!.time),
              settingsState,
            ),
            _buildMetadataRow('Subject', currentEmail!.subject, settingsState),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataRow(
    String label,
    String value,
    SettingsState settingsState,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: settingsState.fontSize,
                fontWeight: FontWeight.w500,
                color:
                    settingsState.isDarkMode
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                fontFamily: settingsState.fontFamily,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                fontSize: settingsState.fontSize,
                color:
                    settingsState.isDarkMode
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                fontFamily: settingsState.fontFamily,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActions(SettingsState settingsState) {
    return ScaleTransition(
      scale: _floatingController,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: "reply",
            onPressed: _replyToEmail,
            backgroundColor: AppColors.info,
            child: Icon(
              Icons.reply,
              color:
                  settingsState.isDarkMode
                      ? AppColors.textPrimaryDark
                      : AppColors.surface,
            ),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: "forward",
            onPressed: _forwardEmail,
            backgroundColor: AppColors.secondary,
            child: Icon(
              Icons.forward,
              color:
                  settingsState.isDarkMode
                      ? AppColors.textPrimaryDark
                      : AppColors.surface,
            ),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "compose",
            onPressed: _composeNewEmail,
            backgroundColor:
                settingsState.isDarkMode
                    ? AppColors.primaryDark
                    : AppColors.primary,
            child: Icon(
              Icons.edit,
              color:
                  settingsState.isDarkMode
                      ? AppColors.textPrimaryDark
                      : AppColors.surface,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return DateFormat('h:mm a').format(date);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(date);
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  String _getFileType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'PDF Document';
      case 'doc':
      case 'docx':
        return 'Word Document';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return 'Image';
      case 'txt':
        return 'Text File';
      case 'zip':
      case 'rar':
        return 'Archive';
      default:
        return 'File';
    }
  }

  void _markAsRead() {
    // if (!currentEmail!.isRead) {
    //   print('Marking email as read: ${currentEmail!.id}, ${currentEmail!.isRead}');
    //   context.read<EmailBloc>().add(MarkEmailAsRead(currentEmail!.id, currentEmail!.isRead));
    // }
  }

  void _toggleStar() {
    context.read<EmailBloc>().add(ToggleStarEmail(currentEmail!.id));
    setState(() {
      currentEmail = currentEmail!.copyWith(starred: !currentEmail!.starred);
    });
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'metadata':
        setState(() {
          _showMetadata = !_showMetadata;
        });
        break;
      case 'labels':
        _showLabelsDialog();
        break;
      case 'trash':
        _moveToTrash();
        break;
    }
  }

  void _replyToEmail() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                ComposeEmailScreen(user: widget.user, replyTo: currentEmail),
      ),
    );
  }

  void _forwardEmail() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                ComposeEmailScreen(user: widget.user!, forward: currentEmail!),
      ),
    );
  }

  void _composeNewEmail() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComposeEmailScreen(user: widget.user!),
      ),
    );
  }

  void _showLabelsDialog() {
    void Function(void Function())? setStateDialog;

    showDialog(
      context: context,
      builder:
          (context) => BlocListener<EmailBloc, EmailState>(
            listener: (context, state) {
              if (state is EmailDetailLoaded) {
                setState(() {
                  currentEmail = state.emailThread.email;
                });
                if (setStateDialog != null) {
                  setStateDialog!(() {});
                }
              }
            },
            child: AlertDialog(
              title: const Text('Manage Labels'),
              content: SizedBox(
                width: 300,
                child: StatefulBuilder(
                  builder: (context, setStateSB) {
                    setStateDialog = setStateSB;

                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: widget.labels!.length,
                      separatorBuilder:
                          (context, index) =>
                              const Divider(height: 1, color: AppColors.border),
                      itemBuilder: (context, index) {
                        final label = widget.labels![index];
                        final isSelected = currentEmail!.labels
                            .map((l) => l['_id'])
                            .contains(label.id);

                        return ListTile(
                          leading: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: _getLabelColor(label).withAlpha(25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.label_rounded,
                              size: 14,
                              color: _getLabelColor(label),
                            ),
                          ),
                          title: Text(
                            label.label,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing:
                              isSelected
                                  ? Icon(
                                    Icons.check_rounded,
                                    color: AppColors.success,
                                    size: 20,
                                  )
                                  : null,
                          onTap: () {
                            context.read<EmailBloc>().add(
                              AddLabelToEmail(currentEmail!.id, label),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
    );
  }

  Color _getLabelColor(LabelModel label) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      AppColors.accent,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];

    return colors[label.id.hashCode % colors.length];
  }

  void _moveToTrash() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Move to Trash'),
            content: const Text(
              'Are you sure you want to move this email to trash?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  context.read<EmailBloc>().add(DeleteEmail(currentEmail!.id));
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close email detail
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.accent),
                child: const Text('Move to Trash'),
              ),
            ],
          ),
    );
  }

  Future<void> downloadAttachment(EmailAttachment attachment) async {
    try {
      final bytes = base64Decode(attachment.bytes!);
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${attachment.name}');
      await file.writeAsBytes(bytes);

      print('File saved to ${file.path}');

      await OpenFile.open(file.path);
    } catch (e) {
      print('Failed to download: $e');
    }
  }

  // void downloadAttachmentWeb(EmailAttachment attachment) {
  //   final bytes = base64Decode(attachment.bytes!);
  //   final blob = html.Blob([bytes] as JSArray<html.BlobPart>);
  //   final url = html.URL.createObjectURL(blob);
  //   final anchor = html.document.createElement('a') as html.HTMLAnchorElement;
  //   anchor.href = url;
  //   anchor.style.display = 'none';
  //   anchor.download = attachment.name;
  //   html.document.body!.append(anchor);
  //   anchor.click();
  //   html.document.body!.removeChild(anchor);
  //   html.URL.revokeObjectURL(url);
  // }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
