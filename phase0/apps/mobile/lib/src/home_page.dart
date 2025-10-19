import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _status;
  bool _isLoading = false;
  String? _error;

  Future<void> _fetchHealth() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await http.get(Uri.parse('${AppConfig.bffBaseUrl}/healthz'));
      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        setState(() => _status = body['status'] as String? ?? 'UNKNOWN');
      } else {
        setState(() => _error = 'Status code: ${response.statusCode}');
      }
    } catch (err) {
      setState(() => _error = err.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchHealth();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade900,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'APP XXX',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Welcome shell — Fase 0',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 24),
                if (_isLoading)
                  const CircularProgressIndicator()
                else if (_error != null)
                  Column(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.amber, size: 40),
                      const SizedBox(height: 12),
                      Text(
                        'Errore:\n$_error',
                        style: const TextStyle(color: Colors.amberAccent),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _fetchHealth,
                        child: const Text('Riprova'),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Colors.lightGreenAccent, size: 40),
                      const SizedBox(height: 12),
                      Text(
                        'Stato BFF: ${_status ?? 'Sconosciuto'}',
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _fetchHealth,
                        child: const Text('Aggiorna'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
