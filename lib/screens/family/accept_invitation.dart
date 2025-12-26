import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meditrack/bloc/family_bloc/family_bloc.dart';
import 'package:meditrack/style/colors.dart';
import 'package:meditrack/widgets/app_bar.dart';

class AcceptInvitationScreen extends StatefulWidget {
  const AcceptInvitationScreen({super.key});

  @override
  State<AcceptInvitationScreen> createState() => _AcceptInvitationScreenState();
}

class _AcceptInvitationScreenState extends State<AcceptInvitationScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final tokenController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool isValidating = false;

  @override
  void dispose() {
    tokenController.dispose();
    super.dispose();
  }

  void _validateAndAcceptInvitation() {
    if (formKey.currentState!.validate()) {
      setState(() => isValidating = true);

      // First validate the token
      context.read<FamilyBloc>().add(
        ValidateInvitationEvent(tokenController.text.trim()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Color(0xFF121212) : Colors.white,
      appBar: MyAppBar.build(context, () {}),
      body: BlocConsumer<FamilyBloc, FamilyState>(
        listener: (context, state) {
          if (state is InvitationValidatedState) {
            setState(() => isValidating = false);

            if (!state.isValid) {
              // Show error
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage ?? 'Invalid invitation'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 4),
                ),
              );
            } else if (state.invitation != null) {
              // Show confirmation dialog
              _showAcceptConfirmationDialog(state.invitation!);
            }
          } else if (state is InvitationAcceptedState) {
            // Success! Navigate to welcome screen
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Successfully joined the family!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else if (state is FamilyErrorState) {
            setState(() => isValidating = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 5),
              ),
            );
            print('Error validating: ${state.error}'); // Debug log
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Icon(
                  Icons.family_restroom,
                  size: 80,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Join a Family Account',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.grey[300] : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Enter the invitation code you received',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),

                // Invitation token input
                Form(
                  key: formKey,
                  child: TextFormField(
                    controller: tokenController,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Invitation Code',
                      hintText: 'Paste your invitation code here',
                      labelStyle: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                      filled: true,
                      fillColor: isDarkMode ? Color(0xFF2C2C2C) : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(
                        Icons.vpn_key,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    maxLines: 2,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter an invitation code';
                      }
                      if (value.trim().length < 10) {
                        return 'Invalid invitation code';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Accept button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isValidating ? null : _validateAndAcceptInvitation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isValidating
                        ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : Text(
                      'Join Family',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Info card
                Card(
                  color: isDarkMode ? Color(0xFF1E1E1E) : Colors.blue[50],
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'How to get an invitation code:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.grey[300] : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInfoItem('1. Ask the family owner to invite you', isDarkMode),
                        _buildInfoItem('2. They will send you an invitation code', isDarkMode),
                        _buildInfoItem('3. Copy the code and paste it here', isDarkMode),
                        _buildInfoItem('4. Tap "Join Family" to accept', isDarkMode),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoItem(String text, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAcceptConfirmationDialog(invitation) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Join Family Account?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You\'ve been invited to join a family account.'),
            const SizedBox(height: 16),
            Text(
              'Invited by:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            Text(invitation.invitedEmail),
            const SizedBox(height: 12),
            Text(
              'By accepting, you\'ll be able to:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            Text('• Share medicine tracking with family'),
            Text('• View family members\' dosages'),
            Text('• Collaborate on medicine management'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (user != null) {
                // Accept the invitation
                context.read<FamilyBloc>().add(
                  AcceptInvitationEvent(
                    invitationToken: tokenController.text.trim(),
                    userId: user!.uid,
                    displayName: user!.displayName ?? 'User',
                    email: user!.email ?? '',
                  ),
                );
                Navigator.pop(dialogContext);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: Text('Accept & Join', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}