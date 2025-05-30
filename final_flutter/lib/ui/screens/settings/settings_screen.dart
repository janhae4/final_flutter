import 'package:flutter/material.dart';
import 'package:final_flutter/data/mock_email_repository.dart';

class SettingsScreen extends StatefulWidget {
  final MockEmailRepository repository;
  final ThemeMode themeMode;
  final void Function(ThemeMode) setThemeMode;
  final String fontFamily;
  final double fontSize;
  final void Function(String) setFontFamily;
  final void Function(double) setFontSize;
  final bool notificationEnabled;
  final void Function(bool) setNotificationEnabled;
  final Color accentColor;
  final void Function(Color) setAccentColor;
  const SettingsScreen({
    super.key,
    required this.repository,
    required this.themeMode,
    required this.setThemeMode,
    required this.fontFamily,
    required this.fontSize,
    required this.setFontFamily,
    required this.setFontSize,
    required this.notificationEnabled,
    required this.setNotificationEnabled,
    required this.accentColor,
    required this.setAccentColor,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _autoAnswerEnabled;
  late TextEditingController _autoAnswerController;
  bool _isEditingAutoAnswer = false;

  @override
  void initState() {
    super.initState();
    _autoAnswerEnabled = widget.repository.autoAnswerEnabled;
    _autoAnswerController = TextEditingController(text: widget.repository.autoAnswerContent);
  }

  @override
  void dispose() {
    _autoAnswerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Cài đặt giao diện', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        ListTile(
          leading: Icon(Icons.color_lens),
          title: Text('Màu nhấn (Accent Color)'),
          subtitle: Row(
            children: [
              _AccentColorDot(color: Colors.blue, selected: widget.accentColor == Colors.blue, onTap: () => widget.setAccentColor(Colors.blue)),
              _AccentColorDot(color: Colors.red, selected: widget.accentColor == Colors.red, onTap: () => widget.setAccentColor(Colors.red)),
              _AccentColorDot(color: Colors.purple, selected: widget.accentColor == Colors.purple, onTap: () => widget.setAccentColor(Colors.purple)),
              _AccentColorDot(color: Colors.green, selected: widget.accentColor == Colors.green, onTap: () => widget.setAccentColor(Colors.green)),
              _AccentColorDot(color: Colors.orange, selected: widget.accentColor == Colors.orange, onTap: () => widget.setAccentColor(Colors.orange)),
            ],
          ),
        ),
        ListTile(
          leading: Icon(Icons.font_download),
          title: Text('Cài đặt font'),
          subtitle: Text('Font: ${widget.fontFamily}, cỡ: ${widget.fontSize.toInt()}'),
          onTap: () async {
            final fonts = ['Roboto', 'Montserrat', 'Lato', 'Noto Sans'];
            final sizes = [14.0, 16.0, 18.0, 20.0, 24.0];
            String? selectedFont = widget.fontFamily;
            double? selectedSize = widget.fontSize;
            await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Chọn font và cỡ chữ'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<String>(
                      value: selectedFont,
                      items: fonts.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                      onChanged: (v) => setState(() => selectedFont = v!),
                    ),
                    DropdownButton<double>(
                      value: selectedSize,
                      items: sizes.map((s) => DropdownMenuItem(value: s, child: Text(s.toInt().toString()))).toList(),
                      onChanged: (v) => setState(() => selectedSize = v!),
                    ),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: Text('Hủy')),
                  TextButton(
                    onPressed: () {
                      if (selectedFont != null && selectedSize != null) {
                        widget.setFontFamily(selectedFont!);
                        widget.setFontSize(selectedSize!);
                      }
                      Navigator.pop(context);
                    },
                    child: Text('Lưu'),
                  ),
                ],
              ),
            );
            setState(() {});
          },
        ),
        SwitchListTile(
          secondary: Icon(Icons.dark_mode),
          title: Text('Chế độ tối'),
          value: widget.themeMode == ThemeMode.dark,
          onChanged: (val) {
            widget.setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
            setState(() {});
          },
        ),
        Divider(),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Cài đặt thông báo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        SwitchListTile(
          secondary: Icon(Icons.notifications),
          title: Text('Bật thông báo'),
          value: widget.notificationEnabled,
          onChanged: (val) {
            widget.setNotificationEnabled(val);
            setState(() {});
          },
        ),
        Divider(),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Cài đặt tài khoản', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        SwitchListTile(
          secondary: Icon(Icons.reply),
          title: Text('Tự động trả lời'),
          value: _autoAnswerEnabled,
          onChanged: (val) {
            setState(() {
              _autoAnswerEnabled = val;
              widget.repository.autoAnswerEnabled = val;
              if (!val) _isEditingAutoAnswer = false;
            });
          },
        ),
        if (_autoAnswerEnabled)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _isEditingAutoAnswer
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _autoAnswerController,
                        decoration: InputDecoration(labelText: 'Nội dung trả lời tự động'),
                        maxLines: 2,
                      ),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                widget.repository.autoAnswerContent = _autoAnswerController.text;
                                _isEditingAutoAnswer = false;
                              });
                            },
                            child: Text('Lưu'),
                          ),
                          SizedBox(width: 8),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _autoAnswerController.text = widget.repository.autoAnswerContent;
                                _isEditingAutoAnswer = false;
                              });
                            },
                            child: Text('Hủy'),
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text(_autoAnswerController.text)),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isEditingAutoAnswer = true;
                          });
                        },
                        child: Text('Sửa'),
                      ),
                    ],
                  ),
          ),
      ],
    );
  }
}

class _AccentColorDot extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _AccentColorDot({required this.color, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: selected ? Border.all(color: Colors.black, width: 3) : null,
        ),
      ),
    );
  }
} 