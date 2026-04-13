import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_theme.dart';
import '../services/ai_alternatives_service.dart';
import '../services/restaurant_locator_service.dart';

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
                  child: Text('AI',
                      style: TextStyle(
                          color: AppTheme.neonMint,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
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

  static const _emojis = ['🥦', '🥑', '🫐', '🥕', '🍓', '🌿', '🥝', '🍋'];

  // ── "Find Nearby & Order" bottom sheet ──────────────────────────────────────

  void _showNearbyRestaurants(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? AppTheme.navyCard : Colors.white;
    final accentColor = isDark ? AppTheme.neonMint : AppTheme.navyColor;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: sheetBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => _RestaurantBottomSheet(
        dishName: name,
        isDark: isDark,
        sheetBg: sheetBg,
        accentColor: accentColor,
      ),
    );
  }

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
              // ── Name row with emoji ────────────────────────────────────────
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
                      child: Text(emoji,
                          style: const TextStyle(fontSize: 24)),
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

              // ── Description ────────────────────────────────────────────────
              Text(
                description,
                style: TextStyle(
                  fontSize: AppTheme.bodyFontSize - 2,
                  color: descColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),

              // ── "Why it's good" pill ───────────────────────────────────────
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
                          color:
                              isDark ? AppTheme.neonMint : AppTheme.mintColor,
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

              const SizedBox(height: 16),

              // ── "Find Nearby & Order" CTA ──────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => _showNearbyRestaurants(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark ? AppTheme.neonMint : AppTheme.navyColor,
                    foregroundColor:
                        isDark ? AppTheme.spaceBlack : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.location_on_rounded, size: 20),
                  label: const Text(
                    'Find Nearby & Order',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
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

// ─── Restaurant Bottom Sheet ──────────────────────────────────────────────────

class _RestaurantBottomSheet extends StatefulWidget {
  final String dishName;
  final bool isDark;
  final Color sheetBg;
  final Color accentColor;

  const _RestaurantBottomSheet({
    required this.dishName,
    required this.isDark,
    required this.sheetBg,
    required this.accentColor,
  });

  @override
  State<_RestaurantBottomSheet> createState() => _RestaurantBottomSheetState();
}

class _RestaurantBottomSheetState extends State<_RestaurantBottomSheet> {
  final RestaurantLocatorService _locator = RestaurantLocatorService();

  bool _isSearching = true;
  List<RestaurantResult> _restaurants = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchRestaurants();
  }

  Future<void> _fetchRestaurants() async {
    try {
      final results = await _locator.findNearby(widget.dishName);
      if (mounted) {
        setState(() {
          _restaurants = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _openAffiliateLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open the link. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? Colors.white : AppTheme.navyColor;
    final subColor = widget.isDark
        ? Colors.white.withOpacity(0.55)
        : Colors.grey.shade600;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      maxChildSize: 0.9,
      minChildSize: 0.35,
      builder: (_, scrollController) => Container(
        color: widget.sheetBg,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: ListView(
            controller: scrollController,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: widget.isDark
                        ? Colors.white.withOpacity(0.2)
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  Icon(Icons.location_on_rounded,
                      color: widget.accentColor, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Nearby restaurants serving\n"${widget.dishName}"',
                      style: TextStyle(
                        fontSize: AppTheme.bodyFontSize,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Commission applied on your order — supporting free AI features 💚',
                style: TextStyle(fontSize: 12, color: subColor),
              ),
              const SizedBox(height: 20),

              // ── Content ────────────────────────────────────────────────────
              if (_isSearching)
                _buildLoadingState(subColor)
              else if (_error != null)
                _buildErrorState(_error!, textColor, subColor)
              else if (_restaurants.isEmpty)
                _buildNoResultsState(subColor)
              else
                ..._restaurants.map(
                  (r) => _RestaurantTile(
                    restaurant: r,
                    isDark: widget.isDark,
                    accentColor: widget.accentColor,
                    onOrderTap: () => _openAffiliateLink(r.affiliateUrl),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(Color subColor) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            CircularProgressIndicator(color: widget.accentColor),
            const SizedBox(height: 16),
            Text(
              'Finding restaurants near you…',
              style: TextStyle(color: subColor, fontSize: 14),
            ),
          ],
        ),
      );

  Widget _buildErrorState(String error, Color textColor, Color subColor) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.dangerColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: AppTheme.dangerColor.withOpacity(0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error_outline,
                    color: AppTheme.dangerColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Could not find restaurants',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(error,
                style: TextStyle(fontSize: 13, color: subColor, height: 1.4)),
          ],
        ),
      );

  Widget _buildNoResultsState(Color subColor) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            const Text('🍽️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'No restaurants found nearby',
              style: TextStyle(color: subColor, fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}

// ─── Restaurant Tile ──────────────────────────────────────────────────────────

class _RestaurantTile extends StatelessWidget {
  final RestaurantResult restaurant;
  final bool isDark;
  final Color accentColor;
  final VoidCallback onOrderTap;

  const _RestaurantTile({
    required this.restaurant,
    required this.isDark,
    required this.accentColor,
    required this.onOrderTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.grey.shade50;
    final textColor = isDark ? Colors.white : AppTheme.navyColor;
    final subColor = isDark
        ? Colors.white.withOpacity(0.55)
        : Colors.grey.shade600;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Restaurant name + map icon row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.restaurant_rounded,
                    color: accentColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      restaurant.address,
                      style:
                          TextStyle(fontSize: 12, color: subColor, height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Commission badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.safeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppTheme.safeColor.withOpacity(0.35)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_rounded,
                    color: AppTheme.safeColor, size: 13),
                SizedBox(width: 4),
                Text(
                  'AI Doctor Eyes Affiliate Partner',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.safeColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Order Now button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: onOrderTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor:
                    isDark ? AppTheme.spaceBlack : Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: const Icon(Icons.open_in_new_rounded, size: 17),
              label: const Text(
                'Order Now (Commission Applied)',
                style:
                    TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
