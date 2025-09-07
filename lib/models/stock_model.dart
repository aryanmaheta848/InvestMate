import 'package:cloud_firestore/cloud_firestore.dart';

enum MarketStatus {
  open,
  closed,
  preMarket,
  postMarket,
}

enum SentimentType {
  bullish,
  bearish,
  neutral,
}

class StockModel {
  final String symbol;
  final String name;
  final String exchange;
  final String sector;
  final String industry;
  final double currentPrice;
  final double previousClose;
  final double dayHigh;
  final double dayLow;
  final double open;
  final int volume;
  final int avgVolume;
  final double marketCap;
  final double pe;
  final double eps;
  final double dividend;
  final double dividendYield;
  final MarketStatus marketStatus;
  final SentimentType sentiment;
  final double sentimentScore;
  final DateTime lastUpdated;
  final List<double> sparklineData;

  StockModel({
    required this.symbol,
    required this.name,
    this.exchange = 'NSE',
    this.sector = 'Unknown',
    this.industry = 'Unknown',
    required this.currentPrice,
    required this.previousClose,
    required this.dayHigh,
    required this.dayLow,
    required this.open,
    required this.volume,
    this.avgVolume = 0,
    this.marketCap = 0.0,
    this.pe = 0.0,
    this.eps = 0.0,
    this.dividend = 0.0,
    this.dividendYield = 0.0,
    this.marketStatus = MarketStatus.closed,
    this.sentiment = SentimentType.neutral,
    this.sentimentScore = 0.0,
    DateTime? lastUpdated,
    this.sparklineData = const [],
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  // Create from Yahoo Finance API response
  factory StockModel.fromYahooFinance(Map<String, dynamic> data) {
    final meta = data['chart']?['result']?[0]?['meta'] ?? {};
    final quote = data['chart']?['result']?[0]?['indicators']?['quote']?[0] ?? {};
    final closes = List<double>.from(quote['close']?.where((x) => x != null) ?? []);
    
    return StockModel(
      symbol: meta['symbol'] ?? '',
      name: meta['longName'] ?? meta['shortName'] ?? '',
      exchange: meta['exchangeName'] ?? 'NSE',
      currentPrice: (meta['regularMarketPrice'] ?? 0.0).toDouble(),
      previousClose: (meta['previousClose'] ?? 0.0).toDouble(),
      dayHigh: (meta['regularMarketDayHigh'] ?? 0.0).toDouble(),
      dayLow: (meta['regularMarketDayLow'] ?? 0.0).toDouble(),
      open: (meta['regularMarketOpen'] ?? 0.0).toDouble(),
      volume: (meta['regularMarketVolume'] ?? 0).toInt(),
      marketCap: (meta['marketCap'] ?? 0.0).toDouble(),
      sparklineData: closes.length > 30 ? closes.sublist(closes.length - 30) : closes,
    );
  }

  // Create from Alpha Vantage API response
  factory StockModel.fromAlphaVantage(Map<String, dynamic> data) {
    final quote = data['Global Quote'] ?? {};
    
    return StockModel(
      symbol: quote['01. symbol'] ?? '',
      name: quote['01. symbol'] ?? '', // Alpha Vantage doesn't provide company name in quote
      currentPrice: double.tryParse(quote['05. price'] ?? '0') ?? 0.0,
      previousClose: double.tryParse(quote['08. previous close'] ?? '0') ?? 0.0,
      dayHigh: double.tryParse(quote['03. high'] ?? '0') ?? 0.0,
      dayLow: double.tryParse(quote['04. low'] ?? '0') ?? 0.0,
      open: double.tryParse(quote['02. open'] ?? '0') ?? 0.0,
      volume: int.tryParse(quote['06. volume'] ?? '0') ?? 0,
    );
  }

  // Create from Firestore document
  factory StockModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    
    return StockModel(
      symbol: doc.id,
      name: data?['name'] ?? '',
      exchange: data?['exchange'] ?? 'NSE',
      sector: data?['sector'] ?? 'Unknown',
      industry: data?['industry'] ?? 'Unknown',
      currentPrice: (data?['currentPrice'] ?? 0.0).toDouble(),
      previousClose: (data?['previousClose'] ?? 0.0).toDouble(),
      dayHigh: (data?['dayHigh'] ?? 0.0).toDouble(),
      dayLow: (data?['dayLow'] ?? 0.0).toDouble(),
      open: (data?['open'] ?? 0.0).toDouble(),
      volume: (data?['volume'] ?? 0).toInt(),
      avgVolume: (data?['avgVolume'] ?? 0).toInt(),
      marketCap: (data?['marketCap'] ?? 0.0).toDouble(),
      pe: (data?['pe'] ?? 0.0).toDouble(),
      eps: (data?['eps'] ?? 0.0).toDouble(),
      dividend: (data?['dividend'] ?? 0.0).toDouble(),
      dividendYield: (data?['dividendYield'] ?? 0.0).toDouble(),
      marketStatus: MarketStatus.values.firstWhere(
        (status) => status.toString() == 'MarketStatus.${data?['marketStatus']}',
        orElse: () => MarketStatus.closed,
      ),
      sentiment: SentimentType.values.firstWhere(
        (sentiment) => sentiment.toString() == 'SentimentType.${data?['sentiment']}',
        orElse: () => SentimentType.neutral,
      ),
      sentimentScore: (data?['sentimentScore'] ?? 0.0).toDouble(),
      lastUpdated: (data?['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      sparklineData: List<double>.from(data?['sparklineData'] ?? []),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'exchange': exchange,
      'sector': sector,
      'industry': industry,
      'currentPrice': currentPrice,
      'previousClose': previousClose,
      'dayHigh': dayHigh,
      'dayLow': dayLow,
      'open': open,
      'volume': volume,
      'avgVolume': avgVolume,
      'marketCap': marketCap,
      'pe': pe,
      'eps': eps,
      'dividend': dividend,
      'dividendYield': dividendYield,
      'marketStatus': marketStatus.toString().split('.').last,
      'sentiment': sentiment.toString().split('.').last,
      'sentimentScore': sentimentScore,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'sparklineData': sparklineData,
    };
  }

  // Calculated properties
  double get changeAmount => currentPrice - previousClose;
  double get changePercentage => previousClose != 0 ? ((changeAmount / previousClose) * 100) : 0.0;
  double get changePercent => changePercentage; // Alias for changePercentage
  String? get companyName => name; // Alias for name
  bool get isPositive => changeAmount >= 0;
  bool get isNegative => changeAmount < 0;
  
  String get formattedPrice => '₹${currentPrice.toStringAsFixed(2)}';
  String get formattedChange => '${isPositive ? '+' : ''}₹${changeAmount.toStringAsFixed(2)}';
  String get formattedChangePercentage => '${isPositive ? '+' : ''}${changePercentage.toStringAsFixed(2)}%';
  String get formattedMarketCap {
    if (marketCap >= 1e12) {
      return '₹${(marketCap / 1e12).toStringAsFixed(2)}T';
    } else if (marketCap >= 1e9) {
      return '₹${(marketCap / 1e9).toStringAsFixed(2)}B';
    } else if (marketCap >= 1e7) {
      return '₹${(marketCap / 1e7).toStringAsFixed(2)}Cr';
    } else if (marketCap >= 1e5) {
      return '₹${(marketCap / 1e5).toStringAsFixed(2)}L';
    } else {
      return '₹${marketCap.toStringAsFixed(0)}';
    }
  }

  String get formattedVolume {
    if (volume >= 1e7) {
      return '${(volume / 1e7).toStringAsFixed(1)}Cr';
    } else if (volume >= 1e5) {
      return '${(volume / 1e5).toStringAsFixed(1)}L';
    } else if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}K';
    } else {
      return volume.toString();
    }
  }

  // Copy with new values
  StockModel copyWith({
    String? symbol,
    String? name,
    String? exchange,
    String? sector,
    String? industry,
    double? currentPrice,
    double? previousClose,
    double? dayHigh,
    double? dayLow,
    double? open,
    int? volume,
    int? avgVolume,
    double? marketCap,
    double? pe,
    double? eps,
    double? dividend,
    double? dividendYield,
    MarketStatus? marketStatus,
    SentimentType? sentiment,
    double? sentimentScore,
    DateTime? lastUpdated,
    List<double>? sparklineData,
  }) {
    return StockModel(
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      exchange: exchange ?? this.exchange,
      sector: sector ?? this.sector,
      industry: industry ?? this.industry,
      currentPrice: currentPrice ?? this.currentPrice,
      previousClose: previousClose ?? this.previousClose,
      dayHigh: dayHigh ?? this.dayHigh,
      dayLow: dayLow ?? this.dayLow,
      open: open ?? this.open,
      volume: volume ?? this.volume,
      avgVolume: avgVolume ?? this.avgVolume,
      marketCap: marketCap ?? this.marketCap,
      pe: pe ?? this.pe,
      eps: eps ?? this.eps,
      dividend: dividend ?? this.dividend,
      dividendYield: dividendYield ?? this.dividendYield,
      marketStatus: marketStatus ?? this.marketStatus,
      sentiment: sentiment ?? this.sentiment,
      sentimentScore: sentimentScore ?? this.sentimentScore,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      sparklineData: sparklineData ?? this.sparklineData,
    );
  }

  @override
  String toString() {
    return 'StockModel(symbol: $symbol, name: $name, currentPrice: $currentPrice)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StockModel && other.symbol == symbol;
  }

  @override
  int get hashCode => symbol.hashCode;
}

// OHLCV data for charts
class OHLCVData {
  final DateTime timestamp;
  final double open;
  final double high;
  final double low;
  final double close;
  final int volume;

  OHLCVData({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  factory OHLCVData.fromJson(Map<String, dynamic> json) {
    return OHLCVData(
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] * 1000),
      open: json['open'].toDouble(),
      high: json['high'].toDouble(),
      low: json['low'].toDouble(),
      close: json['close'].toDouble(),
      volume: json['volume'].toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.millisecondsSinceEpoch ~/ 1000,
      'open': open,
      'high': high,
      'low': low,
      'close': close,
      'volume': volume,
    };
  }
}
