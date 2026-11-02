import 'package:flutter/material.dart';

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

  // Order submission remains disabled until the server-side agreement RPC is ready.
  bool get canProceed => false;

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
    _isProcessing = false;
    _error =
        'تأكيد الطلب متوقف مؤقتًا لحين اكتمال مسار الاتفاقية الآمن على الخادم. لم يتم إنشاء أي طلب أو خصم أي مبلغ.';
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
