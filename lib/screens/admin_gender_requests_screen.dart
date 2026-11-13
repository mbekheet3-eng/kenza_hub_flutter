import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_strings.dart';

class AdminGenderRequestsScreen extends StatefulWidget {
  const AdminGenderRequestsScreen({super.key});

  @override
  State<AdminGenderRequestsScreen> createState() => _AdminGenderRequestsScreenState();
}

class _AdminGenderRequestsScreenState extends State<AdminGenderRequestsScreen> {
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await Supabase.instance.client
          .from('gender_change_requests')
          .select('id,member_id,current_gender,requested_gender,reason,created_at')
          .eq('status', 'pending')
          .order('created_at');
      if (mounted) setState(() => _requests = rows);
    } catch (error) {
      if (mounted) setState(() => _error = '${AppStrings.of(context)!.adminRequestsLoadFailed}: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _gender(BuildContext context, String value) => value == 'female' ? AppStrings.of(context)!.genderWoman : AppStrings.of(context)!.genderMan;

  Future<void> _review(Map<String, dynamic> request, bool approve) async {
    final admin = Supabase.instance.client.auth.currentUser;
    if (admin == null) return;
    final noteController = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(approve ? AppStrings.of(ctx)!.approveRequestTitle : AppStrings.of(ctx)!.rejectRequestTitle),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          decoration: InputDecoration(labelText: AppStrings.of(ctx)!.memberOptionalNote),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.of(ctx)!.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, noteController.text.trim()),
            child: Text(AppStrings.of(ctx)!.confirmAction),
          ),
        ],
      ),
    );
    noteController.dispose();
    if (note == null) return;

    try {
      await Supabase.instance.client
          .from('gender_change_requests')
          .update({
            'status': approve ? 'approved' : 'rejected',
            'reviewed_by': admin.id,
            'reviewed_at': DateTime.now().toUtc().toIso8601String(),
            'admin_note': note.isEmpty ? null : note,
          })
          .eq('id', request['id'])
          .eq('status', 'pending');
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppStrings.of(context)!.saveDecisionFailed}: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.of(context)!.genderRequestsTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _requests.isEmpty
                  ? Center(child: Text(AppStrings.of(context)!.noPendingRequests))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _requests.length,
                        itemBuilder: (context, index) {
                          final request = _requests[index];
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_gender(context, request['current_gender'] as String)} ← ${_gender(context, request['requested_gender'] as String)}',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  if ((request['reason'] as String?)?.isNotEmpty == true)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Text(request['reason'] as String),
                                    ),
                                  Text('${AppStrings.of(context)!.memberIdLabel}: ${request['member_id']}',
                                      style: Theme.of(context).textTheme.bodySmall),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: FilledButton(
                                          onPressed: () => _review(request, true),
                                          child: Text(AppStrings.of(context)!.approveAction),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => _review(request, false),
                                          child: Text(AppStrings.of(context)!.rejectAction),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
