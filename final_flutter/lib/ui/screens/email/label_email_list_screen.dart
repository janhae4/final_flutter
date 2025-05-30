import 'package:flutter/material.dart';
import 'package:final_flutter/data/mock_email_repository.dart';
import 'package:final_flutter/models/email.dart';
import 'package:final_flutter/ui/screens/email/detail_screen.dart';

class LabelEmailListScreen extends StatefulWidget {
  final String label;
  final MockEmailRepository repository;
  const LabelEmailListScreen({super.key, required this.label, required this.repository});

  @override
  State<LabelEmailListScreen> createState() => _LabelEmailListScreenState();
}

class _LabelEmailListScreenState extends State<LabelEmailListScreen> {
  bool _isGrid = false;
  late List<Email> _emails;

  @override
  void initState() {
    super.initState();
    _emails = _getEmailsByLabel();
  }

  List<Email> _getEmailsByLabel() {
    return [
      ...widget.repository.inbox,
      ...widget.repository.sent,
      ...widget.repository.drafts,
      ...widget.repository.trash,
    ].where((e) => e.labels.contains(widget.label)).toList();
  }

  @override
  Widget build(BuildContext context) {
    _emails = _getEmailsByLabel();
    return Scaffold(
      appBar: AppBar(
        title: Text('Nhãn: ${widget.label}'),
        actions: [
          IconButton(
            icon: Icon(_isGrid ? Icons.view_list : Icons.grid_view),
            tooltip: _isGrid ? 'Chuyển sang danh sách' : 'Chuyển sang lưới',
            onPressed: () => setState(() => _isGrid = !_isGrid),
          ),
        ],
      ),
      body: _emails.isEmpty
          ? Center(child: Text('Không có email với nhãn này.'))
          : AnimatedSwitcher(
              duration: Duration(milliseconds: 400),
              child: _isGrid
                  ? GridView.builder(
                      key: ValueKey('grid'),
                      padding: EdgeInsets.all(8),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 2.8),
                      itemCount: _emails.length,
                      itemBuilder: (context, index) {
                        final email = _emails[index];
                        return Card(
                          margin: EdgeInsets.all(8),
                          child: ListTile(
                            leading: CircleAvatar(child: Text(email.sender[0])),
                            title: Text(email.subject, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(email.sender),
                            onTap: () {
                              if (!email.isRead) {
                                setState(() {
                                  widget.repository.markRead(email, true);
                                  widget.repository.notifyListeners();
                                });
                              }
                              Navigator.of(context).push(PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) => DetailScreen(email: email, repository: widget.repository),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  final tween = Tween(begin: 0.9, end: 1.0);
                                  return ScaleTransition(
                                    scale: animation.drive(tween),
                                    child: child,
                                  );
                                },
                              ));
                            },
                          ),
                        );
                      },
                    )
                  : ListView.separated(
                      key: ValueKey('list'),
                      itemCount: _emails.length,
                      separatorBuilder: (_, __) => Divider(height: 1),
                      itemBuilder: (context, index) {
                        final email = _emails[index];
                        return ListTile(
                          leading: CircleAvatar(child: Text(email.sender[0])),
                          title: Row(
                            children: [
                              Expanded(child: Text(email.sender, style: TextStyle(fontWeight: FontWeight.bold))),
                              Text(_formatTime(email.time), style: TextStyle(fontSize: 12)),
                            ],
                          ),
                          subtitle: Text('${email.subject} - ${email.content}', maxLines: 1, overflow: TextOverflow.ellipsis),
                          onTap: () {
                            if (!email.isRead) {
                              setState(() {
                                widget.repository.markRead(email, true);
                                widget.repository.notifyListeners();
                              });
                            }
                            Navigator.of(context).push(PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) => DetailScreen(email: email, repository: widget.repository),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                final tween = Tween(begin: Offset(1, 0), end: Offset.zero);
                                return SlideTransition(
                                  position: animation.drive(tween),
                                  child: child,
                                );
                              },
                            ));
                          },
                        );
                      },
                    ),
            ),
    );
  }

  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }
} 