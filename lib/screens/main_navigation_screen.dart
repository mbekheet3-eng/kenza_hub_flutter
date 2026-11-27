import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_strings.dart';
import 'categories_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import '../widgets/kenza_asset_icon.dart';
import 'messages_inbox_screen.dart';
import 'conversation_screen.dart';
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
  static Future<void> Function(String?)? _notificationMessageHandler;

  /// Routes notification taps through the existing Messages tab navigator.
  static Future<void> openMessagesFromNotification({String? conversationId}) async {
    await _notificationMessageHandler?.call(conversationId);
  }

  int _selectedIndex = 0;
  int _returnIndex = 0;
  bool _openingSell = false;
  bool _sellRouteOpen = false;
  late final StreamSubscription<AuthState> _authSubscription;
  late final List<GlobalKey<NavigatorState>> _navigatorKeys;

  @override
  void initState() {
    super.initState();
    _notificationMessageHandler = _openMessagesFromNotification;
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
    _notificationMessageHandler = null;
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
    // Reuse the current form only while it is still on the Sell tab's stack.
    // A stale flag must never prevent the user from reopening Add Product.
    final sellNavigator = _navigatorKeys[2].currentState;
    if (sellNavigator?.canPop() == true) {
      _sellRouteOpen = true;
      if (mounted) setState(() => _selectedIndex = 2);
      return;
    }
    _sellRouteOpen = false;

    // Avoid opening multiple sign-in sheets/routes from rapid repeated taps.
    if (_openingSell) return;
    _openingSell = true;

    try {
      if (!await _ensureSignedIn() || !mounted) return;

      final navigator = _navigatorKeys[2].currentState;
      if (navigator == null) return;

      _sellRouteOpen = true;
      setState(() => _selectedIndex = 2);
      await navigator.push<void>(
        MaterialPageRoute<void>(builder: (_) => const ProductFormScreen()),
      );
    } finally {
      _openingSell = false;
      _sellRouteOpen = false;
      if (mounted) {
        setState(() => _selectedIndex = _returnIndex);
      }
    }
  }

  Future<void> _openMessagesFromNotification(String? conversationId) async {
    if (!await _ensureSignedIn() || !mounted) return;

    setState(() {
      _returnIndex = 3;
      _selectedIndex = 3;
    });

    final navigator = _navigatorKeys[3].currentState;
    if (navigator == null) return;

    // Keep the inbox as the root of the Messages tab and open the selected
    // conversation inside that tab, not on the app-level navigator.
    navigator.popUntil((route) => route.isFirst);
    if (conversationId == null || conversationId.isEmpty) return;

    await navigator.push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ConversationScreen(conversationId: conversationId),
      ),
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

    if (mounted) {
      setState(() {
        _returnIndex = index;
        _selectedIndex = index;
      });
    }
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
    // Keep the bottom navigation usable with Android's large-font settings.
    // At larger scales, show only the selected label to avoid five labels
    // competing for the narrow width of each destination.
    final textScaler = MediaQuery.textScalerOf(context);
    final textScale = textScaler.scale(1.0);
    final languageCode = Localizations.localeOf(context).languageCode;
    final labelSize = languageCode == 'ar' ? 12.0 : 10.5;
    final scaledLabelSize = textScaler.scale(labelSize);
    final iconSize = textScale >= 1.2 ? 28.0 : 36.0;
    final navigationBarHeight = math.max(
      92.0,
      iconSize + (scaledLabelSize * 1.3) + 36.0,
    ).toDouble();
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
        height: navigationBarHeight,
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: Colors.transparent,
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectDestination,
        labelBehavior: textScale >= 1.3
            ? NavigationDestinationLabelBehavior.onlyShowSelected
            : NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: labelSize,
            height: 1.0,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        destinations: [
          NavigationDestination(
            icon: KenzaAssetIcon('assets/icons/home_icone.png', size: iconSize, scale: 1.0),
            selectedIcon: KenzaAssetIcon('assets/icons/home_icone.png', size: iconSize, scale: 1.0),
            label: strings.mainHome,
          ),
          NavigationDestination(
            icon: KenzaAssetIcon('assets/icons/discover_icon.png', size: iconSize, scale: 1.0),
            selectedIcon: KenzaAssetIcon('assets/icons/discover_icon.png', size: iconSize, scale: 1.0),
            label: strings.discoverTitle,
          ),
          NavigationDestination(
            icon: KenzaAssetIcon('assets/icons/Add_icon.png', size: iconSize, scale: 1.0),
            selectedIcon: KenzaAssetIcon('assets/icons/Add_icon.png', size: iconSize, scale: 1.0),
            label: strings.addProduct,
          ),
          NavigationDestination(
            icon: KenzaAssetIcon('assets/icons/message_icon.png', size: iconSize, scale: 1.0),
            selectedIcon: KenzaAssetIcon('assets/icons/message_icon.png', size: iconSize, scale: 1.0),
            label: strings.messages,
          ),
          NavigationDestination(
            icon: KenzaAssetIcon('assets/icons/profile_icon.png', size: iconSize, scale: 1.0),
            selectedIcon: KenzaAssetIcon('assets/icons/profile_icon.png', size: iconSize, scale: 1.0),
            label: strings.accountTab,
          ),
        ],
      ),
    );
  }
}
