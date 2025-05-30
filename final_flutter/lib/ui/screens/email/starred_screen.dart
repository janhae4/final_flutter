import 'package:flutter/material.dart';
import 'package:final_flutter/data/mock_email_repository.dart';
import 'package:final_flutter/models/email.dart';
import 'package:final_flutter/ui/screens/email/detail_screen.dart';
import 'package:intl/intl.dart';

class StarredScreen extends StatefulWidget {
  final MockEmailRepository repository;
  final String fontFamily;
  final double fontSize;
  const StarredScreen({super.key, required this.repository, this.fontFamily = 'Roboto', this.fontSize = 16});

  @override
  State<StarredScreen> createState() => _StarredScreenState();
}

class _StarredScreenState extends State<StarredScreen> {
  bool _multiSelectMode = false;
  Set<String> _selectedIds = {};

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
    final allStarred = [
      ...widget.repository.inbox,
      ...widget.repository.sent,
      ...widget.repository.drafts,
      ...widget.repository.trash,
    ].where((e) => e.starred).toList();
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
      final total = allStarred.length;
      if (_currentMax < total) {
        setState(() {
          _currentMax = (_currentMax + _pageSize).clamp(0, total);
        });
      }
    }
  }

  void _toggleMultiSelect() {
    setState(() {
      _multiSelectMode = !_multiSelectMode;
      if (!_multiSelectMode) _selectedIds.clear();
    });
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll(List<Email> emails) {
    setState(() {
      _selectedIds = emails.map((e) => e.id).toSet();
    });
  }

  void _deleteSelected(List<Email> emails) {
    final toDelete = emails.where((e) => _selectedIds.contains(e.id)).toList();
    for (final e in toDelete) {
      e.starred = false;
      widget.repository.moveToTrash(e);
    }
    setState(() {
      _selectedIds.clear();
      _multiSelectMode = false;
    });
  }

  void _toggleStarSelected(List<Email> emails) {
    for (final e in emails.where((e) => _selectedIds.contains(e.id))) {
      widget.repository.toggleStar(e);
    }
    setState(() {});
  }

  void _markReadSelected(List<Email> emails, bool read) {
    for (final e in emails.where((e) => _selectedIds.contains(e.id))) {
      widget.repository.markRead(e, read);
    }
    setState(() {});
  }

  void _assignLabelSelected(List<Email> emails, String label) {
    for (final e in emails.where((e) => _selectedIds.contains(e.id))) {
      widget.repository.assignLabel(e, label);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final emails = [
      ...widget.repository.inbox,
      ...widget.repository.sent,
      ...widget.repository.drafts,
      ...widget.repository.trash,
    ].where((e) => e.starred).take(_currentMax).toList()
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
      appBar: _multiSelectMode
          ? AppBar(
              title: Text('Đã chọn ${_selectedIds.length}'),
              leading: IconButton(icon: Icon(Icons.close), onPressed: _toggleMultiSelect),
              actions: [
                IconButton(
                  icon: Icon(Icons.select_all),
                  tooltip: 'Chọn tất cả',
                  onPressed: () => _selectAll(emails),
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  tooltip: 'Xóa',
                  onPressed: () => _deleteSelected(emails),
                ),
                IconButton(
                  icon: Icon(Icons.star_border),
                  tooltip: 'Bỏ gắn sao',
                  onPressed: () => _toggleStarSelected(emails),
                ),
                IconButton(
                  icon: Icon(Icons.mark_email_read),
                  tooltip: 'Đánh dấu đã đọc',
                  onPressed: () => _markReadSelected(emails, true),
                ),
                IconButton(
                  icon: Icon(Icons.mark_email_unread),
                  tooltip: 'Đánh dấu chưa đọc',
                  onPressed: () => _markReadSelected(emails, false),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.label),
                  tooltip: 'Gán nhãn',
                  onSelected: (label) => _assignLabelSelected(emails, label),
                  itemBuilder: (context) => widget.repository.labels
                      .map((l) => PopupMenuItem(value: l, child: Text(l)))
                      .toList(),
                ),
              ],
            )
          : AppBar(
              title: Text('Starred'),
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
                      leading: email.isRead
                          ? CircleAvatar(child: Text(email.sender[0]))
                          : Stack(
                              alignment: Alignment.center,
                              children: [
                                CircleAvatar(child: Text(email.sender[0])),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
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
                                color: email.isRead ? null : Colors.black,
                              ),
                            ),
                          ),
                          Text(_formatTime(email.time), style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      subtitle: Text(
                        '${email.subject} - ${email.content}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: widget.fontFamily,
                          fontSize: widget.fontSize,
                          fontWeight: email.isRead ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                      tileColor: email.isRead ? null : Colors.blue.withOpacity(0.08),
                      onTap: _multiSelectMode
                          ? () => _toggleSelect(email.id)
                          : () {
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
                    ...entry.value.map((email) => GestureDetector(
                      onLongPress: _multiSelectMode ? null : () => setState(() => _multiSelectMode = true),
                      child: Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          leading: CircleAvatar(
                            backgroundColor: email.starred ? Colors.amber : Colors.blueAccent,
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
                                    color: email.isRead ? Colors.black87 : Colors.blueAccent,
                                  ),
                                ),
                              ),
                              Icon(email.starred ? Icons.star : Icons.star_border, color: email.starred ? Colors.amber : Colors.grey, size: 20),
                              SizedBox(width: 8),
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
                                fontWeight: email.isRead ? FontWeight.normal : FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          tileColor: email.isRead ? Colors.white : Colors.blue.withOpacity(0.07),
                          trailing: IconButton(
                            icon: Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: _multiSelectMode
                                ? null
                                : () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text('Xác nhận xóa'),
                                        content: Text('Bạn có chắc chắn muốn chuyển email này vào thùng rác không?'),
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
                                        email.starred = false;
                                        widget.repository.moveToTrash(email);
                                      });
                                    }
                                  },
                            tooltip: 'Xóa',
                          ),
                          onTap: _multiSelectMode
                              ? () => _toggleSelect(email.id)
                              : () {
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