import 'package:final_flutter/config/app_theme.dart';
import 'package:final_flutter/data/models/label_model.dart';
import 'package:final_flutter/data/models/notification_model.dart';
import 'package:final_flutter/data/models/user_model.dart';
import 'package:final_flutter/logic/auth/auth_state.dart';
import 'package:final_flutter/logic/email/email_bloc.dart';
import 'package:final_flutter/logic/email/email_event.dart';
import 'package:final_flutter/logic/email/email_state.dart';
import 'package:final_flutter/logic/notification/notfication_state.dart';
import 'package:final_flutter/logic/notification/notification_bloc.dart';
import 'package:final_flutter/logic/notification/notification_event.dart';
import 'package:final_flutter/presentation/screens/email/compose_screen.dart';
import 'package:final_flutter/presentation/screens/email/inbox_screen.dart';
import 'package:final_flutter/presentation/screens/home/profile_screen.dart';
import 'package:final_flutter/service/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:final_flutter/logic/auth/auth_bloc.dart';
import 'package:final_flutter/logic/auth/auth_event.dart';
import 'package:final_flutter/presentation/screens/auth/login_screen.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:badges/badges.dart' as badges;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  UserModel? _user;

  final List<String> _appBarTitles = [
    'Inbox',
    'Starred',
    'Sent',
    'Drafts',
    'Trash',
    'Spam',
  ];

  List<LabelModel>? _labels;

  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _subjectController = TextEditingController();
  final _keywordController = TextEditingController();
  final _fromDateController = TextEditingController();
  final _toDateController = TextEditingController();
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _hasAttachments = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadProfile();
    _connectSocket();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      NotificationService().resetBadgeCount();
    }
  }

  Future<void> _loadProfile() async {
    context.read<AuthBloc>().add(LoadProfile());
  }

  Future<void> _connectSocket() async {
    context.read<EmailBloc>().add(EmailConnectSocket());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _buildAppBar(context),
      floatingActionButton: _buildFAB(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomNav(context),
      drawer: _buildDrawer(context),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is LoadProfileSuccess) {
            setState(() {
              _user = state.user;
              _labels = _user?.labels ?? [];
            });
          } else if (state is Unauthenticated) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          }
          if (state is LoadLabelsSuccess) {
            setState(() {
              _user = _user?.copyWith(labels: state.labels);
              _labels = state.labels;
            });
          }
        },
        builder: (context, state) {
          if (_user == null) {
            return _buildLoadingState();
          }
          return BlocListener<EmailBloc, EmailState>(
            listener: (context, emailState) {
              if (emailState is EmailError) {
                _showSnackBar(context, emailState.message, isError: true);
              }
            },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.1, 0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOut,
                      ),
                    ),
                    child: child,
                  ),
                );
              },
              child: InboxScreen(
                key: Key('inbox-screen-$_currentIndex'),
                user: _user!,
                tabIndex: _currentIndex,
                labels: _labels ?? [],
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 2,
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      surfaceTintColor: AppColors.surfaceVariant,
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Text(
          _appBarTitles[_currentIndex],
          key: ValueKey(_currentIndex),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
      ),
      actions: [
        _buildAppBarAction(
          icon: Icons.search_rounded,
          onPressed: () => _showSearchDialog(context),
          tooltip: 'Search emails',
        ),
        _buildAppBarAction(
          icon: Icons.refresh_rounded,
          onPressed: () => _refreshEmails(context),
          tooltip: 'Refresh',
        ),
        _buildNotificationButton(context),
        _buildPopupMenu(context),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildAppBarAction({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: IconButton.filled(
        style: IconButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(icon, size: 22),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }

  Widget _buildNotificationButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          return badges.Badge(
            showBadge: state.unreadCount > 0,
            badgeContent: Text(
              '${state.unreadCount}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            badgeStyle: badges.BadgeStyle(
              badgeColor: AppColors.error,
              elevation: 0,
              padding: const EdgeInsets.all(6),
            ),
            badgeAnimation: const badges.BadgeAnimation.slide(
              animationDuration: Duration(milliseconds: 300),
            ),
            child: IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.notifications_rounded, size: 22),
              onPressed: () {
                context.read<NotificationBloc>().add(MarkAllAsRead());
                _showNotificationList(context);
              },
              tooltip: 'Notifications',
            ),
          );
        },
      ),
    );
  }

  Widget _buildPopupMenu(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: PopupMenuButton<String>(
        style: IconButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.more_vert_rounded, size: 22),
        tooltip: 'More options',
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        shadowColor: Theme.of(
          context,
        ).shadowColor.withAlpha((255 * 0.2).toInt()),
        offset: const Offset(0, 8),
        onSelected: (value) {
          switch (value) {
            case 'profile':
              _navigateToProfile(context);
              break;
            case 'settings':
              _navigateToSettings(context);
              break;
            case 'logout':
              _logout(context);
              break;
          }
        },
        itemBuilder: (BuildContext context) {
          return [
            _buildPopupMenuItem(Icons.person_rounded, 'Profile', 'profile'),
            _buildPopupMenuItem(Icons.settings_rounded, 'Settings', 'settings'),
            const PopupMenuDivider(),
            _buildPopupMenuItem(
              Icons.logout_rounded,
              'Logout',
              'logout',
              isDestructive: true,
            ),
          ];
        },
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(
    IconData icon,
    String title,
    String value, {
    bool isDestructive = false,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: isDestructive ? AppColors.error : null),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              color: isDestructive ? AppColors.error : null,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _navigateToCompose(context),
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.surface,
      elevation: 8,
      extendedPadding: const EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: const Icon(Icons.edit_rounded, size: 20),
      label: const Text(
        'Compose',
        style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withAlpha((255 * 0.1).toInt()),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          context.read<EmailBloc>().add(ChangeTab(index));
        },
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: AppColors.primary,
        indicatorColor: AppColors.primary.withAlpha((255 * 0.1).toInt()),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          _buildNavDestination(
            Icons.inbox_rounded,
            Icons.inbox_outlined,
            'Inbox',
          ),
          _buildNavDestination(
            Icons.star_rounded,
            Icons.star_outline_rounded,
            'Starred',
          ),
          _buildNavDestination(Icons.send_rounded, Icons.send_outlined, 'Sent'),
          _buildNavDestination(
            Icons.drafts_rounded,
            Icons.drafts_outlined,
            'Drafts',
          ),
          _buildNavDestination(
            Icons.delete_rounded,
            Icons.delete_outline_rounded,
            'Trash',
          ),
        ],
      ),
    );
  }

  NavigationDestination _buildNavDestination(
    IconData selectedIcon,
    IconData unselectedIcon,
    String label,
  ) {
    return NavigationDestination(
      selectedIcon: Icon(selectedIcon, size: 24),
      icon: Icon(unselectedIcon, size: 24),
      label: label,
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      elevation: 16,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildDrawerHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _buildDrawerSection('FOLDERS', [
                  _buildDrawerItem(Icons.inbox_rounded, 'Inbox', 0),
                  _buildDrawerItem(Icons.star_rounded, 'Starred', 1),
                  _buildDrawerItem(Icons.send_rounded, 'Sent', 2),
                  _buildDrawerItem(Icons.drafts_rounded, 'Drafts', 3),
                  _buildDrawerItem(Icons.delete_rounded, 'Trash', 4),
                  _buildDrawerItem(Icons.report_gmailerrorred_rounded, 'Spam', 5),
                ]),
                const Divider(height: 1, color: AppColors.surfaceVariant),
                _buildDrawerSection('LABELS', [
                  if (_labels != null)
                    ..._labels!.map((label) => _buildLabelItem(context, label)),
                  _buildCreateLabelItem(context),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      constraints: const BoxConstraints(
        minHeight: 150,
        minWidth: double.infinity,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark.withAlpha((255 * 0.8).toInt()),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: NetworkImage(
              'http://localhost:3000/${_user?.avatarUrl}',
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _user?.name ?? '',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          Text(_user?.email ?? '', style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildDrawerSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.surface.withAlpha((255 * 0.6).toInt()),
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    final isSelected = _currentIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        selected: isSelected,
        selectedTileColor: Theme.of(
          context,
        ).colorScheme.primary.withAlpha((255 * 0.08).toInt()),
        selectedColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(icon, size: 22),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        onTap: () {
          setState(() => _currentIndex = index);
          context.read<EmailBloc>().add(ChangeTab(index));
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildLabelItem(BuildContext context, label) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
        title: Text(
          label.label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(
            Icons.more_horiz_rounded,
            size: 18,
            color: AppColors.surface.withAlpha((255 * 0.6).toInt()),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (value) {
            if (value == 'edit') {
              _editLabel(context, label);
            } else if (value == 'delete') {
              _deleteLabel(context, label.id);
            }
          },
          itemBuilder:
              (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: const [
                      Icon(Icons.edit_rounded, size: 18),
                      SizedBox(width: 12),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_rounded,
                        size: 18,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 12),
                      Text('Delete', style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
        ),
        onTap: () {
          context.read<EmailBloc>().add(FilterByLabel(label.id));
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildCreateLabelItem(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha((255 * 0.1).toInt()),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.add_rounded, size: 18, color: AppColors.primary),
        ),
        title: Text(
          'Create new label',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
          ),
        ),
        onTap: () => _createNewLabel(context),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha((255 * 0.1).toInt()),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading your emails...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.surface.withAlpha((255 * 0.7).toInt()),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_rounded : Icons.check_circle_rounded,
              color: Colors.white,
              size: 20,
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
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        elevation: 8,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showNotificationList(BuildContext rootContext) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            // Mark all as read
                          },
                          child: const Text(
                            'Mark all as read',
                            style: TextStyle(color: Colors.blue, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Notifications list
                  Expanded(
                    child: BlocBuilder<NotificationBloc, NotificationState>(
                      bloc: BlocProvider.of<NotificationBloc>(rootContext),
                      builder: (context, state) {
                        if (state.notifications.isEmpty) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.notifications_none,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No notifications',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          controller: scrollController,
                          itemCount: state.notifications.length,
                          itemBuilder: (context, index) {
                            final notification = state.notifications[index];
                            return _buildNotificationItem(
                              context,
                              notification,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationItem(
    BuildContext rootContext,
    NotificationItem notification,
  ) {
    return Container(
      color:
          notification.isRead
              ? Colors.transparent
              : AppColors.primary.withAlpha((255 * 0.1).toInt()),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.primaryLight.withAlpha(
            (255 * 0.9).toInt(),
          ),
          child: Text(
            notification.sender[0].toUpperCase(),
            style: TextStyle(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                notification.sender,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                      notification.isRead ? FontWeight.normal : FontWeight.w600,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              timeago.format(notification.time),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            notification.subject,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing:
            !notification.isRead
                ? Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                )
                : null,
      ),
    );
  }

  void _logout(BuildContext context) {
    context.read<AuthBloc>().add(LogoutRequested());
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _navigateToSettings(BuildContext context) {
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (context) => const SettingsScreen()),
    // );
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfileScreen(user: _user)),
    );
  }

  void _navigateToCompose(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ComposeEmailScreen(user: _user)),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Search Emails'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _keywordController,
                decoration: const InputDecoration(
                  hintText: 'Search by keyword',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showAdvancedSearch(context);
                },
                child: const Text('Advanced Search'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                context.read<EmailBloc>().add(
                  SearchEmail(query: _keywordController.text),
                );
                Navigator.pop(context);
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }

  void _showAdvancedSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        bool hasAttachments = _hasAttachments;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Advanced Search',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _fromController,
                    decoration: const InputDecoration(
                      labelText: 'From',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  TextField(
                    controller: _toController,
                    decoration: const InputDecoration(
                      labelText: 'To',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  TextField(
                    controller: _subjectController,
                    decoration: const InputDecoration(
                      labelText: 'Subject',
                      prefixIcon: Icon(Icons.subject),
                    ),
                  ),
                  TextField(
                    controller: _keywordController,
                    decoration: const InputDecoration(
                      labelText: 'Keywords',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _fromDateController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'From Date',
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          onTap: () => _selectDate(context, true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _toDateController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'To Date',
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          onTap: () => _selectDate(context, false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  CheckboxListTile(
                    title: const Text('Has attachments'),
                    value: hasAttachments,
                    onChanged: (value) {
                      setModalState(() => hasAttachments = value ?? false);
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _hasAttachments = hasAttachments);
                      context.read<EmailBloc>().add(
                        SearchEmail(
                          from: _fromController.text,
                          to: _toController.text,
                          subject: _subjectController.text,
                          keyword: _keywordController.text,
                          fromDate: _fromDate,
                          toDate: _toDate,
                          hasAttachments: hasAttachments,
                        ),
                      );
                      Navigator.pop(context);
                    },
                    child: const Text('Search'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final now = DateTime.now();
    final initialDate = isFromDate ? _fromDate ?? now : _toDate ?? now;
    final firstDate = DateTime(2000);
    final lastDate = DateTime(now.year + 1);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
          _fromDateController.text = DateFormat('yyyy-MM-dd').format(picked);
        } else {
          _toDate = picked;
          _toDateController.text = DateFormat('yyyy-MM-dd').format(picked);
        }
      });
    }
  }
}

void _refreshEmails(BuildContext context) {
  context.read<EmailBloc>().add(RefreshEmails());
}

void _editLabel(BuildContext context, LabelModel label) async {
  final controller = TextEditingController(text: label.label);

  await showDialog(
    context: context,
    builder:
        (_) => AlertDialog(
          title: const Text('Edit Label'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'Label'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<AuthBloc>().add(
                  UpdateLabel(label.id, controller.text),
                );
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
  );
}

void _deleteLabel(BuildContext context, String labelId) {
  context.read<AuthBloc>().add(RemoveLabel(labelId));
}

void _createNewLabel(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      String newLabel = '';
      return AlertDialog(
        title: const Text('Create New Label'),
        content: TextField(
          onChanged: (value) => newLabel = value,
          decoration: const InputDecoration(hintText: 'Enter label name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<AuthBloc>().add(AddLabel(newLabel));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Label "$newLabel" created')),
              );
            },
            child: const Text('Create'),
          ),
        ],
      );
    },
  );
}
