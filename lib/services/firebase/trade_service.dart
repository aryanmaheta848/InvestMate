import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:invest_mate/models/trade_model.dart';
import 'package:invest_mate/models/holding_model.dart';
import 'package:invest_mate/models/portfolio_model.dart';
import 'package:invest_mate/services/firebase/firebase_service.dart';
import 'package:invest_mate/constants/app_constants.dart';

class TradeService {
  static final TradeService _instance = TradeService._internal();
  factory TradeService() => _instance;
  TradeService._internal();

  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new trade
  Future<String> createTrade(TradeModel trade) async {
    try {
      final docRef = await _firestore.collection('trades').add(trade.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create trade: $e');
    }
  }

  // Update trade status
  Future<void> updateTradeStatus(String tradeId, TradeStatus status) async {
    try {
      await _firestore.collection('trades').doc(tradeId).update({
        'status': status.toString().split('.').last,
        'executedAt': status == TradeStatus.executed ? Timestamp.now() : null,
      });
    } catch (e) {
      throw Exception('Failed to update trade status: $e');
    }
  }

  // Get user's trade history
  Future<List<TradeModel>> getUserTrades(String userId, {int? limit}) async {
    try {
      Query query = _firestore
          .collection('trades')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true);
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      QuerySnapshot snapshot = await query.get();
      
      return snapshot.docs
          .map((doc) => TradeModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user trades: $e');
    }
  }

  // Get trades for a specific stock
  Future<List<TradeModel>> getStockTrades(String userId, String symbol) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('trades')
          .where('userId', isEqualTo: userId)
          .where('symbol', isEqualTo: symbol)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => TradeModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get stock trades: $e');
    }
  }

  // Get recent trades with pagination
  Future<List<TradeModel>> getRecentTrades(String userId, {
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection('trades')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit);
      
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      
      QuerySnapshot snapshot = await query.get();
      
      return snapshot.docs
          .map((doc) => TradeModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get recent trades: $e');
    }
  }

  // Stream user trades for real-time updates
  Stream<List<TradeModel>> getUserTradesStream(String userId) {
    return _firestore
        .collection('trades')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TradeModel.fromFirestore(doc))
            .toList());
  }

  // Execute a complete trade with portfolio updates
  Future<bool> executeTrade({
    required String userId,
    required String symbol,
    required String stockName,
    required int quantity,
    required double price,
    required bool isBuy,
    String? clubId,
  }) async {
    try {
      final totalAmount = quantity * price;
      
      // Create trade record
      final trade = TradeModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        symbol: symbol,
        stockName: stockName,
        type: isBuy ? TradeType.buy : TradeType.sell,
        quantity: quantity,
        price: price,
        totalAmount: totalAmount,
        status: TradeStatus.executed,
        executedAt: DateTime.now(),
        clubId: clubId,
      );

      // Use batch write for atomic operations
      WriteBatch batch = _firestore.batch();
      
      // Add trade to trades collection
      DocumentReference tradeRef = _firestore.collection('trades').doc();
      batch.set(tradeRef, trade.toFirestore());
      
      // Update portfolio
      await _updatePortfolioInFirestore(batch, userId, trade);
      
      // Update holdings
      await _updateHoldingsInFirestore(batch, userId, trade);
      
      // Commit all changes
      await batch.commit();
      
      return true;
    } catch (e) {
      throw Exception('Failed to execute trade: $e');
    }
  }

  // Update portfolio in Firestore
  Future<void> _updatePortfolioInFirestore(WriteBatch batch, String userId, TradeModel trade) async {
    try {
      final portfolioRef = _firestore.collection('portfolios').doc(userId);
      final portfolioDoc = await portfolioRef.get();
      
      if (portfolioDoc.exists) {
        final currentBalance = portfolioDoc.data()?['cashBalance'] ?? 0.0;
        final newBalance = trade.isBuy 
            ? currentBalance - trade.totalAmount
            : currentBalance + trade.totalAmount;
        
        batch.update(portfolioRef, {
          'cashBalance': newBalance,
          'lastUpdated': Timestamp.now(),
        });
      } else {
        // Create new portfolio if it doesn't exist
        final portfolio = PortfolioModel(
          userId: userId,
          cashBalance: trade.isBuy ? 1000000.0 - trade.totalAmount : trade.totalAmount,
          totalInvested: trade.isBuy ? trade.totalAmount : 0.0,
          totalCurrentValue: trade.isBuy ? trade.totalAmount : 0.0,
          totalPL: 0.0,
          totalPLPercentage: 0.0,
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        );
        
        batch.set(portfolioRef, portfolio.toFirestore());
      }
    } catch (e) {
      throw Exception('Failed to update portfolio: $e');
    }
  }

  // Update holdings in Firestore
  Future<void> _updateHoldingsInFirestore(WriteBatch batch, String userId, TradeModel trade) async {
    try {
      final holdingRef = _firestore
          .collection('holdings')
          .doc(userId)
          .collection('stocks')
          .doc(trade.symbol);
      
      final holdingDoc = await holdingRef.get();
      
      if (holdingDoc.exists) {
        final holding = HoldingModel.fromFirestore(holdingDoc);
        
        if (trade.isBuy) {
          // Update existing holding for buy
          final newQuantity = holding.quantity + trade.quantity;
          final totalInvested = holding.investedValue + trade.totalAmount;
          final newAveragePrice = totalInvested / newQuantity;
          
          final updatedHolding = holding.copyWith(
            quantity: newQuantity,
            averagePrice: newAveragePrice,
            currentPrice: trade.price,
            lastUpdated: DateTime.now(),
          );
          
          batch.set(holdingRef, updatedHolding.toFirestore());
        } else {
          // Update existing holding for sell
          final newQuantity = holding.quantity - trade.quantity;
          
          if (newQuantity <= 0) {
            // Remove holding if no shares left
            batch.delete(holdingRef);
          } else {
            final updatedHolding = holding.copyWith(
              quantity: newQuantity,
              currentPrice: trade.price,
              lastUpdated: DateTime.now(),
            );
            
            batch.set(holdingRef, updatedHolding.toFirestore());
          }
        }
      } else if (trade.isBuy) {
        // Create new holding for buy
        final newHolding = HoldingModel(
          userId: userId,
          symbol: trade.symbol,
          stockName: trade.stockName,
          quantity: trade.quantity,
          averagePrice: trade.price,
          currentPrice: trade.price,
          lastUpdated: DateTime.now(),
        );
        
        batch.set(holdingRef, newHolding.toFirestore());
      }
    } catch (e) {
      throw Exception('Failed to update holdings: $e');
    }
  }

  // Get portfolio summary
  Future<Map<String, dynamic>> getPortfolioSummary(String userId) async {
    try {
      final portfolioDoc = await _firestore.collection('portfolios').doc(userId).get();
      final holdingsSnapshot = await _firestore
          .collection('holdings')
          .doc(userId)
          .collection('stocks')
          .get();
      
      double totalInvested = 0.0;
      double totalCurrentValue = 0.0;
      
      for (final doc in holdingsSnapshot.docs) {
        final holding = HoldingModel.fromFirestore(doc);
        totalInvested += holding.investedValue;
        totalCurrentValue += holding.currentValue;
      }
      
      final totalPL = totalCurrentValue - totalInvested;
      final totalPLPercentage = totalInvested > 0 ? (totalPL / totalInvested) * 100 : 0.0;
      
      return {
        'cashBalance': portfolioDoc.data()?['cashBalance'] ?? 0.0,
        'totalInvested': totalInvested,
        'totalCurrentValue': totalCurrentValue,
        'totalPL': totalPL,
        'totalPLPercentage': totalPLPercentage,
        'holdingsCount': holdingsSnapshot.docs.length,
      };
    } catch (e) {
      throw Exception('Failed to get portfolio summary: $e');
    }
  }

  // Delete a trade (for testing purposes)
  Future<void> deleteTrade(String tradeId) async {
    try {
      await _firestore.collection('trades').doc(tradeId).delete();
    } catch (e) {
      throw Exception('Failed to delete trade: $e');
    }
  }

  // Get trade statistics
  Future<Map<String, dynamic>> getTradeStatistics(String userId) async {
    try {
      final trades = await getUserTrades(userId);
      
      int totalTrades = trades.length;
      int buyTrades = trades.where((t) => t.isBuy).length;
      int sellTrades = trades.where((t) => t.isSell).length;
      
      double totalBuyAmount = trades
          .where((t) => t.isBuy)
          .fold(0.0, (sum, trade) => sum + trade.totalAmount);
      
      double totalSellAmount = trades
          .where((t) => t.isSell)
          .fold(0.0, (sum, trade) => sum + trade.totalAmount);
      
      return {
        'totalTrades': totalTrades,
        'buyTrades': buyTrades,
        'sellTrades': sellTrades,
        'totalBuyAmount': totalBuyAmount,
        'totalSellAmount': totalSellAmount,
        'netTradingAmount': totalSellAmount - totalBuyAmount,
      };
    } catch (e) {
      throw Exception('Failed to get trade statistics: $e');
    }
  }
}
