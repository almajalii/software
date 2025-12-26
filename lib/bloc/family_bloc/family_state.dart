part of 'family_bloc.dart';

abstract class FamilyState extends Equatable {
  const FamilyState();

  @override
  List<Object?> get props => [];
}

// Initial state
class FamilyInitialState extends FamilyState {}

// Loading state
class FamilyLoadingState extends FamilyState {}

// ==================== FAMILY ACCOUNT STATES ====================

// Family account loaded successfully
class FamilyAccountLoadedState extends FamilyState {
  final FamilyAccount familyAccount;
  final List<FamilyMember> members;
  final List<FamilyInvitation> pendingInvitations;

  const FamilyAccountLoadedState({
    required this.familyAccount,
    this.members = const [],
    this.pendingInvitations = const [],
  });

  @override
  List<Object?> get props => [familyAccount, members, pendingInvitations];

  FamilyAccountLoadedState copyWith({
    FamilyAccount? familyAccount,
    List<FamilyMember>? members,
    List<FamilyInvitation>? pendingInvitations,
  }) {
    return FamilyAccountLoadedState(
      familyAccount: familyAccount ?? this.familyAccount,
      members: members ?? this.members,
      pendingInvitations: pendingInvitations ?? this.pendingInvitations,
    );
  }
}

// No family account found for user
class NoFamilyAccountState extends FamilyState {}

// Family account created successfully
class FamilyAccountCreatedState extends FamilyState {
  final FamilyAccount familyAccount;

  const FamilyAccountCreatedState(this.familyAccount);

  @override
  List<Object?> get props => [familyAccount];
}

// Family account updated successfully
class FamilyAccountUpdatedState extends FamilyState {
  final String message;

  const FamilyAccountUpdatedState(this.message);

  @override
  List<Object?> get props => [message];
}

// Family account deleted successfully
class FamilyAccountDeletedState extends FamilyState {}

// ==================== MEMBER STATES ====================

// Family members loaded
class FamilyMembersLoadedState extends FamilyState {
  final List<FamilyMember> members;

  const FamilyMembersLoadedState(this.members);

  @override
  List<Object?> get props => [members];
}

// Family member removed successfully
class FamilyMemberRemovedState extends FamilyState {
  final String message;

  const FamilyMemberRemovedState(this.message);

  @override
  List<Object?> get props => [message];
}

// ==================== INVITATION STATES ====================

// Invitation sent successfully
class InvitationSentState extends FamilyState {
  final FamilyInvitation invitation;
  final String message;

  const InvitationSentState({
    required this.invitation,
    required this.message,
  });

  @override
  List<Object?> get props => [invitation, message];
}

// Invitation accepted successfully
class InvitationAcceptedState extends FamilyState {
  final String familyAccountId;
  final String message;

  const InvitationAcceptedState({
    required this.familyAccountId,
    required this.message,
  });

  @override
  List<Object?> get props => [familyAccountId, message];
}

// Pending invitations loaded
class PendingInvitationsLoadedState extends FamilyState {
  final List<FamilyInvitation> invitations;

  const PendingInvitationsLoadedState(this.invitations);

  @override
  List<Object?> get props => [invitations];
}

// Invitation deleted successfully
class InvitationDeletedState extends FamilyState {
  final String message;

  const InvitationDeletedState(this.message);

  @override
  List<Object?> get props => [message];
}

// Invitation validation result
class InvitationValidatedState extends FamilyState {
  final FamilyInvitation? invitation;
  final bool isValid;
  final String? errorMessage;

  const InvitationValidatedState({
    this.invitation,
    required this.isValid,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [invitation, isValid, errorMessage];
}

// ==================== ERROR STATE ====================

// Error state
class FamilyErrorState extends FamilyState {
  final String error;

  const FamilyErrorState(this.error);

  @override
  List<Object?> get props => [error];
}