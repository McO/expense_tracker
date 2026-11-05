import 'package:flutter/material.dart';

import '../models/currency.dart';
import '../services/amount_format.dart';

/// Amount text field following the phone's number format and the currency's
/// decimals. Validates with [parseAmount] and rewrites valid input in the
/// phone's format (exact decimals) when it loses focus.
class AmountField extends StatefulWidget {
  final TextEditingController controller;
  final Currency currency;
  final Locale locale;
  final InputDecoration decoration;
  final bool allowNegative;
  final bool autofocus;
  final ValueChanged<String>? onChanged;

  /// Extra validation on the parsed value; return an error text or null.
  final String? Function(double amount)? validateAmount;

  const AmountField({
    super.key,
    required this.controller,
    required this.currency,
    required this.locale,
    this.decoration = const InputDecoration(),
    this.allowNegative = false,
    this.autofocus = false,
    this.onChanged,
    this.validateAmount,
  });

  @override
  State<AmountField> createState() => _AmountFieldState();
}

class _AmountFieldState extends State<AmountField> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) return;
    final parsed = parseAmount(widget.controller.text, widget.currency,
        widget.locale, allowNegative: widget.allowNegative);
    if (parsed == null) return;
    final text = formatAmount(parsed, widget.currency, widget.locale);
    if (text != widget.controller.text) {
      widget.controller.text = text;
      widget.onChanged?.call(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      decoration: widget.decoration.copyWith(
        hintText: amountHint(widget.currency, widget.locale),
      ),
      keyboardType: TextInputType.numberWithOptions(
          decimal: widget.currency.decimalPlaces > 0, signed: widget.allowNegative),
      onChanged: widget.onChanged,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter an amount';
        }
        final amount = parseAmount(value, widget.currency, widget.locale,
            allowNegative: widget.allowNegative);
        if (amount == null) {
          final places = widget.currency.decimalPlaces;
          return places == 0
              ? 'Please enter a whole amount'
              : 'Please enter a valid amount (up to $places decimals)';
        }
        return widget.validateAmount?.call(amount);
      },
    );
  }
}
