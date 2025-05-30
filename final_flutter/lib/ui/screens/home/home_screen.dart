import 'package:flutter/material.dart';
import '../email/inbox_screen.dart';
import '../email/sent_screen.dart';
import '../email/draft_screen.dart';
import '../email/trash_screen.dart';
import '../email/starred_screen.dart';
import '../settings/settings_screen.dart';
import '../profile/profile_screen.dart';
import '../search/search_screen.dart';
import '../email/compose_screen.dart';
import 'package:final_flutter/data/mock_email_repository.dart';
import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../email/label_screen.dart';

class HomeScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final void Function(ThemeMode) setThemeMode;
  final Color accentColor;
  final void Function(Color) setAccentColor;
  const HomeScreen({super.key, required this.themeMode, required this.setThemeMode, required this.accentColor, required this.setAccentColor});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final MockEmailRepository _repository = MockEmailRepository();

  String _fontFamily = 'Roboto';
  double _fontSize = 16;
  bool _notificationEnabled = true;

  void setFontFamily(String font) => setState(() => _fontFamily = font);
  void setFontSize(double size) => setState(() => _fontSize = size);
  void setNotificationEnabled(bool v) => setState(() => _notificationEnabled = v);

  late final List<Widget> _screens;
  final List<String> _titles = [
    'Inbox', 'Starred', 'Sent', 'Drafts', 'Trash', 'Search', 'Settings', 'Profile'
  ];

  @override
  void initState() {
    super.initState();
    _screens = [
      InboxScreen(repository: _repository, notificationEnabled: _notificationEnabled, fontFamily: _fontFamily, fontSize: _fontSize),
      StarredScreen(repository: _repository, fontFamily: _fontFamily, fontSize: _fontSize),
      SentScreen(repository: _repository, fontFamily: _fontFamily, fontSize: _fontSize),
      DraftScreen(repository: _repository, fontFamily: _fontFamily, fontSize: _fontSize),
      TrashScreen(repository: _repository, fontFamily: _fontFamily, fontSize: _fontSize),
      SearchScreen(fontFamily: _fontFamily, fontSize: _fontSize),
      SettingsScreen(
        repository: _repository,
        themeMode: widget.themeMode,
        setThemeMode: widget.setThemeMode,
        fontFamily: _fontFamily,
        fontSize: _fontSize,
        setFontFamily: setFontFamily,
        setFontSize: setFontSize,
        notificationEnabled: _notificationEnabled,
        setNotificationEnabled: setNotificationEnabled,
        accentColor: widget.accentColor,
        setAccentColor: widget.setAccentColor,
      ),
      ProfileScreen(fontFamily: _fontFamily, fontSize: _fontSize),
    ];
  }

  void _onDrawerTap(int index) {
    setState(() {
      _selectedIndex = index;
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      InboxScreen(repository: _repository, notificationEnabled: _notificationEnabled, fontFamily: _fontFamily, fontSize: _fontSize),
      StarredScreen(repository: _repository, fontFamily: _fontFamily, fontSize: _fontSize),
      SentScreen(repository: _repository, fontFamily: _fontFamily, fontSize: _fontSize),
      DraftScreen(repository: _repository, fontFamily: _fontFamily, fontSize: _fontSize),
      TrashScreen(repository: _repository, fontFamily: _fontFamily, fontSize: _fontSize),
      SearchScreen(fontFamily: _fontFamily, fontSize: _fontSize),
      SettingsScreen(
        repository: _repository,
        themeMode: widget.themeMode,
        setThemeMode: widget.setThemeMode,
        fontFamily: _fontFamily,
        fontSize: _fontSize,
        setFontFamily: setFontFamily,
        setFontSize: setFontSize,
        notificationEnabled: _notificationEnabled,
        setNotificationEnabled: setNotificationEnabled,
        accentColor: widget.accentColor,
        setAccentColor: widget.setAccentColor,
      ),
      ProfileScreen(fontFamily: _fontFamily, fontSize: _fontSize),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          IconButton(icon: Icon(Icons.search), onPressed: () {
            setState(() => _selectedIndex = 5); // SearchScreen
          }),
          IconButton(icon: Icon(Icons.settings), onPressed: () {
            setState(() => _selectedIndex = 6); // SettingsScreen
          }),
          GestureDetector(
            onTap: () => setState(() => _selectedIndex = 7), // ProfileScreen
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: CircleAvatar(child: Icon(Icons.person)),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(child: Text('Flutter Mail', style: TextStyle(fontSize: 24))),
            ListTile(
              leading: Icon(Icons.inbox),
              title: Text('Inbox'),
              selected: _selectedIndex == 0,
              onTap: () => _onDrawerTap(0),
            ),
            ListTile(
              leading: Icon(Icons.star),
              title: Text('Starred'),
              selected: _selectedIndex == 1,
              onTap: () => _onDrawerTap(1),
            ),
            ListTile(
              leading: Icon(Icons.send),
              title: Text('Sent'),
              selected: _selectedIndex == 2,
              onTap: () => _onDrawerTap(2),
            ),
            ListTile(
              leading: Icon(Icons.drafts),
              title: Text('Drafts'),
              selected: _selectedIndex == 3,
              onTap: () => _onDrawerTap(3),
            ),
            ListTile(
              leading: Icon(Icons.delete),
              title: Text('Trash'),
              selected: _selectedIndex == 4,
              onTap: () => _onDrawerTap(4),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.label),
              title: Text('Labels'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => LabelScreen(repository: _repository),
                ));
              },
            ),
          ],
        ),
      ),
      body: screens[_selectedIndex],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => ComposeScreen(
              repository: _repository,
              fontFamily: _fontFamily,
              fontSize: _fontSize,
            ),
          ));
        },
        icon: Icon(Icons.edit),
        label: Text('Soạn thư'),
      ),
    );
  }
} 