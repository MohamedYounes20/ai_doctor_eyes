import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:vibration/vibration.dart';
import '../app_theme.dart';
import '../models/health_condition.dart';
import '../models/scan_history_item.dart';
import '../services/database_helper.dart';
import '../services/ingredient_checker_service.dart';
import '../services/preferences_service.dart';

/// Scanner Screen: Camera + ML Kit, SAFE/DANGER banners, save to DB.
class ScannerScreen extends StatefulWidget {
  final HealthCondition healthCondition;
  final VoidCallback? onScanComplete;

  const ScannerScreen({
    super.key,
    required this.healthCondition,
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

  bool _isInitialized = false;
  bool _isProcessing = false;
  String _scannedText = '';
  List<String> _harmfulIngredients = [];
  bool _isSafe = true;
  String _statusMessage = 'Scanning...';
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

  Future<void> _initializeCamera() async {
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
      if (mounted) {
        setState(() => _isInitialized = true);
        _startScanning();
      }
    } catch (e) {
      if (mounted) setState(() => _statusMessage = 'Camera error: $e');
    }
  }

  void _startScanning() {
    _scanTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      if (!_isProcessing && _isInitialized) _processCameraFrame();
    });
  }

  Future<void> _processCameraFrame() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    setState(() => _isProcessing = true);

    try {
      final image = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      final text = recognizedText.text;

      if (mounted) {
        final harmfulIngredients = _ingredientChecker.checkForHarmfulIngredients(
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

        // Vibration (respect user preference)
        final vibEnabled = await _prefs.isVibrationEnabled();
        if (!isSafe && (vibEnabled && (await Vibration.hasVibrator() ?? false))) {
          Vibration.vibrate(duration: 500);
        }

        // Save to DB
        final productName = _extractProductName(text);
        await _db.insertScanHistory(ScanHistoryItem(
          productName: productName,
          status: isSafe ? 'Safe' : 'Danger',
          harmfulIngredients: harmfulIngredients.join(', '),
          timestamp: DateTime.now(),
        ));
        widget.onScanComplete?.call();
      }

      final imageFile = File(image.path);
      if (await imageFile.exists()) await imageFile.delete();
    } catch (_) {}
    if (mounted) setState(() => _isProcessing = false);
  }

  String _extractProductName(String text) {
    final lines = text.split('\n').where((l) => l.trim().length > 3).toList();
    return lines.isNotEmpty ? lines.first.trim() : 'Unknown Product';
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
                    style: const TextStyle(color: Colors.white, fontSize: AppTheme.bodyFontSize),
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
    final color = _isSafe ? AppTheme.safeColor : AppTheme.dangerColor;
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
            _isSafe ? Icons.check_circle : Icons.warning,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(width: 12),
          Text(
            _isSafe ? 'SAFE' : 'DANGER',
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _isSafe
            ? 'All ingredients are safe! This product is suitable for your health condition.'
            : 'Point camera at ingredient list',
        style: const TextStyle(
          color: Colors.white,
          fontSize: AppTheme.bodyFontSize,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
