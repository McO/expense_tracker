import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account.dart';
import '../models/currency.dart';
import 'transactions_store.dart';

class AccountService {
  static const String _accountsKey = 'accounts';
  static const String _selectedAccountKey = 'selected_account_id';

  Future<List<Account>> getAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final accountsJson = prefs.getStringList(_accountsKey) ?? [];
    
    if (accountsJson.isEmpty) {
      // Create default account if none exists
      final defaultAccount = Account(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Main Account',
        currency: Currency.usd,
        icon: '💳',
        color: 'FF2196F3',
        isDefault: true,
      );
      // Save directly without calling saveAccount to avoid infinite recursion
      await prefs.setStringList(_accountsKey, [jsonEncode(defaultAccount.toJson())]);
      return [defaultAccount];
    }
    
    return accountsJson.map((json) => Account.fromJson(jsonDecode(json))).toList();
  }

  Future<Account?> getSelectedAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedId = prefs.getString(_selectedAccountKey);
    
    if (selectedId == null) {
      // Return default account or first account
      final accounts = await getAccounts();
      if (accounts.isEmpty) return null;
      
      final defaultAccount = accounts.firstWhere(
        (account) => account.isDefault,
        orElse: () => accounts.first,
      );
      
      await setSelectedAccount(defaultAccount.id);
      return defaultAccount;
    }
    
    final accounts = await getAccounts();
    try {
      return accounts.firstWhere((account) => account.id == selectedId);
    } catch (e) {
      // Selected account not found, return first account
      if (accounts.isNotEmpty) {
        await setSelectedAccount(accounts.first.id);
        return accounts.first;
      }
      return null;
    }
  }

  Future<void> setSelectedAccount(String accountId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedAccountKey, accountId);
  }

  Future<void> saveAccount(Account account) async {
    final accounts = await getAccounts();
    
    // If this is being set as default, remove default from others
    if (account.isDefault) {
      for (int i = 0; i < accounts.length; i++) {
        if (accounts[i].isDefault) {
          accounts[i] = accounts[i].copyWith(isDefault: false);
        }
      }
    }
    
    accounts.add(account);
    await _saveAccounts(accounts);
  }

  Future<void> updateAccount(Account account) async {
    final accounts = await getAccounts();
    final index = accounts.indexWhere((a) => a.id == account.id);
    
    if (index != -1) {
      // If this is being set as default, remove default from others
      if (account.isDefault) {
        for (int i = 0; i < accounts.length; i++) {
          if (i != index && accounts[i].isDefault) {
            accounts[i] = accounts[i].copyWith(isDefault: false);
          }
        }
      }
      
      accounts[index] = account;
      await _saveAccounts(accounts);
    }
  }

  Future<void> deleteAccount(String accountId) async {
    final accounts = await getAccounts();
    final deleteIdx = accounts.indexWhere((a) => a.id == accountId);
    if (deleteIdx < 0) return;
    final accountToDelete = accounts[deleteIdx];
    
    // Don't allow deleting the last account
    if (accounts.length <= 1) {
      throw Exception('Cannot delete the last account');
    }
    
    accounts.removeWhere((account) => account.id == accountId);
    
    // If deleted account was default, make first remaining account default
    if (accountToDelete.isDefault && accounts.isNotEmpty) {
      accounts[0] = accounts[0].copyWith(isDefault: true);
    }
    
    await _saveAccounts(accounts);

    // Deleting an account deletes its transactions too
    final stored = await TransactionsStore.read();
    final kept = stored
        .where((j) => (jsonDecode(j) as Map<String, dynamic>)['accountId'] != accountId)
        .toList();
    if (kept.length != stored.length) {
      await TransactionsStore.write(kept);
    }
    
    // If deleted account was selected, select the default or first account
    final selectedAccount = await getSelectedAccount();
    if (selectedAccount?.id == accountId) {
      final newDefaultAccount = accounts.firstWhere(
        (a) => a.isDefault,
        orElse: () => accounts.first,
      );
      await setSelectedAccount(newDefaultAccount.id);
    }
  }

  Future<void> _saveAccounts(List<Account> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    final accountsJson = accounts.map((a) => jsonEncode(a.toJson())).toList();
    await prefs.setStringList(_accountsKey, accountsJson);
  }

  Future<Account?> getAccountById(String accountId) async {
    final accounts = await getAccounts();
    final idx = accounts.indexWhere((a) => a.id == accountId);
    return idx >= 0 ? accounts[idx] : null;
  }
}
