import 'package:final_flutter/config/app_theme.dart';
import 'package:final_flutter/data/models/email_response_model.dart';
import 'package:final_flutter/data/models/user_model.dart';
import 'package:final_flutter/logic/email/email_event.dart';
import 'package:final_flutter/logic/email/email_bloc.dart';
import 'package:final_flutter/logic/email/email_state.dart';
import 'package:final_flutter/presentation/screens/email/detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InboxScreen extends StatefulWidget {
  final UserModel? user;
  final int tabIndex;
  const InboxScreen({super.key, required this.user, required this.tabIndex});

  @override
  _InboxScreenState createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showFloatingButton = false;
  String _selectedFilter = 'All';
  // Add this to your InboxScreen's initState method to load emails when the screen starts

  @override
  void initState() {
    super.initState();
    print(widget.tabIndex);
    _scrollController.addListener(_onScroll);
    // Load emails when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmailBloc>().add(LoadEmails(widget.tabIndex));
    });
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
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Unread', 'Starred', 'Important'];

    return SliverToBoxAdapter(
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filters.length,
          itemBuilder: (context, index) {
            final filter = filters[index];
            final isSelected = filter == _selectedFilter;

            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: FilterChip(
                label: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.primary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: Colors.white,
                checkmarkColor: Colors.white,
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      return _buildEmailListView(state.emails);
    } else if (state is EmailError) {
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 18,
                          decoration: BoxDecoration(
                            color: AppColors.divider,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: 120,
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

  Widget _buildEmailItem(EmailResponseModel email) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Card(
        elevation: email.isRead ? 1 : 4,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        shadowColor: AppColors.primary.withOpacity(0.08),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _openEmail(email.id!),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSenderAvatar(email.sender!),
                    const SizedBox(width: 16),
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
                                    fontWeight: email.isRead ? FontWeight.w500 : FontWeight.bold,
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
                              fontWeight: email.isRead ? FontWeight.w400 : FontWeight.w600,
                              fontSize: 15,
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
                const SizedBox(height: 10),
                Text(
                  email.plainTextContent.toString().trim(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    if (email.attachments.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.info.withAlpha((255 * 0.08).toInt()),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.attach_file, size: 16, color: AppColors.info),
                            const SizedBox(width: 4),
                            Text(
                              '${email.attachments.length}',
                              style: const TextStyle(
                                fontSize: 13,
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
                        color: email.starred ? AppColors.starColor : AppColors.textTertiary,
                        size: 22,
                      ),
                      onPressed: () => _toggleStar(email),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        size: 22,
                        color: AppColors.textTertiary,
                      ),
                      padding: EdgeInsets.zero,
                      onSelected: (value) => _handleEmailAction(email, value),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'mark_read',
                          child: Row(
                            children: [
                              Icon(
                                email.isRead ? Icons.mark_email_unread : Icons.mark_email_read,
                                size: 20,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 12),
                              Text(email.isRead ? 'Mark as unread' : 'Mark as read'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'archive',
                          child: Row(
                            children: [
                              Icon(Icons.archive, size: 20, color: AppColors.textSecondary),
                              SizedBox(width: 12),
                              Text('Archive'),
                            ],
                          ),
                        ),
                        email.isInTrash
                            ? PopupMenuItem(
                                value: 'restore',
                                child: Row(
                                  children: [
                                    Icon(Icons.restore_from_trash, size: 20, color: AppColors.accent),
                                    const SizedBox(width: 12),
                                    Text('Restore'),
                                  ],
                                ),
                              )
                            : PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, size: 20, color: AppColors.deleteColor),
                                    SizedBox(width: 12),
                                    Text('Delete'),
                                  ],
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mail_outline, size: 64, color: AppColors.primary.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text(
              'No emails found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your inbox is empty.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            const Text(
              'Something went wrong.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return AnimatedScale(
      scale: _showFloatingButton ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: FloatingActionButton.extended(
        onPressed: () => _composeEmail(),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.textOnPrimary,
        icon: const Icon(Icons.edit),
        label: const Text('Compose'),
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

    if (mounted) {
      context.read<EmailBloc>().add(LoadEmails(widget.tabIndex));
    }
  }

  void _toggleStar(EmailResponseModel email) {
    context.read<EmailBloc>().add(ToggleStarEmail(email.id!));
  }

  void _handleEmailAction(EmailResponseModel email, String action) {
    switch (action) {
      case 'mark_read':
        context.read<EmailBloc>().add(MarkEmailAsRead(email.id!, true));
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

  void _composeEmail() {}
}
