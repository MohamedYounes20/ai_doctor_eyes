import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:vibration/vibration.dart';
import '../app_theme.dart';
import '../models/health_condition.dart';
import '../models/scan_history_item.dart';
import '../services/database_helper.dart';
import '../services/ingredient_checker_service.dart';
import '../services/preferences_service.dart';

/// Scanner Screen: Camera + ML Kit, SAFE/DANGER banners, save to DB.
/// Default state is "Scanning". Camera stops when user leaves this screen.
class ScannerScreen extends StatefulWidget {
  final List<HealthCondition> healthConditions;
  final bool isVisible;
  final VoidCallback? onScanComplete;

  const ScannerScreen({
    super.key,
    required this.healthConditions,
    this.isVisible = true,
    this.onScanComplete,
  });

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  CameraController? _cameraController;
  final IngredientCheckerService _ingredientChecker = IngredientCheckerService();
  final TextRecognizer _textRecognizer = TextRecognizer();
  final PreferencesService _prefs = PreferencesService();
  final DatabaseHelper _db = DatabaseHelper.instance;
  FlutterTts? _tts;

  bool _isInitialized = false;
  bool _isProcessing = false;
  String _scannedText = '';
  List<String> _harmfulIngredients = [];
  bool _hasScanned = false; // Default state: Scanning until first scan
  bool _isSafe = true;
  String _statusMessage = 'Scanning...';
  Timer? _scanTimer;

  @override
  void initState() {
    super.initState();
    _initTts();
    if (widget.isVisible) {
      _initializeCamera();
    }
  }

  @override
  void didUpdateWidget(ScannerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isVisible != widget.isVisible) {
      if (widget.isVisible) {
        _initializeCamera();
      } else {
        _stopCamera();
      }
    }
  }

  @override
  void dispose() {
    _stopCamera();
    _textRecognizer.close();
    _tts?.stop();
    super.dispose();
  }

  Future<void> _initTts() async {
    _tts = FlutterTts();
    await _tts?.setLanguage('en-US');
    await _tts?.setSpeechRate(0.5);
  }

  Future<void> _stopCamera() async {
    _scanTimer?.cancel();
    _scanTimer = null;
    await _cameraController?.dispose();
    _cameraController = null;
    if (mounted) {
      setState(() {
        _isInitialized = false;
      });
    }
  }

  Future<void> _initializeCamera() async {
    if (_cameraController != null) return;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _statusMessage = 'No camera available');
        return;
      }
      _cameraController = CameraController(
        cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      if (mounted && widget.isVisible) {
        setState(() => _isInitialized = true);
        _startScanning();
      } else {
        await _stopCamera();
      }
    } catch (e) {
      if (mounted) setState(() => _statusMessage = 'Camera error: $e');
    }
  }

  void _startScanning() {
    _scanTimer?.cancel();
    _scanTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      if (!_isProcessing && _isInitialized && widget.isVisible) {
        _processCameraFrame();
      }
    });
  }

  Future<void> _speakResult(bool isSafe) async {
    final voiceEnabled = await _prefs.isVoiceFeedbackEnabled();
    if (!voiceEnabled || _tts == null) return;
    await _tts!.speak(isSafe ? 'Safe' : 'Danger');
  }

  Future<void> _processCameraFrame() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        !widget.isVisible) return;
    setState(() => _isProcessing = true);

    try {
      final image = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      final text = recognizedText.text.trim();

      if (mounted) {
        final harmfulIngredients = _ingredientChecker.checkForHarmfulIngredients(
          text,
          widget.healthConditions,
        );
        final isSafe = harmfulIngredients.isEmpty;

        setState(() {
          _scannedText = text;
          _harmfulIngredients = harmfulIngredients;
          _hasScanned = true;
          _isSafe = isSafe;
          _statusMessage = isSafe ? 'Safe' : 'Danger';
        });

        // Vibration (respect user preference)
        final vibEnabled = await _prefs.isVibrationEnabled();
        if (!isSafe && (vibEnabled && (await Vibration.hasVibrator() ?? false))) {
          Vibration.vibrate(duration: 500);
        }

        // Voice feedback (TTS)
        await _speakResult(isSafe);

        // Data integrity: only save valid results (not Unknown Product or empty)
        final productName = _extractProductName(text);
        final isValidProduct = productName.isNotEmpty &&
            productName.toLowerCase() != 'unknown product';
        if (isValidProduct) {
          await _db.insertScanHistory(ScanHistoryItem(
            productName: productName,
            status: isSafe ? 'Safe' : 'Danger',
            harmfulIngredients: harmfulIngredients.join(', '),
            timestamp: DateTime.now(),
          ));
          widget.onScanComplete?.call();
        }
      }

      final imageFile = File(image.path);
      if (await imageFile.exists()) await imageFile.delete();
    } catch (_) {}
    if (mounted) setState(() => _isProcessing = false);
  }

  /// Extract first line of detected text as Product Name
  String _extractProductName(String text) {
    final lines =
        text.split('\n').map((l) => l.trim()).where((l) => l.length > 3).toList();
    return lines.isNotEmpty ? lines.first : '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('AI Food Scanner'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          if (_isInitialized && _cameraController != null)
            SizedBox.expand(child: CameraPreview(_cameraController!))
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 20),
                  Text(
                    _statusMessage,
                    style: const TextStyle(
                        color: Colors.white, fontSize: AppTheme.bodyFontSize),
                  ),
                ],
              ),
            ),
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: _buildStatusBanner(),
          ),
          if (_harmfulIngredients.isNotEmpty)
            Positioned(
              bottom: 120,
              left: 20,
              right: 20,
              child: _buildHarmfulIngredientsList(),
            ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: _buildInstructions(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    // Default state: "Scanning" until first scan
    final isScanning = !_hasScanned;
    final color = isScanning
        ? AppTheme.primaryColor
        : (_isSafe ? AppTheme.safeColor : AppTheme.dangerColor);
    final label = isScanning ? 'SCANNING' : (_isSafe ? 'SAFE' : 'DANGER');
    final icon =
        isScanning ? Icons.document_scanner : (_isSafe ? Icons.check_circle : Icons.warning);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHarmfulIngredientsList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.dangerColor.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Detected Harmful Ingredients:',
            style: TextStyle(
              color: Colors.white,
              fontSize: AppTheme.bodyFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ..._harmfulIngredients.map(
            (ing) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ing,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: AppTheme.bodyFontSize,
                      ),
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

  Widget _buildInstructions() {
    final isScanning = !_hasScanned;
    final message = isScanning
        ? 'Point camera at ingredient list'
        : (_isSafe
            ? 'All ingredients are safe! This product is suitable for your health condition.'
            : 'Point camera at ingredient list');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontSize: AppTheme.bodyFontSize,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
