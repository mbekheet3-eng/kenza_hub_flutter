import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:kenza_hub_flutter/services/supabase_service.dart';
import 'package:kenza_hub_flutter/models/order.dart';
import 'package:kenza_hub_flutter/models/product.dart';

class Address {
  final String id;
  final String fullName;
  final String phone;
  final String street;
  final String city;
  final String governorate;
  final String postalCode;
  final String? apartment;
  bool isDefault;

  Address({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.street,
    required this.city,
    required this.governorate,
    required this.postalCode,
    this.apartment,
    this.isDefault = false,
  });

  String get displayName => '$fullName - $street, $city';

  Map<String, dynamic> toJson() => {
    'id': id,
    'full_name': fullName,
    'phone': phone,
    'street': street,
    'city': city,
    'governorate': governorate,
    'postal_code': postalCode,
    'apartment': apartment,
    'is_default': isDefault,
  };

  factory Address.fromJson(Map<String, dynamic> json) => Address(
    id: json['id'] as String,
    fullName: json['full_name'] as String,
    phone: json['phone'] as String,
    street: json['street'] as String,
    city: json['city'] as String,
    governorate: json['governorate'] as String,
    postalCode: json['postal_code'] as String,
    apartment: json['apartment'] as String?,
    isDefault: json['is_default'] as bool? ?? false,
  );
}

class CheckoutProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  // State
  List<Address> _addresses = [];
  Address? _selectedAddress;
  bool _isLoading = false;
  String? _error;
  
  // Checkout data
  String _paymentMethod = 'cash'; // cash only - card not implemented
  bool _agreedToTerms = false;
  bool _isProcessing = false;
  String? _orderId;

  // Getters
  List<Address> get addresses => _addresses;
  Address? get selectedAddress => _selectedAddress;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get paymentMethod => _paymentMethod;
  bool get agreedToTerms => _agreedToTerms;
  bool get isProcessing => _isProcessing;
  String? get orderId => _orderId;

  bool get canProceed =>
      _selectedAddress != null && _agreedToTerms && !_isProcessing;

  // ✅ FIXED D6: Load addresses from Supabase instead of hardcoded
  // NOTE: This is a temporary implementation.
  // TODO: Implement proper addresses table in Supabase when ready
  Future<void> loadAddresses() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // TODO: When addresses table is ready, fetch from Supabase:
      // final response = await _supabaseService.getUserAddresses(userId);
      // _addresses = (response as List)
      //     .map((json) => Address.fromJson(json))
      //     .toList();

      // For now, return empty list (user must add addresses)
      // In real app, this will fetch from user profile in database
      _addresses = [];
      _selectedAddress = null;

      _isLoading = false;
    } catch (e) {
      _isLoading = false;
      _error = 'خطأ في تحميل العناوين: ${e.toString()}';
      print('❌ Error loading addresses: $e');
    }
    notifyListeners();
  }

  // Add address
  void addAddress(Address address) {
    _addresses.add(address);
    if (_addresses.length == 1) {
      _selectedAddress = address;
    }
    notifyListeners();
  }

  // Select address
  void selectAddress(Address address) {
    _selectedAddress = address;
    notifyListeners();
  }

  // Update payment method
  void setPaymentMethod(String method) {
    // Only allow 'cash' - card payment not yet implemented
    if (method == 'cash' && _paymentMethod != method) {
      _paymentMethod = method;
      notifyListeners();
    }
  }

  // Toggle terms agreement
  void toggleTermsAgreement() {
    _agreedToTerms = !_agreedToTerms;
    notifyListeners();
  }

  // ✅ FIXED D7 + D8: Process payment with seller lookup and proper seller assignment
  Future<bool> processPayment({
    required String buyerId,
    required List<Map<String, dynamic>> cartItems,
    required double totalAmount,
  }) async {
    try {
      if (_selectedAddress == null) {
        _error = 'يرجى اختيار عنوان التوصيل';
        notifyListeners();
        return false;
      }

      if (cartItems.isEmpty) {
        _error = 'السلة فارغة';
        notifyListeners();
        return false;
      }

      _isProcessing = true;
      _error = null;
      notifyListeners();

      // ✅ FIXED: Create one order PER PRODUCT (not one order with all items)
      // This matches the database schema which expects product_id per order
      String lastOrderId = '';

      for (final cartItem in cartItems) {
        final productId = cartItem['product_id'] as String? ?? '';
        
        if (productId.isEmpty) {
          throw Exception('Product ID is missing in cart item');
        }

        // ✅ FIXED D8: Fetch product to get seller_id
        try {
          final productData = await _supabaseService.fetchProductById(productId);
          final sellerId = productData['user_id'] as String?;

          if (sellerId == null || sellerId.isEmpty) {
            throw Exception('Product seller_id is missing for product: $productId');
          }

          // Calculate item amount (price × quantity)
          final price = (cartItem['price'] as num?)?.toDouble() ?? 0.0;
          final quantity = (cartItem['quantity'] as int?) ?? 1;
          final itemAmount = price * quantity;

          // Create order for this product
          final order = Order(
            id: '', // Will be generated by Supabase
            productId: productId,
            buyerId: buyerId,
            sellerId: sellerId, // ✅ FIXED: Now populated from product
            amount: itemAmount,
            status: OrderStatus.pending,
            shippingAddress: _selectedAddress != null 
                ? jsonEncode(_selectedAddress!.toJson()) 
                : null,
            trackingNumber: null,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          lastOrderId = await _supabaseService.createOrder(order);
          print('✅ Order created with ID: $lastOrderId for product: $productId');

        } catch (e) {
          _isProcessing = false;
          _error = 'خطأ في إنشاء الطلب للمنتج $productId: ${e.toString()}';
          print('❌ Error creating order for product $productId: $e');
          notifyListeners();
          return false;
        }
      }

      _orderId = lastOrderId;
      _isProcessing = false;

      // Only cash payment is supported
      if (_paymentMethod == 'cash') {
        print('✅ Orders created successfully. Total amount: ${totalAmount.toStringAsFixed(2)} ج.م');
        return true;
      } else {
        _error = 'طريقة الدفع غير مدعومة حالياً. يرجى استخدام الدفع عند الاستلام';
        print('⚠️ Unsupported payment method: $_paymentMethod');
        return false;
      }

    } catch (e) {
      _isProcessing = false;
      _error = 'خطأ في معالجة الطلب: ${e.toString()}';
      print('❌ Payment processing error: $e');
    }
    notifyListeners();
    return false;
  }

  // Clear checkout state
  void reset() {
    _selectedAddress = null;
    _paymentMethod = 'cash';
    _agreedToTerms = false;
    _isProcessing = false;
    _orderId = null;
    _error = null;
    notifyListeners();
  }
}
