import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final emails = List.generate(10, (index) => {
      'from': 'user$index@example.com',
      'subject': 'Subject $index',
      'body': 'Preview content of email $index...',
    });

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search emails...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: emails.length,
            itemBuilder: (context, index) {
              final email = emails[index];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.email)),
                title: Text(email['subject']!),
                subtitle: Text('${email['from']} • ${email['body']}'),
                onTap: () {
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
