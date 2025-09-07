import 'package:flutter/foundation.dart';
import 'package:invest_mate/models/trade_model.dart';
import 'package:invest_mate/models/holding_model.dart';
import 'package:invest_mate/models/portfolio_model.dart';
import 'package:invest_mate/services/firebase/trade_service.dart';
import 'package:invest_mate/services/firebase/firebase_service.dart';
import 'package:invest_mate/constants/app_constants.dart';
import 'package:invest_mate/utils/utils.dart';
import 'dart:developer' as dev;

class PortfolioProvider extends ChangeNotifier {
  PortfolioModel? _portfolio;
  List<HoldingModel> _holdings = [];
  List<TradeModel> _tradeHistory = [];
  
  bool _isLoading = false;
  String? _errorMessage;
  
  final TradeService _tradeService = TradeService();
  final FirebaseService _firebaseService = FirebaseService();

  // Getters
  PortfolioModel? get portfolio => _portfolio;
  List<HoldingModel> get holdings => _holdings;
  List<TradeModel> get tradeHistory => _tradeHistory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Initialize portfolio
  void initializePortfolio(PortfolioModel portfolio) {
    _portfolio = portfolio;
    notifyListeners();
  }

  // Initialize default portfolio for new users
  Future<void> initializeDefaultPortfolio() async {
    try {
      _setLoading(true);
      
      // Create default portfolio
      _portfolio = PortfolioModel(
        userId: 'demo_user', // Replace with actual user ID
        cashBalance: AppConstants.initialBalance,
        totalInvested: 0.0,
        totalCurrentValue: 0.0,
        totalPL: 0.0,
        totalPLPercentage: 0.0,
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      );
      
      // Load existing data from Firebase
      await loadPortfolioData();
      
      _setLoading(false);
    } catch (e) {
      _setError('Failed to initialize portfolio: $e');
    }
  }

  // Load portfolio data from Firebase
  Future<void> loadPortfolioData() async {
    try {
      _setLoading(true);
      
      final userId = _firebaseService.currentUserId ?? 'demo_user';
      
      // Load portfolio
      final portfolio = await _firebaseService.getPortfolio(userId);
      if (portfolio != null) {
        _portfolio = portfolio;
      }
      
      // Load holdings
      final holdings = await _firebaseService.getUserHoldings(userId);
      _holdings = holdings;
      
      // Load trade history
      final trades = await _tradeService.getUserTrades(userId, limit: 50);
      _tradeHistory = trades;
      
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load portfolio data: $e');
    }
  }

  // Update portfolio
  void updatePortfolio(PortfolioModel portfolio) {
    _portfolio = portfolio;
    notifyListeners();
  }

  // Update holdings
  void updateHoldings(List<HoldingModel> holdings) {
    _holdings = holdings;
    notifyListeners();
  }

  // Update trade history
  void updateTradeHistory(List<TradeModel> trades) {
    _tradeHistory = trades;
    notifyListeners();
  }

  // Add new trade
  void addTrade(TradeModel trade) {
    _tradeHistory.insert(0, trade);
    notifyListeners();
  }

  // Update holding
  void updateHolding(HoldingModel holding) {
    final index = _holdings.indexWhere((h) => h.symbol == holding.symbol);
    if (index != -1) {
      _holdings[index] = holding;
    } else {
      _holdings.add(holding);
    }
    notifyListeners();
  }

  // Remove holding
  void removeHolding(String symbol) {
    _holdings.removeWhere((h) => h.symbol == symbol);
    notifyListeners();
  }

  // Get holding by symbol
  HoldingModel? getHolding(String symbol) {
    try {
      return _holdings.firstWhere((h) => h.symbol == symbol);
    } catch (e) {
      return null;
    }
  }

  // Check if can buy
  bool canBuy(double totalAmount) {
    if (_portfolio == null) return false;
    return _portfolio!.cashBalance >= totalAmount;
  }

  // Check if can sell
  bool canSell(String symbol, int quantity) {
    final holding = getHolding(symbol);
    if (holding == null) return false;
    return holding.quantity >= quantity;
  }

