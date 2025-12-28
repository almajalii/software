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
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      appBar: MyAppBar.build(context, () {}),
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
                  onPressed: () =>
                      _showInviteMemberDialog(context, state.familyAccount.id, isDarkMode),
                  icon: const Icon(Icons.person_add, size: 20),
                  label: const Text('Invite'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Members list with NOTIFY button
          ...state.members.map((member) {
            final isCurrentUser = member.userId == user?.uid;
            return Card(
              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: member.role == MemberRole.owner
                      ? AppColors.primary
                      : (isDarkMode ? Colors.grey[700] : Colors.grey[300]),
                  child: Text(
                    member.displayName.isNotEmpty
                        ? member.displayName[0].toUpperCase()
                        : 'U',
                    style: TextStyle(
                      color: member.role == MemberRole.owner
                          ? Colors.white
                          : (isDarkMode ? Colors.white : Colors.black87),
                      fontWeight: FontWeight.bold,
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
                    if (isCurrentUser) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'You',
                          style: TextStyle(
                            fontSize: 10,
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
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // NOTIFY BUTTON (for other members)
                    if (!isCurrentUser)
                      IconButton(
                        icon: const Icon(Icons.notifications_active_outlined),
                        color: AppColors.primary,
                        tooltip: 'View medicines',
                        onPressed: () => _showMemberMedicines(context, member, isDarkMode),
                      ),

                    // Owner chip or remove button
                    if (member.role == MemberRole.owner)
                      Chip(
                        label: const Text(
                          'Owner',
                          style: TextStyle(fontSize: 11, color: Colors.white),
                        ),
                        backgroundColor: AppColors.primary,
                      )
                    else if (isOwner && !isCurrentUser)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                        onPressed: () => _confirmRemoveMember(
                          context,
                          state.familyAccount.id,
                          member.id,
                          member.displayName,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),

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
                          const Icon(Icons.link, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              invitation.invitationToken,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontFamily: 'monospace',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 16),
                            color: AppColors.primary,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
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
                        ],
                      ),
                    ],
                  ),
                  trailing: IconButton(
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
                ),
              );
            }),
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
    // Prevent multiple taps while loading
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
                labelStyle: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              keyboardType: TextInputType.emailAddress,
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
            child: const Text('Cancel'),
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
            child: const Text('Send Invite', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveMember(
      BuildContext context, String familyAccountId, String memberId, String memberName) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Are you sure you want to remove $memberName from the family?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
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
                const SnackBar(
                  content: Text('Member removed successfully'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteFamilyAccount(BuildContext context, String familyAccountId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'Delete Family Account',
          style: TextStyle(color: Colors.red),
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to delete this family account?'),
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

// Separate widget for the medicines sheet (same as before)
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
                      : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
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
                        color: widget.isDarkMode ? Colors.grey[200] : Colors.black87,
                      ),
                    ),
                    Text(
                      'Today\'s medication schedule',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),

          // Medicines list
          Expanded(
            child: BlocBuilder<MedicineBloc, MedicineState>(
              builder: (context, medState) {
                if (medState is MedicineLoadingState) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (medState is MedicineErrorState) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red.withOpacity(0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Error loading medicines',
                          style: TextStyle(
                            color: widget.isDarkMode ? Colors.grey[400] : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            context.read<MedicineBloc>().add(
                              LoadMedicinesEvent(widget.member.userId),
                            );
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (medState is MedicineLoadedState) {
                  final medicines = medState.medicines;

                  if (medicines.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.medication_outlined,
                            size: 64,
                            color: widget.isDarkMode ? Colors.grey[600] : Colors.grey[400],
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

                  // Load dosages once
                  if (_isInitialized) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        for (var med in medicines) {
                          context.read<DosageBloc>().add(
                            LoadDosagesEvent(widget.member.userId, med.id),
                          );
                        }
                      }
                    });
                  }

                  return BlocBuilder<DosageBloc, DosageState>(
                    builder: (context, dosageState) {
                      if (dosageState is DosageLoadingState) {
                        return const Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        );
                      }

                      if (dosageState is DosageLoadedState) {
                        final allByMed = dosageState.dosagesByMedicine;
                        final today = DateTime.now();

                        // Build dosage list
                        final widgets = <Widget>[];
                        var hasDosages = false;

                        for (var med in medicines) {
                          final medDosages = allByMed[med.id] ?? [];

                          final todayDosages = medDosages.where((d) {
                            final start = d.startDate;
                            final end = d.endDate;
                            return !start.isAfter(today) &&
                                (end == null || !end.isBefore(today));
                          }).toList();

                          if (todayDosages.isEmpty) continue;

                          hasDosages = true;

                          widgets.add(
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 8),
                              child: Text(
                                med.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: widget.isDarkMode
                                      ? Colors.grey[300]
                                      : AppColors.darkBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );

                          for (var dosage in todayDosages) {
                            widgets.add(_buildReadOnlyDosageCard(dosage, widget.isDarkMode));
                          }
                        }

                        if (!hasDosages) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 48,
                                  color: widget.isDarkMode
                                      ? Colors.grey[600]
                                      : Colors.grey[400],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No dosages scheduled for today',
                                  style: TextStyle(
                                    color: widget.isDarkMode
                                        ? Colors.grey[500]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView(
                          controller: widget.scrollController,
                          children: widgets,
                        );
                      }

                      return const SizedBox();
                    },
                  );
                }

                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyDosageCard(Dosage dosage, bool isDarkMode) {
    final today = DateTime.now();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dosage: ${dosage.dosage}, Frequency: ${dosage.frequency}',
              style: TextStyle(
                fontSize: 13,
                color: isDarkMode ? Colors.grey[300] : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            ...List.generate(dosage.times.length, (index) {
              final timeData = dosage.times[index];
              final time = timeData['time'];

              DateTime? takenDate;
              final raw = timeData['takenDate'];
              if (raw != null) {
                takenDate = raw is DateTime ? raw : (raw as Timestamp).toDate();
              }

              final isTakenToday = takenDate != null &&
                  takenDate.year == today.year &&
                  takenDate.month == today.month &&
                  takenDate.day == today.day;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Time: $time",
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey[400] : Colors.black87,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          isTakenToday
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: 18,
                          color: isTakenToday
                              ? Colors.green
                              : (isDarkMode ? Colors.grey[600] : Colors.grey),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isTakenToday ? "Taken" : "Not Taken",
                          style: TextStyle(
                            fontSize: 12,
                            color: isTakenToday
                                ? Colors.green
                                : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}