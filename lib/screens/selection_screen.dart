import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../core/constants/condition_config.dart';
import '../main.dart' show selectedConditionsNotifier;
import '../models/health_condition.dart';
import '../services/preferences_service.dart';
import 'main_parent_screen.dart';

/// Selection Screen: Grid layout, Navy/Mint theme.
/// Navigates to MainParentScreen when done, or back if in update mode.
/// Supports multiple selection of conditions.
class SelectionScreen extends StatefulWidget {
  final bool isUpdateMode;

  const SelectionScreen({super.key, this.isUpdateMode = false});

  @override
  State<SelectionScreen> createState() => _SelectionScreenState();
}

// Emoji + color config sourced from shared condition_config.dart

class _SelectionScreenState extends State<SelectionScreen> {
  final PreferencesService _prefs = PreferencesService();
  final Set<HealthCondition> _selectedConditions = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingConditions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingConditions() async {
    final conditions = await _prefs.getHealthConditions();
    if (mounted) {
      setState(() {
        _selectedConditions.clear();
        _selectedConditions.addAll(conditions);
      });
    }
  }

  Future<void> _handleGetStarted() async {
    if (_selectedConditions.isEmpty || _loading) return;
    setState(() => _loading = true);
    final ok = await _prefs.saveHealthConditions(_selectedConditions.toList());
    if (ok && mounted) {
      // Update global notifier so Profile screen reacts instantly
      selectedConditionsNotifier.value =
          _selectedConditions.map((c) => c.displayName).toList();
      if (!widget.isUpdateMode) await _prefs.setOnboardingCompleted(true);
      if (widget.isUpdateMode) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainParentScreen()),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  void _toggleCondition(HealthCondition condition) {
    setState(() {
      if (_selectedConditions.contains(condition)) {
        _selectedConditions.remove(condition);
      } else {
        _selectedConditions.add(condition);
      }
    });
  }

  List<ConditionVisual> get _filteredConditions {
    if (_searchQuery.isEmpty) return conditionVisuals;
    final q = _searchQuery.toLowerCase();
    return conditionVisuals
        .where((entry) =>
            entry.condition.displayName.toLowerCase().contains(q) ||
            entry.condition.description.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.spaceBlack : AppTheme.icyWhite;
    final filtered = _filteredConditions;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Select Your Conditions'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header + Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Your Conditions',
                    style:
                        Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Choose one or more health conditions to personalize your food scanning experience',
                    style: TextStyle(
                      fontSize: AppTheme.bodyFontSize - 2,
                      color: isDark
                          ? Colors.white.withOpacity(0.55)
                          : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Real-time search bar
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v.trim()),
                    style: TextStyle(
                      fontSize: AppTheme.bodyFontSize - 2,
                      color: isDark ? Colors.white : AppTheme.navyColor,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search conditions…',
                      hintStyle: TextStyle(
                        color: isDark
                            ? Colors.white38
                            : Colors.grey.shade400,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: isDark ? AppTheme.neonMint : AppTheme.navyColor,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.close,
                                color: isDark
                                    ? Colors.white38
                                    : Colors.grey.shade500,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDark
                          ? AppTheme.navyCard
                          : Colors.white,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.grey.shade200,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppTheme.neonMint
                              : AppTheme.navyColor,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Condition grid — grows/shrinks, no fixed height overflow
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '🔍',
                            style: const TextStyle(fontSize: 48),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No conditions match "$_searchQuery"',
                            style: TextStyle(
                              fontSize: AppTheme.bodyFontSize - 2,
                              color: isDark
                                  ? Colors.white54
                                  : Colors.grey.shade500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.05,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final cv = filtered[index];
                        return _ConditionCard(
                          condition: cv.condition,
                          emoji: cv.emoji,
                          color: cv.color,
                          selected: _selectedConditions.contains(cv.condition),
                          onTap: () => _toggleCondition(cv.condition),
                          isDark: isDark,
                        );
                      },
                    ),
            ),

            // ── Bottom action area
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed:
                          _selectedConditions.isNotEmpty && !_loading
                              ? _handleGetStarted
                              : null,
                      child: Text(
                        _loading ? 'Saving...' : 'Get Started',
                        style: const TextStyle(
                          fontSize: AppTheme.bodyFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (_selectedConditions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Please select at least one condition',
                        style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? Colors.white.withOpacity(0.4)
                                : Colors.grey.shade500),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConditionCard extends StatelessWidget {
  final HealthCondition condition;
  final String emoji;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  const _ConditionCard({
    required this.condition,
    required this.emoji,
    required this.color,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark
        ? (selected ? AppTheme.navyColor : AppTheme.navyCard)
        : Colors.white;
    final selectedBorderColor =
        isDark ? AppTheme.neonMint : AppTheme.navyColor;
    final unselBorderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.grey.shade200;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? selectedBorderColor : unselBorderColor,
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(selected ? 0.35 : 0.2)
                  : AppTheme.navyColor.withOpacity(selected ? 0.12 : 0.04),
              blurRadius: selected ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Emoji icon in a colored circle
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.13),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  condition.displayName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.navyColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  condition.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? Colors.white.withOpacity(0.5)
                        : Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            if (selected)
              Positioned(
                top: 0,
                right: 0,
                child: CircleAvatar(
                  radius: 10,
                  backgroundColor:
                      isDark ? AppTheme.neonMint : AppTheme.navyColor,
                  child: Icon(
                    Icons.check,
                    color: isDark ? AppTheme.spaceBlack : Colors.white,
                    size: 13,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
