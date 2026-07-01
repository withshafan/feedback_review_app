import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/feedback_model.dart';
import '../services/feedback_service.dart';
import '../widgets/feedback_card.dart';
import 'feedback_detail_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _searchQuery = '';
  String? _categoryFilter;

  Future<void> _exportCSV(List<FeedbackModel> list) async {
    try {
      List<List<dynamic>> rows = [
        ["ID", "User Email", "Rating", "Comment", "Category", "Status", "Admin Reply", "Created At"]
      ];
      for (var f in list) {
        rows.add([
          f.id,
          f.userEmail,
          f.rating,
          f.comment,
          f.category,
          f.status,
          f.adminReplyText ?? '',
          f.createdAt.toIso8601String()
        ]);
      }
      String csvString = csv.encode(rows);
      
      final directory = await getTemporaryDirectory();
      final path = "${directory.path}/feedback_export_${DateTime.now().millisecondsSinceEpoch}.csv";
      final file = File(path);
      await file.writeAsString(csvString);
      
      await Share.shareXFiles([XFile(path)], text: 'Feedback Data Export');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  BarChartGroupData _buildBarGroup(int x, double y, BuildContext context) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: Theme.of(context).colorScheme.primary,
          width: 20,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 5,
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
          ),
        ),
      ],
      showingTooltipIndicators: [0],
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedbackService = context.read<FeedbackService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: StreamBuilder<List<FeedbackModel>>(
        stream: feedbackService.getFeedbackStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading dashboard: ${snapshot.error}'));
          }

          final allFeedback = snapshot.data ?? [];

          if (allFeedback.isEmpty) {
            return const Center(child: Text('No feedback data available.'));
          }

          // Aggregates
          int totalFeedback = allFeedback.length;
          double totalRating = allFeedback.fold(0.0, (sum, f) => sum + f.rating);
          double avgRating = totalRating / totalFeedback;

          final now = DateTime.now();
          final oneWeekAgo = now.subtract(const Duration(days: 7));
          int feedbackThisWeek = allFeedback.where((f) => f.createdAt.isAfter(oneWeekAgo)).length;

          int openCount = allFeedback.where((f) => f.status == 'open').length;
          int reviewedCount = allFeedback.where((f) => f.status == 'reviewed').length;

          // Rating distribution
          Map<int, int> distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
          for (var f in allFeedback) {
            int r = f.rating.round();
            if (r >= 1 && r <= 5) {
              distribution[r] = distribution[r]! + 1;
            }
          }

          // Apply local filter/search for the embedded list
          List<FeedbackModel> filteredList = allFeedback;
          if (_searchQuery.isNotEmpty) {
            filteredList = filteredList.where((f) => f.comment.toLowerCase().contains(_searchQuery)).toList();
          }
          if (_categoryFilter != null) {
            filteredList = filteredList.where((f) => f.category == _categoryFilter).toList();
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Overview',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton.filledTonal(
                        onPressed: () => _exportCSV(filteredList),
                        icon: const Icon(Icons.download),
                        tooltip: 'Export CSV',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Aggregate Cards
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      _StatCard(
                        title: 'Total Reviews',
                        value: totalFeedback.toString(),
                        icon: Icons.reviews,
                      ),
                      _StatCard(
                        title: 'Average Rating',
                        value: avgRating.toStringAsFixed(1),
                        icon: Icons.star,
                        iconColor: Colors.amber,
                      ),
                      _StatCard(
                        title: 'New This Week',
                        value: feedbackThisWeek.toString(),
                        icon: Icons.date_range,
                      ),
                      _StatCard(
                        title: 'Open / Reviewed',
                        value: '$openCount / $reviewedCount',
                        icon: Icons.check_circle_outline,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Rating Distribution',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: (totalFeedback.toDouble() * 1.2).clamp(5.0, double.infinity),
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (double value, TitleMeta meta) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text('${value.toInt()}★', style: const TextStyle(fontWeight: FontWeight.bold)),
                                );
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: [
                          _buildBarGroup(1, distribution[1]!.toDouble(), context),
                          _buildBarGroup(2, distribution[2]!.toDouble(), context),
                          _buildBarGroup(3, distribution[3]!.toDouble(), context),
                          _buildBarGroup(4, distribution[4]!.toDouble(), context),
                          _buildBarGroup(5, distribution[5]!.toDouble(), context),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Moderate Feedback',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search within comments...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.toLowerCase();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: const Text('All Categories'),
                          selected: _categoryFilter == null,
                          onSelected: (_) => setState(() => _categoryFilter = null),
                        ),
                        const SizedBox(width: 8),
                        ...['bug', 'feature', 'praise', 'complaint', 'general'].map((cat) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(cat[0].toUpperCase() + cat.substring(1)),
                              selected: _categoryFilter == cat,
                              onSelected: (_) => setState(() => _categoryFilter = cat),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      return FeedbackCard(
                        feedback: item,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FeedbackDetailScreen(feedback: item),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? iconColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 24, color: iconColor ?? Theme.of(context).colorScheme.primary),
                const SizedBox(width: 4),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
