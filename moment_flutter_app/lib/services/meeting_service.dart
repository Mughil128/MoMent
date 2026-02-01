import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

class MeetingService {
  final String baseUrl;
  final String wsUrl;

  MeetingService({String? baseUrl, String? wsUrl})
    : baseUrl = baseUrl ?? _getBaseUrl(),
      wsUrl = wsUrl ?? _getWsUrl();

  /// Get the appropriate base URL based on platform
  static String _getBaseUrl() {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  /// Get the appropriate WebSocket URL based on platform
  static String _getWsUrl() {
    if (Platform.isAndroid) {
      return 'ws://10.0.2.2:8000';
    }
    return 'ws://localhost:8000';
  }

  /// Streams audio file to the backend via WebSocket
  Future<void> streamAudioToBackend(
    String meetingId,
    Function(String) onStatus,
  ) async {
    onStatus('Loading audio file...');

    // Load the sample audio from assets (MP3 - backend will convert to PCM)
    final ByteData audioData = await rootBundle.load('assets/sample.mp3');
    final Uint8List mp3Bytes = audioData.buffer.asUint8List();

    onStatus('Connecting to server...');

    // Connect to WebSocket
    final channel = WebSocketChannel.connect(
      Uri.parse('$wsUrl/ws/audio?meeting_id=$meetingId'),
    );

    await channel.ready;
    onStatus('Connected! Streaming MP3 audio...');

    // Stream MP3 audio in chunks
    const chunkSize = 4096;
    int bytesSent = 0;

    for (int i = 0; i < mp3Bytes.length; i += chunkSize) {
      final end = (i + chunkSize < mp3Bytes.length)
          ? i + chunkSize
          : mp3Bytes.length;
      final chunk = mp3Bytes.sublist(i, end);

      channel.sink.add(chunk);
      bytesSent += chunk.length;

      // Small delay to simulate real-time streaming
      await Future.delayed(const Duration(milliseconds: 30));
    }

    onStatus('Audio sent ($bytesSent bytes). Processing...');

    // Close the connection to trigger server-side processing
    await channel.sink.close();

    // Give the server time to process
    await Future.delayed(const Duration(seconds: 3));

    onStatus('Fetching transcript...');
  }

  /// Fetches transcript for a meeting from the backend
  Future<String> getTranscript(String meetingId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/transcript/$meetingId'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print(data);
      return data['moments'] as String;
    } else if (response.statusCode == 404) {
      throw Exception('Transcript not ready yet. Please wait...');
    } else {
      throw Exception('Failed to fetch transcript: ${response.statusCode}');
    }
  }
}
