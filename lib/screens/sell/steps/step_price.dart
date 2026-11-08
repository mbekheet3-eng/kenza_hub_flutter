import 'package:flutter/material.dart';
import 'package:kenza_hub_flutter/core/localization/app_localizations.dart';
import 'package:flutter/services.dart';
import '../../../config/theme.dart';

class StepPrice extends StatefulWidget {
  final Function(double) onPriceChanged;
  final double initialPrice;

  const StepPrice({
    required this.onPriceChanged,
    required this.initialPrice,
  });

  @override
  State<StepPrice> createState() => _StepPriceState();
}

class _StepPriceState extends State<StepPrice> {
  late TextEditingController _priceController;
  late double _currentPrice;

  @override
  void initState() {
    super.initState();
    _currentPrice = widget.initialPrice;
    _priceController = TextEditingController(
      text: _currentPrice > 0 ? _currentPrice.toString() : '',
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  void _updatePrice(double price) {
    setState(() => _currentPrice = price);
    widget.onPriceChanged(price);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).setProductPrice,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),

          // Price Input
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).priceInEgp,
              hintText: AppLocalizations.of(context).priceExample,
              prefixIcon: const Icon(Icons.attach_money),
              suffixText: AppLocalizations.of(context).currency,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) {
              final parsedPrice = double.tryParse(value.trim());
              _updatePrice(
                parsedPrice != null && parsedPrice.isFinite && parsedPrice > 0
                    ? parsedPrice
                    : 0,
              );
            },
          ),

          const SizedBox(height: 24),

          // Price Suggestion
          if (_currentPrice > 0) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb, color: AppTheme.warningColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context).pricingTip,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppLocalizations.of(context).competitivePriceTip,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Price Presets
          Text(
            AppLocalizations.of(context).quickOptions,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickPriceButton('50 ${AppLocalizations.of(context).currency}', 50),
              _buildQuickPriceButton('100 ${AppLocalizations.of(context).currency}', 100),
              _buildQuickPriceButton('200 ${AppLocalizations.of(context).currency}', 200),
              _buildQuickPriceButton('500 ${AppLocalizations.of(context).currency}', 500),
              _buildQuickPriceButton('1000 ${AppLocalizations.of(context).currency}', 1000),
            ],
          ),

          const SizedBox(height: 24),

          // Price Summary
          if (_currentPrice > 0)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppLocalizations.of(context).selectedPrice),
                      Text(
                        '${_currentPrice.toStringAsFixed(2)} ${AppLocalizations.of(context).currency}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickPriceButton(String label, double price) {
    final isSelected = _currentPrice == price;
    return OutlinedButton(
      onPressed: () {
        _priceController.text = price.toString();
        _updatePrice(price);
      },
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : null,
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : AppTheme.borderMedium,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}
