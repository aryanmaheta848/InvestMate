import 'package:cloud_firestore/cloud_firestore.dart';

enum TradeType {
  buy,
  sell,
}

enum TradeStatus {
  pending,
  executed,
  cancelled,
  failed,
}

class TradeModel {
  final String id;
  final String userId;
  final String symbol;
  final String stockName;
  final TradeType type;
  final int quantity;
  final double price;
  final double totalAmount;
  final TradeStatus status;
  final DateTime createdAt;
  final DateTime? executedAt;
  final String? clubId; // null for individual trades

  TradeModel({
    required this.id,
    required this.userId,
    required this.symbol,
    required this.stockName,
    required this.type,
    required this.quantity,
    required this.price,
    required this.totalAmount,
    this.status = TradeStatus.pending,
    DateTime? createdAt,
    this.executedAt,
    this.clubId,
  }) : createdAt = createdAt ?? DateTime.now();

  factory TradeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    
    return TradeModel(
      id: doc.id,
      userId: data?['userId'] ?? '',
      symbol: data?['symbol'] ?? '',
      stockName: data?['stockName'] ?? '',
      type: TradeType.values.firstWhere(
        (type) => type.toString() == 'TradeType.${data?['type']}',
        orElse: () => TradeType.buy,
      ),
      quantity: (data?['quantity'] ?? 0).toInt(),
      price: (data?['price'] ?? 0.0).toDouble(),
      totalAmount: (data?['totalAmount'] ?? 0.0).toDouble(),
      status: TradeStatus.values.firstWhere(
        (status) => status.toString() == 'TradeStatus.${data?['status']}',
        orElse: () => TradeStatus.pending,
      ),
      createdAt: (data?['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      executedAt: (data?['executedAt'] as Timestamp?)?.toDate(),
      clubId: data?['clubId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'symbol': symbol,
      'stockName': stockName,
      'type': type.toString().split('.').last,
      'quantity': quantity,
      'price': price,
      'totalAmount': totalAmount,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'executedAt': executedAt != null ? Timestamp.fromDate(executedAt!) : null,
      'clubId': clubId,
    };
  }

  String get formattedAmount => '₹${totalAmount.toStringAsFixed(2)}';
  String get formattedPrice => '₹${price.toStringAsFixed(2)}';
  bool get isBuy => type == TradeType.buy;
  bool get isSell => type == TradeType.sell;
  bool get isIndividual => clubId == null;
  bool get isClub => clubId != null;

  TradeModel copyWith({
    String? id,
    String? userId,
    String? symbol,
    String? stockName,
    TradeType? type,
    int? quantity,
    double? price,
    double? totalAmount,
    TradeStatus? status,
    DateTime? createdAt,
    DateTime? executedAt,
    String? clubId,
  }) {
    return TradeModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      symbol: symbol ?? this.symbol,
      stockName: stockName ?? this.stockName,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      executedAt: executedAt ?? this.executedAt,
      clubId: clubId ?? this.clubId,
    );
  }

  @override
  String toString() {
    return 'TradeModel(id: $id, symbol: $symbol, type: $type, quantity: $quantity)';
  }
}

// HoldingModel moved to holding_model.dart

// PortfolioModel moved to portfolio_model.dart
