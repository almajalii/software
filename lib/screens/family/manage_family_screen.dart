import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meditrack/bloc/family_bloc/family_bloc.dart';
import 'package:meditrack/model/family_invitation.dart';
import 'package:meditrack/model/family_member.dart';
import 'package:meditrack/style/colors.dart';
import 'package:meditrack/widgets/app_bar.dart';

class ManageFamilyScreen extends StatefulWidget {
  const ManageFamilyScreen({super.key});

  @override
  State<ManageFamilyScreen> createState() => _ManageFamilyScreenState();
}

class _ManageFamilyScreenState extends State<ManageFamilyScreen> {
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      context.read<FamilyBloc>().add(LoadFamilyAccountEvent(user!.uid));
    }
  }

  void _loadPendingInvitations(String familyAccountId) {
    context.read<FamilyBloc>().add(LoadPendingInvitationsEvent(familyAccountId));
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Color(0xFF121212) : Colors.white,
      appBar: MyAppBar.build(context, () {}),
      body: BlocConsumer<FamilyBloc, FamilyState>(
        listener: (context, state) {
          if (state is FamilyAccountCreatedState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Family account created successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is InvitationSentState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          } else if (state is FamilyMemberRemovedState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is FamilyAccountDeletedState) {
            // Navigate back to welcome screen
            Navigator.pop(context);
          } else if (state is FamilyErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is FamilyLoadingState) {
            return Center(child: CircularProgressIndicator());
          }

          if (state is NoFamilyAccountState) {
            return _buildCreateFamilyView(isDarkMode);
          }

          if (state is FamilyAccountLoadedState) {
            // Always load pending invitations to keep them up to date
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadPendingInvitations(state.familyAccount.id);
            });
            return _buildFamilyManagementView(state, isDarkMode);
          }

          return Center(
            child: Text(
              'Loading family account...',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.black87,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCreateFamilyView(bool isDarkMode) {
    final familyNameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Icon(
              Icons.family_restroom,
              size: 70,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Create Your Family Account',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.grey[300] : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Share medicine tracking with family',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Form(
              key: formKey,
              child: SizedBox(
                width: 300,
                child: TextFormField(
                  controller: familyNameController,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Family Name',
                    hintText: 'e.g., Smith Family',
                    labelStyle: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    filled: true,
                    fillColor: isDarkMode ? Color(0xFF2C2C2C) : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a family name';
                    }
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate() && user != null) {
                  context.read<FamilyBloc>().add(
                    CreateFamilyAccountEvent(
                      userId: user!.uid,
                      familyName: familyNameController.text.trim(),
                      primaryContactEmail: user!.email ?? '',
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Create Family Account',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyManagementView(FamilyAccountLoadedState state, bool isDarkMode) {
    final isOwner = state.familyAccount.ownerId == user?.uid;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Family name header
          Card(
            color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.family_restroom,
                    color: AppColors.primary,
                    size: 40,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.familyAccount.familyName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.grey[300] : Colors.black87,
                          ),
                        ),
                        Text(
                          '${state.members.length} member${state.members.length != 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Members section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Family Members',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.grey[300] : Colors.black87,
                ),
              ),
              if (isOwner)
                TextButton.icon(
                  onPressed: () => _showInviteMemberDialog(context, state.familyAccount.id, isDarkMode),
                  icon: Icon(Icons.person_add, size: 20),
                  label: Text('Invite'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Members list
          ...state.members.map((member) {
            final isCurrentUser = member.userId == user?.uid;
            return Card(
              color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: member.role == MemberRole.owner
                      ? AppColors.primary
                      : (isDarkMode ? Colors.grey[700] : Colors.grey[300]),
                  child: Text(
                    member.displayName.isNotEmpty ? member.displayName[0].toUpperCase() : 'U',
                    style: TextStyle(
                      color: member.role == MemberRole.owner
                          ? Colors.white
                          : (isDarkMode ? Colors.white : Colors.black87),
                    ),
                  ),
                ),
                title: Row(
                  children: [
                    Text(
                      member.displayName,
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[300] : Colors.black87,
                      ),
                    ),
                    if (isCurrentUser)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'You',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Text(
                  member.email,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                trailing: member.role == MemberRole.owner
                    ? Chip(
                  label: Text(
                    'Owner',
                    style: TextStyle(fontSize: 11, color: Colors.white),
                  ),
                  backgroundColor: AppColors.primary,
                )
                    : (isOwner && !isCurrentUser
                    ? IconButton(
                  icon: Icon(Icons.remove_circle_outline, color: Colors.red),
                  onPressed: () => _confirmRemoveMember(context, state.familyAccount.id, member.id, member.displayName),
                )
                    : null),
              ),
            );
          }).toList(),

          // Pending invitations (owner only)
          if (isOwner && state.pendingInvitations.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Pending Invitations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.grey[300] : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            ...state.pendingInvitations.map((invitation) {
              return Card(
                color: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(Icons.mail_outline, color: Colors.orange),
                  title: Text(
                    invitation.invitedEmail,
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[300] : Colors.black87,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expires: ${_formatDate(invitation.expiresAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Code: ${invitation.invitationToken}',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.primary,
                                fontFamily: 'monospace',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.copy, size: 16, color: AppColors.primary),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                            onPressed: () {
                              // Copy to clipboard
                              Clipboard.setData(ClipboardData(text: invitation.invitationToken));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Invitation code copied!'),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.cancel, color: Colors.red),
                    onPressed: () {
                      context.read<FamilyBloc>().add(
                        DeleteInvitationEvent(
                          familyAccountId: state.familyAccount.id,
                          invitationId: invitation.id,
                        ),
                      );
                      // Show immediate feedback
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Invitation cancelled'),
                          backgroundColor: Colors.orange,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
              );
            }).toList(),
          ],

          // Delete Family Account button (owner only)
          if (isOwner) ...[
            const SizedBox(height: 32),
            Divider(color: isDarkMode ? Colors.grey[800] : Colors.grey[300]),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => _confirmDeleteFamilyAccount(context, state.familyAccount.id),
              icon: Icon(Icons.delete_forever, color: Colors.red),
              label: Text(
                'Delete Family Account',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  void _showInviteMemberDialog(BuildContext context, String familyAccountId, bool isDarkMode) {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDarkMode ? Color(0xFF2C2C2C) : Colors.white,
        title: Text(
          'Invite Family Member',
          style: TextStyle(
            color: isDarkMode ? Colors.grey[300] : Colors.black87,
          ),
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: TextFormField(
              controller: emailController,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                labelText: 'Email Address',
                hintText: 'member@example.com',
                labelStyle: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                filled: true,
                fillColor: isDarkMode ? Color(0xFF1E1E1E) : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate() && user != null) {
                context.read<FamilyBloc>().add(
                  SendInvitationEvent(
                    familyAccountId: familyAccountId,
                    invitedBy: user!.uid,
                    invitedEmail: emailController.text.trim(),
                    invitationType: InvitationType.email,
                  ),
                );
                Navigator.pop(dialogContext);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: Text('Send Invite', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveMember(BuildContext context, String familyAccountId, String memberId, String memberName) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Remove Member'),
        content: Text('Are you sure you want to remove $memberName from the family?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<FamilyBloc>().add(
                RemoveFamilyMemberEvent(
                  familyAccountId: familyAccountId,
                  memberId: memberId,
                ),
              );
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Member removed successfully'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteFamilyAccount(BuildContext context, String familyAccountId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Delete Family Account',
          style: TextStyle(color: Colors.red),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to delete this family account?'),
              const SizedBox(height: 12),
              Text(
                'This will:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Remove all family members'),
              Text('• Cancel all pending invitations'),
              Text('• Delete the family account permanently'),
              const SizedBox(height: 12),
              Text(
                'This action cannot be undone.',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (user != null) {
                context.read<FamilyBloc>().add(
                  DeleteFamilyAccountEvent(
                    familyAccountId: familyAccountId,
                    userId: user!.uid,
                  ),
                );
                Navigator.pop(dialogContext); // Close dialog
                Navigator.pop(context); // Go back to welcome screen
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Family account deleted'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}