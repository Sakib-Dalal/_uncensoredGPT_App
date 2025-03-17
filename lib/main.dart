import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:chat_bubbles/chat_bubbles.dart';
import 'message.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image(
              image: AssetImage('images/logo.png'),
              height: 100.0,
            ),
            const SizedBox(height: 50.0),
            DefaultTextStyle(
              style: const TextStyle(
                fontSize: 35.0,
                fontFamily: 'Agne',
                color: Color(0xffFF0000),
                fontWeight: FontWeight.bold,
              ),
              child: AnimatedTextKit(
                repeatForever: true,
                pause: const Duration(seconds: 2),
                animatedTexts: [
                  TypewriterAnimatedText('_uncensoredGPT'),
                ],
              ),
            ),
            const SizedBox(height: 50.0),
            FilledButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Color(0xffFF0000)),
                padding: MaterialStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 50),
                ),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ChatScreen(),
                  ),
                );
              },
              child: const Text(
                'Start Chat',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  TextEditingController controller = TextEditingController();
  ScrollController scrollController = ScrollController();
  List<Message> msgs = [];
  bool isTyping = false;

  Future<void> sendMsg() async {
    String text = controller.text.trim();
    String url = "https://7e56-34-74-68-96.ngrok-free.app/chat";
    controller.clear();

    if (text.isEmpty) return;

    setState(() {
      msgs.insert(0, Message(true, text));
      isTyping = true;
    });

    _scrollToBottom();

    try {
      var response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"prompt": text}),
      );

      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        setState(() {
          isTyping = false;
          msgs.insert(
            0,
            Message(
              false,
              MarkdownBody(
                // data: json["message"]["content"].toString().trimLeft(),
                data: json[0]["generated_text"].toString().trimLeft(),
              ),
            ),
          );
        });
      } else {
        throw Exception("Server error. Try again!");
      }
    } on SocketException {
      _showSnackBar("No internet connection.");
    } on FormatException {
      _showSnackBar("Invalid server response.");
    } on Exception catch (e) {
      _showSnackBar(e.toString());
    } finally {
      setState(() => isTyping = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (scrollController.hasClients) {
        scrollController.jumpTo(scrollController.position.minScrollExtent);
      }
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AnimatedTextKit(
          repeatForever: true,
          pause: const Duration(seconds: 2),
          animatedTexts: [
            TypewriterAnimatedText('_uncensoredGPT'),
          ],
        ),
        titleTextStyle: TextStyle(color: Color(0xffFF0000), fontSize: 20),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          const SizedBox(height: 8.0),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: msgs.length + (isTyping ? 1 : 0),
              shrinkWrap: true,
              reverse: true,
              itemBuilder: (context, index) {
                if (index == 0 && isTyping) {
                  return const Padding(
                    padding: EdgeInsets.only(left: 16, top: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Typing...",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }

                final message = msgs[isTyping ? index - 1 : index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: message.msg is String
                      ? BubbleNormal(
                          text: message.msg,
                          textStyle: TextStyle(color: Colors.black),
                          isSender: message.isSender,
                          color: message.isSender
                              ? Colors.red.shade300
                              : Colors.black,
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 20,
                          ),
                          child: Align(
                            alignment: message.isSender
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: message.msg,
                          ),
                        ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      width: double.infinity,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: TextField(
                          autocorrect: false,
                          cursorColor: Colors.red,
                          controller: controller,
                          textCapitalization: TextCapitalization.sentences,
                          style: const TextStyle(color: Colors.white),
                          onSubmitted: (_) => sendMsg(),
                          textInputAction: TextInputAction.send,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "Enter text",
                            hintStyle: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: isTyping ? null : sendMsg,
                  child: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: isTyping ? Colors.black : Color(0xffFF0000),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: isTyping
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                              color: Color(0xffFF0000),
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.send,
                            color: Colors.black,
                          ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
