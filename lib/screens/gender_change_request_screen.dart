import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_strings.dart';

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
      if (mounted) setState(() => _error = '${AppStrings.of(context)!.adminRequestsLoadFailed}: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || _currentGender == null || _requestedGender == null) return;
    if (_requests.any((request) => request['status'] == 'pending')) {
      setState(() => _error = AppStrings.of(context)!.genderRequestsAlreadyPending);
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
          SnackBar(content: Text(AppStrings.of(context)!.genderRequestSubmitted)),
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = '${AppStrings.of(context)!.genderRequestSendFailed}: $error');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _genderLabel(BuildContext context, String? value) =>
      value == 'female' ? AppStrings.of(context)!.genderWoman : value == 'male' ? AppStrings.of(context)!.genderMan : AppStrings.of(context)!.genderNotSpecified;

  String _statusLabel(BuildContext context, String? value) => switch (value) {
        'approved' => AppStrings.of(context)!.statusApproved,
        'rejected' => AppStrings.of(context)!.statusRejected,
        _ => AppStrings.of(context)!.statusPending,
      };

  @override
  Widget build(BuildContext context) {
    final pending = _requests.any((request) => request['status'] == 'pending');
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.of(context)!.genderChangeRequestTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('${AppStrings.of(context)!.registeredGenderLabel}: ${_genderLabel(context, _currentGender)}',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(AppStrings.of(context)!.genderChangeExplanation),
                if (!pending && _currentGender != null) ...[
                  const SizedBox(height: 20),
                  Text(AppStrings.of(context)!.requestedGenderLabel, style: Theme.of(context).textTheme.titleMedium),
                  RadioGroup<String>(
                    groupValue: _requestedGender,
                    onChanged: (value) {
                      if (_sending || value == null) return;
                      setState(() => _requestedGender = value);
                    },
                    child: RadioListTile<String>(
                      value: _currentGender == 'female' ? 'male' : 'female',
                      title: Text(_currentGender == 'female' ? AppStrings.of(context)!.genderMan : AppStrings.of(context)!.genderWoman),
                      contentPadding: EdgeInsets.zero,
                      enabled: !_sending,
                    ),
                  ),
                  TextField(
                    controller: _reason,
                    maxLines: 3,
                    maxLength: 500,
                    decoration: InputDecoration(
                      labelText: AppStrings.of(context)!.requestReasonOptional,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _sending ? null : _submit,
                    child: _sending
                        ? const CircularProgressIndicator()
                        : Text(AppStrings.of(context)!.sendRequestToAdmin),
                  ),
                ] else if (pending) ...[
                  const SizedBox(height: 16),
                  Text(AppStrings.of(context)!.pendingRequestExists),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const Divider(height: 32),
                Text(AppStrings.of(context)!.requestHistory, style: Theme.of(context).textTheme.titleLarge),
                if (_requests.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(AppStrings.of(context)!.noPreviousRequests),
                  ),
                for (final request in _requests)
                  Card(
                    child: ListTile(
                      title: Text('${_genderLabel(context, request['current_gender'] as String?)} ← ${_genderLabel(context, request['requested_gender'] as String?)}'),
                      subtitle: Text(_statusLabel(context, request['status'] as String?) +
                          ((request['admin_note'] as String?)?.isNotEmpty == true
                              ? '\n${AppStrings.of(context)!.adminNoteLabel}: ${request['admin_note']}'
                              : '')),
                    ),
                  ),
              ],
            ),
    );
  }
}
