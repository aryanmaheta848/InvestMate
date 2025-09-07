import 'package:flutter/foundation.dart';
import 'package:invest_mate/models/club_model.dart';

class ClubProvider extends ChangeNotifier {
  List<ClubModel> _userClubs = [];
  List<ProposalModel> _activeProposals = [];
  ClubModel? _selectedClub;
  
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<ClubModel> get userClubs => _userClubs;
  List<ProposalModel> get activeProposals => _activeProposals;
  ClubModel? get selectedClub => _selectedClub;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Update user clubs
  void updateUserClubs(List<ClubModel> clubs) {
    _userClubs = clubs;
    notifyListeners();
  }

  // Add club to user clubs
  void addClub(ClubModel club) {
    _userClubs.add(club);
    notifyListeners();
  }

  // Remove club from user clubs
  void removeClub(String clubId) {
    _userClubs.removeWhere((club) => club.id == clubId);
    if (_selectedClub?.id == clubId) {
      _selectedClub = null;
    }
    notifyListeners();
  }

  // Update specific club
  void updateClub(ClubModel updatedClub) {
    final index = _userClubs.indexWhere((club) => club.id == updatedClub.id);
    if (index != -1) {
      _userClubs[index] = updatedClub;
    }
    
    if (_selectedClub?.id == updatedClub.id) {
      _selectedClub = updatedClub;
    }
    
    notifyListeners();
  }

  // Select club
  void selectClub(ClubModel club) {
    _selectedClub = club;
    notifyListeners();
  }

  // Clear selected club
  void clearSelectedClub() {
    _selectedClub = null;
    notifyListeners();
  }

  // Update active proposals
  void updateActiveProposals(List<ProposalModel> proposals) {
    _activeProposals = proposals;
    notifyListeners();
  }

  // Add proposal
  void addProposal(ProposalModel proposal) {
    _activeProposals.insert(0, proposal);
    notifyListeners();
  }

  // Update proposal
  void updateProposal(ProposalModel updatedProposal) {
    final index = _activeProposals.indexWhere((p) => p.id == updatedProposal.id);
    if (index != -1) {
      _activeProposals[index] = updatedProposal;
      notifyListeners();
    }
  }

  // Remove proposal
  void removeProposal(String proposalId) {
    _activeProposals.removeWhere((p) => p.id == proposalId);
    notifyListeners();
  }

  // Get proposals for specific club
  List<ProposalModel> getClubProposals(String clubId) {
    return _activeProposals.where((p) => p.clubId == clubId).toList();
  }

  // Get club by ID
  ClubModel? getClubById(String clubId) {
    try {
      return _userClubs.firstWhere((club) => club.id == clubId);
    } catch (e) {
      return null;
    }
  }

  // Check if user is admin of club
  bool isAdminOfClub(String clubId, String userId) {
    final club = getClubById(clubId);
    return club?.isAdmin(userId) ?? false;
  }

  // Check if user is member of club
  bool isMemberOfClub(String clubId, String userId) {
    final club = getClubById(clubId);
    return club?.isMember(userId) ?? false;
  }

  // Get user's role in club
  ClubMemberRole? getUserRoleInClub(String clubId, String userId) {
    final club = getClubById(clubId);
    return club?.getMember(userId)?.role;
  }

  // Get pending proposals that user can vote on
  List<ProposalModel> getPendingProposalsForUser(String userId) {
    return _activeProposals.where((proposal) {
      return proposal.isActive && !proposal.hasUserVoted(userId);
    }).toList();
  }

  // Get voted proposals by user
  List<ProposalModel> getVotedProposalsByUser(String userId) {
    return _activeProposals.where((proposal) {
      return proposal.hasUserVoted(userId);
    }).toList();
  }

  // Get proposals created by user
  List<ProposalModel> getProposalsCreatedByUser(String userId) {
    return _activeProposals.where((proposal) {
      return proposal.proposedBy == userId;
    }).toList();
  }

  // Get top performing clubs
  List<ClubModel> getTopPerformingClubs() {
    final sortedClubs = List<ClubModel>.from(_userClubs);
    sortedClubs.sort((a, b) => b.totalPLPercentage.compareTo(a.totalPLPercentage));
    return sortedClubs;
  }

  // Get club statistics
  Map<String, dynamic> getClubStats(String clubId) {
    final club = getClubById(clubId);
    if (club == null) return {};

    final clubProposals = getClubProposals(clubId);
    final activeProposals = clubProposals.where((p) => p.isActive).length;
    final executedProposals = clubProposals.where((p) => p.status == ProposalStatus.executed).length;
    final approvedProposals = clubProposals.where((p) => p.status == ProposalStatus.approved).length;
    final rejectedProposals = clubProposals.where((p) => p.status == ProposalStatus.rejected).length;

    return {
      'totalMembers': club.memberCount,
      'totalProposals': clubProposals.length,
      'activeProposals': activeProposals,
      'executedProposals': executedProposals,
      'approvedProposals': approvedProposals,
      'rejectedProposals': rejectedProposals,
      'portfolioValue': club.totalPortfolioValue,
      'totalPL': club.totalPL,
      'totalPLPercentage': club.totalPLPercentage,
    };
  }

  // Filter clubs by performance
  List<ClubModel> filterClubsByPerformance(bool profitable) {
    return _userClubs.where((club) {
      return profitable ? club.isProfitable : club.isLoss;
    }).toList();
  }

  // Search clubs by name
  List<ClubModel> searchClubsByName(String query) {
    if (query.isEmpty) return _userClubs;
    
    return _userClubs.where((club) {
      return club.name.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
