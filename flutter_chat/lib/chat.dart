import 'dart:io';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat/constant/api.dart';
import 'package:flutter_chat/constant/color.dart';
import 'package:image_picker/image_picker.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

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
    // Initialize Socket.IO connection
    socket = io.io(ApiConstant.BASE_URL, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    // Set up event listener for incoming chat messages
    socket.on('chat message', _handleChatMessage);
    socket.on('file message', _handleFileMessage);

    // Connect to the Socket.IO server
    socket.connect();
  }

  Future<void> _handleSubmitted(String text) async {
    if (_textController.text.isNotEmpty) {
      // Send the chat message to the server
      socket.emit('chat message', _textController.text);
      _textController.clear();
    }
  }

  void _showUsernamePopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String username = '';

        return AlertDialog(
          title: const Text('Set Username'),
          content: TextField(
            onChanged: (value) {
              username = value;
            },
            decoration: const InputDecoration(
              hintText: 'Enter your username',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (username.isNotEmpty) {
                  currentUser = username;
                  // Set the username and emit an event to the server
                  _setUsername(username);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Set'),
            ),
          ],
        );
      },
    );
  }

  void _setUsername(String username) {
    // Emit an event to the server to set the username
    socket.emit('set username', username);
  }

  void _handleChatMessage(dynamic data) {
    if (data['username'] != null) {
      // Check if it's a regular text message
      if (data['message'] != null) {
        _messages.insert(
          0,
          ChatMessage(
            username: data['username'],
            text: data['message'],
            isMe: data['username'] == currentUser,
          ),
        );
      }
      setState(() {});
    }
  }

  void _handleFileMessage(dynamic data) {
    if (data['username'] != null && data['fileName'] != null) {
      _messages.insert(
        0,
        ChatMessage.file(
          username: data['username'],
          fileName: data['fileName'],
          isMe: data['username'] == currentUser,
        ),
      );
      setState(() {});
    }
  }

  Future<void> _sendFile() async {
    XFile? pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File file = File(pickedFile.path);

      Dio dio = Dio();
      // ignore: use_build_context_synchronously
      showDialog(
        context: context,
        barrierDismissible: false, // Prevent user from dismissing the dialog
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Uploading...'),
              ],
            ),
          );
        },
      );

      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
        'username': currentUser,
      });

      try {
        await dio.post(
          ApiConstant.Uploud,
          data: formData,
          onSendProgress: (int sent, int total) {
            // You can update progress if needed
          },
        );

        // ignore: use_build_context_synchronously
        Navigator.pop(context);
      } catch (e) {
        // ignore: use_build_context_synchronously
        Navigator.pop(context);

        // ignore: avoid_print
        print('Error sending file: $e');
        // Handle the error as needed.
      }
    }
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
              config: const Config(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Chat'),
        backgroundColor: ColorConstant.Primary,
      ),
      body: Column(
        children: <Widget>[
          const SizedBox(
            height: 20,
          ),
          ElevatedButton(
            onPressed: _showUsernamePopup,
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstant.Primary,
              shadowColor: Colors.grey, // Warna bayangan
              elevation: 5, // Tingkat elevasi
            ),
            child: const Text(
              'Set Username',
              style: TextStyle(color: Colors.white),
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
          const Divider(height: 1.0),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
            ),
            child: _buildTextComposer(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return IconTheme(
      data: const IconThemeData(
        color: Colors.blue,
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: <Widget>[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: IconButton(
                icon: const Icon(Icons.image_rounded),
                onPressed: () {
                  _sendFile();
                },
                color: Colors.blue,
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: IconButton(
                icon: const Icon(Icons.emoji_emotions),
                onPressed: () {
                  _showEmojiPicker();
                },
                color: Colors.blue,
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            Flexible(
              child: TextField(
                controller: _textController,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration.collapsed(
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
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String username;
  final String text;
  final String? fileName;
  final bool isMe;
  final Key? key;

  ChatMessage({
    required this.username,
    required this.text,
    required this.isMe,
    this.key,
    this.fileName,
  });

  ChatMessage.file({
    required this.username,
    required this.fileName,
    required this.isMe,
    this.text = 'Sent a file',
    this.key,
  });

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
                backgroundColor: ColorConstant.IsNotMe,
                child: Text(username[0]),
              ),
            ),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              decoration: BoxDecoration(
                color: isMe ? ColorConstant.IsMe : ColorConstant.IsNotMe,
                borderRadius: BorderRadius.circular(8.0),
              ),
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (fileName != null) ...[
                    _buildFileMessage(context),
                  ] else ...[
                    Container(
                      margin: const EdgeInsets.only(top: 5.0),
                      child: Text(
                        text,
                        style: const TextStyle(
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileMessage(BuildContext context) {
    Future<void> downloadFile(String fileName) async {
      try {
        var url = Uri.parse(ApiConstant.ImageInSend + '$fileName');
        var response = await http.get(url);

        if (response.statusCode == 200) {
          final directory = await getApplicationDocumentsDirectory();
          final filePath = '${directory.path}/$fileName';

          File file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);

          // File successfully downloaded
        } else {
          // Handle non-200 status code
          print('Failed to download file. Status code: ${response.statusCode}');
        }
      } catch (e) {
        // Handle other exceptions
        print('Error during download: $e');
      }
    }

    return Column(
      children: [
        Hero(
          tag: 'imageHero', // Unique tag for the hero animation
          child: GestureDetector(
            onTap: () {
              // Show the image in a pop-up or navigate to a new screen
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return Dialog(
                    child: CachedNetworkImage(
                      height: MediaQuery.of(context).size.height * 0.5,
                      width: MediaQuery.of(context).size.width * 0.5,
                      imageUrl: ApiConstant.ImageInSend + '$fileName',
                      fit: BoxFit.cover, // Adjust the fit property as needed
                    ),
                  );
                },
              );
            },
            child: Container(
              margin: const EdgeInsets.only(top: 5.0),
              child: CachedNetworkImage(
                imageUrl: ApiConstant.ImageInSend + '$fileName',
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            // Handle download action here
            await downloadFile(fileName!);
          },
          child: const Text('Download'),
        ),
      ],
    );
  }
}
