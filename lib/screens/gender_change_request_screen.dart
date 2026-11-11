import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GenderChangeRequestScreen extends StatefulWidget {
  const GenderChangeRequestScreen({super.key});

  @override
  State<GenderChangeRequestScreen> createState() => _GenderChangeRequestScreenState();
}

class _GenderChangeRequestScreenState extends State<GenderChangeRequestScreen> {
  final _reason = TextEditingController();
  String? _currentGender;
  String? _requestedGender;
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await client
          .from('profiles')
          .select('gender')
          .eq('id', user.id)
          .single();
      final requests = await client
          .from('gender_change_requests')
          .select('id,current_gender,requested_gender,reason,status,created_at,admin_note')
          .eq('member_id', user.id)
          .order('created_at', ascending: false);
      if (!mounted) return;
      setState(() {
        _currentGender = profile['gender'] as String?;
        _requests = requests;
        _requestedGender = _currentGender == 'female' ? 'male' : 'female';
      });
    } catch (error) {
      if (mounted) setState(() => _error = 'تعذر تحميل الطلبات: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || _currentGender == null || _requestedGender == null) return;
    if (_requests.any((request) => request['status'] == 'pending')) {
      setState(() => _error = 'لديك طلب قيد المراجعة بالفعل.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.from('gender_change_requests').insert({
        'member_id': user.id,
        'current_gender': _currentGender,
        'requested_gender': _requestedGender,
        'reason': _reason.text.trim().isEmpty ? null : _reason.text.trim(),
      });
      _reason.clear();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال طلبك للإدارة. يظل النوع الحالي كما هو حتى صدور القرار.')),
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = 'تعذر إرسال الطلب: $error');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _genderLabel(String? value) =>
      value == 'female' ? 'امرأة' : value == 'male' ? 'رجل' : 'غير محدد';

  String _statusLabel(String? value) => switch (value) {
        'approved' => 'تمت الموافقة',
        'rejected' => 'مرفوض',
        _ => 'قيد المراجعة',
      };

  @override
  Widget build(BuildContext context) {
    final pending = _requests.any((request) => request['status'] == 'pending');
    return Scaffold(
      appBar: AppBar(title: const Text('طلب تغيير النوع')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('النوع المسجل: ${_genderLabel(_currentGender)}',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                const Text('لا يمكن تغيير النوع مباشرة من الحساب. أرسل طلبًا للإدارة، وسيظل النوع الحالي فعالًا حتى الموافقة.'),
                if (!pending && _currentGender != null) ...[
                  const SizedBox(height: 20),
                  Text('النوع المطلوب', style: Theme.of(context).textTheme.titleMedium),
                  RadioGroup<String>(
                    groupValue: _requestedGender,
                    onChanged: (value) {
                      if (_sending || value == null) return;
                      setState(() => _requestedGender = value);
                    },
                    child: RadioListTile<String>(
                      value: _currentGender == 'female' ? 'male' : 'female',
                      title: Text(_currentGender == 'female' ? 'رجل' : 'امرأة'),
                      contentPadding: EdgeInsets.zero,
                      enabled: !_sending,
                    ),
                  ),
                  TextField(
                    controller: _reason,
                    maxLines: 3,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      labelText: 'سبب الطلب (اختياري)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _sending ? null : _submit,
                    child: _sending
                        ? const CircularProgressIndicator()
                        : const Text('إرسال الطلب للإدارة'),
                  ),
                ] else if (pending) ...[
                  const SizedBox(height: 16),
                  const Text('لديك طلب قيد المراجعة. لا يمكن إرسال طلب آخر قبل انتهاء المراجعة.'),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const Divider(height: 32),
                Text('سجل الطلبات', style: Theme.of(context).textTheme.titleLarge),
                if (_requests.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('لا توجد طلبات سابقة.'),
                  ),
                for (final request in _requests)
                  Card(
                    child: ListTile(
                      title: Text('${_genderLabel(request['current_gender'] as String?)} ← ${_genderLabel(request['requested_gender'] as String?)}'),
                      subtitle: Text(_statusLabel(request['status'] as String?) +
                          ((request['admin_note'] as String?)?.isNotEmpty == true
                              ? '\nملاحظة الإدارة: ${request['admin_note']}'
                              : '')),
                    ),
                  ),
              ],
            ),
    );
  }
}
