import 'package:flutter/material.dart';

class EmailListTile extends StatelessWidget {
  final String sender;
  final String subject;
  final String preview;
  final String time;
  final bool starred;
  final VoidCallback? onTap;
  final VoidCallback? onStarTap;
  final VoidCallback? onDeleteTap;

  const EmailListTile({super.key, 
    required this.sender,
    required this.subject,
    required this.preview,
    required this.time,
    this.starred = false,
    this.onTap,
    this.onStarTap,
    this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(child: Text(sender[0])),
      title: Row(
        children: [
          Expanded(child: Text(sender, style: TextStyle(fontWeight: FontWeight.bold))),
          Text(time, style: TextStyle(fontSize: 12)),
        ],
      ),
      subtitle: Text('$subject - $preview', maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(starred ? Icons.star : Icons.star_border),
            onPressed: onStarTap,
            tooltip: 'Gắn sao',
          ),
          IconButton(
            icon: Icon(Icons.delete_outline),
            onPressed: onDeleteTap,
            tooltip: 'Xóa',
          ),
        ],
      ),
      onTap: onTap,
    );
  }
} 