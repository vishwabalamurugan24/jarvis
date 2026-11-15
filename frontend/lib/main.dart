import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const JarvisApp());

const kCyan = Color(0xFF22D3EE);

class JarvisApp extends StatelessWidget {
  const JarvisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'J.A.R.V.I.S',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050A0D),
      ),
      home: const JarvisHome(),
    );
  }
}

class JarvisHome extends StatefulWidget {
  const JarvisHome({super.key});

  @override
  State<JarvisHome> createState() => _JarvisHomeState();
}

class _JarvisHomeState extends State<JarvisHome> {
  static const String backendUrl = 'http://localhost:3000/api/chat';

  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  final List<Map<String, String>> _history = [
    {'role': 'assistant', 'content': 'JARVIS online. What do you need, sir?'},
  ];
  bool _loading = false;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _loading) return;

    setState(() {
      _history.add({'role': 'user', 'content': text});
      _input.clear();
      _loading = true;
    });
    _scrollToBottom();

    try {
      final res = await http.post(
        Uri.parse(backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'history': _history}),
      );
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      setState(() {
        _history.add({
          'role': 'assistant',
          'content': (data['reply'] ?? data['error'] ?? 'No reply.').toString(),
        });
      });
    } catch (_) {
      setState(() {
        _history.add({
          'role': 'assistant',
          'content': 'Connection lost. Is the backend running?',
        });
      });
    } finally {
      setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _header(),
          Expanded(child: _chatList()),
          _inputBar(),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: kCyan.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [kCyan, Color(0xFF0E7490)]),
              boxShadow: [BoxShadow(color: kCyan, blurRadius: 14, spreadRadius: 1)],
            ),
          ),
          const SizedBox(width: 14),
          const Text(
            'J.A.R.V.I.S',
            style: TextStyle(
              color: kCyan,
              fontSize: 20,
              letterSpacing: 6,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chatList() {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.all(24),
      itemCount: _history.length + (_loading ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == _history.length && _loading) {
          return _bubble(role: 'assistant', text: '…');
        }
        final m = _history[i];
        return _bubble(role: m['role']!, text: m['content']!);
      },
    );
  }

  Widget _bubble({required String role, required String text}) {
    final isUser = role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF1E293B) : kCyan.withOpacity(0.08),
          border: Border.all(
            color: isUser ? const Color(0xFF334155) : kCyan.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isUser ? 'YOU' : 'JARVIS',
              style: TextStyle(
                color: kCyan.withOpacity(0.8),
                fontSize: 10,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            SelectableText(
              text,
              style: const TextStyle(
                color: Color(0xFFE5F6FF),
                fontSize: 14.5,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: kCyan.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _input,
              enabled: !_loading,
              style: const TextStyle(color: Color(0xFFE5F6FF)),
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: 'Speak your command…',
                hintStyle: TextStyle(color: kCyan.withOpacity(0.4)),
                filled: true,
                fillColor: const Color(0xFF0B1A24),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: kCyan.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: kCyan),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: _loading ? null : _send,
            style: ElevatedButton.styleFrom(
              backgroundColor: kCyan,
              foregroundColor: const Color(0xFF00262E),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              _loading ? '…' : 'SEND',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}