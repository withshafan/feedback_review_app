import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/feedback_model.dart';
import '../services/feedback_service.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final feedbackService = context.read<FeedbackService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      body: StreamBuilder<List<FeedbackModel>>(
        stream: feedbackService.getFeedbackStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final feedbackList = snapshot.data ?? [];
          
          if (feedbackList.isEmpty) {
            return const Center(child: Text('No feedback data available.'));
          }

          int totalFeedback = feedbackList.length;
          double totalRating = feedbackList.fold(0, (sum, item) => sum + item.rating);
          double avgRating = totalRating / totalFeedback;

          final now = DateTime.now();
          final oneWeekAgo = now.subtract(const Duration(days: 7));
          int feedbackThisWeek = feedbackList.where((f) => f.createdAt.isAfter(oneWeekAgo)).length;

          // Rating distribution (1 to 5 stars)
          Map<int, int> distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
          for (var f in feedbackList) {
            int r = f.rating.round();
            if (r >= 1 && r <= 5) {
              distribution[r] = distribution[r]! + 1;
            }
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Total',
                          value: totalFeedback.toString(),
                          icon: Icons.list_alt,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Avg Rating',
                          value: avgRating.toStringAsFixed(1),
                          icon: Icons.star,
                          iconColor: Colors.amber,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'This Week',
                          value: feedbackThisWeek.toString(),
                          icon: Icons.trending_up,
                          iconColor: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text('Rating Distribution', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 250,
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
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, BuildContext context) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: Theme.of(context).colorScheme.primary,
          width: 22,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 5, // Visual background line
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
          ),
        ),
      ],
      showingTooltipIndicators: [0],
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
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        child: Column(
          children: [
            Icon(icon, size: 28, color: iconColor ?? Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
