import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:vibration/vibration.dart';
import '../models/health_condition.dart';
import '../services/ingredient_checker_service.dart';
import 'dart:io'; // موجودة للتصحيح

/// Scanner Screen
///
/// This screen displays the camera view and continuously scans for text
/// using Google ML Kit. It checks for harmful ingredients every 1-2 seconds
/// and displays warnings or safe messages accordingly.
class ScannerScreen extends StatefulWidget {
  final HealthCondition healthCondition;

  const ScannerScreen({
    super.key,
    required this.healthCondition,
  });

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  CameraController? _cameraController;
  final IngredientCheckerService _ingredientChecker =
      IngredientCheckerService();
  final TextRecognizer _textRecognizer = TextRecognizer();

  // State variables
  bool _isInitialized = false;
  bool _isProcessing = false;
  String _scannedText = '';
  List<String> _harmfulIngredients = [];
  bool _isSafe = true;
  String _statusMessage = 'Scanning...';

  // Timer for periodic scanning
  Timer? _scanTimer;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _cameraController?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  /// Initialize the camera
  Future<void> _initializeCamera() async {
    try {
      // Get available cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _statusMessage = 'No camera available';
        });
        return;
      }

      // Initialize camera controller (use back camera)
      _cameraController = CameraController(
        cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        // Start periodic scanning
        _startScanning();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Camera error: $e';
        });
      }
    }
  }

  /// Start periodic scanning every 1.5 seconds
  void _startScanning() {
    _scanTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (!_isProcessing && _isInitialized) {
        _processCameraFrame();
      }
    });
  }

  /// Process a frame from the camera to extract text
  Future<void> _processCameraFrame() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Take a picture
      final image = await _cameraController!.takePicture();

      // Process the image with ML Kit
      final inputImage = InputImage.fromFilePath(image.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      // Extract text
      final text = recognizedText.text;

      if (mounted) {
        // Check for harmful ingredients
        final harmfulIngredients =
            _ingredientChecker.checkForHarmfulIngredients(
          text,
          widget.healthCondition,
        );

        final isSafe = harmfulIngredients.isEmpty;

        setState(() {
          _scannedText = text;
          _harmfulIngredients = harmfulIngredients;
          _isSafe = isSafe;
          _statusMessage = isSafe ? 'Safe' : 'Danger';
        });

        // Trigger vibration if harmful ingredients found
        if (!isSafe) {
          _triggerVibration();
        }
      }

      // --- التعديل هنا (السطر 146 وما بعده) ---
      // تحويل XFile إلى File عادي من مكتبة dart:io لحذفه بنجاح
      final File imageFile = File(image.path);
      if (await imageFile.exists()) {
        await imageFile.delete();
      }
      // ---------------------------------------
    } catch (e) {
      // Handle errors silently to avoid spam
      debugPrint('Error processing frame: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  /// Trigger device vibration
  Future<void> _triggerVibration() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 500);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Scanning: ${widget.healthCondition.displayName}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).pushNamed('/settings');
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview
          if (_isInitialized && _cameraController != null)
            SizedBox.expand(
              child: CameraPreview(_cameraController!),
            )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(
                    _statusMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),

          // Status overlay
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: _buildStatusOverlay(),
          ),

          // Harmful ingredients list (if any found)
          if (_harmfulIngredients.isNotEmpty)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: _buildHarmfulIngredientsList(),
            ),

          // Instructions at bottom
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: _buildInstructions(),
          ),
        ],
      ),
    );
  }

  /// Build the status overlay (DANGER or SAFE)
  Widget _buildStatusOverlay() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: _isSafe ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (_isSafe ? Colors.green : Colors.red).withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Text(
        _isSafe ? 'SAFE' : 'DANGER',
        style: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 4,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Build the list of harmful ingredients found
  Widget _buildHarmfulIngredientsList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade900.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Harmful Ingredients Found:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ..._harmfulIngredients.map(
            (ingredient) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    ingredient.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build instructions text
  Widget _buildInstructions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'Point camera at ingredient list',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
