import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/meeting_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MeetingService _meetingService = MeetingService();
  final Uuid _uuid = const Uuid();

  String _status = 'Ready to start';
  String _transcript = '';
  String _currentMeetingId = '';
  bool _isProcessing = false;

  Future<void> _startMeeting() async {
    setState(() {
      _isProcessing = true;
      _transcript = '';
      _currentMeetingId = 'meeting-${_uuid.v4().substring(0, 8)}';
      _status = 'Starting meeting $_currentMeetingId...';
    });

    try {
      // Stream audio to backend
      await _meetingService.streamAudioToBackend(
        _currentMeetingId,
        (status) => setState(() => _status = status),
      );

      // Fetch transcript with retries
      String? transcript;
      int retries = 0;
      const maxRetries = 1;

      while (transcript == null && retries < maxRetries) {
        try {
          await Future.delayed(const Duration(seconds: 2));
          transcript = await _meetingService.getTranscript(_currentMeetingId);
        } catch (e) {
          retries++;
          setState(
            () => _status =
                'Waiting for transcript... (attempt $retries/$maxRetries)',
          );
        }
      }

      if (transcript != null) {
        setState(() {
          _transcript = transcript!;
          _status = 'Transcription complete!';
        });
      } else {
        setState(() {
          _status = 'Could not retrieve transcript after $maxRetries attempts';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MoMent'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.mic,
                      size: 48,
                      color: _isProcessing ? Colors.red : Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isProcessing ? 'Processing...' : 'Meeting Transcription',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (_currentMeetingId.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Meeting ID: $_currentMeetingId',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Status Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    if (_isProcessing)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      const Icon(Icons.info_outline, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _status,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Start Button
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _startMeeting,
              icon: Icon(
                _isProcessing ? Icons.hourglass_empty : Icons.play_arrow,
              ),
              label: Text(
                _isProcessing ? 'Processing...' : 'Start Demo Meeting',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // Transcript Section
            Expanded(
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.description, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Transcript',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _transcript.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.text_snippet_outlined,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Transcript will appear here',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: SelectableText(
                                _transcript,
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
