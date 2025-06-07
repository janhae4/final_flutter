import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
            child: Text('Email App', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.onPrimary)),
          ),
          ListTile(
            leading: Icon(Icons.inbox, color: Theme.of(context).iconTheme.color),
            title: Text('Inbox', style: Theme.of(context).textTheme.bodyLarge),
          ),
          ListTile(
            leading: Icon(Icons.send, color: Theme.of(context).iconTheme.color),
            title: Text('Sent', style: Theme.of(context).textTheme.bodyLarge),
          ),
          ListTile(
            leading: Icon(Icons.delete, color: Theme.of(context).iconTheme.color),
            title: Text('Trash', style: Theme.of(context).textTheme.bodyLarge),
          ),
          ListTile(
            leading: Icon(Icons.settings, color: Theme.of(context).iconTheme.color),
            title: Text('Settings', style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}
