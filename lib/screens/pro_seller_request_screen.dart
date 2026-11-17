import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/account_access_service.dart';

class ProSellerRequestScreen extends StatefulWidget {
  const ProSellerRequestScreen({super.key});

  @override
  State<ProSellerRequestScreen> createState() => _ProSellerRequestScreenState();
}

class _ProSellerRequestScreenState extends State<ProSellerRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _service = AccountAccessService();
  String _storeType = 'individual_seller';
  bool _submitting = false;

  @override
  void dispose() {
    _storeNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _submitting) return;
    setState(() => _submitting = true);
    try {
      await _service.submitProSellerRequest(
        storeName: _storeNameController.text,
        storeType: _storeType,
        description: _descriptionController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context)!.proSellerRequestSent)),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppStrings.of(context)!.proSellerRequestFailed}: $error')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
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

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context)!;
    final types = const [
      'individual_seller',
      'physical_shop',
      'wekala_corner',
      'online_store',
    ];

    return Scaffold(
      appBar: AppBar(title: Text(strings.proSellerRequestTitle)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                strings.proSellerRequestIntro,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _storeNameController,
                maxLength: 100,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: strings.storeNameLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  final name = value?.trim() ?? '';
                  if (name.length < 2) return strings.storeNameRequired;
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _storeType,
                decoration: InputDecoration(
                  labelText: strings.businessTypeRequested,
                  border: const OutlineInputBorder(),
                ),
                items: types
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(_storeTypeLabel(strings, type)),
                        ))
                    .toList(),
                onChanged: _submitting
                    ? null
                    : (value) {
                        if (value != null) setState(() => _storeType = value);
                      },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLength: 1000,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: strings.storeDescriptionOptional,
                  alignLabelWithHint: true,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(strings.submitProSellerRequest),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
