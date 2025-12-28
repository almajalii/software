import 'package:flutter/material.dart';
import 'package:meditrack/services/account_manager.dart';
import 'package:meditrack/screens/auth/login_screen.dart';
import 'package:meditrack/screens/main/home/navigation_main.dart';
import 'package:meditrack/style/colors.dart';

class AccountSwitcherScreen extends StatefulWidget {
  const AccountSwitcherScreen({super.key});

  @override
  State<AccountSwitcherScreen> createState() => _AccountSwitcherScreenState();
}

class _AccountSwitcherScreenState extends State<AccountSwitcherScreen> {
  final AccountManager _accountManager = AccountManager();
  List<SavedAccount> _accounts = [];
  bool _isLoading = true;
  String? _currentAccountEmail;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() => _isLoading = true);

    final accounts = await _accountManager.getSavedAccounts();
    final currentEmail = await _accountManager.getCurrentAccountEmail();

    setState(() {
      _accounts = accounts;
      _currentAccountEmail = currentEmail;
      _isLoading = false;
    });
  }

  Future<void> _switchToAccount(SavedAccount account) async {
    // Check if credentials are saved
    final credentials = await _accountManager.getAccountCredentials(account.email);

    if (credentials != null && credentials['password']!.isNotEmpty) {
      // Quick switch with saved password
      _showQuickSwitchDialog(account, credentials['password']!);
    } else {
      // Need to enter password
      _showPasswordDialog(account);
    }
  }

  void _showQuickSwitchDialog(SavedAccount account, String password) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Switch Account'),
        content: Text('Switch to ${account.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performSwitch(account.email, password);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Switch', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPasswordDialog(SavedAccount account) {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool rememberPassword = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Sign in as ${account.displayName}'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  account.email,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (v) => v!.isEmpty ? 'Enter password' : null,
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text(
                    'Remember password for quick switching',
                    style: TextStyle(fontSize: 13),
                  ),
                  value: rememberPassword,
                  onChanged: (value) {
                    setDialogState(() => rememberPassword = value ?? false);
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext);

                  // Save password if requested
                  if (rememberPassword) {
                    await _accountManager.saveAccountPassword(
                      account.email,
                      passwordController.text,
                    );
                  }

                  await _performSwitch(account.email, passwordController.text);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Sign In', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performSwitch(String email, String password) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final success = await _accountManager.switchAccount(email, password);

    // Hide loading
    Navigator.pop(context);

    if (success) {
      // Navigate to main screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const NavigationMain()),
            (route) => false,
      );
    } else {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to switch account. Please check your password.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addNewAccount() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  Future<void> _removeAccount(SavedAccount account) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Account'),
        content: Text(
          'Remove ${account.displayName} from saved accounts?\n\nYou can add it back by signing in again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _accountManager.removeAccount(account.email);
      _loadAccounts(); // Reload list

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${account.displayName} removed'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: const Text('Switch Account'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              colors: [Color(0xFF1A3A6B), Color(0xFF00B9E4)],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _accounts.isEmpty
          ? _buildEmptyState(isDarkMode)
          : _buildAccountList(isDarkMode),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewAccount,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Add Account', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No saved accounts',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to add an account',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountList(bool isDarkMode) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _accounts.length,
      itemBuilder: (context, index) {
        final account = _accounts[index];
        final isCurrentAccount = account.email == _currentAccountEmail;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: isCurrentAccount ? 4 : 2,
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isCurrentAccount
                ? BorderSide(color: AppColors.primary, width: 2)
                : BorderSide.none,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Text(
                account.displayName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    account.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.grey[300] : Colors.black87,
                    ),
                  ),
                ),
                if (isCurrentAccount)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Current',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  account.email,
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Last used: ${_formatDate(account.lastUsed)}',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[600] : Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            trailing: isCurrentAccount
                ? null
                : PopupMenuButton(
              icon: Icon(
                Icons.more_vert,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'switch',
                  child: Row(
                    children: [
                      Icon(Icons.swap_horiz),
                      SizedBox(width: 8),
                      Text('Switch to this account'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Remove', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'switch') {
                  _switchToAccount(account);
                } else if (value == 'remove') {
                  _removeAccount(account);
                }
              },
            ),
            onTap: isCurrentAccount ? null : () => _switchToAccount(account),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${date.month}/${date.day}/${date.year}';
  }
}