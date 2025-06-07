import 'package:final_flutter/config/app_theme.dart';
import 'package:final_flutter/data/models/email.dart';
import 'package:final_flutter/data/models/email_response_model.dart';
import 'package:final_flutter/data/models/label_model.dart';
import 'package:final_flutter/data/models/user_model.dart';
import 'package:final_flutter/logic/email/email_event.dart';
import 'package:final_flutter/logic/email/email_bloc.dart';
import 'package:final_flutter/logic/email/email_state.dart';
import 'package:final_flutter/presentation/screens/email/compose_screen.dart';
import 'package:final_flutter/presentation/screens/email/detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InboxScreen extends StatefulWidget {
  final UserModel? user;
  final int tabIndex;
  final List<LabelModel>? labels;
  const InboxScreen({
    super.key,
    required this.user,
    required this.tabIndex,
    this.labels,
  });

  @override
  _InboxScreenState createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  bool _showFloatingButton = false;
  String _selectedFilter = 'List';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.offset > 200 && !_showFloatingButton) {
      setState(() => _showFloatingButton = true);
    } else if (_scrollController.offset <= 200 && _showFloatingButton) {
      setState(() => _showFloatingButton = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<EmailBloc, EmailState>(
        listener: (context, state) {
          if (state is EmailError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return CustomScrollView(
            controller: _scrollController,
            slivers: [_buildFilterChips(), _buildEmailList(state)],
          );
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['List', 'Grid'];

    return SliverToBoxAdapter(
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filters.length,
          itemBuilder: (context, index) {
            final filter = filters[index];
            final isSelected = filter == _selectedFilter;

            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilterChip(
                label: Text(
                  filter,
                  style: TextStyle(
                    color:
                        isSelected
                            ? AppColors.textOnPrimary
                            : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surface,
                checkmarkColor: AppColors.textOnPrimary,
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
                onSelected: (selected) {
                  setState(() => _selectedFilter = filter);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmailList(EmailState state) {
    return SliverToBoxAdapter(child: _buildEmailContent(state));
  }

  Widget _buildEmailContent(EmailState state) {
    if (state is EmailLoading) {
      return _buildLoadingState();
    } else if (state is EmailLoaded) {
      if (_selectedFilter == 'Grid') {
        return _buildEmailGridView(state.emails);
      }
      if (_selectedFilter == 'List') {
        return _buildEmailListView(state.emails);
      }
    } else if (state is EmailError) {
      print(state.message);
      return _buildErrorState(state.message);
    }
    return _buildEmptyState();
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 400,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        itemBuilder: (context, index) => _buildShimmerEmailItem(),
      ),
    );
  }

  Widget _buildShimmerEmailItem() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppColors.divider,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 100,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.divider,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailListView(List<EmailResponseModel> emails) {
    print (emails[0].labels);
    if (emails.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: emails.length,
      itemBuilder: (context, index) {
        final email = emails[index];
        return _buildEmailItem(email);
      },
    );
  }

  Widget _buildEmailGridView(List<EmailResponseModel> emails) {
    if (emails.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // Số cột
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 3,
      ),
      itemCount: emails.length,
      itemBuilder: (context, index) {
        final email = emails[index];
        return _buildEmailItem(email);
      },
    );
  }

  Widget _buildEmailItem(EmailResponseModel email) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: email.isRead ? 1 : 3,
        color: email.isRead ? AppColors.surface : AppColors.unreadBackground,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openEmail(email.id!),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildSenderAvatar(email.sender!),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  email.sender!,
                                  style: TextStyle(
                                    fontWeight:
                                        email.isRead
                                            ? FontWeight.w500
                                            : FontWeight.w700,
                                    fontSize: 16,
                                    color: AppColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                _formatTime(email.createdAt!),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email.subject.toString().trim(),
                            style: TextStyle(
                              fontWeight:
                                  email.isRead
                                      ? FontWeight.w400
                                      : FontWeight.w600,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  email.plainTextContent.toString().trim(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (email.attachmentsCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.info.withAlpha((255 * 0.1).toInt()),
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
                              '${email.attachmentsCount}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.info,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        email.starred ? Icons.star : Icons.star_border,
                        color:
                            email.starred
                                ? AppColors.starColor
                                : AppColors.textTertiary,
                        size: 20,
                      ),
                      onPressed: () => _toggleStar(email),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      offset: const Offset(0, 8),
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: Theme.of(context).cardColor,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.transparent,
                        ),
                        child: Icon(
                          Icons.more_vert_rounded,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                      onSelected: (value) {
                        if (value.startsWith('label_')) {
                          final labelId = value.replaceFirst('label_', '');
                          final labelModel = widget.labels!.firstWhere(
                            (l) => l.id == labelId,
                          );
                          _handleEmailAction(email, 'label', labelModel);
                        } else {
                          _handleEmailAction(email, value, null);
                        }
                      },
                      itemBuilder:
                          (context) => [
                            if (widget.labels != null &&
                                widget.labels!.isNotEmpty) ...[
                              PopupMenuItem<String>(
                                value: 'select_label',
                                enabled: false,
                                height: 32,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Text(
                                    'LABELS',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary.withAlpha(
                                        (255 * 0.8).toInt(),
                                      ),
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              ),
                              PopupMenuItem<String>(
                                enabled: false,
                                height: 1,
                                child: Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: AppColors.textSecondary.withAlpha(
                                    (255 * 0.1).toInt(),
                                  ),
                                ),
                              ),
                              ...widget.labels!.map(
                                (label) => PopupMenuItem<String>(
                                  value: 'label_${label.id}',
                                  height: 48,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: _getLabelColor(
                                              label,
                                            ).withAlpha((255 * 0.1).toInt()),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.label_rounded,
                                            size: 14,
                                            color: _getLabelColor(label),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            label.label,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (email.labels.map((l) => l['_id']).contains(label.id))
                                          Icon(
                                            Icons.check_rounded,
                                            color: AppColors.success,
                                            size: 20,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              PopupMenuItem<String>(
                                enabled: false,
                                height: 8,
                                child: Divider(
                                  height: 8,
                                  thickness: 1,
                                  color: AppColors.textSecondary.withAlpha(
                                    (255 * 0.1).toInt(),
                                  ),
                                ),
                              ),
                            ],

                            PopupMenuItem(
                              value: 'mark_read',
                              height: 48,
                              child: _buildActionItem(
                                icon:
                                    email.isRead
                                        ? Icons.mark_email_unread_rounded
                                        : Icons.mark_email_read_rounded,
                                text:
                                    email.isRead
                                        ? 'Mark as unread'
                                        : 'Mark as read',
                                color: AppColors.primary,
                              ),
                            ),

                            PopupMenuItem(
                              value: 'archive',
                              height: 48,
                              child: _buildActionItem(
                                icon: Icons.archive_rounded,
                                text: 'Archive',
                                color: AppColors.textSecondary,
                              ),
                            ),

                            email.isInTrash
                                ? PopupMenuItem(
                                  value: 'restore',
                                  height: 48,
                                  child: _buildActionItem(
                                    icon: Icons.restore_from_trash_rounded,
                                    text: 'Restore',
                                    color: AppColors.accent,
                                  ),
                                )
                                : PopupMenuItem(
                                  value: 'delete',
                                  height: 48,
                                  child: _buildActionItem(
                                    icon: Icons.delete_rounded,
                                    text: 'Delete',
                                    color: AppColors.deleteColor,
                                  ),
                                ),
                          ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withAlpha((255 * 0.1).toInt()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
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

  Widget _buildSenderAvatar(String sender) {
    final initial = sender.isNotEmpty ? sender[0].toUpperCase() : '?';
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.accent,
      AppColors.info,
    ];
    final color = colors[sender.hashCode % colors.length];

    return CircleAvatar(
      radius: 20,
      backgroundColor: color,
      child: Text(
        initial,
        style: const TextStyle(
          color: AppColors.textOnPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              'No emails found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your inbox is empty or no emails match the current filter',
              style: TextStyle(fontSize: 14, color: AppColors.textTertiary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return SizedBox(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(fontSize: 14, color: AppColors.textTertiary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<EmailBloc>().add(LoadEmails(widget.tabIndex));
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  void _openEmail(String emailId) async {
    if (widget.tabIndex == 3) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => BlocProvider.value(
                value: context.read<EmailBloc>(),
                child: ComposeEmailScreen(user: widget.user, emailId: emailId),
              ),
        ),
      );
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => BlocProvider.value(
                value: context.read<EmailBloc>(),
                child: EmailDetailScreen(user: widget.user, id: emailId),
              ),
        ),
      );
    }

    if (mounted) {
      context.read<EmailBloc>().add(LoadEmails(widget.tabIndex));
    }
  }

  void _toggleStar(EmailResponseModel email) {
    context.read<EmailBloc>().add(ToggleStarEmail(email.id!));
  }

  void _handleEmailAction(
    EmailResponseModel email,
    String action,
    LabelModel? label,
  ) {
    switch (action) {
      case 'label':
        context.read<EmailBloc>().add(AddLabelToEmail(email.id!, label!));
        break;
      case 'mark_read':
        if (!email.isRead) {
          context.read<EmailBloc>().add(MarkEmailAsRead(email.id!, false));
        }
        break;
      case 'archive':
        break;
      case 'delete':
        context.read<EmailBloc>().add(DeleteEmail(email.id!));
        break;
      case 'restore':
        context.read<EmailBloc>().add(RestoreEmail(email.id!));
        break;
    }
  }
}