// lib/services/socket_service.dart
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket socket;

  void connect({
    required String userId,
    required BuildContext context,
    required Function(bool approved) onUserDecision,
  }) {
    socket = IO.io('http://localhost:3000', {
      'transports': ['websocket'],
      'query': {'userId': userId},
    });

    socket.on('connect', (_) {
      print('Socket connected ✅');
    });

    socket.on('login_request', (data) {
      final sessionId = data['sessionId'];

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Xác nhận đăng nhập'),
          content: Text('Bạn có muốn cho phép đăng nhập không?'),
          actions: [
            TextButton(
              onPressed: () {
                socket.emit('login_response', {
                  'sessionId': sessionId,
                  'approved': false,
                });
                onUserDecision(false);
                Navigator.pop(context);
              },
              child: Text('Từ chối'),
            ),
            TextButton(
              onPressed: () {
                socket.emit('login_response', {
                  'sessionId': sessionId,
                  'approved': true,
                });
                onUserDecision(true);
                Navigator.pop(context);
              },
              child: Text('Cho phép'),
            ),
          ],
        ),
      );
    });
  }

  void dispose() {
    socket.dispose();
  }
}
