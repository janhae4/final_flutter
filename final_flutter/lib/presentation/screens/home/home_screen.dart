import 'package:final_flutter/data/models/user_model.dart';
import 'package:final_flutter/logic/auth/auth_state.dart';
import 'package:final_flutter/presentation/screens/home/inbox_screen.dart';
import 'package:final_flutter/presentation/screens/home/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:final_flutter/logic/auth/auth_bloc.dart';
import 'package:final_flutter/logic/auth/auth_event.dart';
import 'package:final_flutter/presentation/screens/auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  UserModel? _user;
  final List<Widget> _screens = [
    const InboxScreen(),
    // const StarredScreen(),
    // const SentScreen(),
    // const DraftsScreen(),
    // const TrashScreen(),
  ];

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
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    context.read<AuthBloc>().add(LoadProfile());
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
            onPressed: () => _refreshEmails(),
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
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(
                      'https://example.com/profile.jpg',
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'John Doe',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  Text(
                    'john.doe@example.com',
                    style: TextStyle(color: Colors.white),
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
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          } else if (state is Unauthenticated) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          }
        },
        builder: (context, state) {
          return IndexedStack(index: _currentIndex, children: _screens);
        },
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
      MaterialPageRoute(builder: (context) => ProfileScreen(user: _user,)),
    );
  }

  void _navigateToCompose(BuildContext context) {
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (context) => const ComposeScreen()),
    // );
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
    // Implement refresh functionality
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Refreshing emails...')));
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

// // Example screen implementations for different email categories
// class InboxScreen extends StatelessWidget {
//   const InboxScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return ListView.builder(
//       itemCount: 10,
//       itemBuilder: (context, index) {
//         return EmailListItem(
//           isRead: index % 3 == 0,
//           hasAttachment: index % 4 == 0,
//           isStarred: index % 5 == 0,
//           onTap: () => Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => EmailDetailScreen(
//                 emailId: 'email$index',
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

// class StarredScreen extends StatelessWidget {
//   const StarredScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return ListView.builder(
//       itemCount: 5,
//       itemBuilder: (context, index) {
//         return EmailListItem(
//           isRead: true,
//           hasAttachment: index % 2 == 0,
//           isStarred: true,
//           onTap: () => Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => EmailDetailScreen(
//                 emailId: 'starred$index',
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

// class SentScreen extends StatelessWidget {
//   const SentScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return ListView.builder(
//       itemCount: 8,
//       itemBuilder: (context, index) {
//         return EmailListItem(
//           isRead: true,
//           hasAttachment: index % 3 == 0,
//           isStarred: false,
//           onTap: () => Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => EmailDetailScreen(
//                 emailId: 'sent$index',
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

// class DraftsScreen extends StatelessWidget {
//   const DraftsScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return ListView.builder(
//       itemCount: 3,
//       itemBuilder: (context, index) {
//         return ListTile(
//           leading: const Icon(Icons.drafts),
//           title: Text('Draft email ${index + 1}'),
//           subtitle: Text('This is a draft email content preview...'),
//           onTap: () => Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => const ComposeScreen(isDraft: true),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

// class TrashScreen extends StatelessWidget {
//   const TrashScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return ListView.builder(
//       itemCount: 4,
//       itemBuilder: (context, index) {
//         return EmailListItem(
//           isRead: index % 2 == 0,
//           hasAttachment: false,
//           isStarred: false,
//           onTap: () => Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => EmailDetailScreen(
//                 emailId: 'trash$index',
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

// class SettingsScreen extends StatelessWidget {
//   const SettingsScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Settings'),
//       ),
//       body: ListView(
//         children: [
//           const Padding(
//             padding: EdgeInsets.all(16.0),
//             child: Text(
//               'Account Settings',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//           ),
//           ListTile(
//             leading: const Icon(Icons.person),
//             title: const Text('Profile Information'),
//             onTap: () => _navigateToProfile(context),
//           ),
//           ListTile(
//             leading: const Icon(Icons.lock),
//             title: const Text('Change Password'),
//             onTap: () => _navigateToChangePassword(context),
//           ),
//           ListTile(
//             leading: const Icon(Icons.security),
//             title: const Text('Two-Step Verification'),
//             trailing: Switch(
//               value: true,
//               onChanged: (value) {},
//             ),
//           ),
//           const Divider(),
//           const Padding(
//             padding: EdgeInsets.all(16.0),
//             child: Text(
//               'Appearance',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//           ),
//           ListTile(
//             leading: const Icon(Icons.color_lens),
//             title: const Text('Theme'),
//             subtitle: const Text('Dark'),
//             onTap: () => _showThemeDialog(context),
//           ),
//           ListTile(
//             leading: const Icon(Icons.text_fields),
//             title: const Text('Default Font Size'),
//             subtitle: const Text('Medium'),
//             onTap: () => _showFontSizeDialog(context),
//           ),
//           const Divider(),
//           const Padding(
//             padding: EdgeInsets.all(16.0),
//             child: Text(
//               'Email Settings',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//           ),
//           ListTile(
//             leading: const Icon(Icons.notifications),
//             title: const Text('Notifications'),
//             trailing: Switch(
//               value: true,
//               onChanged: (value) {},
//             ),
//           ),
//           ListTile(
//             leading: const Icon(Icons.reply),
//             title: const Text('Auto-Reply'),
//             subtitle: const Text('Off'),
//             onTap: () => _navigateToAutoReply(context),
//           ),
//           ListTile(
//             leading: const Icon(Icons.label),
//             title: const Text('Label Colors'),
//             onTap: () => _navigateToLabelColors(context),
//           ),
//         ],
//       ),
//     );
//   }

//   void _navigateToProfile(BuildContext context) {
//     // Navigate to profile screen
//   }

//   void _navigateToChangePassword(BuildContext context) {
//     // Navigate to change password screen
//   }

//   void _showThemeDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text('Select Theme'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               ListTile(
//                 title: const Text('Light'),
//                 onTap: () {
//                   // Change to light theme
//                   Navigator.pop(context);
//                 },
//               ),
//               ListTile(
//                 title: const Text('Dark'),
//                 onTap: () {
//                   // Change to dark theme
//                   Navigator.pop(context);
//                 },
//               ),
//               ListTile(
//                 title: const Text('System Default'),
//                 onTap: () {
//                   // Use system theme
//                   Navigator.pop(context);
//                 },
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   void _showFontSizeDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text('Select Font Size'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               ListTile(
//                 title: const Text('Small'),
//                 onTap: () {
//                   // Set small font size
//                   Navigator.pop(context);
//                 },
//               ),
//               ListTile(
//                 title: const Text('Medium'),
//                 onTap: () {
//                   // Set medium font size
//                   Navigator.pop(context);
//                 },
//               ),
//               ListTile(
//                 title: const Text('Large'),
//                 onTap: () {
//                   // Set large font size
//                   Navigator.pop(context);
//                 },
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   void _navigateToAutoReply(BuildContext context) {
//     // Navigate to auto-reply settings
//   }

//   void _navigateToLabelColors(BuildContext context) {
//     // Navigate to label colors settings
//   }
// }
