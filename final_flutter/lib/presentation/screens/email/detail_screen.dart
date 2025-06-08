import 'dart:convert';
import 'dart:io';
import 'dart:js_interop';

import 'package:final_flutter/config/app_theme.dart';
import 'package:final_flutter/data/models/email.dart';
import 'package:final_flutter/data/models/email_attachment_model.dart';
import 'package:final_flutter/data/models/email_response_model.dart';
import 'package:final_flutter/data/models/label_model.dart';
import 'package:final_flutter/data/models/user_model.dart';
import 'package:final_flutter/logic/email/email_bloc.dart';
import 'package:final_flutter/logic/email/email_event.dart';
import 'package:final_flutter/logic/email/email_state.dart';
import 'package:final_flutter/presentation/screens/email/compose_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:web/web.dart' as html;

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
  bool _showConversation = true;

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
    return Scaffold(
      body: BlocConsumer<EmailBloc, EmailState>(
        listener: _handleBlocState,
        builder: (context, state) {
          if (currentEmail == null) {
            return _buildLoadingScreen();
          }
          return _buildEmailContent();
        },
      ),
      floatingActionButton: _buildFloatingActions(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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

  Widget _buildLoadingScreen() {
    return Container(
      decoration: _buildGradientBackground(),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
            SizedBox(height: 16),
            Text(
              'Loading email...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailContent() {
    return Container(
      decoration: _buildGradientBackground(),
      child: SafeArea(
        child: Column(
          children: [
            _buildModernHeader(),
            Expanded(child: _buildScrollableContent()),
          ],
        ),
      ),
    );
  }

  BoxDecoration _buildGradientBackground() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primary, Color(0xFF764ba2)],
      ),
    );
  }

  Widget _buildModernHeader() {
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
              Colors.white.withAlpha((0.2 * 255).toInt()),
              Colors.white.withAlpha((0.1 * 255).toInt()),
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
            _buildHeaderActions(),
            const SizedBox(height: 16),
            _buildSubjectTitle(),
            const SizedBox(height: 8),
            _buildEmailMeta(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderActions() {
    return Row(
      children: [
        _buildBackButton(),
        const Spacer(),
        _buildStarButton(),
        const SizedBox(width: 8),
        _buildMoreButton(),
      ],
    );
  }

  Widget _buildBackButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((255 * 0.2).toInt()),
        borderRadius: BorderRadius.circular(16),
      ),
      child: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildStarButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color:
            currentEmail!.starred
                ? Colors.amber.withAlpha((255 * 0.3).toInt())
                : Colors.white.withAlpha((255 * 0.2).toInt()),
        borderRadius: BorderRadius.circular(16),
      ),
      child: IconButton(
        onPressed: _toggleStar,
        icon: Icon(
          currentEmail!.starred ? Icons.star : Icons.star_border,
          color: currentEmail!.starred ? Colors.amber : Colors.white,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildMoreButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((255 * 0.2).toInt()),
        borderRadius: BorderRadius.circular(16),
      ),
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: Colors.white),
        onSelected: _handleMenuAction,
        itemBuilder:
            (context) => [
              _buildPopupMenuItem(
                'metadata',
                _showMetadata ? Icons.visibility_off : Icons.visibility,
                _showMetadata ? 'Hide details' : 'Show details',
              ),
              _buildPopupMenuItem(
                'labels',
                Icons.label_outline,
                'Manage labels',
              ),
              const PopupMenuDivider(),
              _buildPopupMenuItem(
                'trash',
                Icons.delete_outline,
                'Move to trash',
                isDestructive: true,
              ),
            ],
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(
    String value,
    IconData icon,
    String text, {
    bool isDestructive = false,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: isDestructive ? Colors.red : null),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(color: isDestructive ? Colors.red : null),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectTitle() {
    return FadeTransition(
      opacity: _fadeController,
      child: Text(
        currentEmail!.subject.isEmpty ? 'No Subject' : currentEmail!.subject,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          height: 1.2,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildEmailMeta() {
    return FadeTransition(
      opacity: _fadeController,
      child: Text(
        'From ${currentEmail!.sender} • ${_formatDate(currentEmail!.time)} • ${currentEmail!.attachments.length} attachment${currentEmail!.attachments.length != 1 ? 's' : ''}',
        style: TextStyle(
          color: Colors.white.withAlpha((0.8 * 255).toInt()),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildScrollableContent() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(32),
        topRight: Radius.circular(32),
      ),
      child: Container(
        color: const Color(0xFFF8FAFC),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildSenderCard(),
                  const SizedBox(height: 20),
                  _buildEmailBodyCard(),
                  const SizedBox(height: 20),
                  if (_showMetadata) ...[
                    _buildMetadataCard(),
                    const SizedBox(height: 20),
                  ],
                  if (currentEmail!.attachments.isNotEmpty) ...[
                    _buildAttachmentsCard(),
                    const SizedBox(height: 20),
                  ],
                  if (threadEmail!.isNotEmpty) ...[
                    _buildConversationCard(),
                    const SizedBox(height: 20),
                  ],
                  _buildStatusBadges(),
                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSenderCard() {
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((255 * 0.05).toInt()),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildSenderAvatar(),
            const SizedBox(width: 16),
            Expanded(child: _buildSenderInfo()),
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildSenderAvatar() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF764ba2)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha((255 * 0.3).toInt()),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          currentEmail!.sender.substring(0, 1).toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSenderInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          currentEmail!.sender,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'to ${currentEmail!.to.join(', ')}',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('MMM d, yyyy at h:mm a').format(currentEmail!.time),
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        _buildActionButton(
          Icons.reply,
          () => _replyToEmail(),
          const Color(0xFF3B82F6),
        ),
        const SizedBox(height: 8),
        _buildActionButton(
          Icons.forward,
          () => _forwardEmail(),
          const Color(0xFF10B981),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    IconData icon,
    VoidCallback onPressed,
    Color color,
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

  Widget _buildEmailBodyCard() {
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((255 * 0.05).toInt()),
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
                const Icon(
                  Icons.email_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Message',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_quillController != null)
              QuillEditor.basic(
                configurations: QuillEditorConfigurations(
                  controller: _quillController!,
                ),
              )
            else
              const Text(
                'This email appears to be empty or contains only formatting.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentsCard() {
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((255 * 0.05).toInt()),
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
                const Icon(
                  Icons.attach_file,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Attachments (${currentEmail!.attachments.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...currentEmail!.attachments
                .map((attachment) => _buildAttachmentItem(attachment))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentItem(EmailAttachment attachment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          _buildAttachmentIcon(attachment),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getFileType(attachment.name),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          _buildDownloadButton(attachment),
        ],
      ),
    );
  }

  Widget _buildAttachmentIcon(EmailAttachment attachment) {
    IconData icon;
    Color color;

    if (attachment.name.toLowerCase().endsWith('.pdf')) {
      icon = Icons.picture_as_pdf;
      color = const Color(0xFFEF4444);
    } else if (attachment.name.toLowerCase().contains(
      RegExp(r'\.(jpg|jpeg|png|gif)$'),
    )) {
      icon = Icons.image;
      color = const Color(0xFF10B981);
    } else if (attachment.name.toLowerCase().contains(
      RegExp(r'\.(doc|docx)$'),
    )) {
      icon = Icons.description;
      color = const Color(0xFF3B82F6);
    } else {
      icon = Icons.insert_drive_file;
      color = const Color(0xFF6B7280);
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).toInt()),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildDownloadButton(EmailAttachment attachment) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (kIsWeb) {
              downloadAttachmentWeb(attachment);
            } else {
              downloadAttachment(attachment);
            }
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.download, color: Colors.white, size: 16),
                SizedBox(width: 4),
                Text(
                  'Download',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConversationCard() {
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((255 * 0.05).toInt()),
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
                const Icon(
                  Icons.forum_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Conversation Thread',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildConversationMessage(),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationMessage() {
    return Column(
      children:
          threadEmail!.map((email) {
            print('Processing email: ${email.id}');
            print('Sender: ${email.sender}');
            print(email.createdAt);
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          email.sender!.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                email.sender!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF374151),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat(
                                  'MMM d, h:mm a',
                                ).format(email.createdAt!),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            email.plainTextContent!.trim().isEmpty
                                ? 'This message contains formatted content or attachments.'
                                : email.plainTextContent!.trim(),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF4B5563),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildStatusBadges() {
    final badges = <Widget>[];

    if (currentEmail!.isRead) {
      badges.add(_buildStatusBadge('Read', const Color(0xFF10B981)));
    }

    if (currentEmail!.starred) {
      badges.add(_buildStatusBadge('Starred', const Color(0xFFF59E0B)));
    }

    if (currentEmail!.isDraft) {
      badges.add(_buildStatusBadge('Draft', const Color(0xFF6B7280)));
    }

    if (currentEmail!.isInTrash) {
      badges.add(_buildStatusBadge('In Trash', const Color(0xFFEF4444)));
    } else {
      badges.add(_buildStatusBadge('Normal', const Color(0xFF3B82F6)));
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

  Widget _buildStatusBadge(String label, Color color) {
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
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMetadataCard() {
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((255 * 0.05).toInt()),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Email Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMetadataRow('From', currentEmail!.sender),
            _buildMetadataRow('To', currentEmail!.to.join(', ')),
            if (currentEmail!.cc.isNotEmpty)
              _buildMetadataRow('CC', currentEmail!.cc.join(', ')),
            if (currentEmail!.bcc.isNotEmpty)
              _buildMetadataRow('BCC', currentEmail!.bcc.join(', ')),
            _buildMetadataRow(
              'Date',
              DateFormat(
                'EEEE, MMMM d, y \'at\' h:mm a',
              ).format(currentEmail!.time),
            ),
            _buildMetadataRow('Subject', currentEmail!.subject),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActions() {
    return ScaleTransition(
      scale: _floatingController,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: "reply",
            onPressed: _replyToEmail,
            backgroundColor: const Color(0xFF3B82F6),
            child: const Icon(Icons.reply, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: "forward",
            onPressed: _forwardEmail,
            backgroundColor: const Color(0xFF10B981),
            child: const Icon(Icons.forward, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "compose",
            onPressed: _composeNewEmail,
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.edit, color: Colors.white),
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
                // Email được cập nhật → gọi setState của dialog để redraw lại
                setState(() {
                  currentEmail = state.emailThread.email;
                });
                if (setStateDialog != null) {
                  setStateDialog!(() {}); // rebuild dialog
                }
              }
            },
            child: AlertDialog(
              title: const Text('Manage Labels'),
              content: SizedBox(
                width: 300,
                child: StatefulBuilder(
                  builder: (context, setStateSB) {
                    setStateDialog =
                        setStateSB; // giữ lại để dùng trong BlocListener

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
      Colors.red,
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
                style: TextButton.styleFrom(foregroundColor: Colors.red),
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

  void downloadAttachmentWeb(EmailAttachment attachment) {
    final bytes = base64Decode(attachment.bytes!);
    final blob = html.Blob([bytes] as JSArray<html.BlobPart>);
    final url = html.URL.createObjectURL(blob);
    final anchor = html.document.createElement('a') as html.HTMLAnchorElement;
    anchor.href = url;
    anchor.style.display = 'none';
    anchor.download = attachment.name;
    html.document.body!.append(anchor);
    anchor.click();
    html.document.body!.removeChild(anchor);
    html.URL.revokeObjectURL(url);
  }

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
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
