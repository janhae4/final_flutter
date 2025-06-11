import 'package:final_flutter/data/models/email_response_model.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class EmailSocketService {
  late IO.Socket socket;

  void initSocket(String token) {
    socket = IO.io(
      'https://final-flutter.onrender.com',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    socket.onConnect((_) {
      print('Connected to WebSocket');
    });

    socket.onDisconnect((_) {
      print('Disconnected');
    });

    socket.connect();
  }

  void sendEmail(EmailResponseModel email) {
    socket.emit('send_email', email.toJson());
  }

  void listenForEmails(Function(EmailResponseModel) onNewEmail) {
    socket.on('new_email', (data) {
      print('New email received: $data');
      final email = EmailResponseModel.fromJson(data);
      print(email.toJson());
      onNewEmail(email);
    });
  }

  void dispose() {
    socket.dispose();
  }
}
