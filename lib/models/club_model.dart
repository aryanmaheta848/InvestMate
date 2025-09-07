import 'package:cloud_firestore/cloud_firestore.dart';

enum ClubMemberRole {
  admin,
  member,
}

enum ProposalType {
  buy,
  sell,
}

enum ProposalStatus {
  active,
  approved,
  rejected,
  expired,
  executed,
}

enum VoteType {
  yes,
  no,
}

class ClubMember {
  final String userId;
  final String displayName;
  final String? photoURL;
  final ClubMemberRole role;
  final DateTime joinedAt;
  final bool isActive;

  ClubMember({
    required this.userId,
    required this.displayName,
    this.photoURL,
    this.role = ClubMemberRole.member,
    DateTime? joinedAt,
    this.isActive = true,
  }) : joinedAt = joinedAt ?? DateTime.now();

  factory ClubMember.fromFirestore(Map<String, dynamic> data) {
    return ClubMember(
      userId: data['userId'] ?? '',
      displayName: data['displayName'] ?? '',
      photoURL: data['photoURL'],
      role: ClubMemberRole.values.firstWhere(
        (role) => role.toString() == 'ClubMemberRole.${data['role']}',
        orElse: () => ClubMemberRole.member,
      ),
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'displayName': displayName,
      'photoURL': photoURL,
      'role': role.toString().split('.').last,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'isActive': isActive,
    };
  }

  bool get isAdmin => role == ClubMemberRole.admin;

