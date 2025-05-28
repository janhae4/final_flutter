import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: const [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text('Email App', style: TextStyle(color: Colors.white)),
          ),
          ListTile(
            leading: Icon(Icons.inbox),
            title: Text('Inbox'),
          ),
          ListTile(
            leading: Icon(Icons.send),
            title: Text('Sent'),
          ),
          ListTile(
            leading: Icon(Icons.delete),
            title: Text('Trash'),
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
          ),
        ],
      ),
    );
  }
}
