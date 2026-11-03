import 'package:flutter_test/flutter_test.dart';
import 'package:kenza_hub_flutter/providers/cart_provider.dart';

void main() {
  group('CartProvider account isolation', () {
    CartProvider createCart({String? userId}) {
      return CartProvider(initialUserId: userId);
    }

    void addProduct(CartProvider cart, String productId) {
      cart.addItem(
        productId: productId,
        title: 'منتج تجريبي',
        price: 100,
      );
    }

    test('clears a signed-in account cart on sign out', () {
      final cart = createCart(userId: 'user-a');
      addProduct(cart, 'product-a');

      cart.handleAuthUserChanged(null);

      expect(cart.items, isEmpty);
      cart.dispose();
    });

    test('clears the previous account cart when another account signs in', () {
      final cart = createCart(userId: 'user-a');
      addProduct(cart, 'product-a');

      cart.handleAuthUserChanged('user-b');

      expect(cart.items, isEmpty);
      cart.dispose();
    });

    test('preserves a guest cart on the first sign in', () {
      final cart = createCart();
      addProduct(cart, 'product-a');

      cart.handleAuthUserChanged('user-a');

      expect(cart.items, hasLength(1));
      expect(cart.items.single.productId, 'product-a');
      cart.dispose();
    });

    test('does not clear the cart when the same account emits again', () {
      final cart = createCart(userId: 'user-a');
      addProduct(cart, 'product-a');

      cart.handleAuthUserChanged('user-a');

      expect(cart.items, hasLength(1));
      cart.dispose();
    });
  });
}
