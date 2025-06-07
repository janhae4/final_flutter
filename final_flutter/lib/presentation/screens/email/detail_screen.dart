import 'package:final_flutter/config/app_theme.dart';
import 'package:final_flutter/data/models/email.dart';
import 'package:final_flutter/data/models/user_model.dart';
import 'package:final_flutter/logic/email/email_bloc.dart';
import 'package:final_flutter/logic/email/email_event.dart';
import 'package:final_flutter/logic/email/email_state.dart';
import 'package:final_flutter/presentation/screens/email/compose_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:intl/intl.dart';

class EmailDetailScreen extends StatefulWidget {
  final UserModel? user;
  final String id;

  const EmailDetailScreen({super.key, required this.user, required this.id});

  @override
  State<EmailDetailScreen> createState() => _EmailDetailScreenState();
}

class _EmailDetailScreenState extends State<EmailDetailScreen>
    with TickerProviderStateMixin {
  Email? currentEmail;
  QuillController? _quillController;
  late AnimationController _fabAnimationController;
  late AnimationController _headerAnimationController;
  bool _showMetadata = false;
  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    context.read<EmailBloc>().add(LoadEmailDetail(widget.id));
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _headerAnimationController.dispose();
    _quillController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<EmailBloc, EmailState>(
        listener: (context, state) {
          if (state is EmailDetailLoaded) {
            setState(() {
              currentEmail = state.email;
              final document = Document.fromJson(state.email.content);

              _quillController = QuillController(
                document: document,
                selection: const TextSelection.collapsed(offset: 0),
                readOnly: true,
              );
            });

            _markAsRead();
            _headerAnimationController.forward();
          }
        },
        builder: (context, state) {
          if (currentEmail == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildEmailHeader(),
                    _buildEmailContent(),
                    if (_showMetadata) _buildMetadata(),
                    _buildAttachments(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  void _markAsRead() {
    if (!currentEmail!.isRead) {
      setState(() {
        currentEmail = currentEmail?.copyWith(isRead: true);
      });
    }
  }

  void _toggleStar() {
    HapticFeedback.lightImpact();
    context.read<EmailBloc>().add(ToggleStarEmail(currentEmail!.id));

    setState(() {
      currentEmail = currentEmail?.copyWith(starred: !currentEmail!.starred);
    });


    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(currentEmail!.starred ? 'Email starred' : 'Star removed'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _moveToTrash() {
    HapticFeedback.mediumImpact();

    context.read<EmailBloc>().add(DeleteEmail(currentEmail!.id));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Email moved to trash'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            context.read<EmailBloc>().add(RestoreEmail(currentEmail!.id));
          },
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showLabelsDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Manage Labels'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLabelChip('Work', Colors.blue),
                _buildLabelChip('Personal', Colors.green),
                _buildLabelChip('Important', Colors.red),
                _buildLabelChip('Projects', Colors.orange),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ],
          ),
    );
  }

  Widget _buildLabelChip(String label, Color color) {
    final isSelected = currentEmail!.labels.contains(label);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            if (selected) {
              currentEmail!.labels.add(label);
            } else {
              currentEmail!.labels.remove(label);
            }
          });
        },
        selectedColor: color.withOpacity(0.2),
        checkmarkColor: color,
      ),
    );
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
                ComposeEmailScreen(user: widget.user, forward: currentEmail),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          currentEmail!.subject,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        titlePadding: const EdgeInsets.only(left: 72, right: 16, bottom: 16),
      ),
      actions: [
        IconButton(
          icon: Icon(
            currentEmail!.starred ? Icons.star : Icons.star_border,
            color: currentEmail!.starred ? AppColors.starColor : null,
          ),
          onPressed: _toggleStar,
          tooltip: currentEmail!.starred ? 'Remove star' : 'Add star',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'metadata':
                setState(() => _showMetadata = !_showMetadata);
                break;
              case 'labels':
                _showLabelsDialog();
                break;
              case 'trash':
                _moveToTrash();
                break;
            }
          },
          itemBuilder:
              (context) => [
                PopupMenuItem(
                  value: 'metadata',
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline),
                      const SizedBox(width: 12),
                      Text(_showMetadata ? 'Hide details' : 'Show details'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'labels',
                  child: Row(
                    children: [
                      Icon(Icons.label_outline),
                      SizedBox(width: 12),
                      Text('Manage labels'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'trash',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: AppColors.error),
                      SizedBox(width: 12),
                      Text(
                        'Move to trash',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ],
                  ),
                ),
              ],
        ),
      ],
    );
  }

  Widget _buildEmailHeader() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -0.5),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _headerAnimationController,
          curve: Curves.easeOutBack,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.all(16),
        child: Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        currentEmail!.sender.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentEmail!.sender,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'to ${currentEmail!.to.join(', ')}',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      DateFormat('MMM d, h:mm a').format(currentEmail!.time),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                if (currentEmail!.labels.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children:
                        currentEmail!.labels.map((label) {
                          return Chip(
                            label: Text(
                              label,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            backgroundColor:
                                Theme.of(
                                  context,
                                ).colorScheme.secondaryContainer,
                            side: BorderSide.none,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          );
                        }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailContent() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: isDark
            ? Theme.of(context).colorScheme.surfaceContainerLowest
            : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _quillController == null
              ? const SizedBox.shrink()
              : QuillEditor.basic(
                  controller: _quillController!,
                  config: QuillEditorConfig(
                    // Thêm các tham số hợp lệ nếu muốn, ví dụ:
                    // placeholder: 'Write your message...',
                    // padding: EdgeInsets.all(16),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildMetadata() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Email Details',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
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
              _buildMetadataRow('Status', _getStatusText()),
            ],
          ),
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText() {
    List<String> status = [];
    if (currentEmail!.isRead) status.add('Read');
    if (currentEmail!.starred) status.add('Starred');
    if (currentEmail!.isDraft) status.add('Draft');
    if (currentEmail!.isInTrash) status.add('In Trash');
    return status.isEmpty ? 'Normal' : status.join(', ');
  }

  Widget _buildAttachments() {
    if (currentEmail!.attachments.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.attach_file),
                  const SizedBox(width: 8),
                  Text(
                    'Attachments (${currentEmail!.attachments.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...currentEmail!.attachments.map((attachment) {
                return ListTile(
                  leading: const Icon(Icons.insert_drive_file),
                  title: Text(attachment),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.download),
                        onPressed: () {
                          // Download attachment
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Downloading $attachment...'),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.share),
                        onPressed: () {
                          // Share attachment
                        },
                      ),
                    ],
                  ),
                  contentPadding: EdgeInsets.zero,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          heroTag: "forward",
          onPressed: _forwardEmail,
          tooltip: 'Forward',
          child: const Icon(Icons.forward),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          heroTag: "reply",
          onPressed: _replyToEmail,
          tooltip: 'Reply',
          child: const Icon(Icons.reply),
        ),
      ],
    );
  }
}
