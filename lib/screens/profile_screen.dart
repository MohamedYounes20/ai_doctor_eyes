import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/health_condition.dart';
import '../models/scan_history_item.dart';
import '../services/database_helper.dart';
import '../services/preferences_service.dart';
import 'selection_screen.dart';

/// Profile tab: User name, Active condition, Scan history list.
/// Matches design with Green/Red badges.
class ProfileScreen extends StatefulWidget {
  final VoidCallback? onUpdateConditions;
  final ValueNotifier<int>? scanRefreshTrigger;

  const ProfileScreen({super.key, this.onUpdateConditions, this.scanRefreshTrigger});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final PreferencesService _prefs = PreferencesService();
  final DatabaseHelper _db = DatabaseHelper.instance;

  String? _fullName;
  int? _yearOfBirth;
  List<HealthCondition> _conditions = [];
  List<ScanHistoryItem> _scanHistory = [];
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
    final conditions = await _prefs.getHealthConditions();
    final history = await _db.getAllScanHistory();
    if (mounted) {
      setState(() {
        _fullName = name ?? 'User';
        _yearOfBirth = year;
        _conditions = conditions;
        _scanHistory = history;
        _loading = false;
      });
    }
  }

  void _refresh() => _load();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppTheme.primaryColor,
              child: CustomScrollView(
                slivers: [
                  // Blue header
                  SliverToBoxAdapter(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(top: 48, bottom: 24),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'My Profile',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white,
                            child: Text(
                              (_fullName?.isNotEmpty == true ? _fullName![0] : '?').toUpperCase(),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _fullName ?? 'User',
                                style: const TextStyle(
                                  fontSize: AppTheme.titleFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                                onPressed: () {},
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          if (_yearOfBirth != null)
                            Text(
                              'Age: ${_prefs.getAgeFromYearOfBirth(_yearOfBirth!)} years',
                              style: const TextStyle(
                                fontSize: AppTheme.bodyFontSize,
                                color: Colors.white70,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Active conditions
                          Text(
                            'Active Health Conditions',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.primaryColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_conditions.isEmpty)
                                  const Text('No conditions selected')
                                else
                                  ..._conditions.map(
                                    (c) => _buildConditionRow(c.displayName),
                                  ),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const SelectionScreen(isUpdateMode: true),
                                      ),
                                    );
                                    _refresh();
                                    widget.onUpdateConditions?.call();
                                  },
                                  icon: const Icon(Icons.edit, size: 18),
                                  label: Text(
                                    _conditions.isEmpty
                                        ? 'Select Conditions'
                                        : 'Update My Conditions',
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.primaryColor,
                                    side: const BorderSide(color: AppTheme.primaryColor),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Scan history
                          Text(
                            'Scan History',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                  if (_scanHistory.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'No scan history yet',
                          style: TextStyle(fontSize: AppTheme.bodyFontSize, color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = _scanHistory[index];
                          return _ScanHistoryCard(item: item);
                        },
                        childCount: _scanHistory.length,
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildConditionRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 8, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: AppTheme.bodyFontSize)),
        ],
      ),
    );
  }
}

class _ScanHistoryCard extends StatelessWidget {
  final ScanHistoryItem item;

  const _ScanHistoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isSafe = item.isSafe;
    final color = isSafe ? AppTheme.safeColor : AppTheme.dangerColor;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withOpacity(0.2),
              child: Icon(
                isSafe ? Icons.check : Icons.close,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(
                      fontSize: AppTheme.bodyFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _formatDate(item.timestamp),
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.status,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
