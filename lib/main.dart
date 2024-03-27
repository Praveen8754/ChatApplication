import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Firebase Chat',
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _taskController = TextEditingController();
  var mobilenumber="8754507235";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Chat App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: ChatList(mobilenumber)),
          Divider(),
          ChatInput(mobilenumber),
        ],
      ),
    );
  }
}

class ChatList extends StatefulWidget {
  final String mobilenumber;
  ChatList(this. mobilenumber);

  @override
  _ChatListState createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref('chen');
  List<Item> _groceryItems = [];
  late DatabaseReference _messagesRef;
  late Future<Item> _futureAlbum;

  final StreamController<List<Item>> _messagesController =
      StreamController<List<Item>>();

  @override
  void initState() {
    super.initState();
    FirebaseMessaging.instance.getToken().then((token) {
      print("FCM Token: $token");
    });
    _loadItems();
  }

  void _loadItems() async {
    _database.onValue.listen((event) {
      DataSnapshot dataSnapshot = event.snapshot;
      print("B");
      print(dataSnapshot.value);
      List<Item> messages = [];
      if (dataSnapshot.value != null) {
        Map<dynamic, dynamic>? values = dataSnapshot.value as Map?;
        values?.forEach((key, value) {
          messages.add(Item(
              sendername: value['sendername'],
              content: value['content'],
              time: value['time']));
        });
      }
      _messagesController.add(messages);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Item>>(
      stream: _messagesController.stream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<Item> messages = snapshot.data!;
          messages.sort((a, b) {
            return b.time.compareTo((a.time));
          });
          Iterable<Item> reverseOrder = messages.reversed;
          List<Item> r = reverseOrder.toList();
          return ListView.builder(
              itemCount: r.length,
              itemBuilder: (context, index) {
                Item message = r[index];
                return _buildMessage(message, widget.mobilenumber);
              });
        } else {
          return const Text("Loading...");
        }
      },
    );
  }

  Widget _buildMessage(Item message, String mobilenumber) {
    DateTime dateTime =
        DateTime.fromMillisecondsSinceEpoch(message.time);
    String formattedDateTime = DateFormat.yMd()
        .add_Hms()
        .format(dateTime.toLocal()/*.add(const Duration(hours: 5, minutes: 30))*/);
    return message.sendername== mobilenumber
        ? Padding(
            padding: EdgeInsets.fromLTRB(
                MediaQuery.of(context).size.width / 2, 0, 0, 0),
            child: Card(
              color: Colors.grey[300],
              child: ListTile(
                title: ListTile(
                  title: Text("${message.sendername}"),
                  subtitle: Text("${message.content}"),
                ),
                subtitle: Text("${formattedDateTime}",textAlign: TextAlign.right, ),
              ),
            ),
          )
        : Padding(
            padding: EdgeInsets.fromLTRB(
                0, 0, MediaQuery.of(context).size.width / 2, 0),
            child: Card(
              color: Colors.blueGrey,
              child: ListTile(
                title: ListTile(
                  title: Text("${message.sendername}",textAlign: TextAlign.right,),
                  subtitle: Text("${message.content}",textAlign: TextAlign.right,),
                ),
                subtitle: Text("${formattedDateTime}"),
              ),
            ),
          );
  }
}

class Item {
  Item({
    required this.sendername,
    required this.content,
    required this.time,
  });

  late final String sendername;
  late final String content;
  late final int time;

  Item.fromJson(Map<String, dynamic> json) {
    sendername = json['sendername'];
    content = json['content'];
    time = json['time'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['sendername'] = this.sendername;
    data['content'] = this.content;
    data['time'] = this.time;
    return data;
  }
}

class ChatInput extends StatefulWidget {
  final String mobilenumber;
  ChatInput(this. mobilenumber);

  @override
  _ChatInputState createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _messageController = TextEditingController();


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Enter your message...',
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () async {
              var messageText = _messageController.text;
              var messageSender =widget.mobilenumber;

              if (messageText.isNotEmpty) {
                _sendMessage(messageText, messageSender);
              }
              _messageController.clear();
            },
          ),
        ],
      ),
    );
  }

  void _sendMessage(String messageText, String messageSender) {
    final url = Uri.https(
        'crud-17232-default-rtdb.asia-southeast1.firebasedatabase.app',
        'chen.json');
    http.post(url,
        body: json.encode({
          'sendername': messageSender,
          'content': messageText,
          'time': DateTime.now().millisecondsSinceEpoch
        }));
  }
}
