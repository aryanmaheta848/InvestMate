import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  user,
  premium,
  admin,
}

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final UserRole role;
  final double portfolioBalance;
  final List<String> watchlist;
  final List<String> clubIds;
  final DateTime createdAt;
  final DateTime lastActive;
  final Map<String, dynamic> preferences;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    this.role = UserRole.user,
    this.portfolioBalance = 1000000.0, // ₹10,00,000 initial balance
    this.watchlist = const [],
    this.clubIds = const [],
    DateTime? createdAt,
    DateTime? lastActive,
    this.preferences = const {},
  })  : createdAt = createdAt ?? DateTime.now(),
        lastActive = lastActive ?? DateTime.now();

  // Create from Firebase User
  factory UserModel.fromAuth({
    required String uid,
    required String email,
    String? displayName,
    String? photoURL,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? email.split('@')[0],
      photoURL: photoURL,
    );
  }

  // Create from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    
    return UserModel(
      uid: doc.id,
      email: data?['email'] ?? '',
      displayName: data?['displayName'] ?? '',
      photoURL: data?['photoURL'],
      role: UserRole.values.firstWhere(
        (role) => role.toString() == 'UserRole.${data?['role']}',
        orElse: () => UserRole.user,
      ),
      portfolioBalance: (data?['portfolioBalance'] ?? 1000000.0).toDouble(),
      watchlist: List<String>.from(data?['watchlist'] ?? []),
      clubIds: List<String>.from(data?['clubIds'] ?? []),
      createdAt: (data?['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActive: (data?['lastActive'] as Timestamp?)?.toDate() ?? DateTime.now(),
      preferences: Map<String, dynamic>.from(data?['preferences'] ?? {}),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'role': role.toString().split('.').last,
      'portfolioBalance': portfolioBalance,
      'watchlist': watchlist,
      'clubIds': clubIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': Timestamp.fromDate(lastActive),
      'preferences': preferences,
    };
  }

  // Copy with new values
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    UserRole? role,
    double? portfolioBalance,
    List<String>? watchlist,
    List<String>? clubIds,
    DateTime? createdAt,
    DateTime? lastActive,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      role: role ?? this.role,
      portfolioBalance: portfolioBalance ?? this.portfolioBalance,
      watchlist: watchlist ?? this.watchlist,
      clubIds: clubIds ?? this.clubIds,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      preferences: preferences ?? this.preferences,
    );
  }

  // Utility methods
  bool get isPremium => role == UserRole.premium || role == UserRole.admin;
  bool get isAdmin => role == UserRole.admin;
  
  bool hasStockInWatchlist(String symbol) {
    return watchlist.contains(symbol);
  }
  
  bool isMemberOfClub(String clubId) {
    return clubIds.contains(clubId);
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, displayName: $displayName, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}
