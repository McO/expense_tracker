import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/currency.dart';
import '../services/settings_service.dart';
import '../services/theme_service.dart';
import '../services/currency_service.dart';
import 'account_management_screen.dart';

class SettingsScreen extends StatefulWidget {
  final Function(AppThemeMode)? onThemeModeChanged;
  final AppThemeMode currentThemeMode;

  const SettingsScreen({
    super.key,
    this.onThemeModeChanged,
    this.currentThemeMode = AppThemeMode.system,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  final ThemeService _themeService = ThemeService();
  final CurrencyService _currencyService = CurrencyService();
  Currency _selectedCurrency = Currency.usd;
  bool _isLoading = true;
  AppThemeMode _currentThemeMode = AppThemeMode.system;
  List<Currency> _customCurrencies = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final currency = await _settingsService.getDefaultCurrency();
      final themeMode = await _themeService.getThemeMode();
      final customCurrencies = await _currencyService.getCustomCurrencies();
      setState(() {
        _selectedCurrency = currency;
        _currentThemeMode = themeMode;
        _customCurrencies = customCurrencies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateCurrency(Currency currency) async {
    try {
      await _settingsService.setDefaultCurrency(currency);
      setState(() {
        _selectedCurrency = currency;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Default currency updated to ${currency.displayName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating currency: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateThemeMode(AppThemeMode mode) async {
    try {
      await _themeService.setThemeMode(mode);
      setState(() {
        _currentThemeMode = mode;
      });

      // Call the parent's theme mode change callback if provided
      widget.onThemeModeChanged?.call(mode);

      if (mounted) {
        String modeText;
        switch (mode) {
          case AppThemeMode.light:
            modeText = 'Light mode';
            break;
          case AppThemeMode.dark:
            modeText = 'Dark mode';
            break;
          case AppThemeMode.system:
            modeText = 'System mode';
            break;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Theme changed to $modeText'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating theme: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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

  Future<void> _showAddCurrencyDialog() async {
    final codeController = TextEditingController();
    final symbolController = TextEditingController();
    final nameController = TextEditingController();
    bool lookupFound = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Custom Currency'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeController,
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
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    codeController.dispose();
    symbolController.dispose();
    nameController.dispose();

    if (result == true && mounted) {
      try {
        await _currencyService.addCustomCurrency(
          codeController.text.trim(),
          symbolController.text.trim(),
          nameController.text.trim(),
        );
        
        await _loadSettings();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Currency ${codeController.text.toUpperCase()} added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding currency: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteCustomCurrency(String code) async {
    try {
      await _currencyService.removeCustomCurrency(code);
      await _loadSettings();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Currency $code removed successfully'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Account Management Section
                  Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.account_balance_wallet,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: const Text(
                        'Account Management',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text('Manage your accounts and currencies'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AccountManagementScreen(),
                          ),
                        );
                        // Reload settings after returning from account management
                        _loadSettings();
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.add_circle_outline,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Custom Currencies',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: _showAddCurrencyDialog,
                                tooltip: 'Add Currency',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add custom currencies to use in your expenses',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                          const SizedBox(height: 16),
                          if (_customCurrencies.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Center(
                                child: Text(
                                  'No custom currencies added yet',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.grey[500],
                                      ),
                                ),
                              ),
                            )
                          else
                            ...(_customCurrencies.map((currency) {
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                  child: Text(
                                    currency.symbol,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  currency.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text('${currency.code} • ${currency.symbol}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
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
                                    
                                    if (confirm == true) {
                                      await _deleteCustomCurrency(currency.code);
                                    }
                                  },
                                ),
                              );
                            }).toList()),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _getThemeIcon(),
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Appearance',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Choose your preferred theme',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                          ),
                          const SizedBox(height: 16),
                          _buildThemeOption(
                            AppThemeMode.light,
                            'Light',
                            'Use light theme',
                            Icons.light_mode,
                          ),
                          const SizedBox(height: 8),
                          _buildThemeOption(
                            AppThemeMode.dark,
                            'Dark',
                            'Use dark theme',
                            Icons.dark_mode,
                          ),
                          const SizedBox(height: 8),
                          _buildThemeOption(
                            AppThemeMode.system,
                            'System',
                            'Follow device settings',
                            Icons.settings_system_daydream,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildThemeOption(AppThemeMode mode, String label, String description, IconData icon) {
    final isSelected = _currentThemeMode == mode;

    return InkWell(
      onTap: () => _updateThemeMode(mode),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color:
                  isSelected ? Theme.of(context).colorScheme.onPrimaryContainer : Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8)
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  IconData _getThemeIcon() {
    switch (_currentThemeMode) {
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.dark:
        return Icons.dark_mode;
      case AppThemeMode.system:
        return Icons.settings_system_daydream;
    }
  }
}
