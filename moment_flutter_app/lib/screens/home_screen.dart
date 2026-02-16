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
  String _currentMeetingId = '';

  bool _isRecording = false;
  bool _isProcessing = false;

  // 🔹 Meeting output
  String _mom = '';
  List _actions = [];

  Future<void> _startMeeting() async {
    setState(() {
      _mom = '';
      _actions = [];
      _currentMeetingId = 'meeting-${_uuid.v4().substring(0, 8)}';
      _status = 'Starting meeting $_currentMeetingId...';
      _isRecording = true;
      _isProcessing = false;
    });

    try {
      await _meetingService.streamAudioToBackend(
        _currentMeetingId,
        (status) => setState(() => _status = status),
      );
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isRecording = false;
      });
    }
  }

  Future<void> _stopMeeting() async {
    if (_currentMeetingId.isEmpty || !_isRecording) return;

    setState(() {
      _isProcessing = true;
      _status = "Finalizing meeting...";
    });

    try {
      await _meetingService.stopStreaming(
        (status) => setState(() => _status = status),
      );

      setState(() => _isRecording = false);

      // wait for backend processing
      await Future.delayed(const Duration(seconds: 2));

      final data =
          await _meetingService.getTranscript(_currentMeetingId);

      final moments = data['moments'];

      setState(() {
        _mom = moments?['mom'] ?? 'No MoM generated.';
        _actions = moments?['actions'] ?? [];
        _status = "Meeting summary ready!";
      });
    } catch (e) {
      setState(() {
        _status = 'Error retrieving summary';
      });
    } finally {
      setState(() => _isProcessing = false);
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
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// 🔹 Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Icons.mic,
                      size: 48,
                      color: _isRecording ? Colors.red : Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isRecording
                          ? 'Recording in progress...'
                          : _isProcessing
                              ? 'Processing meeting...'
                              : 'AI Meeting Assistant',
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

            /// 🔹 Status Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    _isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.info_outline),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_status)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// 🔹 Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        _isRecording || _isProcessing ? null : _startMeeting,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text("Start"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isRecording ? _stopMeeting : null,
                    icon: const Icon(Icons.stop),
                    label: const Text("Stop"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// 🔹 Output Section
            Expanded(
              child: Card(
                child: _mom.isEmpty
                    ? Center(
                        child: Text(
                          "Meeting summary will appear here",
                          style:
                              TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Minutes of Meeting",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SelectableText(
                              _mom,
                              style: const TextStyle(
                                  fontSize: 16, height: 1.5),
                            ),

                            if (_actions.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              const Text(
                                "Action Items",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),

                              ..._actions.map((action) {
                                final owner = action['owner']?.toString().trim();
                                final task = action['task']?.toString().trim();
                                final deadline = action['deadline']?.toString().trim();

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: ListTile(
                                    leading: const Icon(Icons.check_circle_outline),
                                    title: Text(
                                      task?.isNotEmpty == true ? task! : "Task not specified",
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (owner != null && owner.isNotEmpty)
                                          Text("Owner: $owner"),
                                        if (deadline != null && deadline.isNotEmpty)
                                          Text("Deadline: $deadline"),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],

                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
