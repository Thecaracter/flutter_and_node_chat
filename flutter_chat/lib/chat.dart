import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rizqi Chat'),
      ),
      body: ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  State createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _messages = [];
  late io.Socket socket;

  @override
  void initState() {
    super.initState();
    // Ganti URL sesuai dengan URL backend server Anda
    socket =
        io.io('https://4x4mx23n-3000.asse.devtunnels.ms', <String, dynamic>{
      'transports': ['websocket'],
    });

    socket.on('chat message', (data) {
      setState(() {
        _messages.add(data);
      });
    });
  }

  void _sendMessage() {
    socket.emit('chat message', _controller.text);
    _controller.clear();
  }

  @override
  void dispose() {
    // Tutup koneksi Socket.IO ketika widget dihapus
    socket.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(_messages[index]),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Enter your message...',
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
