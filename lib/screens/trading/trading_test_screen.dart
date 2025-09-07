import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:invest_mate/constants/app_constants.dart';
import 'package:invest_mate/models/stock_model.dart';
import 'package:invest_mate/providers/portfolio_provider.dart';
import 'package:invest_mate/screens/trading/trade_screen.dart';
import 'package:invest_mate/screens/trading/trade_history_screen.dart';

class TradingTestScreen extends StatefulWidget {
  const TradingTestScreen({super.key});

  @override
  State<TradingTestScreen> createState() => _TradingTestScreenState();
}

class _TradingTestScreenState extends State<TradingTestScreen> {
  final List<StockModel> _testStocks = [
    StockModel(
      symbol: 'RELIANCE.NS',
      name: 'Reliance Industries Ltd',
      currentPrice: 2450.50,
      previousClose: 2400.00,
      dayHigh: 2500.00,
      dayLow: 2380.00,
      open: 2410.00,
      volume: 1000000,
    ),
    StockModel(
      symbol: 'TCS.NS',
      name: 'Tata Consultancy Services Ltd',
      currentPrice: 3850.75,
      previousClose: 3800.00,
      dayHigh: 3900.00,
      dayLow: 3750.00,
      open: 3820.00,
      volume: 500000,
    ),
    StockModel(
      symbol: 'HDFCBANK.NS',
      name: 'HDFC Bank Ltd',
      currentPrice: 1650.25,
      previousClose: 1620.00,
      dayHigh: 1680.00,
      dayLow: 1600.00,
      open: 1630.00,
      volume: 800000,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trading Test'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const TradeHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<PortfolioProvider>(
        builder: (context, portfolioProvider, child) {
          return Padding(
            padding: const EdgeInsets.all(AppSizes.padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Portfolio Summary
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Portfolio Summary',
                          style: AppTextStyles.heading3,
                        ),
                        const SizedBox(height: AppSizes.padding),
                        if (portfolioProvider.portfolio != null) ...[
                          _buildSummaryRow('Cash Balance', '₹${portfolioProvider.portfolio!.cashBalance.toStringAsFixed(2)}'),
                          _buildSummaryRow('Total Invested', '₹${portfolioProvider.portfolio!.totalInvested.toStringAsFixed(2)}'),
                          _buildSummaryRow('Current Value', '₹${portfolioProvider.portfolio!.totalCurrentValue.toStringAsFixed(2)}'),
                          _buildSummaryRow('P&L', '₹${portfolioProvider.portfolio!.totalPL.toStringAsFixed(2)}'),
                          _buildSummaryRow('P&L %', '${portfolioProvider.portfolio!.totalPLPercentage.toStringAsFixed(2)}%'),
                        ] else ...[
                          const Text('No portfolio data available'),
                        ],
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: AppSizes.paddingLarge),
                
                Text(
                  'Test Stocks',
                  style: AppTextStyles.heading3,
                ),
                const SizedBox(height: AppSizes.padding),
                
                // Test stocks list
                Expanded(
                  child: ListView.builder(
                    itemCount: _testStocks.length,
                    itemBuilder: (context, index) {
                      final stock = _testStocks[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
                        child: ListTile(
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.primary, AppColors.primaryLight],
                              ),
                              borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                            ),
                            child: Center(
                              child: Text(
                                stock.symbol.replaceAll('.NS', '').substring(0, 3),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          title: Text(stock.name),
                          subtitle: Text('NSE: ${stock.symbol.replaceAll('.NS', '')}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${stock.currentPrice.toStringAsFixed(2)}',
                                style: AppTextStyles.body1.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                '${stock.changePercentage >= 0 ? '+' : ''}${stock.changePercentage.toStringAsFixed(2)}%',
                                style: AppTextStyles.caption.copyWith(
                                  color: stock.changePercentage >= 0 ? AppColors.success : AppColors.error,
                                ),
                              ),
                            ],
                          ),
                          onTap: () => _showTradingOptions(stock),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _showTradingOptions(StockModel stock) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.borderRadiusLarge),
        ),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Trade ${stock.symbol.replaceAll('.NS', '')}',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: AppSizes.padding),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => TradeScreen(
                            stock: stock,
                            isBuyOrder: true,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.trending_up_rounded),
                    label: const Text('Buy'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.padding),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => TradeScreen(
                            stock: stock,
                            isBuyOrder: false,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.trending_down_rounded),
                    label: const Text('Sell'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSizes.padding),
          ],
        ),
      ),
    );
  }
}


