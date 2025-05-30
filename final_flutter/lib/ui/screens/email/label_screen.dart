import 'package:flutter/material.dart';
import 'package:final_flutter/data/mock_email_repository.dart';
import 'label_email_list_screen.dart';

class LabelScreen extends StatefulWidget {
  final MockEmailRepository repository;
  const LabelScreen({super.key, required this.repository});

  @override
  State<LabelScreen> createState() => _LabelScreenState();
}

class _LabelScreenState extends State<LabelScreen> {
  final _controller = TextEditingController();
  String? _editingLabel;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  void _addLabel() {
    final label = _controller.text.trim();
    if (label.isNotEmpty && !widget.repository.labels.contains(label)) {
      widget.repository.addLabel(label);
      _controller.clear();
      setState(() {});
      if (_listKey.currentState != null) {
        _listKey.currentState!.insertItem(widget.repository.labels.length - 1);
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã thêm nhãn "$label"')));
    }
  }

  void _editLabel(String oldLabel) {
    setState(() {
      _editingLabel = oldLabel;
      _controller.text = oldLabel;
    });
  }

  void _saveEditLabel() {
    final newLabel = _controller.text.trim();
    if (_editingLabel != null && newLabel.isNotEmpty && !_editingLabel!.contains(newLabel)) {
      widget.repository.renameLabel(_editingLabel!, newLabel);
      setState(() {
        _editingLabel = null;
        _controller.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã đổi nhãn thành "$newLabel"')));
    }
  }

  void _deleteLabel(String label) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xóa nhãn'),
        content: Text('Bạn có chắc chắn muốn xóa nhãn "$label" không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Xóa')),
        ],
      ),
    );
    if (confirm == true) {
      final idx = widget.repository.labels.indexOf(label);
      widget.repository.removeLabelGlobal(label);
      setState(() {});
      if (_listKey.currentState != null) {
        _listKey.currentState!.removeItem(
          idx,
          (context, animation) => SizeTransition(
            sizeFactor: animation,
            child: ListTile(title: Text(label)),
          ),
        );
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã xóa nhãn "$label"')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.repository.labels;
    return Scaffold(
      appBar: AppBar(title: Text('Quản lý nhãn')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(labelText: _editingLabel == null ? 'Thêm nhãn mới' : 'Sửa nhãn'),
                  ),
                ),
                SizedBox(width: 8),
                _editingLabel == null
                    ? ElevatedButton(onPressed: _addLabel, child: Text('Thêm'))
                    : ElevatedButton(onPressed: _saveEditLabel, child: Text('Lưu')),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: AnimatedList(
                key: _listKey,
                initialItemCount: labels.length,
                itemBuilder: (context, index, animation) {
                  final label = labels[index];
                  return SizeTransition(
                    sizeFactor: animation,
                    child: ListTile(
                      title: Text(label),
                      onTap: () {
                        Navigator.of(context).push(PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => LabelEmailListScreen(label: label, repository: widget.repository),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            final tween = Tween(begin: 0.9, end: 1.0);
                            return ScaleTransition(
                              scale: animation.drive(tween),
                              child: child,
                            );
                          },
                        ));
                      },
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () => _editLabel(label),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => _deleteLabel(label),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 