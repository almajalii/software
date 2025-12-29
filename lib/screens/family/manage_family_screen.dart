import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meditrack/bloc/family_bloc/family_bloc.dart';
import 'package:meditrack/bloc/medicine_bloc/medicine_bloc.dart';
import 'package:meditrack/bloc/dosage_bloc/dosage_bloc.dart';
import 'package:meditrack/model/family_invitation.dart';
import 'package:meditrack/model/family_member.dart';
import 'package:meditrack/model/dosage.dart';
import 'package:meditrack/style/colors.dart';
import 'package:meditrack/widgets/app_bar.dart';
import 'package:meditrack/screens/main/home/navigation_main.dart';

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

  // Navigate back to home screen
  void _navigateToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const NavigationMain()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _navigateToHome,
        ),
        title: const Text('Family Account'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              colors: [Color(0xFF1A3A6B), Color(0xFF00B9E4)],
            ),
          ),
        ),
      ),
      body: BlocConsumer<FamilyBloc, FamilyState>(
        listener: (context, state) {
          if (state is FamilyAccountCreatedState) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Family account created successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is FamilyErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("error"),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is FamilyLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is NoFamilyAccountState) {
            return _buildNoFamilyUI(isDarkMode);
          }

          if (state is FamilyAccountLoadedState) {
            _loadPendingInvitations(state.familyAccount.id);
            return _buildFamilyAccountUI(state, isDarkMode);
          }

          return const Center(child: Text('Something went wrong'));
        },
      ),
    );
  }

  Widget _buildNoFamilyUI(bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.family_restroom,
              size: 100,
              color: isDarkMode ? Colors.grey[700] : Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No Family Account',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.grey[300] : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create a family account to share\nmedicine tracking with your family',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => _showCreateFamilyDialog(context, isDarkMode),
              child: const Text(
                'Create Family Account',
                style: TextStyle(
                  fontSize: 14,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyAccountUI(FamilyAccountLoadedState state, bool isDarkMode) {
    final isOwner = state.members.any(
          (m) => m.userId == user?.uid && m.role == MemberRole.owner,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Family Account Card
          Card(
            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
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
          const SizedBox(height: 20),

          // Family Members Section
          Text(
            'Family Members',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.grey[300] : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          // Member list
          ...state.members.map((member) {
            final isCurrentUser = member.userId == user?.uid;
            return Card(
              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Text(
                    member.displayName.isNotEmpty
                        ? member.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Row(
                  children: [
                    Text(
                      member.displayName.isEmpty ? 'Unknown' : member.displayName,
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[300] : Colors.black87,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'You',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: Text(
                  member.email,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: member.role == MemberRole.owner
                            ? Colors.amber.withOpacity(0.2)
                            : Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        member.role == MemberRole.owner ? 'Owner' : 'Member',
                        style: TextStyle(
                          fontSize: 11,
                          color: member.role == MemberRole.owner
                              ? Colors.amber[700]
                              : Colors.blue[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.medication, size: 20),
                      color: AppColors.primary,
                      onPressed: () => _showMemberMedicines(context, member, isDarkMode),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),

          // Invite Member button (owner only)
          if (isOwner) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showInviteMemberDialog(
                  context,
                  state.familyAccount.id,
                  isDarkMode,
                ),
                icon: const Icon(Icons.person_add, color: Colors.white),
                label: const Text('Invite Member', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],

          // Pending Invitations
          if (isOwner) ...[
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
            BlocBuilder<FamilyBloc, FamilyState>(
              builder: (context, familyState) {
                if (familyState is! FamilyAccountLoadedState) {
                  return const SizedBox.shrink();
                }

                final invitations = familyState.pendingInvitations;

                if (invitations.isEmpty) {
                  return Text(
                    'No pending invitations',
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                    ),
                  );
                }

                return Column(
                  children: invitations.map((invitation) {
                    return Card(
                      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.mail_outline, color: Colors.orange),
                        title: Text(
                          invitation.invitedEmail,
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey[300] : Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          'Invited ${_formatDate(invitation.createdAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.copy, size: 18),
                              color: AppColors.primary,
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: invitation.invitationToken),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Invitation code copied!'),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: () {
                                context.read<FamilyBloc>().add(
                                  DeleteInvitationEvent(
                                    familyAccountId: state.familyAccount.id,
                                    invitationId: invitation.id,
                                  ),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Invitation cancelled'),
                                    backgroundColor: Colors.orange,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],

          // Delete Family Account button (owner only)
          if (isOwner) ...[
            const SizedBox(height: 32),
            Divider(color: isDarkMode ? Colors.grey[800] : Colors.grey[300]),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => _confirmDeleteFamilyAccount(context, state.familyAccount.id),
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              label: const Text(
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

  // Show member's medicines (READ-ONLY)
  void _showMemberMedicines(BuildContext context, FamilyMember member, bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return _MemberMedicinesSheet(
              member: member,
              scrollController: scrollController,
              isDarkMode: isDarkMode,
            );
          },
        );
      },
    );
  }

  void _showCreateFamilyDialog(BuildContext context, bool isDarkMode) {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
        title: Text(
          'Create Family Account',
          style: TextStyle(
            color: isDarkMode ? Colors.grey[300] : Colors.black87,
          ),
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.family_restroom,
                  color: AppColors.primary,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  'Choose a name for your family',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  autofocus: true,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Family Name',
                    hintText: 'e.g., The Smiths',
                    labelStyle: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a family name';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate() && user != null) {
                context.read<FamilyBloc>().add(
                  CreateFamilyAccountEvent(
                    userId: user!.uid,
                    familyName: nameController.text.trim(),
                    primaryContactEmail: user!.email ?? '',
                    primaryContactPhone: null,
                  ),
                );
                Navigator.pop(dialogContext);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Create', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showInviteMemberDialog(
      BuildContext context, String familyAccountId, bool isDarkMode) {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
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
                hintText: 'Enter member\'s email',
                labelStyle: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[100],
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an email';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
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
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                context.read<FamilyBloc>().add(
                  SendInvitationEvent(
                    familyAccountId: familyAccountId,
                    invitedBy: user!.uid,
                    invitedEmail: emailController.text.trim(),
                    invitationType: InvitationType.email,
                  ),
                );
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invitation sent successfully!'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Invite', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteFamilyAccount(BuildContext context, String familyAccountId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2C2C2C)
            : Colors.white,
        title: const Text(
          'Delete Family Account?',
          style: TextStyle(color: Colors.red),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Are you sure you want to delete this family account?',
              ),
              SizedBox(height: 12),
              Text(
                'This will:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Remove all family members'),
              Text('• Cancel all pending invitations'),
              Text('• Delete the family account permanently'),
              SizedBox(height: 12),
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
            child: const Text('Cancel'),
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
                Navigator.pop(dialogContext);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Family account deleted'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

// Separate widget for the medicines sheet
class _MemberMedicinesSheet extends StatefulWidget {
  final FamilyMember member;
  final ScrollController scrollController;
  final bool isDarkMode;

  const _MemberMedicinesSheet({
    required this.member,
    required this.scrollController,
    required this.isDarkMode,
  });

  @override
  State<_MemberMedicinesSheet> createState() => _MemberMedicinesSheetState();
}

class _MemberMedicinesSheetState extends State<_MemberMedicinesSheet> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Load medicines immediately and only once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isInitialized && mounted) {
        context.read<MedicineBloc>().add(LoadMedicinesEvent(widget.member.userId));
        setState(() {
          _isInitialized = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary,
                child: Text(
                  widget.member.displayName.isNotEmpty
                      ? widget.member.displayName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.member.displayName}\'s Medicines',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: widget.isDarkMode ? Colors.grey[300] : Colors.black87,
                      ),
                    ),
                    Text(
                      'Read-only view',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isDarkMode ? Colors.grey[500] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: widget.isDarkMode ? Colors.grey[800] : Colors.grey[300]),
          const SizedBox(height: 8),

          // Medicine list
          Expanded(
            child: BlocBuilder<MedicineBloc, MedicineState>(
              builder: (context, state) {
                if (state is MedicineLoadingState) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is MedicineLoadedState) {
                  if (state.medicines.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.medication_outlined,
                            size: 64,
                            color: widget.isDarkMode ? Colors.grey[700] : Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No medicines found',
                            style: TextStyle(
                              color: widget.isDarkMode ? Colors.grey[500] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: widget.scrollController,
                    itemCount: state.medicines.length,
                    itemBuilder: (context, index) {
                      final medicine = state.medicines[index];
                      return Card(
                        color: widget.isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: (medicine.imageUrl != null && medicine.imageUrl!.isNotEmpty)
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              medicine.imageUrl!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.medication,
                                    color: AppColors.primary,
                                  ),
                                );
                              },
                            ),
                          )
                              : Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.medication,
                              color: AppColors.primary,
                            ),
                          ),
                          title: Text(
                            medicine.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: widget.isDarkMode ? Colors.grey[300] : Colors.black87,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (medicine.type.isNotEmpty)
                                Text(
                                  medicine.type,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: widget.isDarkMode ? Colors.grey[500] : Colors.grey[600],
                                  ),
                                ),
                              Text(
                                'Quantity: ${medicine.quantity}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: widget.isDarkMode ? Colors.grey[500] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }

                return Center(
                  child: Text(
                    'Unable to load medicines',
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.grey[500] : Colors.grey[600],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}