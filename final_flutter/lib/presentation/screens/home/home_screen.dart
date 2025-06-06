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
      appBar: AppBar(
        title: Text(_appBarTitles[_currentIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshEmails(context),
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
        onTap: (index) {
          setState(() => _currentIndex = index);
          context.read<EmailBloc>().add(ChangeTab(index));
        },
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
                context.read<EmailBloc>().add(ChangeTab(0));
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Starred'),
              selected: _currentIndex == 1,
              onTap: () {
                setState(() => _currentIndex = 1);
                context.read<EmailBloc>().add(ChangeTab(1));
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.send),
              title: const Text('Sent'),
              selected: _currentIndex == 2,
              onTap: () {
                setState(() => _currentIndex = 2);
                context.read<EmailBloc>().add(ChangeTab(2));
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.drafts),
              title: const Text('Drafts'),
              selected: _currentIndex == 3,
              onTap: () {
                setState(() => _currentIndex = 3);
                context.read<EmailBloc>().add(ChangeTab(3));
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Trash'),
              selected: _currentIndex == 4,
              onTap: () {
                setState(() => _currentIndex = 4);
                context.read<EmailBloc>().add(ChangeTab(4));
                Navigator.pop(context);
              },
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text('Labels'),
            ),
            if (_labels != null)
              ..._labels!.map((label) {
                return ListTile(
                  leading: const Icon(Icons.label),
                  onTap: () {},
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            context.read<EmailBloc>().add(
                              FilterByLabel(label.label),
                            );
                            Navigator.pop(context);
                          },
                          child: Text(label.label),
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _editLabel(context, label);
                          } else if (value == 'delete') {
                            _deleteLabel(context, label.id);
                          }
                        },
                        itemBuilder:
                            (context) => const [
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                      ),
                    ],
                  ),
                );
              })
            else
              Container(),

            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Create new label'),
              onTap: () {
                print('Create new label tapped');
                _createNewLabel(context);
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
            });
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
  context.read<AuthBloc>().add(DeleteLabel(labelId));
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
