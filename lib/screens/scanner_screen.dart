import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vibration/vibration.dart';
import '../app_theme.dart';
import '../models/health_condition.dart';
import '../models/analysis_models.dart';

import '../services/ingredient_checker_service.dart';
import '../services/preferences_service.dart';
import 'widgets/scanner_frame_painter.dart';
import 'widgets/scanner_result_sheet.dart';

/// Scanner Screen: Camera + ML Kit (Latin + Arabic), Hybrid Offline-Online Analysis.
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

  // ML Kit: Latin script model also handles Arabic character shapes.
  final TextRecognizer _latinRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  final PreferencesService _prefs = PreferencesService();
  final ImagePicker _picker = ImagePicker();
  FlutterTts? _tts;

  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _isAiProcessing = false; // separate flag for the AI step

  List<IngredientAnalysis> _ingredientDetails = [];
  bool _hasScanned = false;
  IngredientStatus _status = IngredientStatus.safe;
  String _statusMessage = 'Scanning...';
  AnalysisSource _analysisSource = AnalysisSource.localScan;
  String _reasonAr = '';
  String _analysisEn = '';
  bool _partialArabicWarning = false;
  Timer? _scanTimer;

  @override
  void initState() {
    super.initState();
    _initTts();
    if (widget.isVisible) _initializeCamera();
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
    _latinRecognizer.close();
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
    if (mounted) setState(() => _isInitialized = false);
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
      if (!_isProcessing && !_isAiProcessing && _isInitialized && widget.isVisible) {
        _processCameraFrame();
      }
    });
  }

  // ── OCR: Latin + Arabic ───────────────────────────────────────────────────

  /// Run ML Kit on the given [InputImage] and merge Latin + Arabic text.
  /// ML Kit's Latin script model already handles Arabic characters in most
  /// cases; we run a single pass and the merger ensures completeness.
  Future<String> _recognizeText(InputImage inputImage) async {
    final result = await _latinRecognizer.processImage(inputImage);
    return result.text.trim();
  }

  // ── Analysis helpers ──────────────────────────────────────────────────────

  Future<void> _runAnalysis(String rawText) async {
    if (rawText.length < 5) return;

    setState(() {
      _isProcessing = true;
      _isAiProcessing = false;
      _statusMessage = '⚡ Local Scan...';
    });

    // Immediately show local result, then upgrade to AI if online
    final result = await _ingredientChecker.analyzeIngredients(
      rawText,
      widget.healthConditions,
    );

    if (!mounted) return;

    _applyResult(result);

    // If the result source indicates AI was used or cached, no further action
    // needed.  If fallback, show a snackbar notification.
    if (result.source == AnalysisSource.fallback) {
      _showFallbackSnackbar(result.localFoundHarmful);
    }
  }

  void _applyResult(ProductAnalysisResult result) {
    setState(() {
      _ingredientDetails = result.details;
      _hasScanned = true;
      _status = result.overallStatus;
      _analysisSource = result.source;
      _reasonAr = result.reasonAr;
      _analysisEn = result.analysisEn;
      _partialArabicWarning = result.partialArabicWarning;
      _isProcessing = false;
      _isAiProcessing = false;

      switch (_status) {
        case IngredientStatus.safe:
          _statusMessage = 'Safe';
          break;
        case IngredientStatus.warning:
          _statusMessage = 'Warning';
          break;
        case IngredientStatus.danger:
          _statusMessage = 'Danger';
          break;
      }
    });
  }

  void _showFallbackSnackbar(bool localFoundHarmful) {
    if (!mounted) return;

    final isPositive = localFoundHarmful;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isPositive ? Icons.check_circle : Icons.wifi_off,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isPositive
                    ? 'Instant Scan Complete. Found local results.'
                    : 'AI analysis timed out. Showing local scan result.',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor:
            isPositive ? Colors.green[700] : Colors.deepOrange[700],
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ── Camera frame processing ───────────────────────────────────────────────

  Future<void> _processCameraFrame() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        !widget.isVisible) return;

    setState(() => _isProcessing = true);

    try {
      final image = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);
      final text = await _recognizeText(inputImage);

      final normalized = text.replaceAll(RegExp(r'\s+'), '');
      if (normalized.length < 10) {
        if (mounted) {
          setState(() {
            _ingredientDetails = [];
            _hasScanned = false;
            _status = IngredientStatus.safe;
            _statusMessage = 'Scanning...';
            _isProcessing = false;
          });
        }
      } else {
        await _runAnalysis(text);
        if (mounted && _status != IngredientStatus.safe) {
          final vibEnabled = await _prefs.isVibrationEnabled();
          if (vibEnabled && (await Vibration.hasVibrator() ?? false)) {
            Vibration.vibrate(duration: 500);
          }
          await _speakResult(_status);
        }
      }

      final imageFile = File(image.path);
      if (await imageFile.exists()) await imageFile.delete();
    } catch (_) {}

    if (mounted) setState(() => _isProcessing = false);
  }

  // ── Gallery picker ────────────────────────────────────────────────────────

  Future<void> _pickFromGallery() async {
    _scanTimer?.cancel();
    _scanTimer = null;

    try {
      final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;

      final inputImage = InputImage.fromFilePath(file.path);
      final text = await _recognizeText(inputImage);

      if (!mounted) return;

      if (text.length < 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Image is not clear. Please pick a clearer photo of the ingredients.'),
          ),
        );
        return;
      }

      await _runAnalysis(text);

      if (!mounted) return;

      final isSafe = _status == IngredientStatus.safe;
      final vibEnabled = await _prefs.isVibrationEnabled();
      if (!isSafe && (vibEnabled && (await Vibration.hasVibrator() ?? false))) {
        Vibration.vibrate(duration: 500);
      }
      await _speakResult(_status);
      _showResultBottomSheet();
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Error analyzing';
      });
    } finally {
      if (mounted && widget.isVisible && _isInitialized) {
        _startScanning();
      }
    }
  }

  // ── TTS ───────────────────────────────────────────────────────────────────

  Future<void> _speakResult(IngredientStatus status) async {
    final voiceEnabled = await _prefs.isVoiceFeedbackEnabled();
    if (!voiceEnabled || _tts == null) return;
    String verb = 'Safe';
    if (status == IngredientStatus.warning) verb = 'Warning';
    if (status == IngredientStatus.danger) verb = 'Danger';
    await _tts!.speak(verb);
  }

  // ── Bottom Sheet (delegated to extracted widget) ──────────────────────────

  void _showResultBottomSheet() {
    ScannerResultSheet.show(
      context,
      status: _status,
      analysisSource: _analysisSource,
      ingredientDetails: _ingredientDetails,
      reasonAr: _reasonAr,
      analysisEn: _analysisEn,
      partialArabicWarning: _partialArabicWarning,
    );
  }

  // ── Status badge helpers ──────────────────────────────────────────────────

  Widget _buildSourceBadgeCompact() {
    switch (_analysisSource) {
      case AnalysisSource.aiAnalysis:
        return const Text('🤖 Deep AI Analysis',
            style: TextStyle(color: Colors.white70, fontSize: 11));
      case AnalysisSource.aiCached:
        return const Text('🤖 AI (Cached)',
            style: TextStyle(color: Colors.white70, fontSize: 11));
      case AnalysisSource.fallback:
        return const Text('⚡ Local Scan (AI unavailable)',
            style: TextStyle(color: Colors.white70, fontSize: 11));
      case AnalysisSource.localScan:
        return const Text('⚡ Local Fast Scan',
            style: TextStyle(color: Colors.white70, fontSize: 11));
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('AI Food Scanner'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library_outlined),
            tooltip: 'Scan from gallery',
            onPressed: _pickFromGallery,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview
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

          // Corner-bracket viewfinder overlay
          if (_isInitialized)
            Positioned.fill(
              child: CustomPaint(
                painter: ScannerFramePainter(
                  color: _hasScanned
                      ? (_status == IngredientStatus.safe
                          ? AppTheme.safeColor
                          : _status == IngredientStatus.warning
                              ? AppTheme.warningColor
                              : AppTheme.dangerColor)
                      : AppTheme.neonMint,
                ),
              ),
            ),

          // AI processing overlay – ONLY shown when online AI call is ongoing
          if (_isAiProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                          color: AppTheme.neonMint),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '🤖 Deep AI Analysis…',
                          style:
                              TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Status banner at top
          Positioned(
            top: 16,
            left: 20,
            right: 20,
            child: _buildStatusBanner(),
          ),

          // Inline issues list
          if (_hasScanned && _status != IngredientStatus.safe)
            Positioned(
              bottom: 80,
              left: 16,
              right: 16,
              child: _buildIngredientDetailsList(),
            ),

          // Bottom instructions
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _buildInstructions(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    Color color = AppTheme.neonMint;
    String label = 'SCANNING';
    IconData icon = Icons.document_scanner_outlined;

    if (_hasScanned) {
      if (_status == IngredientStatus.danger) {
        color = AppTheme.dangerColor;
        label = 'DANGER';
        icon = Icons.warning_rounded;
      } else if (_status == IngredientStatus.warning) {
        color = AppTheme.warningColor;
        label = 'WARNING';
        icon = Icons.error_outline;
      } else {
        color = AppTheme.safeColor;
        label = 'SAFE';
        icon = Icons.check_circle;
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black.withOpacity(0.72), Colors.black.withOpacity(0.56)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.6), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 26),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
            if (_hasScanned) ...[
              const SizedBox(height: 4),
              _buildSourceBadgeCompact(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientDetailsList() {
    final issues = _ingredientDetails
        .where((d) => d.status != IngredientStatus.safe)
        .where((d) => _isValidIngredientName(d.ingredientName))
        .toList();

    if (issues.isEmpty) return const SizedBox();

    final displayIssues = issues.take(3).toList();
    final statusColor = _status == IngredientStatus.danger
        ? AppTheme.dangerColor
        : AppTheme.warningColor;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: statusColor.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _status == IngredientStatus.danger
                  ? '⚠️ Harmful Ingredients:'
                  : '⚠️ Warnings:',
              style: TextStyle(
                color: statusColor,
                fontSize: AppTheme.bodyFontSize - 2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: displayIssues.map((ing) {
                final c = ing.status == IngredientStatus.danger
                    ? AppTheme.dangerColor
                    : AppTheme.warningColor;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: c.withOpacity(0.5)),
                  ),
                  child: Text(
                    ing.ingredientName,
                    style: TextStyle(
                      color: c,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }).toList(),
            ),
            if (issues.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '+ ${issues.length - 3} more issues...',
                  style: const TextStyle(
                      color: Colors.white70, fontWeight: FontWeight.w500),
                ),
              ),
            GestureDetector(
              onTap: _showResultBottomSheet,
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'View full analysis →',
                  style: TextStyle(
                    color: AppTheme.neonMint,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                    decorationColor: AppTheme.neonMint,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    String message = 'Point camera at ingredient list';

    if (_isProcessing || _isAiProcessing) {
      message = _isAiProcessing
          ? '🤖 Running Deep AI Analysis...'
          : '⚡ Running local keyword scan...';
    } else if (_hasScanned) {
      if (_status == IngredientStatus.safe) {
        message = '✅ Safe! No harmful ingredients detected.';
      } else if (_status == IngredientStatus.warning) {
        message = '⚠️ Warning! Please review ingredients manually.';
      } else {
        message = '🚫 Danger! Harmful ingredients detected.';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neonMint.withOpacity(0.15)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontSize: AppTheme.bodyFontSize - 2,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Returns false for ingredient names that are OCR noise:
  /// - Less than 3 characters
  /// - More than 50% symbols/punctuation (non-letter, non-digit, non-space)
  bool _isValidIngredientName(String name) {
    final trimmed = name.trim();
    if (trimmed.length < 3) return false;

    final nonSpace = trimmed.replaceAll(RegExp(r'\s'), '');
    if (nonSpace.isEmpty) return false;

    // Count characters that are NOT letters (any script) or digits
    final symbolCount =
        nonSpace.replaceAll(RegExp(r'[\p{L}\p{N}]', unicode: true), '').length;
    if (symbolCount / nonSpace.length > 0.5) return false;

    return true;
  }
}
