import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../models/feedback_model.dart';
import '../services/feedback_service.dart';
import '../widgets/feedback_card.dart';
import 'submit_feedback_screen.dart';
import 'feedback_detail_screen.dart';

class FeedbackListScreen extends StatefulWidget {
  const FeedbackListScreen({super.key});

  @override
  State<FeedbackListScreen> createState() => _FeedbackListScreenState();
}

class _FeedbackListScreenState extends State<FeedbackListScreen> {
  String _searchQuery = '';
  double? _ratingFilter;
  String? _categoryFilter;

  Future<void> _refreshData() async {
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() {});
  }

  void _openFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Filter Feed', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Search comments',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (val) {
                      setModalState(() => _searchQuery = val.toLowerCase());
                      setState(() => _searchQuery = val.toLowerCase());
                    },
                    controller: TextEditingController(text: _searchQuery)..selection = TextSelection.collapsed(offset: _searchQuery.length),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<double?>(
                    value: _ratingFilter,
                    decoration: InputDecoration(
                      labelText: 'Rating',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All Ratings')),
                      DropdownMenuItem(value: 5.0, child: Text('5 Stars')),
                      DropdownMenuItem(value: 4.0, child: Text('4 Stars')),
                      DropdownMenuItem(value: 3.0, child: Text('3 Stars')),
                      DropdownMenuItem(value: 2.0, child: Text('2 Stars')),
                      DropdownMenuItem(value: 1.0, child: Text('1 Star')),
                    ],
                    onChanged: (val) {
                      setModalState(() => _ratingFilter = val);
                      setState(() => _ratingFilter = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    value: _categoryFilter,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All Categories')),
                      DropdownMenuItem(value: 'bug', child: Text('Bug')),
                      DropdownMenuItem(value: 'feature', child: Text('Feature')),
                      DropdownMenuItem(value: 'praise', child: Text('Praise')),
                      DropdownMenuItem(value: 'complaint', child: Text('Complaint')),
                      DropdownMenuItem(value: 'general', child: Text('General')),
                    ],
                    onChanged: (val) {
                      setModalState(() => _categoryFilter = val);
                      setState(() => _categoryFilter = val);
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Apply Filters'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Shimmer.fromColors(
              baseColor: Theme.of(context).brightness == Brightness.light ? Colors.grey[300]! : Colors.grey[800]!,
              highlightColor: Theme.of(context).brightness == Brightness.light ? Colors.grey[100]! : Colors.grey[700]!,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 40, height: 40, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(width: 100, height: 16, color: Colors.white),
                          const SizedBox(height: 8),
                          Container(width: 60, height: 12, color: Colors.white),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(width: double.infinity, height: 14, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(width: 200, height: 14, color: Colors.white),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool hasFilters) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(hasFilters ? Icons.search_off : Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            hasFilters ? 'No matches found' : 'No feedback yet',
            style: TextStyle(fontSize: 20, color: Colors.grey[600], fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilters ? 'Try altering your filters.' : 'Tap the + button to share your thoughts.',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedbackService = context.read<FeedbackService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Feedback'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _openFilterModal,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: StreamBuilder<List<FeedbackModel>>(
          stream: feedbackService.getFeedbackStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildShimmerLoading();
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error loading feedback: ${snapshot.error}'));
            }

            List<FeedbackModel> feedbackList = snapshot.data ?? [];

            // Apply local filters
            if (_searchQuery.isNotEmpty) {
              feedbackList = feedbackList.where((f) => f.comment.toLowerCase().contains(_searchQuery)).toList();
            }
            if (_ratingFilter != null) {
              feedbackList = feedbackList.where((f) => f.rating == _ratingFilter).toList();
            }
            if (_categoryFilter != null) {
              feedbackList = feedbackList.where((f) => f.category.toLowerCase() == _categoryFilter!.toLowerCase()).toList();
            }

            bool hasFilters = _searchQuery.isNotEmpty || _ratingFilter != null || _categoryFilter != null;

            if (feedbackList.isEmpty) {
              return _buildEmptyState(hasFilters);
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: feedbackList.length,
              itemBuilder: (context, index) {
                final item = feedbackList[index];
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
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SubmitFeedbackScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
