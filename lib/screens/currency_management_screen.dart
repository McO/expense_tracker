import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/currency.dart';
import '../services/currency_service.dart';

class CurrencyManagementScreen extends StatefulWidget {
  const CurrencyManagementScreen({super.key});

  @override
  State<CurrencyManagementScreen> createState() => _CurrencyManagementScreenState();
}

class _CurrencyManagementScreenState extends State<CurrencyManagementScreen> {
  final CurrencyService _currencyService = CurrencyService();
  List<Currency> _customCurrencies = [];
  bool _isLoading = true;

  static const Map<String, String> _isoNames = {
    'AED': 'UAE Dirham', 'AFN': 'Afghan Afghani', 'ALL': 'Albanian Lek',
    'AMD': 'Armenian Dram', 'ANG': 'Netherlands Antillean Guilder',
    'AOA': 'Angolan Kwanza', 'ARS': 'Argentine Peso', 'AUD': 'Australian Dollar',
    'AWG': 'Aruban Florin', 'AZN': 'Azerbaijani Manat',
    'BAM': 'Bosnia-Herzegovina Mark', 'BBD': 'Barbadian Dollar',
    'BDT': 'Bangladeshi Taka', 'BGN': 'Bulgarian Lev', 'BHD': 'Bahraini Dinar',
    'BND': 'Brunei Dollar', 'BOB': 'Bolivian Boliviano', 'BRL': 'Brazilian Real',
    'BSD': 'Bahamian Dollar', 'BTN': 'Bhutanese Ngultrum',
    'BWP': 'Botswanan Pula', 'BYN': 'Belarusian Ruble', 'BZD': 'Belize Dollar',
    'CAD': 'Canadian Dollar', 'CDF': 'Congolese Franc', 'CHF': 'Swiss Franc',
    'CLP': 'Chilean Peso', 'CNY': 'Chinese Yuan', 'COP': 'Colombian Peso',
    'CRC': 'Costa Rican Colón', 'CUP': 'Cuban Peso', 'CVE': 'Cape Verdean Escudo',
    'CZK': 'Czech Koruna', 'DJF': 'Djiboutian Franc', 'DKK': 'Danish Krone',
    'DOP': 'Dominican Peso', 'DZD': 'Algerian Dinar', 'EGP': 'Egyptian Pound',
    'ERN': 'Eritrean Nakfa', 'ETB': 'Ethiopian Birr', 'EUR': 'Euro',
    'FJD': 'Fijian Dollar', 'GBP': 'British Pound', 'GEL': 'Georgian Lari',
    'GHS': 'Ghanaian Cedi', 'GMD': 'Gambian Dalasi', 'GNF': 'Guinean Franc',
    'GTQ': 'Guatemalan Quetzal', 'GYD': 'Guyanaese Dollar',
    'HKD': 'Hong Kong Dollar', 'HNL': 'Honduran Lempira',
    'HTG': 'Haitian Gourde', 'HUF': 'Hungarian Forint', 'IDR': 'Indonesian Rupiah',
    'ILS': 'Israeli New Shekel', 'INR': 'Indian Rupee', 'IQD': 'Iraqi Dinar',
    'IRR': 'Iranian Rial', 'ISK': 'Icelandic Króna', 'JMD': 'Jamaican Dollar',
    'JOD': 'Jordanian Dinar', 'JPY': 'Japanese Yen', 'KES': 'Kenyan Shilling',
    'KGS': 'Kyrgystani Som', 'KHR': 'Cambodian Riel', 'KMF': 'Comorian Franc',
    'KRW': 'South Korean Won', 'KWD': 'Kuwaiti Dinar',
    'KYD': 'Cayman Islands Dollar', 'KZT': 'Kazakhstani Tenge',
    'LAK': 'Laotian Kip', 'LBP': 'Lebanese Pound', 'LKR': 'Sri Lankan Rupee',
    'LRD': 'Liberian Dollar', 'LYD': 'Libyan Dinar', 'MAD': 'Moroccan Dirham',
    'MDL': 'Moldovan Leu', 'MKD': 'Macedonian Denar', 'MMK': 'Myanmar Kyat',
    'MNT': 'Mongolian Tögrög', 'MOP': 'Macanese Pataca',
    'MUR': 'Mauritian Rupee', 'MVR': 'Maldivian Rufiyaa',
    'MWK': 'Malawian Kwacha', 'MXN': 'Mexican Peso', 'MYR': 'Malaysian Ringgit',
    'MZN': 'Mozambican Metical', 'NAD': 'Namibian Dollar',
    'NGN': 'Nigerian Naira', 'NIO': 'Nicaraguan Córdoba',
    'NOK': 'Norwegian Krone', 'NPR': 'Nepalese Rupee', 'NZD': 'New Zealand Dollar',
    'OMR': 'Omani Rial', 'PAB': 'Panamanian Balboa', 'PEN': 'Peruvian Sol',
    'PGK': 'Papua New Guinean Kina', 'PHP': 'Philippine Peso',
    'PKR': 'Pakistani Rupee', 'PLN': 'Polish Złoty', 'PYG': 'Paraguayan Guarani',
    'QAR': 'Qatari Rial', 'RON': 'Romanian Leu', 'RSD': 'Serbian Dinar',
    'RUB': 'Russian Ruble', 'RWF': 'Rwandan Franc', 'SAR': 'Saudi Riyal',
    'SBD': 'Solomon Islands Dollar', 'SCR': 'Seychellois Rupee',
    'SDG': 'Sudanese Pound', 'SEK': 'Swedish Krona', 'SGD': 'Singapore Dollar',
    'SHP': 'Saint Helena Pound', 'SOS': 'Somali Shilling',
    'SRD': 'Surinamese Dollar', 'SYP': 'Syrian Pound', 'SZL': 'Swazi Lilangeni',
    'THB': 'Thai Baht', 'TJS': 'Tajikistani Somoni', 'TMT': 'Turkmenistani Manat',
    'TND': 'Tunisian Dinar', 'TOP': "Tongan Pa'anga", 'TRY': 'Turkish Lira',
    'TTD': 'Trinidad & Tobago Dollar', 'TWD': 'New Taiwan Dollar',
    'TZS': 'Tanzanian Shilling', 'UAH': 'Ukrainian Hryvnia',
    'UGX': 'Ugandan Shilling', 'USD': 'US Dollar', 'UYU': 'Uruguayan Peso',
    'UZS': 'Uzbekistani Som', 'VND': 'Vietnamese Đồng', 'VUV': 'Vanuatu Vatu',
    'WST': 'Samoan Tala', 'XAF': 'Central African CFA Franc',
    'XCD': 'East Caribbean Dollar', 'XOF': 'West African CFA Franc',
    'XPF': 'CFP Franc', 'YER': 'Yemeni Rial', 'ZAR': 'South African Rand',
    'ZMW': 'Zambian Kwacha',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final currencies = await _currencyService.getCustomCurrencies();
    setState(() {
      _customCurrencies = currencies;
      _isLoading = false;
    });
  }

