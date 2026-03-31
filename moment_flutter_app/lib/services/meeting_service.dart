import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:record/record.dart';

class MeetingService {
  final String baseUrl;
  final String wsUrl;

  AudioRecorder? _currentRecorder;
  WebSocketChannel? _currentChannel;
  StreamSubscription<Uint8List>? _streamSubscription;

  Future<void> stopStreaming(Function(String) onStatus) async {
    onStatus("Stopping recording...");

    // Stop the recorder first (this stops producing new chunks)
    await _currentRecorder?.stop();

    // Cancel the stream subscription
    await _streamSubscription?.cancel();

    // Small delay to ensure last chunks are sent
    await Future.delayed(const Duration(milliseconds: 100));

    // Close the websocket
    await _currentChannel?.sink.close();

    _currentRecorder = null;
    _currentChannel = null;
    _streamSubscription = null;

    onStatus("Audio sent. Processing...");
  }

  MeetingService({String? baseUrl, String? wsUrl})
    : baseUrl = baseUrl ?? _getBaseUrl(),
      wsUrl = wsUrl ?? _getWsUrl();

  /// Get the appropriate base URL based on platform
  static String _getBaseUrl() {
    // if (Platform.isAndroid) {
    //   return 'http://10.0.2.2:8000';
    // }
    return 'http://10.107.134.99:8000';
  }

  /// Get the appropriate WebSocket URL based on platform
  static String _getWsUrl() {
    // if (Platform.isAndroid) {
    //   return 'ws://10.0.2.2:8000';
    // }
    return 'ws://10.107.134.99:8000';
  }

  /// Streams audio to the backend via WebSocket
  Future<void> streamAudioToBackend(
    String meetingId,
    Function(String) onStatus,
  ) async {
    final record = AudioRecorder();

    // Check permission
    if (!await record.hasPermission()) {
      throw Exception("Microphone permission not granted");
    }

    onStatus("Connecting to server...");

    final channel = WebSocketChannel.connect(
      Uri.parse('$wsUrl/ws/audio?meeting_id=$meetingId'),
    );

    await channel.ready;

    onStatus("Connected! Recording and streaming audio...");

    // Start recording as AAC stream
    final stream = await record.startStream(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 16000,
        numChannels: 1,
      ),
    );

    // Listen to audio stream and send to backend
    _streamSubscription = stream.listen(
      (Uint8List chunk) {
        print("Sending audio chunk: ${chunk.length} bytes");
        channel.sink.add(chunk);
      },
      onError: (e) {
        print("Stream error: $e");
      },
      onDone: () {
        print("Audio stream completed");
      },
    );

    // Store references so you can stop later
    _currentRecorder = record;
    _currentChannel = channel;
  }

  /// Fetches transcript for a meeting from the backend
  Future<Map<String, dynamic>> getTranscript(String meetingId) async {
  final response = await http.get(Uri.parse('$baseUrl/api/transcript/$meetingId'));

  return jsonDecode(response.body);
}
}