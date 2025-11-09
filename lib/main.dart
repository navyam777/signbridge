import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final cameras = await availableCameras();
    runApp(MyApp(cameras: cameras));
  } catch (e) {
    print("Error getting cameras: $e");
    runApp(const ErrorApp());
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(
          child: Text('Failed to initialize camera'),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  const MyApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SignAptic',
      theme: ThemeData(
        useMaterial3: true,
        textTheme: TextTheme(
          displayLarge: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFB0D4E3),
            ),
          bodyMedium: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: const Color(0xFFE8F0F7),
          ),
          labelLarge: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
          scaffoldBackgroundColor: const Color(0xFF0E141C),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0E141C),
          foregroundColor: Color(0xFFB0D4E3),
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
      home: SignLanguageLessonScreen(cameras: cameras),
    );
  }
}

class SignLanguageLessonScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const SignLanguageLessonScreen({super.key, required this.cameras});

  @override
  State<SignLanguageLessonScreen> createState() =>
      _SignLanguageLessonScreenState();
}

class _SignLanguageLessonScreenState extends State<SignLanguageLessonScreen>
    with SingleTickerProviderStateMixin {
  late CameraController _cameraController;
  bool _isCameraInitialized = false;
  bool _isRecording = false;
  late AnimationController _pulseController;

  String currentSign = "Hello";
  int accuracy = 0;
  String feedback = "Position your hands in front of you";
  List<String> allSigns = ["Hello", "Thank You", "Please", "Goodbye", "Help"];
  int currentSignIndex = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      if (widget.cameras.isEmpty) {
        print("No cameras available");
        return;
      }

      _cameraController = CameraController(
        widget.cameras[0],
        ResolutionPreset.high,
      );

      await _cameraController.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;

      if (_isRecording) {
        accuracy = 75 + (DateTime.now().millisecond % 20);
        feedback = "Perfect form! Keep your hands steady.";
      } else {
        accuracy = 0;
        feedback = "Great attempt! Review the feedback below.";
      }
    });
  }

  void _nextSign() {
    setState(() {
      currentSignIndex = (currentSignIndex + 1) % allSigns.length;
      currentSign = allSigns[currentSignIndex];
      accuracy = 0;
      feedback = "Get ready for: $currentSign. Position yourself clearly.";
      _isRecording = false;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    if (_isCameraInitialized) {
      _cameraController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 90,
        title:  Text(
          'SignAptic',
          style: GoogleFonts.abrilFatface(
            fontSize: 56,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
            color: Color(0xFFB0D4E3),
          ),
        ),
        centerTitle: true,
      ),
      body: !_isCameraInitialized
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFB0D4E3),
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // Camera Section with Glassmorphism
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF314B6E).withOpacity(0.4),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CameraPreview(_cameraController),
                              // Gradient overlay
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.transparent,
                                      const Color(0xFF0E141C).withOpacity(0.1),
                                    ],
                                  ),
                                ),
                              ),
                              // Recording indicator
                              if (_isRecording)
                                Positioned(
                                  top: 16,
                                  left: 16,
                                  child: ScaleTransition(
                                    scale: Tween(begin: 1.0, end: 1.1).animate(
                                      CurvedAnimation(
                                        parent: _pulseController,
                                        curve: Curves.easeInOut,
                                      ),
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE74C3C)
                                            .withOpacity(0.9),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFE74C3C)
                                                .withOpacity(0.5),
                                            blurRadius: 12,
                                          ),
                                        ],
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.fiber_manual_record,
                                              color: Colors.white, size: 10),
                                          SizedBox(width: 8),
                                          Text(
                                            'DETECTING',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 11,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Sign & Accuracy Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF314B6E).withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF607EA0).withOpacity(0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF314B6E).withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Current Sign',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF8DA3B8),
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  currentSign,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w300,
                                    color: Color(0xFFB0D4E3),
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Accuracy',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF8DA3B8),
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$accuracy%',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w300,
                                    color: _getAccuracyColor(accuracy),
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Progress Bar
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: const Color(0xFF1A2438),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: accuracy / 100,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getAccuracyColor(accuracy),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Feedback Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF314B6E).withOpacity(0.6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF607EA0).withOpacity(0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF314B6E).withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Feedback',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFB0D4E3),
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              feedback,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.6,
                                color: Color(0xFFE8F0F7),
                                fontWeight: FontWeight.w300,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _toggleRecording,
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: _isRecording
                                        ? [
                                            const Color(0xFFE74C3C),
                                            const Color(0xFFC0392B),
                                          ]
                                        : [
                                            const Color(0xFF2ECC71),
                                            const Color(0xFF27AE60),
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (_isRecording
                                              ? const Color(0xFFE74C3C)
                                              : const Color(0xFF2ECC71))
                                          .withOpacity(0.4),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  _isRecording ? 'Stop' : 'Start',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: GestureDetector(
                              onTap: _nextSign,
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF314B6E)
                                      .withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF607EA0)
                                        .withOpacity(0.5),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF314B6E)
                                          .withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'Next Sign',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFB0D4E3),
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Color _getAccuracyColor(int accuracy) {
    if (accuracy < 30) return const Color(0xFFE74C3C);
    if (accuracy < 70) return const Color(0xFFF39C12);
    return const Color(0xFF2ECC71);
  }
}