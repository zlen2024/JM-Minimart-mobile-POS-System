import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class IoTControlPage extends StatefulWidget {
  const IoTControlPage({super.key});

  @override
  State<IoTControlPage> createState() => _IoTControlPageState();
}

class _IoTControlPageState extends State<IoTControlPage> {
  final TextEditingController _urlController = TextEditingController(text: "ws://192.168.1.100:8000/ws/flutter_app");
  final TextEditingController _deviceIdController = TextEditingController(text: "esp32-9f83b1c1");

  WebSocketChannel? _channel;
  bool _isConnected = false;
  List<String> _logs = [];

  @override
  void dispose() {
    _urlController.dispose();
    _deviceIdController.dispose();
    _channel?.sink.close();
    super.dispose();
  }

  void _connect() {
    if (_urlController.text.isEmpty) return;

    try {
      final uri = Uri.parse(_urlController.text);
      _channel = WebSocketChannel.connect(uri);

      setState(() {
        _isConnected = true;
        _log("Connected to ${uri.toString()}");
      });

      _channel!.stream.listen(
        (message) {
          _log("Received: $message");
        },
        onDone: () {
          setState(() {
            _isConnected = false;
            _log("Disconnected.");
          });
        },
        onError: (error) {
          setState(() {
            _isConnected = false;
            _log("Error: $error");
          });
        },
      );
    } catch (e) {
      _log("Connection failed: $e");
    }
  }

  void _disconnect() {
    _channel?.sink.close();
    setState(() {
      _isConnected = false;
      _log("Disconnected intentionally.");
    });
  }

  void _sendCommand(String cmd) {
    if (_channel == null || !_isConnected) {
      _log("Cannot send: Not connected.");
      return;
    }

    if (_deviceIdController.text.isEmpty) {
       _log("Error: Device ID is required.");
       return;
    }

    final message = jsonEncode({
      "id": _deviceIdController.text,
      "cmd": cmd
    });

    _channel!.sink.add(message);
    _log("Sent: $message");
  }

  void _log(String message) {
    setState(() {
      _logs.insert(0, "${DateTime.now().toIso8601String().substring(11, 19)} - $message");
      if (_logs.length > 50) _logs.removeLast();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("IoT Control Dashboard"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Connection Setup
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _urlController,
                      decoration: const InputDecoration(labelText: "FastAPI WebSocket URL"),
                      enabled: !_isConnected,
                    ),
                    TextField(
                      controller: _deviceIdController,
                      decoration: const InputDecoration(labelText: "Target Device ID"),
                      enabled: !_isConnected,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _isConnected ? _disconnect : _connect,
                      child: Text(_isConnected ? "Disconnect" : "Connect"),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Control Buttons
            if (_isConnected)
               Card(
                 child: Padding(
                   padding: const EdgeInsets.all(16.0),
                   child: Column(
                     children: [
                       const Text("Device Controls", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                       const SizedBox(height: 10),
                       Row(
                         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                         children: [
                           ElevatedButton(
                             onPressed: () => _sendCommand("led_on"),
                             style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                             child: const Text("ON", style: TextStyle(color: Colors.white)),
                           ),
                           ElevatedButton(
                             onPressed: () => _sendCommand("led_off"),
                             style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                             child: const Text("OFF", style: TextStyle(color: Colors.white)),
                           ),
                           ElevatedButton(
                             onPressed: () => _sendCommand("toggle"),
                             style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                             child: const Text("TOGGLE", style: TextStyle(color: Colors.white)),
                           ),
                         ],
                       ),
                       const SizedBox(height: 10),
                       ElevatedButton(
                             onPressed: () => _sendCommand("reboot"),
                             style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                             child: const Text("REBOOT", style: TextStyle(color: Colors.white)),
                       ),
                     ],
                   ),
                 ),
               ),

            const SizedBox(height: 20),

            // Logs
            const Align(alignment: Alignment.centerLeft, child: Text("Logs:", style: TextStyle(fontWeight: FontWeight.bold))),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                      child: Text(_logs[index], style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                    );
                  },
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
