import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../app_theme.dart';
import '../core/constants/condition_config.dart';
import '../main.dart' show selectedConditionsNotifier;
import '../services/preferences_service.dart';
import '../widgets/modern_header.dart';
import 'medical_record_screen.dart';
import 'selection_screen.dart';
import 'welcome_screen.dart';

/// Profile tab — card-based dashboard layout with avatar photo picker,
/// member-since date, and clean section cards.
class ProfileScreen extends StatefulWidget {
  final VoidCallback? onUpdateConditions;
  final ValueNotifier<int>? scanRefreshTrigger;

  const ProfileScreen(
      {super.key, this.onUpdateConditions, this.scanRefreshTrigger});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final PreferencesService _prefs = PreferencesService();
  final ImagePicker _picker = ImagePicker();

  String? _fullName;
  int? _yearOfBirth;
  String? _avatarPath;
  String _memberSince = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    widget.scanRefreshTrigger?.addListener(_load);
  }

  @override
  void dispose() {
    widget.scanRefreshTrigger?.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final name = await _prefs.getFullName();
    final year = await _prefs.getYearOfBirth();
    final avatar = await _prefs.getAvatarPath();
    final since = await _prefs.getMemberSince();
    if (mounted) {
      setState(() {
        _fullName = name ?? 'User';
        _yearOfBirth = year;
        _avatarPath = avatar;
        _memberSince = since;
        _loading = false;
      });
    }
  }

  Future<void> _pickAvatar() async {
    try {
      final XFile? file =
          await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (file == null || !mounted) return;
      await _prefs.saveAvatarPath(file.path);
      setState(() => _avatarPath = file.path);
    } catch (_) {}
  }

  void _refresh() => _load();

  // ── Helpers ───────────────────────────────────────────────────────────────

  String get _initials {
    final name = _fullName ?? '';
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  String get _ageLabel {
    if (_yearOfBirth == null) return '';
    final age = _prefs.getAgeFromYearOfBirth(_yearOfBirth!);
    return age != null ? 'Age $age' : '';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                color: isDark ? AppTheme.neonMint : AppTheme.navyColor,
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: isDark ? AppTheme.neonMint : AppTheme.navyColor,
              child: CustomScrollView(
                slivers: [
                  // ── Header ─────────────────────────────────────────────
                  SliverToBoxAdapter(child: _buildPageHeader()),
                  // ── User Info Card ─────────────────────────────────────
                  SliverToBoxAdapter(child: _buildUserCard(isDark)),
                  // ── Active Conditions Card ─────────────────────────────
                  SliverToBoxAdapter(child: _buildConditionsCard(isDark)),
                  // ── Medical & Data Card ────────────────────────────────
                  SliverToBoxAdapter(child: _buildMedicalCard(isDark)),
                  // Bottom padding
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            ),
    );
  }

  // ── Page header ───────────────────────────────────────────────────────────

  Widget _buildPageHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 56, 20, 8),
      child: ModernHeader(
        firstWord: 'Your',
        secondWord: 'Profile',
        hasLineBreak: false,
      ),
    );
  }

  // ── User info card ────────────────────────────────────────────────────────

  Widget _buildUserCard(bool isDark) {
    final cardBg = isDark ? AppTheme.darkSurface : Colors.white;
    final subtleText =
        isDark ? Colors.white.withOpacity(0.5) : Colors.grey.shade500;
    final nameColor = isDark ? Colors.white : AppTheme.navyColor;

    return _SectionCard(
      isDark: isDark,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          // ── Avatar with camera badge ──────────────────────────────────
          GestureDetector(
            onTap: _pickAvatar,
            child: Stack(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppTheme.neonMint : AppTheme.mintColor,
                      width: 2.5,
                    ),
                  ),
                  child: ClipOval(
                    child: _avatarPath != null &&
                            File(_avatarPath!).existsSync()
                        ? Image.file(
                            File(_avatarPath!),
                            fit: BoxFit.cover,
                            width: 80,
                            height: 80,
                          )
                        : CircleAvatar(
                            radius: 40,
                            backgroundColor: (isDark
                                    ? AppTheme.neonMint
                                    : AppTheme.mintColor)
                                .withOpacity(0.15),
                            child: Text(
                              _initials,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppTheme.neonMint
                                    : AppTheme.mintColor,
                              ),
                            ),
                          ),
                  ),
                ),
                // Camera badge
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color:
                          isDark ? AppTheme.neonMint : AppTheme.navyColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: cardBg, width: 2),
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 13,
                      color: isDark ? AppTheme.spaceBlack : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // ── Name / age / member since ─────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _fullName ?? 'User',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: nameColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Edit pencil
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const WelcomeScreen(isEditing: true),
                          ),
                        );
                        _refresh();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: (isDark
                                  ? AppTheme.neonMint
                                  : AppTheme.navyColor)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.edit_rounded,
                          size: 16,
                          color:
                              isDark ? AppTheme.neonMint : AppTheme.navyColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_ageLabel.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _ageLabel,
                    style: TextStyle(
                      fontSize: 14,
                      color: subtleText,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      size: 13,
                      color: subtleText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Member since $_memberSince',
                      style: TextStyle(fontSize: 13, color: subtleText),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Active conditions card ────────────────────────────────────────────────

  Widget _buildConditionsCard(bool isDark) {
    return _SectionCard(
      isDark: isDark,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            label: 'Active Health Conditions',
            icon: Icons.favorite_rounded,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<List<String>>(
            valueListenable: selectedConditionsNotifier,
            builder: (context, conditionNames, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (conditionNames.isEmpty)
                    Text(
                      'No conditions selected',
                      style: TextStyle(
                        fontSize: AppTheme.bodyFontSize,
                        color: isDark ? Colors.white54 : Colors.grey,
                      ),
                    )
                  else
                    ...conditionNames.map(
                      (name) => _buildConditionRow(name, isDark),
                    ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const SelectionScreen(isUpdateMode: true),
                        ),
                      );
                      _refresh();
                      widget.onUpdateConditions?.call();
                    },
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: Text(
                      conditionNames.isEmpty
                          ? 'Select Conditions'
                          : 'Update My Conditions',
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Medical & Data card ───────────────────────────────────────────────────

  Widget _buildMedicalCard(bool isDark) {
    return _SectionCard(
      isDark: isDark,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            label: 'Medical & Data',
            icon: Icons.folder_special_rounded,
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _MedicalTile(
            icon: Icons.medical_information_rounded,
            title: 'Lab Report & Backup',
            subtitle: 'Upload lab results • Export & Import data',
            isDark: isDark,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MedicalRecordScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Condition row ─────────────────────────────────────────────────────────

  Widget _buildConditionRow(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(emojiForCondition(text),
              style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: AppTheme.bodyFontSize,
                color: isDark ? Colors.white : AppTheme.navyColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

/// A clean card container used for all sections.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.child,
    required this.isDark,
    this.margin,
  });

  final Widget child;
  final bool isDark;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.07)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.25)
                : Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Section title row with accent icon.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.label,
    required this.icon,
    required this.isDark,
  });

  final String label;
  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppTheme.neonMint : AppTheme.navyColor;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: accent),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppTheme.navyColor,
          ),
        ),
      ],
    );
  }
}

/// Clean list tile for the Medical & Data card.
class _MedicalTile extends StatelessWidget {
  const _MedicalTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppTheme.neonMint : AppTheme.navyColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppTheme.navyColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? Colors.white.withOpacity(0.45)
                          : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color:
                  isDark ? Colors.white.withOpacity(0.3) : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
