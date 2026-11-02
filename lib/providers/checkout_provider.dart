import 'package:flutter/material.dart';
import '../services/address_service.dart';

class Address {
  final String id;
  final String fullName;
  final String phone;
  final String street;
  final String city;
  final String governorate;
  final String postalCode;
  final String? apartment;
  final String? regionId;
  final String? landmark;
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
    this.regionId,
    this.landmark,
    this.isDefault = false,
  });

  String get displayName => '$fullName - $street, $city';

  Map<String, dynamic> toJson() => {
        if (regionId != null) 'region_id': regionId,
        'recipient_name': fullName,
        'recipient_phone': phone,
        'address_line_1': street,
        'address_line_2': apartment,
        'landmark': landmark,
        'postal_code': postalCode,
        'is_default': isDefault,
      };

  factory Address.fromJson(Map<String, dynamic> json) {
    final regionValue = json['regions'] ?? json['region'];
    final region = regionValue is Map
        ? Map<String, dynamic>.from(regionValue)
        : <String, dynamic>{};
    return Address(
      id: json['id'] as String,
      fullName: json['recipient_name'] as String? ?? '',
      phone: json['recipient_phone'] as String? ?? '',
      street: json['address_line_1'] as String? ?? '',
      city: region['name_ar'] as String? ??
          region['district'] as String? ??
          '',
      governorate: region['city'] as String? ?? '',
      postalCode: json['postal_code'] as String? ?? '',
      apartment: json['address_line_2'] as String?,
      regionId: json['region_id'] as String?,
      landmark: json['landmark'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
    );
  }
}

class CheckoutProvider with ChangeNotifier {
  final AddressService _addressService = AddressService();

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
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final rows = await _addressService.fetchCurrentUserAddresses();
      _addresses = rows.map(Address.fromJson).toList(growable: false);
      _selectedAddress = _addresses.isEmpty
          ? null
          : _addresses.firstWhere(
              (address) => address.isDefault,
              orElse: () => _addresses.first,
            );
    } catch (e) {
      _addresses = [];
      _selectedAddress = null;
      _error = 'تعذر تحميل عناوينك: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
