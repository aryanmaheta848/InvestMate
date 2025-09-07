import 'package:cloud_firestore/cloud_firestore.dart';

class HoldingModel {
  final String userId;
  final String symbol;
  final String stockName;
  final int quantity;
  final double averagePrice;
  final double? currentPrice;
  final DateTime lastUpdated;

  HoldingModel({
    required this.userId,
    required this.symbol,
    required this.stockName,
    required this.quantity,
    required this.averagePrice,
    this.currentPrice,
    required this.lastUpdated,
  });

  // Calculated properties
  double get investedValue => quantity * averagePrice;
  double get currentValue => quantity * (currentPrice ?? averagePrice);
  double get unrealizedPL => currentValue - investedValue;
  double get unrealizedPLPercentage => investedValue > 0 ? (unrealizedPL / investedValue) * 100 : 0.0;
  bool get isProfitable => unrealizedPL >= 0;
  
  // Formatted properties
  String get formattedAveragePrice => '₹${averagePrice.toStringAsFixed(2)}';
  String get formattedCurrentValue => '₹${currentValue.toStringAsFixed(2)}';
  String get formattedUnrealizedPL => '₹${unrealizedPL.toStringAsFixed(2)}';
  String get formattedUnrealizedPLPercentage => '${unrealizedPLPercentage >= 0 ? '+' : ''}${unrealizedPLPercentage.toStringAsFixed(2)}%';

  // Factory constructor to create a HoldingModel from a Firestore document
  factory HoldingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    return HoldingModel(
      userId: data?['userId'] ?? '',
      symbol: data?['symbol'] ?? '',
      stockName: data?['stockName'] ?? '',
      quantity: data?['quantity'] ?? 0,
      averagePrice: (data?['averagePrice'] ?? 0.0).toDouble(),
      currentPrice: data?['currentPrice']?.toDouble(),
      lastUpdated: (data?['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert HoldingModel to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'symbol': symbol,
      'stockName': stockName,
      'quantity': quantity,
      'averagePrice': averagePrice,
      'currentPrice': currentPrice,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  // Create a copy of this HoldingModel with updated fields
  HoldingModel copyWith({
    String? userId,
    String? symbol,
    String? stockName,
    int? quantity,
    double? averagePrice,
    double? currentPrice,
    DateTime? lastUpdated,
  }) {
    return HoldingModel(
      userId: userId ?? this.userId,
      symbol: symbol ?? this.symbol,
      stockName: stockName ?? this.stockName,
      quantity: quantity ?? this.quantity,
      averagePrice: averagePrice ?? this.averagePrice,
      currentPrice: currentPrice ?? this.currentPrice,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}