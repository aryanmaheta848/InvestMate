import 'package:cloud_firestore/cloud_firestore.dart';

class PortfolioModel {
  final String userId;
  final double cashBalance;
  final double totalInvested;
  final double currentValue;
  final double totalCurrentValue;
  final double totalPL;
  final double totalPLPercentage;
  final double realizedPL;
  final double unrealizedPL;
  final DateTime createdAt;
  final DateTime lastUpdated;

  PortfolioModel({
    required this.userId,
    required this.cashBalance,
    this.totalInvested = 0.0,
    this.currentValue = 0.0,
    this.totalCurrentValue = 0.0,
    this.totalPL = 0.0,
    this.totalPLPercentage = 0.0,
    this.realizedPL = 0.0,
    this.unrealizedPL = 0.0,
    DateTime? createdAt,
    required this.lastUpdated,
  }) : createdAt = createdAt ?? DateTime.now();

  // Calculate total portfolio value (cash + investments)
  double get totalPortfolioValue => cashBalance + currentValue;
  bool get isProfitable => totalPL >= 0;
  
  // Formatted properties
  String get formattedTotalPortfolioValue => '₹${totalPortfolioValue.toStringAsFixed(2)}';
  String get formattedTotalPL => '₹${totalPL.toStringAsFixed(2)}';
  String get formattedTotalPLPercentage => '${totalPLPercentage >= 0 ? '+' : ''}${totalPLPercentage.toStringAsFixed(2)}%';
  String get formattedTotalInvested => '₹${totalInvested.toStringAsFixed(2)}';
  String get formattedTotalCurrentValue => '₹${totalCurrentValue.toStringAsFixed(2)}';
  String get formattedCashBalance => '₹${cashBalance.toStringAsFixed(2)}';
  
  // Create a copy with updated values
  PortfolioModel copyWith({
    String? userId,
    double? cashBalance,
    double? totalInvested,
    double? currentValue,
    double? totalCurrentValue,
    double? totalPL,
    double? totalPLPercentage,
    double? realizedPL,
    double? unrealizedPL,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return PortfolioModel(
      userId: userId ?? this.userId,
      cashBalance: cashBalance ?? this.cashBalance,
      totalInvested: totalInvested ?? this.totalInvested,
      currentValue: currentValue ?? this.currentValue,
      totalCurrentValue: totalCurrentValue ?? this.totalCurrentValue,
      totalPL: totalPL ?? this.totalPL,
      totalPLPercentage: totalPLPercentage ?? this.totalPLPercentage,
      realizedPL: realizedPL ?? this.realizedPL,
      unrealizedPL: unrealizedPL ?? this.unrealizedPL,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  // Factory constructor to create a PortfolioModel from Firestore data
  factory PortfolioModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return PortfolioModel(
      userId: data['userId'] ?? '',
      cashBalance: (data['cashBalance'] ?? 0.0).toDouble(),
      totalInvested: (data['totalInvested'] ?? 0.0).toDouble(),
      currentValue: (data['currentValue'] ?? 0.0).toDouble(),
      totalCurrentValue: (data['totalCurrentValue'] ?? 0.0).toDouble(),
      totalPL: (data['totalPL'] ?? 0.0).toDouble(),
      totalPLPercentage: (data['totalPLPercentage'] ?? 0.0).toDouble(),
      realizedPL: (data['realizedPL'] ?? 0.0).toDouble(),
      unrealizedPL: (data['unrealizedPL'] ?? 0.0).toDouble(),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastUpdated: data['lastUpdated'] != null
          ? (data['lastUpdated'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // Convert PortfolioModel to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'cashBalance': cashBalance,
      'totalInvested': totalInvested,
      'currentValue': currentValue,
      'totalCurrentValue': totalCurrentValue,
      'totalPL': totalPL,
      'totalPLPercentage': totalPLPercentage,
      'realizedPL': realizedPL,
      'unrealizedPL': unrealizedPL,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}