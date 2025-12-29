import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:meditrack/screens/auth/start_screen.dart';
import 'package:meditrack/screens/main/settings/edit_profile_screen.dart';
import 'package:meditrack/screens/main/settings/user_feedback_screen.dart';
import 'package:meditrack/services/account_manager.dart';
import 'package:meditrack/style/colors.dart';
import 'package:meditrack/bloc/theme_bloc/theme_bloc.dart';
import 'package:meditrack/screens/main/settings/chat_support_screen.dart';
import 'package:meditrack/screens/main/home/pharmacy_search_screen.dart';
import 'account_switcher.dart';
import 'data_export.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AccountManager _accountManager = AccountManager();

  User? user;
  int savedAccountsCount = 0;

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
    _loadSavedAccountsCount();
  }

  Future<void> _loadSavedAccountsCount() async {
    final accounts = await _accountManager.getSavedAccounts();
    setState(() {
      savedAccountsCount = accounts.length;
    });
  }

  void logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const StartScreen()),
          (route) => false,
        );
      }
    }
  }

  void openEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
    );
  }

  void openDataExport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DataExportScreen()),
    );
  }

  void openAccountSwitcher() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AccountSwitcherScreen()),
    ).then((_) => _loadSavedAccountsCount());
  }

  void openFeedback() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserFeedbackScreen()),
    );
  }

  void openPharmacySearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PharmacySearchScreen()),
    );
  }

  void _showContactDialog() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
          title: Row(
            children: [
              Icon(Icons.contact_support, color: AppColors.primary),
              const SizedBox(width: 12),
              const Text('Contact Us'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildContactButton(
                  context: context,
                  isDarkMode: isDarkMode,
                  icon: Icons.email,
                  title: 'Email Support',
                  subtitle: 'support@meditrack.com',
                  onTap: _launchEmail,
                ),
                const SizedBox(height: 12),
                _buildContactButton(
                  context: context,
                  isDarkMode: isDarkMode,
                  icon: Icons.phone,
                  title: 'Phone Support',
                  subtitle: '+1 (555) 123-4567',
                  onTap: () {},
                ),
                const SizedBox(height: 20),
                Text(
                  'Follow Us',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSocialButton(
                      context: context,
                      isDarkMode: isDarkMode,
                      icon: Icons.facebook,
                      label: 'Facebook',
                      color: const Color(0xFF1877F2),
                      onTap: () => _launchSocialMedia('https://facebook.com/meditrack'),
                    ),
                    _buildSocialButton(
                      context: context,
                      isDarkMode: isDarkMode,
                      icon: Icons.camera_alt,
                      label: 'Instagram',
                      color: const Color(0xFFE4405F),
                      onTap: () => _launchSocialMedia('https://instagram.com/meditrack'),
                    ),
                    _buildSocialButton(
                      context: context,
                      isDarkMode: isDarkMode,
                      icon: Icons.chat,
                      label: 'Twitter',
                      color: const Color(0xFF1DA1F2),
                      onTap: () => _launchSocialMedia('https://twitter.com/meditrack'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContactButton({
    required BuildContext context,
    required bool isDarkMode,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isDarkMode ? Colors.grey[300] : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required BuildContext context,
    required bool isDarkMode,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@meditrack.com',
      query: 'subject=MediTrack Support Request',
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open email client'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _launchSocialMedia(String url) async {
    final Uri uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open link'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: Container(
          height: 70,
          width: 70,
          child: Image.asset('images/1.png'),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout),
            color: AppColors.error,
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              colors: [Color(0xFF1A3A6B), Color(0xFF00B9E4)],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // User Info Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      color: AppColors.primary,
                      size: 40,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'User',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.grey[300] : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Edit Profile Card
            Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Icon(
                  Icons.edit,
                  color: AppColors.primary,
                  size: 28,
                ),
                title: const Text(
                  'Edit Profile',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Update your personal information',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: openEditProfile,
              ),
            ),

            // Theme Toggle Card
            Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: BlocBuilder<ThemeBloc, ThemeState>(
                builder: (context, themeState) {
                  return SwitchListTile(
                    title: const Text(
                      'Dark Mode',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      themeState.isDarkMode
                          ? 'Dark theme enabled'
                          : 'Light theme enabled',
                    ),
                    value: themeState.isDarkMode,
                    onChanged: (value) {
                      context.read<ThemeBloc>().add(ToggleThemeEvent());
                    },
                    secondary: Icon(
                      themeState.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color: AppColors.primary,
                    ),
                    activeColor: AppColors.primary,
                  );
                },
              ),
            ),

            // Account Switcher Card
            Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Stack(
                  children: [
                    Icon(
                      Icons.people,
                      color: AppColors.primary,
                      size: 28,
                    ),
                    if (savedAccountsCount > 1)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Center(
                            child: Text(
                              '$savedAccountsCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                title: const Text(
                  'Switch Account',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  savedAccountsCount > 1
                      ? '$savedAccountsCount accounts saved'
                      : 'Manage your accounts',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: openAccountSwitcher,
              ),
            ),

            // Pharmacy Search Card
            Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Icon(
                  Icons.local_pharmacy,
                  color: AppColors.primary,
                  size: 28,
                ),
                title: const Text(
                  'Find Nearby Pharmacies',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Search for pharmacies near you',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: openPharmacySearch,
              ),
            ),

            // Chat Support Card
            Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Icon(
                  Icons.chat_bubble_outline,
                  color: AppColors.primary,
                  size: 28,
                ),
                title: const Text(
                  'Chat Support',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Live chat with customer service',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChatSupportScreen(),
                    ),
                  );
                },
              ),
            ),

            // Data Export Card
            Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Icon(
                  Icons.download,
                  color: AppColors.primary,
                  size: 28,
                ),
                title: const Text(
                  'Export Data',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Download your data as PDF',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: openDataExport,
              ),
            ),

            // Feedback Card
            Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Icon(
                  Icons.feedback_outlined,
                  color: AppColors.primary,
                  size: 28,
                ),
                title: const Text(
                  'Send Feedback',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Help us improve MediTrack',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: openFeedback,
              ),
            ),

            // Contact Us Card
            Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Icon(
                  Icons.contact_support,
                  color: AppColors.primary,
                  size: 28,
                ),
                title: const Text(
                  'Contact Us',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Get in touch with our team',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _showContactDialog,
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}