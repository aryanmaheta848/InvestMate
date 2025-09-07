import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:invest_mate/constants/app_constants.dart';
import 'package:invest_mate/providers/portfolio_provider.dart';
import 'package:invest_mate/providers/auth_provider.dart';
import 'package:invest_mate/models/trade_model.dart';
import 'package:invest_mate/models/portfolio_model.dart';
import 'package:invest_mate/models/holding_model.dart';
import 'package:invest_mate/screens/trading/trade_history_screen.dart';
import 'package:invest_mate/widgets/common/common_widgets.dart';
import 'package:invest_mate/utils/utils.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PortfolioProvider, AuthProvider>(
      builder: (context, portfolioProvider, authProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('My Portfolio'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
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
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  portfolioProvider.loadPortfolioData();
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Portfolio Summary
              _buildPortfolioSummary(portfolioProvider),
              
              // Tabs
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.onBackground.withOpacity(0.6),
                tabs: const [
                  Tab(text: 'Holdings'),
                  Tab(text: 'Trades'),
                  Tab(text: 'Performance'),
                ],
              ),
              
              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildHoldingsTab(portfolioProvider),
                    _buildTradesTab(portfolioProvider),
                    _buildPerformanceTab(portfolioProvider),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPortfolioSummary(PortfolioProvider portfolioProvider) {
    // Mock data for demonstration
    final portfolio = portfolioProvider.portfolio ?? PortfolioModel(
      userId: 'demo_user',
      cashBalance: 750000.0,
      totalInvested: 250000.0,
      currentValue: 250000.0,
      totalCurrentValue: 287500.0,
      totalPL: 37500.0,
      totalPLPercentage: 15.0,
      lastUpdated: DateTime.now(),
    );

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
      ),
      padding: const EdgeInsets.all(AppSizes.paddingLarge),
      child: Column(
        children: [
          // Total Portfolio Value
          Text(
            'Total Portfolio Value',
            style: AppTextStyles.body1.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: AppSizes.paddingSmall),
          Text(
            portfolio.formattedTotalPortfolioValue,
            style: AppTextStyles.heading1.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 32,
            ),
          ),
          const SizedBox(height: AppSizes.paddingSmall),
          
          // P/L Display
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.padding,
              vertical: AppSizes.paddingSmall,
            ),
            decoration: BoxDecoration(
              color: portfolio.isProfitable 
                  ? AppColors.success.withOpacity(0.2)
                  : AppColors.error.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppSizes.borderRadius),
              border: Border.all(
                color: portfolio.isProfitable 
                    ? AppColors.success 
                    : AppColors.error,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  portfolio.isProfitable 
                      ? Icons.trending_up 
                      : Icons.trending_down,
                  color: portfolio.isProfitable 
                      ? AppColors.success 
                      : AppColors.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  portfolio.formattedTotalPL,
                  style: AppTextStyles.body1.copyWith(
                    color: portfolio.isProfitable 
                        ? AppColors.success 
                        : AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${portfolio.formattedTotalPLPercentage})',
                  style: AppTextStyles.body1.copyWith(
                    color: portfolio.isProfitable 
                        ? AppColors.success 
                        : AppColors.error,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppSizes.paddingLarge),
          
          // Quick Stats Row
          Row(
            children: [
              Expanded(
                child: _buildQuickStat(
                  'Invested',
                  portfolio.formattedTotalInvested,
                  Colors.white70,
                ),
              ),
              Expanded(
                child: _buildQuickStat(
                  'Current Value',
                  portfolio.formattedTotalCurrentValue,
                  Colors.white70,
                ),
              ),
              Expanded(
                child: _buildQuickStat(
                  'Cash Balance',
                  portfolio.formattedCashBalance,
                  Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: color.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.body1.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildHoldingsTab(PortfolioProvider portfolioProvider) {
    if (portfolioProvider.holdings.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.pie_chart_outline,
        title: 'No Holdings',
        message: 'Start investing to see your holdings here',
        actionText: 'Explore Stocks',
        onAction: () {
          // TODO: Navigate to stock search
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.padding),
      itemCount: portfolioProvider.holdings.length,
      itemBuilder: (context, index) {
        final holding = portfolioProvider.holdings[index];
        return _buildHoldingCard(holding);
      },
    );
  }

  Widget _buildHoldingCard(HoldingModel holding) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
      child: Row(
        children: [
          // Stock info
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  holding.symbol.replaceAll('.NS', ''),
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  holding.stockName,
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.onBackground.withOpacity(0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSizes.paddingSmall),
                Text(
                  '${holding.quantity} shares • Avg: ${holding.formattedAveragePrice}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          
          // Performance
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  holding.formattedCurrentValue,
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  holding.formattedUnrealizedPL,
                  style: AppTextStyles.body2.copyWith(
                    color: holding.isProfitable 
                        ? AppColors.success 
                        : AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  holding.formattedUnrealizedPLPercentage,
                  style: AppTextStyles.caption.copyWith(
                    color: holding.isProfitable 
                        ? AppColors.success 
                        : AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTradesTab(PortfolioProvider portfolioProvider) {
    final trades = portfolioProvider.getRecentTrades(20);
    
    if (trades.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.receipt_long,
        title: 'No Trades',
        message: 'Your trade history will appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.padding),
      itemCount: trades.length,
      itemBuilder: (context, index) {
        final trade = trades[index];
        return _buildTradeCard(trade);
      },
    );
  }

  Widget _buildTradeCard(TradeModel trade) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
      child: Row(
        children: [
          // Trade type indicator
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingSmall),
            decoration: BoxDecoration(
              color: trade.isBuy 
                  ? AppColors.success.withOpacity(0.1) 
                  : AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusSmall),
            ),
            child: Icon(
              trade.isBuy ? Icons.add : Icons.remove,
              color: trade.isBuy ? AppColors.success : AppColors.error,
              size: 20,
            ),
          ),
          
          const SizedBox(width: AppSizes.padding),
          
          // Trade details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      trade.symbol.replaceAll('.NS', ''),
                      style: AppTextStyles.body1.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      trade.formattedAmount,
                      style: AppTextStyles.body1.copyWith(
                        fontWeight: FontWeight.bold,
                        color: trade.isBuy ? AppColors.error : AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${trade.quantity} @ ${trade.formattedPrice}',
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.onBackground.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      Utils.formatDate(trade.createdAt),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.onBackground.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab(PortfolioProvider portfolioProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Performance summary cards
          Row(
            children: [
              Expanded(
                child: _buildPerformanceCard(
                  'Total Return',
                  '₹37,500',
                  '+15.0%',
                  AppColors.success,
                ),
              ),
              const SizedBox(width: AppSizes.padding),
              Expanded(
                child: _buildPerformanceCard(
                  'Today\'s Return',
                  '₹2,350',
                  '+0.95%',
                  AppColors.success,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSizes.paddingLarge),
          
          // Top Performers Section
          Text(
            'Top Performers',
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSizes.padding),
          
          // Mock top performers
          _buildPerformanceItem('RELIANCE', '+18.5%', AppColors.success),
          _buildPerformanceItem('TCS', '+12.3%', AppColors.success),
          _buildPerformanceItem('INFY', '+8.7%', AppColors.success),
          
          const SizedBox(height: AppSizes.paddingLarge),
          
          // Portfolio Allocation
          Text(
            'Portfolio Allocation',
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSizes.padding),
          
          const Center(
            child: Column(
              children: [
                Icon(
                  Icons.pie_chart,
                  size: 64,
                  color: AppColors.primary,
                ),
                SizedBox(height: AppSizes.padding),
                Text(
                  'Portfolio Allocation Chart',
                  style: AppTextStyles.body1,
                ),
                Text(
                  'Coming Soon!',
                  style: AppTextStyles.body2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard(String title, String value, String percentage, Color color) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.onBackground.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: AppSizes.paddingSmall),
          Text(
            value,
            style: AppTextStyles.body1.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            percentage,
            style: AppTextStyles.body2.copyWith(
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceItem(String symbol, String return_, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingSmall),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            symbol,
            style: AppTextStyles.body1.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingSmall,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusSmall),
            ),
            child: Text(
              return_,
              style: AppTextStyles.body2.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
