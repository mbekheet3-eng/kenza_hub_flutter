import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class DisputeEvidenceService {
  DisputeEvidenceService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const _bucket = 'dispute-evidence';
  static const _function = 'dispute-evidence-access';
  static const _uuid = Uuid();

  Future<String> getDisputeIdForOrder(String orderId) async {
    final row = await _client
        .from('disputes')
        .select('id')
        .eq('order_id', orderId)
        .maybeSingle();
    if (row == null) {
      throw StateError('لا يوجد نزاع مسجل لهذا الطلب حتى الآن.');
    }
    return row['id'] as String;
  }

  Future<List<Map<String, dynamic>>> listEvidence(String disputeId) async {
    final rows = await _client
        .from('dispute_evidence')
        .select('id,uploaded_by,caption,file_sha256,created_at')
        .eq('dispute_id', disputeId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  Future<void> uploadImage({
    required String disputeId,
    required Uint8List bytes,
    required String extension,
    String? caption,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('يجب تسجيل الدخول أولاً');

    final safeExtension = extension.toLowerCase() == 'png' ? 'png' : 'jpg';
    final contentType = safeExtension == 'png' ? 'image/png' : 'image/jpeg';
    final path = '$disputeId/$userId/${_uuid.v4()}.$safeExtension';

    await _client.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType,
            cacheControl: '3600',
            upsert: false,
          ),
        );

    try {
      final response = await _client.functions.invoke(
        _function,
        body: {
          'action': 'register',
          'dispute_id': disputeId,
          'storage_path': path,
          'caption': caption,
        },
      );
      if (response.status < 200 || response.status >= 300) {
        throw StateError('تعذر تسجيل الدليل على الخادم.');
      }
      final data = response.data;
      if (data is! Map || data['success'] != true) {
        throw StateError('لم يؤكد الخادم تسجيل الدليل.');
      }
    } catch (_) {
      // Keep the uploaded object for a safe retry/reconciliation; do not delete
      // evidence automatically after a transient registration/network failure.
      rethrow;
    }
  }

  Future<Uri> createTemporaryUrl({
    required String evidenceId,
    bool download = false,
  }) async {
    final response = await _client.functions.invoke(
      _function,
      body: {
        'action': 'signed_url',
        'evidence_id': evidenceId,
        'purpose': download ? 'download' : 'view',
      },
    );
    if (response.status < 200 || response.status >= 300) {
      throw StateError('تعذر إنشاء رابط آمن للدليل.');
    }
    final data = response.data;
    if (data is! Map || data['signed_url'] is! String) {
      throw StateError('استجابة رابط الدليل غير صالحة.');
    }
    return Uri.parse(data['signed_url'] as String);
  }
}
