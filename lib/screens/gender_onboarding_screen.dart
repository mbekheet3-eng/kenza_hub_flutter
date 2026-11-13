import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_strings.dart';

class GenderOnboardingScreen extends StatefulWidget {
  const GenderOnboardingScreen({super.key, required this.onCompleted});

  final VoidCallback onCompleted;

  @override
  State<GenderOnboardingScreen> createState() => _GenderOnboardingScreenState();
}

class _GenderOnboardingScreenState extends State<GenderOnboardingScreen> {
  String? _gender;
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    if (_gender == null || _saving) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await Supabase.instance.client
          .from('profiles')
          .upsert({'id': user.id, 'gender': _gender}, onConflict: 'id');
      widget.onCompleted();
    } catch (error) {
      if (mounted) setState(() => _error = '${AppStrings.of(context)!.saveSelectionFailed}: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.of(context)!.accountSetupTitle), automaticallyImplyLeading: false),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.of(context)!.selectGenderTitle, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(AppStrings.of(context)!.genderAudienceExplanation),
              const SizedBox(height: 20),
              RadioGroup<String>(
                groupValue: _gender,
                onChanged: (value) {
                  if (_saving || value == null) return;
                  setState(() => _gender = value);
                },
                child: Column(
                  children: [
                    RadioListTile<String>(
                      value: 'male',
                      title: Text(AppStrings.of(context)!.genderMan),
                      contentPadding: EdgeInsets.zero,
                      enabled: !_saving,
                    ),
                    RadioListTile<String>(
                      value: 'female',
                      title: Text(AppStrings.of(context)!.genderWoman),
                      contentPadding: EdgeInsets.zero,
                      enabled: !_saving,
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving || _gender == null ? null : _save,
                  child: _saving
                      ? const CircularProgressIndicator()
                      : Text(AppStrings.of(context)!.confirmAndContinue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
