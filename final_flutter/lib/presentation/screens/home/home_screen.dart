import 'package:final_flutter/config/app_theme.dart';
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
import 'package:final_flutter/presentation/screens/home/settings_screen.dart';
import 'package:final_flutter/service/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:final_flutter/logic/auth/auth_bloc.dart';
import 'package:final_flutter/logic/auth/auth_event.dart';
import 'package:final_flutter/presentation/screens/auth/login_screen.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:badges/badges.dart' as badges;
import 'package:final_flutter/logic/settings/settings_bloc.dart';

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
  ];

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
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(
          _appBarTitles[_currentIndex],
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshEmails(),
          ),
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              return badges.Badge(
                showBadge: state.unreadCount > 0,
                badgeContent: Text(
                  '${state.unreadCount}',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
                child: IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () {
                    context.read<NotificationBloc>().add(MarkAllAsRead());
                    _showNotificationList(context);
                  },
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _logout(context);
              } else if (value == 'settings') {
                _navigateToSettings(context);
              } else {
                _navigateToProfile(context);
              }
            },
            itemBuilder: (BuildContext context) {
              return {'Profile', 'Settings', 'Logout'}.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice.toLowerCase(),
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCompose(context),
        child: const Icon(Icons.edit),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.inbox), label: 'Inbox'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Starred'),
          BottomNavigationBarItem(icon: Icon(Icons.send), label: 'Sent'),
          BottomNavigationBarItem(icon: Icon(Icons.drafts), label: 'Drafts'),
          BottomNavigationBarItem(icon: Icon(Icons.delete), label: 'Trash'),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: AppColors.primary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  Text(
                    _user?.email ?? '',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.inbox),
              title: const Text('Inbox'),
              selected: _currentIndex == 0,
              onTap: () {
                setState(() => _currentIndex = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Starred'),
              selected: _currentIndex == 1,
              onTap: () {
                setState(() => _currentIndex = 1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.send),
              title: const Text('Sent'),
              selected: _currentIndex == 2,
              onTap: () {
                setState(() => _currentIndex = 2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.drafts),
              title: const Text('Drafts'),
              selected: _currentIndex == 3,
              onTap: () {
                setState(() => _currentIndex = 3);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Trash'),
              selected: _currentIndex == 4,
              onTap: () {
                setState(() => _currentIndex = 4);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text('Labels'),
            ),
            ListTile(
              leading: const Icon(Icons.label),
              title: const Text('Work'),
              onTap: () {
                // Navigate to label view
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.label),
              title: const Text('Personal'),
              onTap: () {
                // Navigate to label view
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Create new label'),
              onTap: () {
                _createNewLabel(context);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is LoadProfileSuccess) {
            setState(() {
              _user = state.user;
            });
          } else if (state is Unauthenticated) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          }
        },
        builder: (context, state) {
          if (_user == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return BlocListener<EmailBloc, EmailState>(
            listener: (context, emailState) {
              if (emailState is EmailError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${emailState.message}')),
                );
              }
            },
            child: InboxScreen(
              key: Key('inbox-screen-$_currentIndex'),
              user: _user!,
              tabIndex: _currentIndex,
            ),
          );
        },
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<SettingsBloc>(),
          child: const SettingsScreen(),
        ),
      ),
    );
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
                decoration: const InputDecoration(
                  hintText: 'Search by keyword',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  // Implement search functionality
                },
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  // Navigate to advanced search
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
                // Perform search
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
                decoration: const InputDecoration(
                  labelText: 'From',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'To',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  prefixIcon: Icon(Icons.subject),
                ),
              ),
              TextField(
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
                value: false,
                onChanged: (value) {},
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Perform advanced search
                  Navigator.pop(context);
                },
                child: const Text('Search'),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      // Update the corresponding date field
    }
  }

  void _refreshEmails() {
    context.read<EmailBloc>().add(RefreshEmails());
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
                // Save new label
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
}
