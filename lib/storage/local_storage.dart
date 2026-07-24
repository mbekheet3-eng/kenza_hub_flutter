import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Local Storage Service
class LocalStorage {
  static final LocalStorage _instance = LocalStorage._internal();
  late SharedPreferences _prefs;
  bool _initialized = false;

  factory LocalStorage() {
    return _instance;
  }

  LocalStorage._internal();

  /// تهيئة الـ Storage
  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  // ==================== String Operations ====================

  /// حفظ نص
  Future<bool> saveString(String key, String value) async {
    _ensureInitialized();
    return await _prefs.setString(key, value);
  }

  /// قراءة نص
  String? getString(String key) {
    _ensureInitialized();
    return _prefs.getString(key);
  }

  /// قراءة نص مع default
  String getStringOrDefault(String key, String defaultValue) {
    _ensureInitialized();
    return _prefs.getString(key) ?? defaultValue;
  }

  // ==================== Int Operations ====================

  /// حفظ رقم صحيح
  Future<bool> saveInt(String key, int value) async {
    _ensureInitialized();
    return await _prefs.setInt(key, value);
  }

  /// قراءة رقم صحيح
  int? getInt(String key) {
    _ensureInitialized();
    return _prefs.getInt(key);
  }

  /// قراءة رقم صحيح مع default
  int getIntOrDefault(String key, int defaultValue) {
    _ensureInitialized();
    return _prefs.getInt(key) ?? defaultValue;
  }

  // ==================== Double Operations ====================

  /// حفظ رقم عشري
  Future<bool> saveDouble(String key, double value) async {
    _ensureInitialized();
    return await _prefs.setDouble(key, value);
  }

  /// قراءة رقم عشري
  double? getDouble(String key) {
    _ensureInitialized();
    return _prefs.getDouble(key);
  }

  /// قراءة رقم عشري مع default
  double getDoubleOrDefault(String key, double defaultValue) {
    _ensureInitialized();
    return _prefs.getDouble(key) ?? defaultValue;
  }

  // ==================== Boolean Operations ====================

  /// حفظ قيمة منطقية
  Future<bool> saveBool(String key, bool value) async {
    _ensureInitialized();
    return await _prefs.setBool(key, value);
  }

  /// قراءة قيمة منطقية
  bool? getBool(String key) {
    _ensureInitialized();
    return _prefs.getBool(key);
  }

  /// قراءة قيمة منطقية مع default
  bool getBoolOrDefault(String key, bool defaultValue) {
    _ensureInitialized();
    return _prefs.getBool(key) ?? defaultValue;
  }

  // ==================== List Operations ====================

  /// حفظ قائمة من النصوص
  Future<bool> saveStringList(String key, List<String> value) async {
    _ensureInitialized();
    return await _prefs.setStringList(key, value);
  }

  /// قراءة قائمة من النصوص
  List<String>? getStringList(String key) {
    _ensureInitialized();
    return _prefs.getStringList(key);
  }

  // ==================== JSON Operations ====================

  /// حفظ JSON object
  Future<bool> saveJson<T>(String key, T value) async {
    _ensureInitialized();
    final jsonString = jsonEncode(value);
    return await _prefs.setString(key, jsonString);
  }

  /// قراءة JSON object
  T? getJson<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    _ensureInitialized();
    final jsonString = _prefs.getString(key);
    if (jsonString == null) return null;

    try {
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      return fromJson(decoded);
    } catch (e) {
      return null;
    }
  }

  // ==================== Delete Operations ====================

  /// حذف قيمة
  Future<bool> remove(String key) async {
    _ensureInitialized();
    return await _prefs.remove(key);
  }

  /// حذف جميع القيم
  Future<bool> clear() async {
    _ensureInitialized();
    return await _prefs.clear();
  }

  /// حذف قيم برمز معين
  Future<bool> removeByPrefix(String prefix) async {
    _ensureInitialized();
    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(prefix)) {
        await _prefs.remove(key);
      }
    }
    return true;
  }

  // ==================== Utility Operations ====================

  /// التحقق من وجود مفتاح
  bool containsKey(String key) {
    _ensureInitialized();
    return _prefs.containsKey(key);
  }

  /// الحصول على جميع المفاتيح
  Set<String> getKeys() {
    _ensureInitialized();
    return _prefs.getKeys();
  }

  /// حذف آخر حفظ
  Future<bool> clearAll() async {
    _ensureInitialized();
    return await _prefs.clear();
  }

  // ==================== Private Methods ====================

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('LocalStorage not initialized. Call init() first.');
    }
  }
}
