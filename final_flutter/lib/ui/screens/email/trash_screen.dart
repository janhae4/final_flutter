import 'package:flutter/material.dart';
import 'package:final_flutter/ui/widgets/email_list_tile.dart';
import 'package:final_flutter/data/mock_email_repository.dart';
import 'package:final_flutter/models/email.dart';
import 'package:final_flutter/ui/screens/email/detail_screen.dart';
import 'package:intl/intl.dart';

class TrashScreen extends StatefulWidget {
  final MockEmailRepository repository;
  final String fontFamily;
  final double fontSize;
  const TrashScreen({super.key, required this.repository, this.fontFamily = 'Roboto', this.fontSize = 16});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  // Pagination
  final int _pageSize = 20;
  int _currentMax = 20;
  late ScrollController _scrollController;
  bool _isGrid = false;

  @override
  void initState() {
    super.initState();
    widget.repository.addListener(_onRepositoryChanged);
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.repository.removeListener(_onRepositoryChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onRepositoryChanged() {
    setState(() {});
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
      final total = widget.repository.trash.length;
      if (_currentMax < total) {
        setState(() {
          _currentMax = (_currentMax + _pageSize).clamp(0, total);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final emails = widget.repository.trash.take(_currentMax).toList()
      ..sort((a, b) => b.time.compareTo(a.time));
    final grouped = <String, List<Email>>{};
    final now = DateTime.now();
    for (final e in emails) {
      String key;
      if (e.time.year == now.year && e.time.month == now.month && e.time.day == now.day) {
        key = 'Hôm nay';
      } else if (e.time.year == now.year && e.time.month == now.month && e.time.day == now.day - 1) {
        key = 'Hôm qua';
      } else {
        key = DateFormat('dd/MM/yyyy').format(e.time);
      }
      grouped.putIfAbsent(key, () => []).add(e);
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Trash'),
        actions: [
          IconButton(
            icon: Icon(_isGrid ? Icons.view_list : Icons.grid_view),
            tooltip: _isGrid ? 'Chuyển sang danh sách' : 'Chuyển sang lưới',
            onPressed: () => setState(() => _isGrid = !_isGrid),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 400),
        child: _isGrid
            ? GridView.builder(
                key: ValueKey('grid'),
                controller: _scrollController,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 2.8),
                itemCount: emails.length,
                itemBuilder: (context, index) {
                  final email = emails[index];
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
            : ListView(
                controller: _scrollController,
                children: [
                  for (final entry in grouped.entries) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      child: Text(entry.key, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blueGrey)),
                    ),
                    ...entry.value.map((email) => Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        leading: CircleAvatar(
                          backgroundColor: Colors.redAccent,
                          child: Text(email.sender[0], style: TextStyle(color: Colors.white)),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                email.sender,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: widget.fontFamily,
                                  fontSize: widget.fontSize,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Text(_formatTime(email.time), style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${email.subject} - ${email.content}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: widget.fontFamily,
                              fontSize: widget.fontSize - 2,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        tileColor: Colors.white,
                        trailing: IconButton(
                          icon: Icon(Icons.delete_forever, color: Colors.red),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Xác nhận xóa'),
                                content: Text('Bạn có chắc chắn muốn xóa email này vĩnh viễn không?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: Text('Hủy'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: Text('Xóa'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              setState(() {
                                widget.repository.deleteEmailPermanently(email);
                              });
                            }
                          },
                          tooltip: 'Xóa vĩnh viễn',
                        ),
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
                      ),
                    )),
                  ],
                ],
              ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }
} 