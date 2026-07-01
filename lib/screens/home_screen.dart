import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'feedback_list_screen.dart';
import 'my_feedback_screen.dart';
import 'profile_screen.dart';
import 'admin_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _userRole = 'user';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRole();
  }

  Future<void> _fetchRole() async {
    final authService = context.read<AuthService>();
    final user = authService.currentUser;
    if (user != null) {
      final role = await authService.getUserRole(user.uid);
      if (mounted) {
        setState(() {
          _userRole = role;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Stream<int> _unreadFeedbackCountStream(String uid) {
    return FirebaseFirestore.instance.collection('users').doc(uid).snapshots().asyncExpand((userSnap) {
      final lastVisit = (userSnap.data()?['lastDashboardVisit'] as Timestamp?)?.toDate();
      return FirebaseFirestore.instance.collection('feedback').snapshots().map((feedbackSnap) {
        if (lastVisit == null) return feedbackSnap.docs.length;
        return feedbackSnap.docs.where((doc) {
          final createdAt = (doc.data()?['createdAt'] as Timestamp?)?.toDate();
          return createdAt != null && createdAt.isAfter(lastVisit);
        }).length;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bool isAdmin = _userRole == 'admin';
    final user = context.read<AuthService>().currentUser;

    final List<Widget> screens = [
      const FeedbackListScreen(),
      const MyFeedbackScreen(),
      if (isAdmin) const AdminDashboardScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          if (isAdmin && index == 2 && user != null) {
            context.read<AuthService>().updateLastDashboardVisit(user.uid);
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Feed',
          ),
          const NavigationDestination(
            icon: Icon(Icons.rate_review_outlined),
            selectedIcon: Icon(Icons.rate_review),
            label: 'My Feedback',
          ),
          if (isAdmin)
            NavigationDestination(
              icon: user == null
                  ? const Icon(Icons.dashboard_outlined)
                  : StreamBuilder<int>(
                      stream: _unreadFeedbackCountStream(user.uid),
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        if (count > 0) {
                          return Badge(
                            label: Text(count.toString()),
                            child: const Icon(Icons.dashboard_outlined),
                          );
                        }
                        return const Icon(Icons.dashboard_outlined);
                      },
                    ),
              selectedIcon: const Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
