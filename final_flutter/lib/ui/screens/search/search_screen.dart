import 'package:flutter/material.dart';
import 'package:final_flutter/data/mock_email_repository.dart';
import 'package:final_flutter/models/email.dart';
import 'package:final_flutter/ui/screens/email/detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final MockEmailRepository? repository;
  final String fontFamily;
  final double fontSize;
  const SearchScreen({super.key, this.repository, this.fontFamily = 'Roboto', this.fontSize = 16});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _keywordController = TextEditingController();
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _subjectController = TextEditingController();
  String? _selectedLabel;
  DateTime? _selectedDate;
  bool _hasAttachment = false;
  List<Email> _results = [];
  bool _isGrid = false;

  MockEmailRepository get _repo => widget.repository ?? MockEmailRepository();

  void _search() {
    final all = [..._repo.inbox, ..._repo.sent, ..._repo.drafts, ..._repo.trash];
    setState(() {
      _results = all.where((e) {
        if (_keywordController.text.isNotEmpty &&
            !e.content.toLowerCase().contains(_keywordController.text.toLowerCase()) &&
            !e.subject.toLowerCase().contains(_keywordController.text.toLowerCase())) {
          return false;
        }
        if (_fromController.text.isNotEmpty && !e.sender.toLowerCase().contains(_fromController.text.toLowerCase())) return false;
        if (_toController.text.isNotEmpty && !e.to.any((t) => t.toLowerCase().contains(_toController.text.toLowerCase()))) return false;
        if (_subjectController.text.isNotEmpty && !e.subject.toLowerCase().contains(_subjectController.text.toLowerCase())) return false;
        if (_selectedLabel != null && _selectedLabel!.isNotEmpty && !e.labels.contains(_selectedLabel)) return false;
        if (_selectedDate != null && (e.time.year != _selectedDate!.year || e.time.month != _selectedDate!.month || e.time.day != _selectedDate!.day)) return false;
        if (_hasAttachment && (e.attachments.isEmpty)) return false;
        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final labels = _repo.labels;
    return Scaffold(
      appBar: AppBar(
        title: Text('Tìm kiếm nâng cao'),
        actions: [
          IconButton(
            icon: Icon(_isGrid ? Icons.view_list : Icons.grid_view),
            tooltip: _isGrid ? 'Chuyển sang danh sách' : 'Chuyển sang lưới',
            onPressed: () => setState(() => _isGrid = !_isGrid),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _keywordController,
              decoration: InputDecoration(labelText: 'Từ khóa'),
            ),
            TextField(
              controller: _fromController,
              decoration: InputDecoration(labelText: 'Người gửi'),
            ),
            TextField(
              controller: _toController,
              decoration: InputDecoration(labelText: 'Người nhận'),
            ),
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(labelText: 'Chủ đề'),
            ),
            DropdownButtonFormField<String>(
              value: _selectedLabel,
              items: [null, ...labels].map((l) => DropdownMenuItem(value: l, child: Text(l ?? '---'))).toList(),
              onChanged: (v) => setState(() => _selectedLabel = v),
              decoration: InputDecoration(labelText: 'Nhãn'),
            ),
            Row(
              children: [
                Expanded(
                  child: InputDecorator(
                    decoration: InputDecoration(labelText: 'Ngày'),
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => _selectedDate = picked);
                      },
                      child: Text(_selectedDate == null ? '---' : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
                    ),
                  ),
                ),
                Checkbox(
                  value: _hasAttachment,
                  onChanged: (v) => setState(() => _hasAttachment = v!),
                ),
                Text('Có đính kèm'),
              ],
            ),
            SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _search,
              icon: Icon(Icons.search),
              label: Text('Tìm kiếm'),
            ),
            SizedBox(height: 16),
            if (_results.isNotEmpty)
              AnimatedSwitcher(
                duration: Duration(milliseconds: 400),
                child: _isGrid
                    ? GridView.builder(
                        key: ValueKey('grid'),
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 2.8),
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final e = _results[index];
                          return Card(
                            margin: EdgeInsets.all(8),
                            child: ListTile(
                              leading: CircleAvatar(child: Text(e.sender[0])),
                              title: Text(e.subject, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: widget.fontFamily, fontSize: widget.fontSize)),
                              subtitle: Text(e.sender, style: TextStyle(fontWeight: FontWeight.bold, fontFamily: widget.fontFamily, fontSize: widget.fontSize)),
                              onTap: () {
                                Navigator.of(context).push(PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) => DetailScreen(email: e, repository: _repo),
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
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => Divider(height: 1),
                        itemBuilder: (context, index) {
                          final e = _results[index];
                          return ListTile(
                            leading: CircleAvatar(child: Text(e.sender[0])),
                            title: Text(e.subject, style: TextStyle(fontFamily: widget.fontFamily, fontSize: widget.fontSize)),
                            subtitle: Text('${e.sender} - ${e.to.join(", ")}', style: TextStyle(fontFamily: widget.fontFamily, fontSize: widget.fontSize)),
                            trailing: Text('${e.time.hour.toString().padLeft(2, '0')}:${e.time.minute.toString().padLeft(2, '0')}'),
                            onTap: () {
                              Navigator.of(context).push(PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) => DetailScreen(email: e, repository: _repo),
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
            if (_results.isEmpty) Text('Không có kết quả.'),
          ],
        ),
      ),
    );
  }
} 