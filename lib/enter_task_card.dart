/*

import 'package:flutter/material.dart';
import 'services/task_submit_service.dart';
import 'services/database_helper.dart';
import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:math' show sin;
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

class EnterTaskCard extends StatefulWidget {
  final Function(Map<String, dynamic>) onTaskAdded;
  final String userId;

  const EnterTaskCard({required this.onTaskAdded, required this.userId, Key? key}) : super(key: key);

  @override
  _EnterTaskCardState createState() => _EnterTaskCardState();
}

class _EnterTaskCardState extends State<EnterTaskCard> with SingleTickerProviderStateMixin {
  final TextEditingController _taskController = TextEditingController();
  String? _errorMessage;
  bool _isProcessing = false;

  // Speech recognition variables
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _recognizedText = '';
  Timer? _silenceTimer;
  late AnimationController _animController;

  // Audio level monitoring
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _recorderIsInited = false;
  double _currentVolume = 0.0;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initRecorder();

    // Initialize animation controller for voice wave
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _taskController.dispose();
    _silenceTimer?.cancel();
    _animController.dispose();
    _recorder.closeRecorder();
    super.dispose();
  }

  // Initialize the recorder
  Future<void> _initRecorder() async {
    await _recorder.openRecorder();
    _recorder.setSubscriptionDuration(const Duration(milliseconds: 100));
    setState(() {
      _recorderIsInited = true;
    });
  }

  // Start recording to monitor audio levels
  Future<void> _startRecording() async {
    if (_recorderIsInited) {
      try {
        await _recorder.startRecorder(
          toFile: 'temp_recording.aac',
          codec: Codec.aacADTS,
        );

        _recorder.onProgress!.listen((RecordingDisposition e) {
          setState(() {
            // Get the decibel level (normalized between 0.0 and 1.0)
            _currentVolume = e.decibels != null
                ? (e.decibels! / 100).clamp(0.0, 1.0)
                : 0.0;
          });
        });
      } catch (e) {
        print('Error starting recorder: $e');
      }
    }
  }

  // Stop recording
  Future<void> _stopRecording() async {
    try {
      if (_recorder.isRecording) {
        await _recorder.stopRecorder();
      }
    } catch (e) {
      print('Error stopping recorder: $e');
    }
  }

  // Initialize speech recognition
  void _initSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        print('Speech recognition status: $status');
        if (status == 'done' && _isListening) {
          setState(() {
            _isListening = false;
          });
          _stopRecording();
          if (_recognizedText.isNotEmpty) {
            _taskController.text = _recognizedText;
            _submitRecognizedText();
          }
        }
      },
      onError: (errorNotification) {
        print('Speech recognition error: $errorNotification');
        // Check if mounted before calling setState
        if (mounted) {
          setState(() {
            _isListening = false;
            if (errorNotification.errorMsg == 'error_speech_timeout') {
              _errorMessage = "No speech detected. Please try again and speak clearly.";
            } else {
              _errorMessage = "Speech recognition error. Please try again.";
            }
          });
        }
        _stopRecording();
      },
    );
    print('Speech recognition available: $available');
  }

  // Start listening
  void _startListening() async {
    _recognizedText = '';

    // Request microphone permission
    var status = await Permission.microphone.request();
    print("Permission status: $status");
    if (status != PermissionStatus.granted) {
      setState(() {
        _errorMessage = "Microphone permission denied";
      });
      return;
    }

    if (!_speech.isAvailable) {
      _initSpeech(); // Don't await since it's void
    }

    if (_speech.isAvailable) {
      setState(() {
        _isListening = true;
        _errorMessage = null;
      });

      // Start recording to monitor audio levels
      await _startRecording();

      await _speech.listen(
        onResult: (result) {
          setState(() {
            _recognizedText = result.recognizedWords;
          });

          // Reset the silence timer each time we get a result
          _silenceTimer?.cancel();
          _silenceTimer = Timer(const Duration(seconds: 3), () {
            if (_isListening) {
              _speech.stop();
              _stopRecording();
              setState(() {
                _isListening = false;
              });
              if (_recognizedText.isNotEmpty) {
                _taskController.text = _recognizedText;
                _submitRecognizedText();
              }
            }
          });
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: 'en_US',
      );
    }
  }

  // Submit the recognized text
  void _submitRecognizedText() async {
    if (_recognizedText.isEmpty) return;

    await _submitTask(); // Use the existing task submission logic
  }

  Future<void> _submitTask() async {
    final String inputText = _taskController.text.trim();
    print('Starting task submission with text: $inputText');

    print('Device current time: ${DateTime.now()}');
    print('Device timezone: ${DateTime.now().timeZoneName}');


    if (inputText.isEmpty) {
      setState(() {
        _errorMessage = "Task description cannot be empty.";
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Call the TaskSubmitService to send the input to the backend
      final responseData = await TaskSubmitService.submitTask(inputText);

      if (responseData['success'] == true) {
        final task = responseData['task'];
        print('Task parsed successfully: $task');
        // Save to database
        try {
          print('Attempting to save to database');
          await DatabaseHelper.instance.insertTask(task, widget.userId);
          print('Successfully saved to database');
        } catch (e) {
          print('Error saving to database: $e');
          // Continue even if database save fails
        }

        widget.onTaskAdded(task); // Notify the parent widget of the new task
        Navigator.pop(context); // Close the task entry card
      } else {
        setState(() {
          _errorMessage = responseData['error'];
        });
      }
    } catch (e) {
      print('Error in submitTask: $e');
      setState(() {
        _errorMessage = "An error occurred. Please try again.";
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Regular dialog
        Dialog(
          backgroundColor: Colors.grey.shade900,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Enter Task/Event",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _taskController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Barbecue on December 23rd at 10am",
                    hintStyle: TextStyle(color: Colors.white54),
                    errorText: _errorMessage,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Microphone button
                    IconButton(
                      icon: Icon(
                        Icons.mic,
                        color: Colors.orange.shade700,
                        size: 28,
                      ),
                      onPressed: _isProcessing ? null : _startListening,
                    ),
                    // Submit button
                    ElevatedButton(
                      onPressed: _isProcessing ? null : _submitTask,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isProcessing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                        "Submit",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Voice recognition overlay - only shows when listening
        if (_isListening)
          Positioned.fill(
            child: _buildVoiceRecognitionOverlay(),
          ),
      ],
    );
  }

  // Voice recognition overlay widget
  Widget _buildVoiceRecognitionOverlay() {
    return Dialog(
      backgroundColor: Colors.black.withOpacity(0.9),
      insetPadding: EdgeInsets.zero,
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: _recognizedText.isEmpty
                    ? Container() // Empty container when no text instead of "Listening..."
                    : Text(
                      _recognizedText,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(height: 40),
              // Voice wave animation - use real volume when recording is active
              CustomPaint(
                size: Size(MediaQuery.of(context).size.width, 60),
                painter: VoiceWavePainter(
                  volumeLevel: _recorder.isRecording
                      ? _currentVolume
                      : 0.5 + (0.5 * _animController.value),
                  color: Colors.orange.shade700,
                ),
              ),
              SizedBox(height: 40),
              IconButton(
                icon: Icon(
                  Icons.mic_off,
                  color: Colors.white,
                  size: 36,
                ),
                onPressed: () {
                  _speech.stop();
                  _stopRecording();
                  setState(() {
                    _isListening = false;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom painter for the voice wave
class VoiceWavePainter extends CustomPainter {
  final double volumeLevel;
  final Color color;

  VoiceWavePainter({
    required this.volumeLevel,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final path = Path();
    final width = size.width;
    final height = size.height;
    final mid = height / 2;

    // Start the path at the left edge, middle height
    path.moveTo(0, mid);

    // Generate a multi-frequency wave based on volume level
    for (double i = 0; i < width; i += 1) {
      // Calculate a more complex wave with multiple frequencies
      final amplitude = volumeLevel * 25.0; // Amplify the effect

      // Primary wave
      final y1 = sin(i / 10) * amplitude;
      // Secondary faster wave
      final y2 = sin(i / 5) * amplitude * 0.5;
      // Third even faster wave
      final y3 = sin(i / 2) * amplitude * 0.25;

      // Combined wave with all frequencies
      final y = mid + y1 + y2 + y3;

      path.lineTo(i, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant VoiceWavePainter oldDelegate) {
    return oldDelegate.volumeLevel != volumeLevel;
  }
}


 */