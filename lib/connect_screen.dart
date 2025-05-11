import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/services.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final TextEditingController _send = TextEditingController();
  final TextEditingController _url = TextEditingController();
  final _scroll = ScrollController();
  bool isConnected = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // final url = 'ws://localhost:3216/chat/';
  late WebSocketChannel channel;

  List<String> data = [];

  void startListening() async {
    if (_formKey.currentState!.validate()) {
      try {
        channel = WebSocketChannel.connect(
          Uri.parse(_url.text),
        );

        channel.stream.listen((message) {
          setState(() {
            data.add(message);
          });
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(microseconds: 100),
            curve: Curves.fastOutSlowIn,
          );
        });
        setState(() {
          isConnected = !isConnected;
        });
      } catch (e) {
        const snackBar = SnackBar(content: Text("Error connecting to URL"));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  void stopListening() {
    channel.sink.close(1000);
    setState(() {
      isConnected = !isConnected;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Websocket Inspector"),
        bottom: AppBar(
            title: Row(
          children: [
            Flexible(
                child: Form(
              key: _formKey,
              child: TextFormField(
                controller: _url,
                validator: (val) {
                  if (val!.length <= 5) {
                    return "Input valid URL";
                  } else {
                    return null;
                  }
                },
                decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide:
                            const BorderSide(color: Colors.blue, width: 2)),
                    hintText:
                        "Enter full URL, Example - ws://localhost:3216/connect "),
              ),
            )),
            const SizedBox(
              width: 20,
            ),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: isConnected ? Colors.red : Colors.green),
                onPressed: () async {
                  if (isConnected) {
                    stopListening();
                  } else {
                    startListening();
                  }
                },
                child: Text(
                  isConnected ? "Disconnect" : "Connect",
                  style: const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold),
                ))
          ],
        )),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ListView.builder(
            controller: _scroll,
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: data.length,
            itemBuilder: (context, length) {
              return SelectableText(data[length]);
            }),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 20, right: 10, bottom: 10),
        child: Row(
          children: [
            Flexible(
              child: TextFormField(
                controller: _send,
                decoration: InputDecoration(
                    hintText: "Message",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide:
                            const BorderSide(color: Colors.blue, width: 2))),
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                onPressed: () async {
                  channel.sink.add(_send.text);
                },
                child: const Text(
                  "Send",
                  style: TextStyle(color: Colors.black),
                )),
            const SizedBox(
              width: 10,
            ),
            IconButton(
                tooltip: "Copy Payload to clipboard as json",
                onPressed: () async {
                  await Clipboard.setData(
                      ClipboardData(text: json.encode(data)));
                },
                icon: const Icon(Icons.copy))
          ],
        ),
      ),
    );
  }
}