  void _lookupCurrency(String code, StateSetter setDialogState,
      TextEditingController symbolController,
      TextEditingController nameController) {
    final name = _isoNames[code];

    String symbol = '';
    try {
      final s = NumberFormat.simpleCurrency(name: code).currencySymbol;
      if (s != code) symbol = s;
    } catch (_) {}

    setDialogState(() {
      if (name != null) nameController.text = name;
      if (symbol.isNotEmpty) symbolController.text = symbol;
    });
  }

  Future<void> _showAddCurrencyDialog() => _showCurrencyDialog();

  Future<void> _showCurrencyDialog({Currency? existing}) async {
    final isEdit = existing != null;
    final codeController = TextEditingController(text: existing?.code ?? '');
    final symbolController =
        TextEditingController(text: existing?.symbol ?? '');
    final nameController = TextEditingController(text: existing?.name ?? '');
    int decimalPlaces = existing?.decimalPlaces ?? 2;
    bool lookupFound = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Custom Currency' : 'Add Custom Currency'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeController,
                  enabled: !isEdit,
                  decoration: InputDecoration(
                    labelText: 'Currency Code',
                    hintText: 'e.g., EUR',
                    border: const OutlineInputBorder(),
                    helperText: 'Symbol and name auto-filled when recognized',
                    suffixIcon: lookupFound
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                  ),
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 3,
                  onChanged: (value) {
                    final code = value.toUpperCase();
                    if (code.length == 3) {
                      _lookupCurrency(
                          code, setDialogState, symbolController, nameController);
                      setDialogState(
                          () => lookupFound = _isoNames.containsKey(code));
                    } else {
                      setDialogState(() => lookupFound = false);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: symbolController,
                  decoration: const InputDecoration(
                    labelText: 'Symbol',
                    hintText: 'e.g., €',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Currency Name',
                    hintText: 'e.g., Euro',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Decimal places',
                      style: Theme.of(context).textTheme.labelLarge),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    children: [
                      for (final n in const [0, 1, 2, 3])
                        ChoiceChip(
                          key: Key('decimal-places-$n'),
                          label: Text('$n'),
                          selected: decimalPlaces == n,
                          onSelected: (_) =>
                              setDialogState(() => decimalPlaces = n),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (codeController.text.isEmpty ||
                    symbolController.text.isEmpty ||
                    nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all fields'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              child: Text(isEdit ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );

    final code = codeController.text.trim();
    final symbol = symbolController.text.trim();
    final name = nameController.text.trim();

    // Controllers are not disposed here: the dialog is still animating out and
    // would rebuild with a disposed controller. They hold no resources.

    if (result == true && mounted) {
      try {
        if (isEdit) {
          await _currencyService.updateCustomCurrency(existing.code,
              symbol: symbol, name: name, decimalPlaces: decimalPlaces);
        } else {
          await _currencyService.addCustomCurrency(code, symbol, name,
              decimalPlaces: decimalPlaces);
        }
        await _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEdit
                  ? 'Currency ${existing.code} updated'
                  : 'Currency ${code.toUpperCase()} added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving currency: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteCurrency(Currency currency) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Currency'),
        content: Text('Remove ${currency.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _currencyService.removeCustomCurrency(currency.code);
        await _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Currency ${currency.code} removed'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error removing currency: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Currencies',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCurrencyDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add currency'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _customCurrencies.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.currency_exchange,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No custom currencies yet',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey[500],
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap "Add currency" to add a custom currency',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[400],
                            ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _customCurrencies.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final currency = _customCurrencies[index];
                    return Card(
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          child: Text(
                            currency.symbol,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          currency.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                            '${currency.code} • ${currency.symbol} • ${currency.decimalPlaces} decimals'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showCurrencyDialog(existing: currency);
                            }
                            if (value == 'delete') _deleteCurrency(currency);
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete'),
                                ],
                              ),
                            ),
                          ],
                          child: const Icon(Icons.more_vert),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
