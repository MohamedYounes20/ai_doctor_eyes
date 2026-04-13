import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../services/ai_alternatives_service.dart';

/// Screen where users type a food craving and receive AI-generated healthy
/// alternatives personalised to their health profile.
class AlternativesScreen extends StatefulWidget {
  const AlternativesScreen({super.key});

  @override
  State<AlternativesScreen> createState() => _AlternativesScreenState();
}

class _AlternativesScreenState extends State<AlternativesScreen> {
  final AiAlternativesService _service = AiAlternativesService();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isLoading = false;
  List<Map<String, String>>? _alternatives;
  String? _searchedFood;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    _focusNode.unfocus();
    setState(() {
      _isLoading = true;
      _alternatives = null;
      _searchedFood = query;
    });

    try {
      final results = await _service.getAlternatives(query);
      if (mounted) setState(() => _alternatives = results);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
              style: const TextStyle(fontSize: 16),
            ),
            backgroundColor: AppTheme.dangerColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildSearchBar()),
          if (_isLoading) SliverFillRemaining(child: _buildLoading()),
          if (!_isLoading && _alternatives != null) _buildResults(),
          if (!_isLoading && _alternatives == null)
            SliverFillRemaining(child: _buildEmptyState()),
        ],
      ),
    );
  }

  // ─── App Bar ────────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SliverAppBar(
      pinned: true,
      expandedHeight: 130,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 14),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Smart Alternatives',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            Text(
              'Healthier swaps for your cravings',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF0D1B35), const Color(0xFF0B2A40)]
                  : [AppTheme.navyColor, const Color(0xFF243B6E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 20, top: 20),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.neonMint.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text('AI', style: TextStyle(color: AppTheme.neonMint, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Search Bar ─────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.3)
                        : AppTheme.navyColor.withOpacity(0.06),
                    blurRadius: 12,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
                style: TextStyle(
                    fontSize: AppTheme.bodyFontSize,
                    color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Search healthy alternatives...',
                  hintStyle: TextStyle(
                    fontSize: AppTheme.bodyFontSize - 2,
                    color: isDark
                        ? Colors.white.withOpacity(0.38)
                        : Colors.grey.shade500,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 22,
                    color: isDark
                        ? Colors.white.withOpacity(0.5)
                        : Colors.grey.shade500,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF1A2C4A)
                      : Colors.grey.shade100,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(
                        color: isDark
                            ? AppTheme.neonMint
                            : AppTheme.navyColor,
                        width: 1.5),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: isDark ? AppTheme.neonMint : AppTheme.navyColor,
            borderRadius: BorderRadius.circular(30),
            child: InkWell(
              onTap: _isLoading ? null : _search,
              borderRadius: BorderRadius.circular(30),
              child: SizedBox(
                width: 50,
                height: 50,
                child: Icon(
                  Icons.send_rounded,
                  color: isDark ? AppTheme.spaceBlack : Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Loading ────────────────────────────────────────────────────────────────

  Widget _buildLoading() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
              color: isDark ? AppTheme.neonMint : AppTheme.navyColor),
          const SizedBox(height: 20),
          Text(
            'Finding healthy alternatives for\n"$_searchedFood"…',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTheme.bodyFontSize,
              color: isDark
                  ? Colors.white.withOpacity(0.6)
                  : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Empty state ────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.neonMint.withOpacity(0.08)
                    : AppTheme.mintColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.restaurant_menu_rounded,
                size: 48,
                color: isDark
                    ? AppTheme.neonMint.withOpacity(0.6)
                    : AppTheme.mintColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Craving something?',
              style: TextStyle(
                fontSize: AppTheme.titleFontSize,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.navyColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Type a food above and we\'ll suggest healthy alternatives that are safe for your condition.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppTheme.bodyFontSize - 2,
                color: isDark
                    ? Colors.white.withOpacity(0.5)
                    : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Results ────────────────────────────────────────────────────────────────

  SliverList _buildResults() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                'Healthy alternatives for "$_searchedFood"',
                style: TextStyle(
                  fontSize: AppTheme.bodyFontSize - 2,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.7)
                      : Colors.grey.shade700,
                ),
              ),
            );
          }

          final alt = _alternatives![index - 1];
          return _AlternativeCard(
            index: index,
            name: alt['name'] ?? '',
            description: alt['description'] ?? '',
            whyItsGood: alt['why_its_good'] ?? '',
          );
        },
        childCount: (_alternatives?.length ?? 0) + 1, // +1 for header
      ),
    );
  }
}

// ─── Alternative Card ─────────────────────────────────────────────────────────

class _AlternativeCard extends StatelessWidget {
  const _AlternativeCard({
    required this.index,
    required this.name,
    required this.description,
    required this.whyItsGood,
  });

  final int index;
  final String name;
  final String description;
  final String whyItsGood;

  // Emoji food placeholders cycling per card index
  static const _emojis = ['🥦', '🥑', '🫐', '🥕', '🍓', '🌿', '🥝', '🍋'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.navyCard : Colors.white;
    final descColor = isDark
        ? Colors.white.withOpacity(0.65)
        : Colors.grey.shade700;

    final emoji = _emojis[(index - 1) % _emojis.length];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : AppTheme.navyColor.withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Name row with emoji
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.neonMint.withOpacity(0.1)
                          : AppTheme.mintColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.navyColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ── Description
              Text(
                description,
                style: TextStyle(
                  fontSize: AppTheme.bodyFontSize - 2,
                  color: descColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),

              // ── "Why it's good" pill tag
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.neonMint.withOpacity(0.15)
                      : AppTheme.mintColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isDark
                        ? AppTheme.neonMint.withOpacity(0.3)
                        : AppTheme.mintColor.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: isDark ? AppTheme.neonMint : AppTheme.mintColor,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Why it\'s good for you',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppTheme.neonMint : AppTheme.mintColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  whyItsGood,
                  style: TextStyle(
                    fontSize: AppTheme.bodyFontSize - 3,
                    color: descColor,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
