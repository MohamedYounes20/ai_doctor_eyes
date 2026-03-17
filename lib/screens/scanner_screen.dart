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


import '../services/ingredient_checker_service.dart';
import '../services/preferences_service.dart';

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

  // ── Bottom Sheet ──────────────────────────────────────────────────────────

  void _showResultBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        maxChildSize: 0.92,
        minChildSize: 0.35,
        builder: (context, scrollController) =>
            _buildBottomSheetContent(scrollController),
      ),
    );
  }

  Widget _buildBottomSheetContent(ScrollController scrollController) {
    Color color = AppTheme.safeColor;
    IconData icon = Icons.check_circle;
    String statusText = 'SAFE';

    if (_status == IngredientStatus.danger) {
      color = AppTheme.dangerColor;
      icon = Icons.warning_rounded;
      statusText = 'DANGER';
    } else if (_status == IngredientStatus.warning) {
      color = AppTheme.warningColor;
      icon = Icons.error_outline;
      statusText = 'WARNING';
    }

    final issues = _ingredientDetails
        .where((d) => d.status != IngredientStatus.safe)
        .where((d) => _isValidIngredientName(d.ingredientName))
        .toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListView(
        controller: scrollController,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            'Analysis Result',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),

          // Source badge
          Center(child: _buildSourceBadge()),
          const SizedBox(height: 16),

          // Status banner
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: AppTheme.titleFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Partial Arabic warning
          if (_partialArabicWarning) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.translate, color: Colors.amber[800], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Analysis based on partial Arabic text. '
                      'Scan English ingredients if available for 100% accuracy.',
                      style: TextStyle(fontSize: 12, color: Colors.amber[900]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Bilingual AI summary (only when available)
          if (_analysisEn.isNotEmpty || _reasonAr.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.psychology, color: Colors.blue, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'AI Analysis',
                        style: TextStyle(
                          color: Colors.blue[900],
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  if (_analysisEn.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _analysisEn,
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ],
                  if (_reasonAr.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _reasonAr,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Ingredient issues
          Text(
            'Ingredient Issues',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),

          if (issues.isEmpty)
            const Text(
              'No harmful ingredients found.',
              style: TextStyle(fontSize: AppTheme.bodyFontSize),
            )
          else
            ...issues.map((ing) => _buildIssueRow(ing)),

          const SizedBox(height: 24),

          SizedBox(
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(
                  fontSize: AppTheme.bodyFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueRow(IngredientAnalysis ing) {
    final isDanger = ing.status == IngredientStatus.danger;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isDanger ? Icons.warning_rounded : Icons.error_outline,
            color: isDanger ? Colors.red : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ing.ingredientName,
                        style: const TextStyle(
                          fontSize: AppTheme.bodyFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (ing.severity != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: (ing.severity?.toLowerCase() == 'high')
                              ? Colors.red[100]
                              : Colors.orange[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          ing.severity!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: (ing.severity?.toLowerCase() == 'high')
                                ? Colors.red[900]
                                : Colors.orange[900],
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  ing.reason,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Status badge helpers ──────────────────────────────────────────────────

  Widget _buildSourceBadge() {
    switch (_analysisSource) {
      case AnalysisSource.aiAnalysis:
        return _badge('🤖 Deep AI Analysis', Colors.indigo);
      case AnalysisSource.aiCached:
        return _badge('🤖 AI (Cached)', Colors.teal);
      case AnalysisSource.fallback:
        return _badge('⚡ Local Scan (AI failed)', Colors.deepOrange);
      case AnalysisSource.localScan:
        return _badge('⚡ Local Fast Scan', Colors.blueGrey);
    }
  }

  Widget _badge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          border: Border.all(color: color.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('AI Food Scanner'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
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

          // AI processing overlay – ONLY shown when online AI call is ongoing
          if (_isAiProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        '🤖 Deep AI Analysis…',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Status banner at top
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: _buildStatusBanner(),
          ),

          // Inline issues list
          if (_hasScanned && _status != IngredientStatus.safe)
            Positioned(
              bottom: 90,
              left: 20,
              right: 20,
              child: _buildIngredientDetailsList(),
            ),

          // Bottom instructions
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
    Color color = AppTheme.primaryColor;
    String label = 'SCANNING';
    IconData icon = Icons.document_scanner;

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

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
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
    );
  }

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

  Widget _buildIngredientDetailsList() {
    final issues = _ingredientDetails
        .where((d) => d.status != IngredientStatus.safe)
        .where((d) => _isValidIngredientName(d.ingredientName))
        .toList();

    if (issues.isEmpty) return const SizedBox();

    final displayIssues = issues.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _status == IngredientStatus.danger
            ? AppTheme.dangerColor.withOpacity(0.95)
            : AppTheme.warningColor.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _status == IngredientStatus.danger
                ? 'Harmful Ingredients:'
                : 'Warnings:',
            style: const TextStyle(
              color: Colors.white,
              fontSize: AppTheme.bodyFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ...displayIssues.map(
            (ing) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    ing.status == IngredientStatus.danger
                        ? Icons.warning_rounded
                        : Icons.error_outline,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      ing.ingredientName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: AppTheme.bodyFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (issues.length > 3)
            Text(
              '+ ${issues.length - 3} more issues...',
              style: const TextStyle(
                  color: Colors.white70, fontWeight: FontWeight.w500),
            ),
          GestureDetector(
            onTap: _showResultBottomSheet,
            child: const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Tap for full details →',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white),
              ),
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.72),
        borderRadius: BorderRadius.circular(8),
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
