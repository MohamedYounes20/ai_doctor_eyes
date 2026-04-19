import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../app_theme.dart';
import '../models/medical_profile.dart';
import '../services/backup_service.dart';
import '../services/database_helper.dart';
import '../services/medical_analysis_service.dart';

/// Full-screen Medical Record and Data Management screen.
///
/// **Medical Record card** — upload a lab report image → Gemini Vision
/// extracts forbidden ingredients → displayed and persisted offline.
///
/// **Data Management card** — export / import a full SQLite backup as JSON.
class MedicalRecordScreen extends StatefulWidget {
  const MedicalRecordScreen({super.key});

  @override
  State<MedicalRecordScreen> createState() => _MedicalRecordScreenState();
}

class _MedicalRecordScreenState extends State<MedicalRecordScreen> {
  final MedicalAnalysisService _analysisService = MedicalAnalysisService();
  final BackupService _backupService = BackupService();

  MedicalProfile? _profile;
  bool _loadingProfile = true;
  bool _analyzingReport = false;
  bool _exportingBackup = false;
  bool _importingBackup = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ── Data Loading ────────────────────────────────────────────────────────────

  Future<void> _loadProfile() async {
    final profile = await DatabaseHelper.instance.getMedicalProfile();
    if (mounted) {
      setState(() {
        _profile = profile;
        _loadingProfile = false;
      });
    }
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  Future<void> _uploadLabReport() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() => _analyzingReport = true);
    try {
      final profile =
          await _analysisService.analyzeMedicalReport(File(picked.path));
      if (mounted) {
        setState(() => _profile = profile);
        _showSnackBar(
          '✅ Medical profile extracted and saved!',
          AppTheme.safeColor,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          e.toString().replaceFirst('Exception: ', ''),
          AppTheme.dangerColor,
        );
      }
    } finally {
      if (mounted) setState(() => _analyzingReport = false);
    }
  }

  Future<void> _exportBackup() async {
    setState(() => _exportingBackup = true);
    try {
      final path = await _backupService.exportBackup();
      if (mounted) {
        _showSnackBar('💾 Backup saved to:\n$path', AppTheme.safeColor,
            duration: const Duration(seconds: 6));
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          e.toString().replaceFirst('Exception: ', ''),
          AppTheme.dangerColor,
        );
      }
    } finally {
      if (mounted) setState(() => _exportingBackup = false);
    }
  }

  Future<void> _importBackup() async {
    setState(() => _importingBackup = true);
    try {
      await _backupService.importBackup();
      await _loadProfile(); // Reload to show restored profile
      if (mounted) {
        _showSnackBar('✅ Backup restored successfully!', AppTheme.safeColor);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          e.toString().replaceFirst('Exception: ', ''),
          AppTheme.dangerColor,
        );
      }
    } finally {
      if (mounted) setState(() => _importingBackup = false);
    }
  }

  void _showSnackBar(String message, Color color,
      {Duration duration = const Duration(seconds: 4)}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 14)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.spaceBlack : AppTheme.icyWhite;

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(isDark),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildMedicalRecordCard(isDark),
                const SizedBox(height: 16),
                _buildDataManagementCard(isDark),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── App Bar ─────────────────────────────────────────────────────────────────

  Widget _buildAppBar(bool isDark) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 110,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 56, bottom: 14),
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Medical & Data',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white),
            ),
            Text(
              'Lab records & backup',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF0D1B35), const Color(0xFF0F2545)]
                  : [AppTheme.navyColor, const Color(0xFF243B6E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
    );
  }

  // ── Medical Record Card ─────────────────────────────────────────────────────

  Widget _buildMedicalRecordCard(bool isDark) {
    final textColor = isDark ? Colors.white : AppTheme.navyColor;
    final subColor =
        isDark ? Colors.white.withOpacity(0.6) : Colors.grey.shade600;
    final accent = isDark ? AppTheme.neonMint : AppTheme.navyColor;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.biotech_rounded, color: accent, size: 22),
            ),
            const SizedBox(width: 10),
            Text(
              'Medical Lab Record',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
            ),
          ]),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 44),
            child: Text(
              'Upload a lab report and AI will extract\nyour personal forbidden ingredients.',
              style: TextStyle(fontSize: 12, color: subColor),
            ),
          ),
          const SizedBox(height: 16),

          // Profile display or empty state
          if (_loadingProfile)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(color: accent),
              ),
            )
          else if (_profile != null)
            _buildProfileDisplay(_profile!, isDark, textColor, subColor, accent)
          else
            _buildEmptyProfileState(isDark, subColor),

          const SizedBox(height: 16),

          // Upload button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _analyzingReport ? null : _uploadLabReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: isDark ? AppTheme.spaceBlack : Colors.white,
                disabledBackgroundColor: accent.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13)),
                elevation: 0,
              ),
              icon: _analyzingReport
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isDark ? AppTheme.spaceBlack : Colors.white,
                      ),
                    )
                  : const Icon(Icons.upload_file_rounded, size: 20),
              label: Text(
                _analyzingReport
                    ? 'Analysing with AI…'
                    : _profile != null
                        ? 'Update Lab Report'
                        : 'Upload Lab Report',
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDisplay(
    MedicalProfile profile,
    bool isDark,
    Color textColor,
    Color subColor,
    Color accent,
  ) {
    final severityColor = profile.severity == 'High'
        ? AppTheme.dangerColor
        : profile.severity == 'Medium'
            ? AppTheme.warningColor
            : AppTheme.safeColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Condition row
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Detected Condition',
                      style: TextStyle(fontSize: 11, color: subColor)),
                  const SizedBox(height: 2),
                  Text(
                    profile.condition,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textColor),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: severityColor.withOpacity(0.12),
                border:
                    Border.all(color: severityColor.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                profile.severity,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: severityColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Forbidden keywords
        Text('Forbidden Ingredients',
            style: TextStyle(fontSize: 11, color: subColor)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: profile.forbiddenKeywords
              .map((kw) => _KeywordChip(label: kw, isDark: isDark))
              .toList(),
        ),
        const SizedBox(height: 8),

        // Last updated
        Text(
          'Last updated: ${_formatDate(profile.lastUpdated)}',
          style: TextStyle(fontSize: 11, color: subColor),
        ),
      ],
    );
  }

  Widget _buildEmptyProfileState(bool isDark, Color subColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Text('🧪', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No lab report uploaded yet.\nUpload one to activate personalised Critical alerts.',
              style: TextStyle(fontSize: 13, color: subColor, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ── Data Management Card ────────────────────────────────────────────────────

  Widget _buildDataManagementCard(bool isDark) {
    final textColor = isDark ? Colors.white : AppTheme.navyColor;
    final subColor =
        isDark ? Colors.white.withOpacity(0.6) : Colors.grey.shade600;
    final accent = isDark ? AppTheme.neonMint : AppTheme.navyColor;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.import_export_rounded, color: accent, size: 22),
            ),
            const SizedBox(width: 10),
            Text(
              'Data Management',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
            ),
          ]),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 44),
            child: Text(
              'Export or restore all your health data\nas a JSON file for any device.',
              style: TextStyle(fontSize: 12, color: subColor),
            ),
          ),
          const SizedBox(height: 16),

          // Info banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.neonMint.withOpacity(isDark ? 0.08 : 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppTheme.neonMint.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_outline_rounded,
                    color: AppTheme.neonMint, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'All data stays on your device. No cloud servers involved.',
                    style: TextStyle(fontSize: 12, color: subColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Export button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _exportingBackup ? null : _exportBackup,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: isDark ? AppTheme.spaceBlack : Colors.white,
                disabledBackgroundColor: accent.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13)),
                elevation: 0,
              ),
              icon: _exportingBackup
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                              isDark ? AppTheme.spaceBlack : Colors.white))
                  : const Icon(Icons.upload_rounded, size: 20),
              label: Text(
                _exportingBackup ? 'Exporting…' : 'Export Backup',
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Import button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _importingBackup ? null : _importBackup,
              style: OutlinedButton.styleFrom(
                foregroundColor: accent,
                side: BorderSide(color: accent.withOpacity(0.6)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13)),
              ),
              icon: _importingBackup
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: accent))
                  : const Icon(Icons.download_rounded, size: 20),
              label: Text(
                _importingBackup ? 'Restoring…' : 'Import Backup',
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.navyCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.25)
                : AppTheme.navyColor.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _KeywordChip extends StatelessWidget {
  final String label;
  final bool isDark;
  const _KeywordChip({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.dangerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AppTheme.dangerColor.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.dangerColor,
        ),
      ),
    );
  }
}
