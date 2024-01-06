import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = <ChatMessage>[];
  late io.Socket socket;
  String? currentUser;

  @override
  void initState() {
    super.initState();
    socket =
        io.io('https://4x4mx23n-9000.asse.devtunnels.ms', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.on('chat message', _handleChatMessage);

    socket.connect();
  }

  void _handleSubmitted(String text) {
    if (_textController.text.isNotEmpty) {
      socket.emit('chat message', _textController.text);
      _textController.clear();
    }
  }

  void _showUsernamePopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String _username = '';

        return AlertDialog(
          title: Text('Set Username'),
          content: TextField(
            onChanged: (value) {
              _username = value;
            },
            decoration: InputDecoration(
              hintText: 'Enter your username',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_username.isNotEmpty) {
                  currentUser = _username;
                  _setUsername(_username);
                  Navigator.of(context).pop();
                }
              },
              child: Text('Set'),
            ),
          ],
        );
      },
    );
  }

  void _setUsername(String username) {
    socket.emit('set username', username);
  }

  void _handleChatMessage(dynamic data) {
    if (data['username'] != null && data['message'] != null) {
      _messages.insert(
        0,
        ChatMessage(
          username: data['username'],
          text: data['message'],
          isMe: data['username'] == currentUser,
        ),
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat Flutter'),
        backgroundColor: Color(0xFF83A2FF),
      ),
      body: Column(
        children: <Widget>[
          SizedBox(
            height: 20,
          ),
          ElevatedButton(
            onPressed: _showUsernamePopup,
            child: Text(
              'Set Username',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              primary: Color(0xFF83A2FF),
            ),
          ),
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              reverse: true,
              itemBuilder: (_, int index) => _messages[index],
              itemCount: _messages.length,
            ),
          ),
          Divider(height: 1.0),
          Container(
            decoration: BoxDecoration(
              color: Color(0xFFEEF5FF),
            ),
            child: _buildTextComposer(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return IconTheme(
      data: IconThemeData(
        color: Color(0xFF83A2FF),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: <Widget>[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: IconButton(
                icon: const Icon(Icons.emoji_emotions),
                onPressed: () {
                  _showEmojiPicker();
                },
                color: Color(0xFF83A2FF),
              ),
            ),
            SizedBox(
              width: 10,
            ),
            Flexible(
              child: TextField(
                controller: _textController,
                style: TextStyle(color: Colors.black),
                decoration: InputDecoration.collapsed(
                  hintText: 'Send a message',
                  hintStyle: TextStyle(color: Colors.grey),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: IconButton(
                icon: const Icon(Icons.send),
                onPressed: () => _handleSubmitted(_textController.text),
                color: Color(0xFF83A2FF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmojiPicker() {
    showDialog(
      context: context,
      builder: (BuildContext builder) {
        return Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width / 1.5,
            height: MediaQuery.of(context).size.height / 2,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
            child: EmojiPicker(
              onEmojiSelected: (category, Emoji emoji) {
                _textController.text += emoji.emoji;
              },
              config: Config(
                columns: 5,
                emojiSizeMax: 32.0,
                verticalSpacing: 0,
                horizontalSpacing: 0,
                initCategory: Category.RECENT,
                bgColor: Colors.white,
                indicatorColor: Colors.blue,
                iconColor: Colors.black,
                iconColorSelected: Colors.blue,
                loadingIndicator: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
                recentTabBehavior: RecentTabBehavior.POPULAR,
                recentsLimit: 28,
                noRecents: Text("no recent emojis"),
                categoryIcons: CategoryIcons(),
                buttonMode: ButtonMode.MATERIAL,
              ),
            ),
          ),
        );
      },
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String username;
  final String text;
  final bool isMe;

  ChatMessage({required this.username, required this.text, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (!isMe)
            Container(
              margin: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                child: Text(username[0]),
                backgroundColor: Color(0xFF83A2FF),
              ),
            ),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              decoration: BoxDecoration(
                color: isMe ? Color(0xFF86B6F6) : Color(0xFFB4D4FF),
                borderRadius: BorderRadius.circular(8.0),
              ),
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    username,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 5.0),
                    child: Text(
                      text,
                      style: TextStyle(
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