  // Calculate portfolio metrics
  Map<String, double> calculateMetrics() {
    if (_holdings.isEmpty) {
      return {
        'totalInvested': 0.0,
        'currentValue': 0.0,
        'totalPL': 0.0,
        'totalPLPercentage': 0.0,
      };
    }

    double totalInvested = 0.0;
    double currentValue = 0.0;

    for (final holding in _holdings) {
      totalInvested += holding.investedValue;
      currentValue += holding.currentValue;
    }

    final totalPL = currentValue - totalInvested;
    final totalPLPercentage = totalInvested > 0 ? (totalPL / totalInvested) * 100 : 0.0;

    return {
      'totalInvested': totalInvested,
      'currentValue': currentValue,
      'totalPL': totalPL,
      'totalPLPercentage': totalPLPercentage,
    };
  }

  // Get top performers
  List<HoldingModel> getTopPerformers([int limit = 5]) {
    final sortedHoldings = List<HoldingModel>.from(_holdings);
    sortedHoldings.sort((a, b) => b.unrealizedPLPercentage.compareTo(a.unrealizedPLPercentage));
    return sortedHoldings.take(limit).toList();
  }

  // Get worst performers
  List<HoldingModel> getWorstPerformers([int limit = 5]) {
    final sortedHoldings = List<HoldingModel>.from(_holdings);
    sortedHoldings.sort((a, b) => a.unrealizedPLPercentage.compareTo(b.unrealizedPLPercentage));
    return sortedHoldings.take(limit).toList();
  }

  // Get recent trades
  List<TradeModel> getRecentTrades([int limit = 10]) {
    return _tradeHistory.take(limit).toList();
  }

  // Get trades for a specific stock
  List<TradeModel> getTradesForStock(String symbol) {
    return _tradeHistory.where((trade) => trade.symbol == symbol).toList();
  }

  // Calculate realized P&L from trades
  double calculateRealizedPL() {
    double realizedPL = 0.0;
    
    // Group trades by symbol
    final tradesBySymbol = <String, List<TradeModel>>{};
    for (final trade in _tradeHistory) {
      if (trade.status == TradeStatus.executed) {
        tradesBySymbol[trade.symbol] ??= [];
        tradesBySymbol[trade.symbol]!.add(trade);
      }
    }

    // Calculate realized P&L for each symbol
    for (final entry in tradesBySymbol.entries) {
      final trades = entry.value;
      trades.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      int remainingQuantity = 0;
      double totalCost = 0.0;
      
      for (final trade in trades) {
        if (trade.isBuy) {
          remainingQuantity += trade.quantity;
          totalCost += trade.totalAmount;
        } else {
          if (remainingQuantity > 0) {
            final sellQuantity = trade.quantity.clamp(0, remainingQuantity);
            final avgCostPerShare = totalCost / remainingQuantity;
            final costOfSoldShares = avgCostPerShare * sellQuantity;
            final saleProceeds = trade.price * sellQuantity;
            
            realizedPL += saleProceeds - costOfSoldShares;
            
            remainingQuantity -= sellQuantity;
            totalCost -= costOfSoldShares;
          }
        }
      }
    }
    
    return realizedPL;
  }

  // Get portfolio allocation by stock
  Map<String, double> getPortfolioAllocation() {
    if (_holdings.isEmpty) return {};
    
    final totalValue = _holdings.fold(0.0, (sum, holding) => sum + holding.currentValue);
    if (totalValue == 0) return {};
    
    final allocation = <String, double>{};
    for (final holding in _holdings) {
      allocation[holding.symbol] = (holding.currentValue / totalValue) * 100;
    }
    
    return allocation;
  }

