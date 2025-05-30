import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  final String fontFamily;
  final double fontSize;
  const ProfileScreen({super.key, this.fontFamily = 'Roboto', this.fontSize = 16});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = 'Tên người dùng';
  String _phone = '0123456789';
  String _email = 'user@email.com';
  File? _avatar;

  void _pickAvatar() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _avatar = File(result.files.single.path!);
      });
    }
  }

  void _editInfo() async {
    final nameController = TextEditingController(text: _name);
    final phoneController = TextEditingController(text: _phone);
    final emailController = TextEditingController(text: _email);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cập nhật thông tin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: 'Tên')), 
            TextField(controller: phoneController, decoration: InputDecoration(labelText: 'Số điện thoại')), 
            TextField(controller: emailController, decoration: InputDecoration(labelText: 'Email')), 
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Lưu')),
        ],
      ),
    );
    if (ok == true) {
      setState(() {
        _name = nameController.text;
        _phone = phoneController.text;
        _email = emailController.text;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        elevation: 6,
        margin: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _pickAvatar,
                child: CircleAvatar(
                  radius: 48,
                  backgroundImage: _avatar != null ? FileImage(_avatar!) : null,
                  child: _avatar == null ? Icon(Icons.person, size: 48) : null,
                ),
              ),
              SizedBox(height: 16),
              Text(_name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: widget.fontFamily)),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.phone, size: 18),
                  SizedBox(width: 6),
                  Text(_phone, style: TextStyle(fontFamily: widget.fontFamily, fontSize: widget.fontSize)),
                ],
              ),
              SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.email, size: 18),
                  SizedBox(width: 6),
                  Text(_email, style: TextStyle(fontFamily: widget.fontFamily, fontSize: widget.fontSize)),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _editInfo,
                icon: Icon(Icons.edit),
                label: Text('Cập nhật thông tin'),
                style: ElevatedButton.styleFrom(
                  shape: StadiumBorder(),
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 