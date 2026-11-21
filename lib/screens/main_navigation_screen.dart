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
///
/// Each tab owns a nested Navigator so pages pushed from that tab keep the
/// shared bottom navigation visible.
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  late final StreamSubscription<AuthState> _authSubscription;
  late final List<GlobalKey<NavigatorState>> _navigatorKeys;

  @override
  void initState() {
    super.initState();
    _navigatorKeys = List.generate(5, (_) => GlobalKey<NavigatorState>());
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((state) {
      if (!mounted) return;
      setState(() {
        if (state.session == null) {
          _selectedIndex = 0;
          // Recreate the authenticated tab navigators so a later sign-in
          // starts with fresh inbox/profile pages.
          _navigatorKeys[3] = GlobalKey<NavigatorState>();
          _navigatorKeys[4] = GlobalKey<NavigatorState>();
        } else {
          _navigatorKeys[3] = GlobalKey<NavigatorState>();
          _navigatorKeys[4] = GlobalKey<NavigatorState>();
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

    final previousIndex = _selectedIndex;
    final navigator = _navigatorKeys[2].currentState;
    if (navigator == null) return;

    setState(() => _selectedIndex = 2);
    navigator.popUntil((route) => route.isFirst);
    await navigator.push<void>(
      MaterialPageRoute<void>(builder: (_) => const ProductFormScreen()),
    );

    if (mounted) {
      setState(() => _selectedIndex = previousIndex == 2 ? 0 : previousIndex);
    }
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

  Widget _tabNavigator(int index, Widget initialPage) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (_) => MaterialPageRoute<void>(
        builder: (_) => initialPage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context)!;
    final signedIn = Supabase.instance.client.auth.currentUser != null;
    final destinations = <Widget>[
      _tabNavigator(0, const HomeScreen()),
      _tabNavigator(1, const CategoriesScreen()),
      _tabNavigator(2, const SizedBox.shrink()),
      _tabNavigator(
        3,
        signedIn ? const MessagesInboxScreen() : const SizedBox.shrink(),
      ),
      _tabNavigator(
        4,
        signedIn ? const ProfileScreen() : const SizedBox.shrink(),
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: destinations,
      ),
      bottomNavigationBar: NavigationBar(
        height: 92,
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
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        destinations: [
          NavigationDestination(
            icon: Image.asset('assets/icons/home_icone.png', width: 36, height: 36),
            selectedIcon: Image.asset('assets/icons/home_icone.png', width: 26, height: 26),
            label: strings.mainHome,
          ),
          NavigationDestination(
            icon: Image.asset('assets/icons/discover_icon.png', width: 26, height: 26),
            selectedIcon: Image.asset('assets/icons/discover_icon.png', width: 26, height: 26),
            label: strings.discoverTitle,
          ),
          NavigationDestination(
            icon: Image.asset('assets/icons/Add_icon.png', width: 38, height: 38),
            selectedIcon: Image.asset('assets/icons/Add_icon.png', width: 28, height: 28),
            label: strings.addProduct,
          ),
          NavigationDestination(
            icon: Image.asset('assets/icons/message_icon.png', width: 26, height: 26),
            selectedIcon: Image.asset('assets/icons/message_icon.png', width: 26, height: 26),
            label: strings.messages,
          ),
          NavigationDestination(
            icon: Image.asset('assets/icons/profile_icon.png', width: 26, height: 26),
            selectedIcon: Image.asset('assets/icons/profile_icon.png', width: 26, height: 26),
            label: strings.accountTab,
          ),
        ],
      ),
    );
  }
}