  // Execute a trade with Firebase integration
  Future<bool> executeTrade({
    required String symbol,
    required String companyName,
    required int quantity,
    required double price,
    required bool isBuy,
    bool isMarketOrder = true,
  }) async {
    try {
      _setLoading(true);
      
      // Validate input parameters
      if (quantity <= 0) {
        handleTradeError('invalid_quantity');
        return false;
      }
      
      if (price <= 0) {
        handleTradeError('invalid_price');
        return false;
      }

      final totalAmount = quantity * price;

      // Validate trade conditions
      if (isBuy) {
        if (!canBuy(totalAmount)) {
          handleTradeError('insufficient_balance', amount: totalAmount);
          return false;
        }
      } else {
        final holding = getHolding(symbol);
        final availableQuantity = holding?.quantity ?? 0;
        
        if (!canSell(symbol, quantity)) {
          handleTradeError('insufficient_shares', symbol: symbol, quantity: availableQuantity);
          return false;
        }
      }

      // Execute trade using Firebase service
      final userId = _firebaseService.currentUserId ?? 'demo_user';
      final success = await _tradeService.executeTrade(
        userId: userId,
        symbol: symbol,
        stockName: companyName,
        quantity: quantity,
        price: price,
        isBuy: isBuy,
      );

      if (success) {
        // Reload data from Firebase to ensure consistency
        await loadPortfolioData();
        clearError();
        return true;
      } else {
        _setError('Failed to execute trade');
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _executeBuyTrade(TradeModel trade) {
    // Update cash balance
    if (_portfolio != null) {
      _portfolio = _portfolio!.copyWith(
        cashBalance: _portfolio!.cashBalance - trade.totalAmount,
      );
    }

    // Update or create holding
    final existingHolding = getHolding(trade.symbol);
    if (existingHolding != null) {
      // Average down the cost
      final totalQuantity = existingHolding.quantity + trade.quantity;
      final totalInvestedValue = existingHolding.investedValue + trade.totalAmount;
      final newAveragePrice = totalInvestedValue / totalQuantity;

      final updatedHolding = existingHolding.copyWith(
        quantity: totalQuantity,
        averagePrice: newAveragePrice,
        currentPrice: trade.price, // Update with latest price
        lastUpdated: DateTime.now(),
      );

      updateHolding(updatedHolding);
    } else {
      // Create new holding
      final newHolding = HoldingModel(
        userId: trade.userId,
        symbol: trade.symbol,
        stockName: trade.stockName,
        quantity: trade.quantity,
        averagePrice: trade.price,
        currentPrice: trade.price,
        lastUpdated: DateTime.now(),
      );

      _holdings.add(newHolding);
    }
  }

  void _executeSellTrade(TradeModel trade) {
    // Update cash balance
    if (_portfolio != null) {
      _portfolio = _portfolio!.copyWith(
        cashBalance: _portfolio!.cashBalance + trade.totalAmount,
      );
    }

    // Update holding
    final existingHolding = getHolding(trade.symbol);
    if (existingHolding != null) {
      final newQuantity = existingHolding.quantity - trade.quantity;
      
      if (newQuantity <= 0) {
        // Remove holding if no shares left
        removeHolding(trade.symbol);
      } else {
        // Update quantity, keep same average price
        final updatedHolding = existingHolding.copyWith(
          quantity: newQuantity,
          currentPrice: trade.price,
          lastUpdated: DateTime.now(),
        );

        updateHolding(updatedHolding);
      }
    }
  }

  // Refresh portfolio data
  Future<void> refreshPortfolioData() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));

      // Update portfolio metrics
      final metrics = calculateMetrics();
      
      if (_portfolio != null) {
        _portfolio = _portfolio!.copyWith(
          totalInvested: metrics['totalInvested']!,
          totalCurrentValue: metrics['currentValue']!,
          totalPL: metrics['totalPL']!,
          totalPLPercentage: metrics['totalPLPercentage']!,
        );
      }

      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error with improved error handling
  void _setError(String error) {
    // Log the error for debugging purposes
    debugPrint('PortfolioProvider Error: $error');
    
    // Set the error message
    _errorMessage = error;
    
    // Notify listeners of the error state change
    notifyListeners();
  }

  // Clear error
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }
  
  // Handle specific trade errors
  void handleTradeError(String errorType, {String? symbol, int? quantity, double? amount}) {
    switch (errorType) {
      case 'insufficient_balance':
        _setError('Insufficient cash balance to complete this purchase of ${Utils.formatCurrency(amount ?? 0)}');
        break;
      case 'insufficient_shares':
        _setError('Insufficient shares to sell. You only have ${quantity ?? 0} shares of $symbol');
        break;
      case 'invalid_quantity':
        _setError('Invalid quantity. Please enter a valid number of shares.');
        break;
      case 'invalid_price':
        _setError('Invalid price. Please enter a valid price per share.');
        break;
      case 'market_closed':
        _setError('Market is currently closed. Please try again during market hours.');
        break;
      default:
        _setError('An error occurred while processing your trade. Please try again.');
    }
  }
}
