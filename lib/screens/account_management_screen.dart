import 'package:flutter/material.dart';
import '../models/account.dart';
import '../models/currency.dart';
import '../services/account_service.dart';
import '../services/currency_service.dart';

class AccountManagementScreen extends StatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  State<AccountManagementScreen> createState() => _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  final AccountService _accountService = AccountService();
  final CurrencyService _currencyService = CurrencyService();
  List<Account> _accounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() => _isLoading = true);
    try {
      final accounts = await _accountService.getAccounts();
      setState(() {
        _accounts = accounts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString, radix: 16));
    } catch (e) {
      return Colors.blue;
    }
  }

  Future<void> _showAddEditDialog({Account? account}) async {
    final isEditing = account != null;
    final nameController = TextEditingController(text: account?.name ?? '');
    final iconController = TextEditingController(text: account?.icon ?? '💳');
    Currency selectedCurrency = account?.currency ?? Currency.usd;
    String selectedColor = account?.color ?? 'FF2196F3';
    bool isDefault = account?.isDefault ?? false;

    final availableCurrencies = await _currencyService.getAllAvailableCurrencies();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Account' : 'Add Account'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Account Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: iconController,
                  decoration: const InputDecoration(
                    labelText: 'Icon (Emoji)',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 2,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Currency>(
                  value: selectedCurrency,
                  decoration: const InputDecoration(
                    labelText: 'Currency',
                    border: OutlineInputBorder(),
                  ),
                  isExpanded: true,
                  items: availableCurrencies.map((currency) {
                    return DropdownMenuItem<Currency>(
                      value: currency,
                      child: Row(
                        children: [
                          Text(
                            currency.symbol,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(currency.displayName)),
                          if (currency.isCustom)
                            const Icon(Icons.star, size: 12, color: Colors.amber),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedCurrency = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedColor,
                  decoration: const InputDecoration(
                    labelText: 'Color',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'FF2196F3', child: Row(children: [CircleAvatar(backgroundColor: Color(0xFF2196F3), radius: 10), SizedBox(width: 8), Text('Blue')])),
                    DropdownMenuItem(value: 'FF4CAF50', child: Row(children: [CircleAvatar(backgroundColor: Color(0xFF4CAF50), radius: 10), SizedBox(width: 8), Text('Green')])),
                    DropdownMenuItem(value: 'FFFF9800', child: Row(children: [CircleAvatar(backgroundColor: Color(0xFFFF9800), radius: 10), SizedBox(width: 8), Text('Orange')])),
                    DropdownMenuItem(value: 'FFF44336', child: Row(children: [CircleAvatar(backgroundColor: Color(0xFFF44336), radius: 10), SizedBox(width: 8), Text('Red')])),
                    DropdownMenuItem(value: 'FF9C27B0', child: Row(children: [CircleAvatar(backgroundColor: Color(0xFF9C27B0), radius: 10), SizedBox(width: 8), Text('Purple')])),
                    DropdownMenuItem(value: 'FF00BCD4', child: Row(children: [CircleAvatar(backgroundColor: Color(0xFF00BCD4), radius: 10), SizedBox(width: 8), Text('Cyan')])),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedColor = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Set as Default'),
                  value: isDefault,
                  onChanged: (value) {
                    setDialogState(() => isDefault = value);
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter account name')),
                  );
                  return;
                }
                Navigator.pop(context, true);
              },
              child: Text(isEditing ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      try {
        final newAccount = Account(
          id: account?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          name: nameController.text.trim(),
          currency: selectedCurrency,
          icon: iconController.text.trim(),
          color: selectedColor,
          isDefault: isDefault,
        );

        if (isEditing) {
          await _accountService.updateAccount(newAccount);
        } else {
          await _accountService.saveAccount(newAccount);
        }

        await _loadAccounts();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditing ? 'Account updated' : 'Account added')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteAccount(Account account) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text('Are you sure you want to delete "${account.name}"?\n\nAll expenses in this account will be moved to the default account.'),
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
      try {
        await _accountService.deleteAccount(account.id);
        await _loadAccounts();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Accounts'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _accounts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No accounts yet',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your first account to get started',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _accounts.length,
                  itemBuilder: (context, index) {
                    final account = _accounts[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _parseColor(account.color),
                          child: Text(
                            account.icon,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              account.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (account.isDefault) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Default',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text('${account.currency.displayName} (${account.currency.symbol})'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showAddEditDialog(account: account),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: _accounts.length > 1 ? () => _deleteAccount(account) : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