  ClubMember copyWith({
    String? userId,
    String? displayName,
    String? photoURL,
    ClubMemberRole? role,
    DateTime? joinedAt,
    bool? isActive,
  }) {
    return ClubMember(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

class ClubModel {
  final String id;
  final String name;
  final String description;
  final String? photoURL;
  final String createdBy;
  final DateTime createdAt;
  final List<ClubMember> members;
  final List<String> watchlist;
  final double portfolioBalance;
  final double totalInvested;
  final double totalCurrentValue;
  final double totalPL;
  final double totalPLPercentage;
  final bool isPublic;
  final String? inviteCode;
  final int maxMembers;

  ClubModel({
    required this.id,
    required this.name,
    required this.description,
    this.photoURL,
    required this.createdBy,
    DateTime? createdAt,
    this.members = const [],
    this.watchlist = const [],
    this.portfolioBalance = 1000000.0, // ₹10,00,000 initial balance
    this.totalInvested = 0.0,
    this.totalCurrentValue = 0.0,
    this.totalPL = 0.0,
    this.totalPLPercentage = 0.0,
    this.isPublic = false,
    this.inviteCode,
    this.maxMembers = 50,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ClubModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    
    return ClubModel(
      id: doc.id,
      name: data?['name'] ?? '',
      description: data?['description'] ?? '',
      photoURL: data?['photoURL'],
      createdBy: data?['createdBy'] ?? '',
      createdAt: (data?['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      members: (data?['members'] as List?)
              ?.map((member) => ClubMember.fromFirestore(member as Map<String, dynamic>))
              .toList() ??
          [],
      watchlist: List<String>.from(data?['watchlist'] ?? []),
      portfolioBalance: (data?['portfolioBalance'] ?? 1000000.0).toDouble(),
      totalInvested: (data?['totalInvested'] ?? 0.0).toDouble(),
      totalCurrentValue: (data?['totalCurrentValue'] ?? 0.0).toDouble(),
      totalPL: (data?['totalPL'] ?? 0.0).toDouble(),
      totalPLPercentage: (data?['totalPLPercentage'] ?? 0.0).toDouble(),
      isPublic: data?['isPublic'] ?? false,
      inviteCode: data?['inviteCode'],
      maxMembers: (data?['maxMembers'] ?? 50).toInt(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'photoURL': photoURL,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'members': members.map((member) => member.toFirestore()).toList(),
      'watchlist': watchlist,
      'portfolioBalance': portfolioBalance,
      'totalInvested': totalInvested,
      'totalCurrentValue': totalCurrentValue,
      'totalPL': totalPL,
      'totalPLPercentage': totalPLPercentage,
      'isPublic': isPublic,
      'inviteCode': inviteCode,
      'maxMembers': maxMembers,
    };
  }

  // Calculated properties
  int get memberCount => members.length;
  bool get isFull => memberCount >= maxMembers;
  double get totalPortfolioValue => portfolioBalance + totalCurrentValue;
  bool get isProfitable => totalPL > 0;
  bool get isLoss => totalPL < 0;

  // Formatted strings
  String get formattedPortfolioBalance => '₹${portfolioBalance.toStringAsFixed(2)}';
  String get formattedTotalInvested => '₹${totalInvested.toStringAsFixed(2)}';
  String get formattedTotalCurrentValue => '₹${totalCurrentValue.toStringAsFixed(2)}';
  String get formattedTotalPL => '${isProfitable ? '+' : ''}₹${totalPL.toStringAsFixed(2)}';
  String get formattedTotalPLPercentage => '${isProfitable ? '+' : ''}${totalPLPercentage.toStringAsFixed(2)}%';
  String get formattedTotalPortfolioValue => '₹${totalPortfolioValue.toStringAsFixed(2)}';

  // Utility methods
  bool isMember(String userId) {
    return members.any((member) => member.userId == userId && member.isActive);
  }

  bool isAdmin(String userId) {
    return members.any((member) => member.userId == userId && member.isAdmin && member.isActive);
  }

  ClubMember? getMember(String userId) {
    try {
      return members.firstWhere((member) => member.userId == userId && member.isActive);
    } catch (e) {
      return null;
    }
  }

  List<ClubMember> get activeMembers => members.where((member) => member.isActive).toList();
  List<ClubMember> get admins => members.where((member) => member.isAdmin && member.isActive).toList();

  ClubModel copyWith({
    String? id,
    String? name,
    String? description,
    String? photoURL,
    String? createdBy,
    DateTime? createdAt,
    List<ClubMember>? members,
    List<String>? watchlist,
    double? portfolioBalance,
    double? totalInvested,
    double? totalCurrentValue,
    double? totalPL,
    double? totalPLPercentage,
    bool? isPublic,
    String? inviteCode,
    int? maxMembers,
  }) {
    return ClubModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      photoURL: photoURL ?? this.photoURL,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      members: members ?? this.members,
      watchlist: watchlist ?? this.watchlist,
      portfolioBalance: portfolioBalance ?? this.portfolioBalance,
      totalInvested: totalInvested ?? this.totalInvested,
      totalCurrentValue: totalCurrentValue ?? this.totalCurrentValue,
      totalPL: totalPL ?? this.totalPL,
      totalPLPercentage: totalPLPercentage ?? this.totalPLPercentage,
      isPublic: isPublic ?? this.isPublic,
      inviteCode: inviteCode ?? this.inviteCode,
      maxMembers: maxMembers ?? this.maxMembers,
    );
  }

  @override
  String toString() {
    return 'ClubModel(id: $id, name: $name, members: $memberCount)';
  }
}

class Vote {
  final String userId;
  final String displayName;
  final VoteType vote;
  final DateTime votedAt;
  final String? reason;

  Vote({
    required this.userId,
    required this.displayName,
    required this.vote,
    DateTime? votedAt,
    this.reason,
  }) : votedAt = votedAt ?? DateTime.now();

  factory Vote.fromFirestore(Map<String, dynamic> data) {
    return Vote(
      userId: data['userId'] ?? '',
      displayName: data['displayName'] ?? '',
      vote: VoteType.values.firstWhere(
        (vote) => vote.toString() == 'VoteType.${data['vote']}',
        orElse: () => VoteType.no,
      ),
      votedAt: (data['votedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reason: data['reason'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'displayName': displayName,
      'vote': vote.toString().split('.').last,
      'votedAt': Timestamp.fromDate(votedAt),
      'reason': reason,
    };
  }

  bool get isYes => vote == VoteType.yes;
  bool get isNo => vote == VoteType.no;
}

class ProposalModel {
  final String id;
  final String clubId;
  final String proposedBy;
  final String proposerName;
  final ProposalType type;
  final String symbol;
  final String stockName;
  final int quantity;
  final double? targetPrice;
  final String reason;
  final String? aiAnalysis;
  final ProposalStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<Vote> votes;
  final DateTime? executedAt;
  final String? executionTradeId;

  ProposalModel({
    required this.id,
    required this.clubId,
    required this.proposedBy,
    required this.proposerName,
    required this.type,
    required this.symbol,
    required this.stockName,
    required this.quantity,
    this.targetPrice,
    required this.reason,
    this.aiAnalysis,
    this.status = ProposalStatus.active,
    DateTime? createdAt,
    DateTime? expiresAt,
    this.votes = const [],
    this.executedAt,
    this.executionTradeId,
  })  : createdAt = createdAt ?? DateTime.now(),
        expiresAt = expiresAt ?? DateTime.now().add(const Duration(hours: 24));

  factory ProposalModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    
    return ProposalModel(
      id: doc.id,
      clubId: data?['clubId'] ?? '',
      proposedBy: data?['proposedBy'] ?? '',
      proposerName: data?['proposerName'] ?? '',
      type: ProposalType.values.firstWhere(
        (type) => type.toString() == 'ProposalType.${data?['type']}',
        orElse: () => ProposalType.buy,
      ),
      symbol: data?['symbol'] ?? '',
      stockName: data?['stockName'] ?? '',
      quantity: (data?['quantity'] ?? 0).toInt(),
      targetPrice: data?['targetPrice']?.toDouble(),
      reason: data?['reason'] ?? '',
      aiAnalysis: data?['aiAnalysis'],
      status: ProposalStatus.values.firstWhere(
        (status) => status.toString() == 'ProposalStatus.${data?['status']}',
        orElse: () => ProposalStatus.active,
      ),
      createdAt: (data?['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data?['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(hours: 24)),
      votes: (data?['votes'] as List?)
              ?.map((vote) => Vote.fromFirestore(vote as Map<String, dynamic>))
              .toList() ??
          [],
      executedAt: (data?['executedAt'] as Timestamp?)?.toDate(),
      executionTradeId: data?['executionTradeId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'clubId': clubId,
      'proposedBy': proposedBy,
      'proposerName': proposerName,
      'type': type.toString().split('.').last,
      'symbol': symbol,
      'stockName': stockName,
      'quantity': quantity,
      'targetPrice': targetPrice,
      'reason': reason,
      'aiAnalysis': aiAnalysis,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'votes': votes.map((vote) => vote.toFirestore()).toList(),
      'executedAt': executedAt != null ? Timestamp.fromDate(executedAt!) : null,
      'executionTradeId': executionTradeId,
    };
  }

  // Calculated properties
  int get totalVotes => votes.length;
  int get yesVotes => votes.where((vote) => vote.isYes).length;
  int get noVotes => votes.where((vote) => vote.isNo).length;
  double get yesPercentage => totalVotes > 0 ? (yesVotes / totalVotes) * 100 : 0.0;
  double get noPercentage => totalVotes > 0 ? (noVotes / totalVotes) * 100 : 0.0;
  
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isActive => status == ProposalStatus.active && !isExpired;
  bool get hasEnoughVotes => yesPercentage >= 60.0; // 60% majority
  bool get isBuy => type == ProposalType.buy;
  bool get isSell => type == ProposalType.sell;
  
  Duration get timeRemaining => isExpired ? Duration.zero : expiresAt.difference(DateTime.now());
  String get formattedTimeRemaining {
    if (isExpired) return 'Expired';
    final hours = timeRemaining.inHours;
    final minutes = timeRemaining.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m remaining';
    } else {
      return '${minutes}m remaining';
    }
  }

  String get formattedTargetPrice => targetPrice != null ? '₹${targetPrice!.toStringAsFixed(2)}' : 'Market Price';
  String get formattedQuantity => quantity.toString();
  
  bool hasUserVoted(String userId) {
    return votes.any((vote) => vote.userId == userId);
  }

  Vote? getUserVote(String userId) {
    try {
      return votes.firstWhere((vote) => vote.userId == userId);
    } catch (e) {
      return null;
    }
  }

  ProposalModel copyWith({
    String? id,
    String? clubId,
    String? proposedBy,
    String? proposerName,
    ProposalType? type,
    String? symbol,
    String? stockName,
    int? quantity,
    double? targetPrice,
    String? reason,
    String? aiAnalysis,
    ProposalStatus? status,
    DateTime? createdAt,
    DateTime? expiresAt,
    List<Vote>? votes,
    DateTime? executedAt,
    String? executionTradeId,
  }) {
    return ProposalModel(
      id: id ?? this.id,
      clubId: clubId ?? this.clubId,
      proposedBy: proposedBy ?? this.proposedBy,
      proposerName: proposerName ?? this.proposerName,
      type: type ?? this.type,
      symbol: symbol ?? this.symbol,
      stockName: stockName ?? this.stockName,
      quantity: quantity ?? this.quantity,
      targetPrice: targetPrice ?? this.targetPrice,
      reason: reason ?? this.reason,
      aiAnalysis: aiAnalysis ?? this.aiAnalysis,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      votes: votes ?? this.votes,
      executedAt: executedAt ?? this.executedAt,
      executionTradeId: executionTradeId ?? this.executionTradeId,
    );
  }

  @override
  String toString() {
    return 'ProposalModel(id: $id, symbol: $symbol, type: $type, status: $status)';
  }
}
