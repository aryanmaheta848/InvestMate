import 'package:flutter/material.dart';
import 'package:invest_mate/constants/app_constants.dart';
import 'package:invest_mate/models/stock_model.dart';
import 'package:invest_mate/screens/trading/trade_screen.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Watchlist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Implement add stock functionality
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Watchlist tabs
          _buildWatchlistTabs(),
          
          // Watchlist content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.padding),
              child: Column(
                children: [
                  _buildStocksList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWatchlistTabs() {
    return Container(
      height: 50,
      margin: const EdgeInsets.all(AppSizes.padding),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusSmall),
              ),
              child: Center(
                child: Text(
                  'Watchlist 1',
                  style: AppTextStyles.body2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Watchlist 2',
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.onBackground,
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Watchlist 3',
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.onBackground,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStocksList() {
    final stocks = [
      {
        'symbol': 'RELIANCE',
        'name': 'Reliance Industries Ltd',
        'price': '2,450.30',
        'change': '+2.45%',
        'changeValue': '+58.70',
        'isPositive': true
      },
      {
        'symbol': 'TCS',
        'name': 'Tata Consultancy Services Ltd',
        'price': '3,220.45',
        'change': '+1.89%',
        'changeValue': '+59.80',
        'isPositive': true
      },
      {
        'symbol': 'HDFCBANK',
        'name': 'HDFC Bank Ltd',
        'price': '1,680.20',
        'change': '-0.67%',
        'changeValue': '-11.30',
        'isPositive': false
      },
      {
        'symbol': 'INFY',
        'name': 'Infosys Ltd',
        'price': '1,420.85',
        'change': '+3.21%',
        'changeValue': '+44.15',
        'isPositive': true
      },
      {
        'symbol': 'ICICIBANK',
        'name': 'ICICI Bank Ltd',
        'price': '920.50',
        'change': '-1.45%',
        'changeValue': '-13.55',
        'isPositive': false
      },
      {
        'symbol': 'HINDUNILVR',
        'name': 'Hindustan Unilever Ltd',
        'price': '2,650.90',
        'change': '+0.85%',
        'changeValue': '+22.35',
        'isPositive': true
      },
    ];

    return Column(
      children: stocks.map((stock) => Container(
        margin: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
        child: Card(
          child: InkWell(
            onTap: () {
              // TODO: Navigate to stock detail screen
            },
            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.padding),
              child: Row(
                children: [
                  // Stock icon/logo
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSizes.borderRadiusSmall),
                    ),
                    child: Center(
                      child: Text(
                        (stock['symbol'] as String).substring(0, 2),
                        style: AppTextStyles.body1.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: AppSizes.padding),
                  
                  // Stock details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stock['symbol'] as String,
                          style: AppTextStyles.body1.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          stock['name'] as String,
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  // Price and change
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${stock['price']}',
                        style: AppTextStyles.body1.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.paddingSmall,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: (stock['isPositive'] as bool)
                              ? AppColors.success.withOpacity(0.1)
                              : AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              (stock['isPositive'] as bool)
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 12,
                              color: (stock['isPositive'] as bool)
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              stock['change'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: (stock['isPositive'] as bool)
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // More options
                  IconButton(
                    icon: const Icon(
                      Icons.more_vert,
                      color: AppColors.onBackground,
                    ),
                    onPressed: () {
                      _showStockOptions(context, stock['symbol'] as String);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      )).toList(),
    );
  }

  void _showStockOptions(BuildContext context, String symbol) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.borderRadius),
        ),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSizes.padding),
            Text(
              symbol,
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: AppSizes.padding),
            ListTile(
              leading: const Icon(Icons.show_chart, color: AppColors.primary),
              title: const Text('View Chart'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to chart screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart, color: AppColors.success),
              title: const Text('Buy'),
              onTap: () {
                Navigator.pop(context);
                _navigateToTrade(context, symbol, true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.sell, color: AppColors.error),
              title: const Text('Sell'),
              onTap: () {
                Navigator.pop(context);
                _navigateToTrade(context, symbol, false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: const Text('Remove from Watchlist'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Remove from watchlist
              },
            ),
            const SizedBox(height: AppSizes.padding),
          ],
        ),
      ),
    );
  }

  void _navigateToTrade(BuildContext context, String symbol, bool isBuy) {
    // Create a mock StockModel for demonstration
    // In a real app, you would fetch the actual stock data
    final stock = StockModel(
      symbol: '$symbol.NS',
      name: _getCompanyName(symbol),
      currentPrice: _getMockPrice(symbol),
      previousClose: _getMockPrice(symbol) - (_getMockChange(symbol) / 100 * _getMockPrice(symbol)),
      dayHigh: _getMockPrice(symbol) * 1.05,
      dayLow: _getMockPrice(symbol) * 0.95,
      open: _getMockPrice(symbol) * 0.98,
      volume: 1000000,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TradeScreen(
          stock: stock,
          isBuyOrder: isBuy,
        ),
      ),
    );
  }

  String _getCompanyName(String symbol) {
    // Mock company names for demonstration
    const companyNames = {
      'RELIANCE': 'Reliance Industries Ltd',
      'TCS': 'Tata Consultancy Services Ltd',
      'HDFCBANK': 'HDFC Bank Ltd',
      'INFY': 'Infosys Ltd',
      'ICICIBANK': 'ICICI Bank Ltd',
      'HINDUNILVR': 'Hindustan Unilever Ltd',
    };
    return companyNames[symbol] ?? '$symbol Ltd';
  }

  double _getMockPrice(String symbol) {
    // Mock prices for demonstration
    const prices = {
      'RELIANCE': 2450.30,
      'TCS': 3220.45,
      'HDFCBANK': 1680.20,
      'INFY': 1420.85,
      'ICICIBANK': 920.50,
      'HINDUNILVR': 2650.90,
    };
    return prices[symbol] ?? 1000.0;
  }

  double _getMockChange(String symbol) {
    // Mock change percentages for demonstration
    const changes = {
      'RELIANCE': 2.45,
      'TCS': 1.89,
      'HDFCBANK': -0.67,
      'INFY': 3.21,
      'ICICIBANK': -1.45,
      'HINDUNILVR': 0.85,
    };
    return changes[symbol] ?? 0.0;
  }
}
