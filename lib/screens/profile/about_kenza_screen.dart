import 'package:flutter/material.dart';

class AboutKenzaScreen extends StatelessWidget {
  const AboutKenzaScreen({super.key});

  static const Color _red = Color(0xFFC62828);
  static const Color _navy = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).aboutTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _navy,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.storefront_rounded, color: Colors.white, size: 42),
                SizedBox(height: 18),
                Text(
                  'كنزة هب',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context).brandTagline,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  AppLocalizations.of(context).brandSubtitle,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _section(
            context,
            title: AppLocalizations.of(context).ideaTitle,
            body:
                AppLocalizations.of(context).ideaBody,
          ),
          _section(
            context,
            title: AppLocalizations.of(context).whatYouFindTitle,
            body:
                AppLocalizations.of(context).whatYouFindBody,
          ),
          _section(
            context,
            title: AppLocalizations.of(context).howItWorksTitle,
            body:
                AppLocalizations.of(context).howItWorksBody,
          ),
          _section(
            context,
            title: AppLocalizations.of(context).missionTitle,
            body:
                AppLocalizations.of(context).missionBody,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _red.withOpacity(0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _red.withOpacity(0.18)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.favorite_outline, color: _red),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).aboutThanks,
                    style: TextStyle(
                      color: _navy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Center(
            child: Text(
              AppLocalizations.of(context).copyright,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _section(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _navy,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.8,
                  color: const Color(0xFF475569),
                ),
          ),
        ],
      ),
    );
  }
}
