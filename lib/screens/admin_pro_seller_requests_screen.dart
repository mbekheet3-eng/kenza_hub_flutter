import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/account_access_service.dart';

class AdminProSellerRequestsScreen extends StatefulWidget {
  const AdminProSellerRequestsScreen({super.key});

  @override
  State<AdminProSellerRequestsScreen> createState() =>
      _AdminProSellerRequestsScreenState();
}

class _AdminProSellerRequestsScreenState
    extends State<AdminProSellerRequestsScreen> {
  final _service = AccountAccessService();
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
      final requests = await _service.getPendingProSellerRequests();
      if (mounted) setState(() => _requests = requests);
    } catch (error) {
      if (mounted) {
        setState(() => _error =
            '${AppStrings.of(context)!.adminRequestsLoadFailed}: $error');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _storeTypeLabel(AppStrings strings, String value) {
    switch (value) {
      case 'physical_shop':
        return strings.storeTypePhysicalShop;
      case 'wekala_corner':
        return strings.storeTypeWekala;
      case 'online_store':
        return strings.storeTypeOnline;
      default:
        return strings.storeTypeIndividual;
    }
  }

  Future<void> _review(
    Map<String, dynamic> request,
    bool approve,
  ) async {
    final strings = AppStrings.of(context)!;
    final noteController = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          approve ? strings.approveRequestTitle : strings.rejectRequestTitle,
        ),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          maxLength: 1000,
          decoration: InputDecoration(labelText: strings.adminNoteLabel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              noteController.text.trim(),
            ),
            child: Text(strings.confirmAction),
          ),
        ],
      ),
    );
    noteController.dispose();
    if (note == null) return;

    try {
      await _service.reviewProSellerRequest(
        requestId: request['id'] as String,
        approve: approve,
        adminNote: note,
      );
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${strings.saveDecisionFailed}: $error'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(strings.adminProSellerRequests)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _load,
                          child: Text(strings.retry),
                        ),
                      ],
                    ),
                  ),
                )
              : _requests.isEmpty
                  ? Center(child: Text(strings.noPendingProSellerRequests))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _requests.length,
                        itemBuilder: (context, index) {
                          final request = _requests[index];
                          final profile = request['member_profile']
                              as Map<String, dynamic>?;
                          final firstName =
                              (profile?['first_name'] as String?)?.trim();
                          final avatar = profile?['avatar_url'] as String?;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundImage: avatar == null ||
                                                avatar.isEmpty
                                            ? null
                                            : NetworkImage(avatar),
                                        child: avatar == null || avatar.isEmpty
                                            ? const Icon(Icons.person_outline)
                                            : null,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          firstName?.isNotEmpty == true
                                              ? firstName!
                                              : strings.memberFallback,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    request['requested_store_name'] as String,
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(_storeTypeLabel(
                                    strings,
                                    request['store_type'] as String,
                                  )),
                                  if ((request['store_description'] as String?)
                                          ?.isNotEmpty ==
                                      true) ...[
                                    const SizedBox(height: 8),
                                    Text(request['store_description'] as String),
                                  ],
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: FilledButton(
                                          onPressed: () =>
                                              _review(request, true),
                                          child: Text(strings.approveAction),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () =>
                                              _review(request, false),
                                          child: Text(strings.rejectAction),
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
