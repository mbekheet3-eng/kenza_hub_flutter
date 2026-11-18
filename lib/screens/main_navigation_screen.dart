import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_strings.dart';


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
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((state) {
      if (!mounted) return;
      setState(() {
        if (state.session == null && _selectedIndex >= 3) {
          _selectedIndex = 0;
        }
      });
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  Future<bool> _ensureSignedIn() async {
    if (Supabase.instance.client.auth.currentUser != null) return true;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FractionallySizedBox(
        heightFactor: 0.94,
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          child: LoginScreen(),
        ),
      ),
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
    final strings = AppStrings.of(context)!;
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
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: Colors.transparent,
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectDestination,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: strings.mainHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.explore_outlined),
            selectedIcon: const Icon(Icons.explore_rounded),
            label: strings.discoverTitle,
          ),
          NavigationDestination(
            icon: const Icon(Icons.add_rounded, size: 28),
            selectedIcon: const Icon(Icons.add_rounded, size: 28),
            label: strings.addProduct,
          ),
          NavigationDestination(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: const Icon(Icons.chat_bubble_rounded),
            label: strings.messages,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: const Icon(Icons.person_rounded),
            label: strings.accountTab,
          ),
        ],
      ),
    );
  }
}
