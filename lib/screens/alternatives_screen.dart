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
    return SliverAppBar(
      pinned: true,
      expandedHeight: 120,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Smart Alternatives',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryColor, Color(0xFF0077FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Search Bar ─────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              style: const TextStyle(fontSize: AppTheme.bodyFontSize),
              decoration: InputDecoration(
                hintText: 'What are you craving today?',
                hintStyle: TextStyle(
                  fontSize: AppTheme.bodyFontSize,
                  color: Colors.grey.shade500,
                ),
                prefixIcon: const Icon(Icons.search, size: 26),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      const BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: _isLoading ? null : _search,
              borderRadius: BorderRadius.circular(16),
              child: const SizedBox(
                width: 52,
                height: 52,
                child: Icon(Icons.send_rounded, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Loading ────────────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppTheme.primaryColor),
          const SizedBox(height: 20),
          Text(
            'Finding healthy alternatives for\n"$_searchedFood"…',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTheme.bodyFontSize,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Empty state ────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restaurant_menu_rounded,
                size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Craving something?',
              style: TextStyle(
                fontSize: AppTheme.titleFontSize,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Type a food above and we\'ll suggest healthy alternatives that are safe for your condition.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppTheme.bodyFontSize,
                color: Colors.grey.shade500,
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
                style: const TextStyle(
                  fontSize: AppTheme.bodyFontSize,
                  fontWeight: FontWeight.w600,
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

  static const _icons = [
    Icons.looks_one_rounded,
    Icons.looks_two_rounded,
    Icons.looks_3_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        elevation: 2,
        shadowColor: AppTheme.primaryColor.withOpacity(0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Name row
              Row(
                children: [
                  Icon(
                    index <= 3 ? _icons[index - 1] : Icons.circle,
                    color: AppTheme.primaryColor,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
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
                  fontSize: AppTheme.bodyFontSize,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),

              // ── Why it's good
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.safeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.safeColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: AppTheme.safeColor, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Why it\'s good for you',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.safeColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            whyItsGood,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade800,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
