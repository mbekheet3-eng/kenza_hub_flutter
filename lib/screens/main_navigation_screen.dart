import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'categories_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'messages_inbox_screen.dart';
import 'product_form_screen.dart';
import 'profile_screen.dart';

/// Persistent top-level navigation for the marketplace.
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  Future<bool> _ensureSignedIn() async {
    if (Supabase.instance.client.auth.currentUser != null) return true;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
    );
    return mounted && Supabase.instance.client.auth.currentUser != null;
  }

  Future<void> _openSell() async {
    if (!await _ensureSignedIn() || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ProductFormScreen()),
    );
  }

  Future<void> _selectDestination(int index) async {
    if (index == 2) {
      await _openSell();
      return;
    }

    if (index == 3 || index == 4) {
      if (!await _ensureSignedIn() || !mounted) return;
    }

    if (mounted) setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = Supabase.instance.client.auth.currentUser != null;
    final destinations = <Widget>[
      const HomeScreen(),
      const CategoriesScreen(),
      const SizedBox.shrink(),
      signedIn ? const MessagesInboxScreen() : const SizedBox.shrink(),
      signedIn ? const ProfileScreen() : const SizedBox.shrink(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: destinations,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectDestination,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'الأقسام',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline_rounded, size: 30),
            selectedIcon: Icon(Icons.add_circle_rounded, size: 30),
            label: 'أضف منتجًا',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'الرسائل',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'حسابي',
          ),
        ],
      ),
    );
  }
}
