import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:invest_mate/constants/app_constants.dart';
import 'package:invest_mate/models/trade_model.dart';
import 'package:invest_mate/providers/portfolio_provider.dart';
import 'package:invest_mate/utils/utils.dart';
import 'package:intl/intl.dart';

class TradeHistoryScreen extends StatefulWidget {
  const TradeHistoryScreen({super.key});

  @override
  State<TradeHistoryScreen> createState() => _TradeHistoryScreenState();
}

class _TradeHistoryScreenState extends State<TradeHistoryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Buy', 'Sell', 'Today', 'This Week', 'This Month'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trade History'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              Provider.of<PortfolioProvider>(context, listen: false)
                  .loadPortfolioData();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All Trades'),
            Tab(text: 'Statistics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTradesList(),
          _buildStatisticsView(),
        ],
      ),
    );
  }

  Widget _buildTradesList() {
    return Column(
      children: [
        // Filter chips
        _buildFilterChips(),
        
        // Trades list
        Expanded(
          child: Consumer<PortfolioProvider>(
            builder: (context, portfolioProvider, child) {
              if (portfolioProvider.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final trades = _getFilteredTrades(portfolioProvider.tradeHistory);

              if (trades.isEmpty) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                onRefresh: () => portfolioProvider.loadPortfolioData(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppSizes.padding),
                  itemCount: trades.length,
                  itemBuilder: (context, index) {
                    return _buildTradeCard(trades[index]);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingSmall),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          
          return Padding(
            padding: const EdgeInsets.only(right: AppSizes.paddingSmall),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              selectedColor: AppColors.primary.withOpacity(0.2),
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.onBackground,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTradeCard(TradeModel trade) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
      elevation: AppSizes.elevationLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
      ),
      child: InkWell(
        onTap: () => _showTradeDetails(trade),
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Stock symbol and name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trade.symbol.replaceAll('.NS', ''),
                          style: AppTextStyles.body1.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          trade.stockName,
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.onBackground.withOpacity(0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  // Trade type badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingSmall,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: trade.isBuy 
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      trade.isBuy ? 'BUY' : 'SELL',
                      style: AppTextStyles.caption.copyWith(
                        color: trade.isBuy ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppSizes.paddingSmall),
              
              // Trade details
              Row(
                children: [
                  // Quantity and price
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${trade.quantity} shares @ ${Utils.formatCurrency(trade.price)}',
                          style: AppTextStyles.body2,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('MMM dd, yyyy • HH:mm').format(trade.createdAt),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.onBackground.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Total amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Utils.formatCurrency(trade.totalAmount),
                        style: AppTextStyles.body1.copyWith(
                          fontWeight: FontWeight.bold,
                          color: trade.isBuy ? AppColors.error : AppColors.success,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(trade.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          trade.status.toString().split('.').last.toUpperCase(),
                          style: AppTextStyles.caption.copyWith(
                            color: _getStatusColor(trade.status),
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_rounded,
            size: 80,
            color: AppColors.onBackground.withOpacity(0.3),
          ),
          const SizedBox(height: AppSizes.paddingLarge),
          Text(
            'No trades yet',
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.onBackground.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: AppSizes.paddingSmall),
          Text(
            'Start trading to see your transaction history here',
            style: AppTextStyles.body2.copyWith(
              color: AppColors.onBackground.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.paddingLarge),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.trending_up_rounded),
            label: const Text('Start Trading'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsView() {
    return Consumer<PortfolioProvider>(
      builder: (context, portfolioProvider, child) {
        final trades = portfolioProvider.tradeHistory;
        
        if (trades.isEmpty) {
          return _buildEmptyState();
        }

        final stats = _calculateStatistics(trades);
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overview cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Trades',
                      '${stats['totalTrades']}',
                      Icons.swap_horiz_rounded,
                      AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingSmall),
                  Expanded(
                    child: _buildStatCard(
                      'Buy Orders',
                      '${stats['buyTrades']}',
                      Icons.trending_up_rounded,
                      AppColors.success,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppSizes.paddingSmall),
              
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Sell Orders',
                      '${stats['sellTrades']}',
                      Icons.trending_down_rounded,
                      AppColors.error,
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingSmall),
                  Expanded(
                    child: _buildStatCard(
                      'Success Rate',
                      '${stats['successRate']}%',
                      Icons.check_circle_rounded,
                      AppColors.info,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppSizes.paddingLarge),
              
              // Trading volume
              _buildVolumeCard(stats),
              
              const SizedBox(height: AppSizes.paddingLarge),
              
              // Recent activity
              _buildRecentActivityCard(trades.take(5).toList()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: AppSizes.elevationLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: AppSizes.paddingSmall),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.onBackground.withOpacity(0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.paddingSmall),
            Text(
              value,
              style: AppTextStyles.heading3.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVolumeCard(Map<String, dynamic> stats) {
    return Card(
      elevation: AppSizes.elevationLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trading Volume',
              style: AppTextStyles.heading4.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSizes.padding),
            
            _buildVolumeRow(
              'Total Buy Volume',
              Utils.formatCurrency(stats['totalBuyVolume']),
              AppColors.success,
            ),
            _buildVolumeRow(
              'Total Sell Volume',
              Utils.formatCurrency(stats['totalSellVolume']),
              AppColors.error,
            ),
            _buildVolumeRow(
              'Net Volume',
              Utils.formatCurrency(stats['netVolume']),
              stats['netVolume'] >= 0 ? AppColors.success : AppColors.error,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVolumeRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.body2,
          ),
          Text(
            value,
            style: AppTextStyles.body2.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard(List<TradeModel> recentTrades) {
    return Card(
      elevation: AppSizes.elevationLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: AppTextStyles.heading4.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSizes.padding),
            
            ...recentTrades.map((trade) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: trade.isBuy ? AppColors.success : AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingSmall),
                  Expanded(
                    child: Text(
                      '${trade.isBuy ? 'Bought' : 'Sold'} ${trade.quantity} ${trade.symbol.replaceAll('.NS', '')}',
                      style: AppTextStyles.body2,
                    ),
                  ),
                  Text(
                    DateFormat('MMM dd').format(trade.createdAt),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.onBackground.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  List<TradeModel> _getFilteredTrades(List<TradeModel> trades) {
    final now = DateTime.now();
    
    switch (_selectedFilter) {
      case 'Buy':
        return trades.where((t) => t.isBuy).toList();
      case 'Sell':
        return trades.where((t) => t.isSell).toList();
      case 'Today':
        return trades.where((t) => 
          t.createdAt.day == now.day &&
          t.createdAt.month == now.month &&
          t.createdAt.year == now.year
        ).toList();
      case 'This Week':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return trades.where((t) => t.createdAt.isAfter(weekStart)).toList();
      case 'This Month':
        return trades.where((t) => 
          t.createdAt.month == now.month &&
          t.createdAt.year == now.year
        ).toList();
      default:
        return trades;
    }
  }

  Map<String, dynamic> _calculateStatistics(List<TradeModel> trades) {
    final totalTrades = trades.length;
    final buyTrades = trades.where((t) => t.isBuy).length;
    final sellTrades = trades.where((t) => t.isSell).length;
    
    final totalBuyVolume = trades
        .where((t) => t.isBuy)
        .fold(0.0, (sum, trade) => sum + trade.totalAmount);
    
    final totalSellVolume = trades
        .where((t) => t.isSell)
        .fold(0.0, (sum, trade) => sum + trade.totalAmount);
    
    final netVolume = totalSellVolume - totalBuyVolume;
    final successRate = totalTrades > 0 ? ((trades.where((t) => t.status == TradeStatus.executed).length / totalTrades) * 100).round() : 0;
    
    return {
      'totalTrades': totalTrades,
      'buyTrades': buyTrades,
      'sellTrades': sellTrades,
      'totalBuyVolume': totalBuyVolume,
      'totalSellVolume': totalSellVolume,
      'netVolume': netVolume,
      'successRate': successRate,
    };
  }

  Color _getStatusColor(TradeStatus status) {
    switch (status) {
      case TradeStatus.executed:
        return AppColors.success;
      case TradeStatus.pending:
        return AppColors.warning;
      case TradeStatus.cancelled:
        return AppColors.error;
      case TradeStatus.failed:
        return AppColors.error;
    }
  }

  void _showTradeDetails(TradeModel trade) {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trade Details',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: AppSizes.padding),
            
            _buildDetailRow('Symbol', trade.symbol.replaceAll('.NS', '')),
            _buildDetailRow('Company', trade.stockName),
            _buildDetailRow('Type', trade.isBuy ? 'Buy' : 'Sell'),
            _buildDetailRow('Quantity', '${trade.quantity} shares'),
            _buildDetailRow('Price', Utils.formatCurrency(trade.price)),
            _buildDetailRow('Total Amount', Utils.formatCurrency(trade.totalAmount)),
            _buildDetailRow('Status', trade.status.toString().split('.').last.toUpperCase()),
            _buildDetailRow('Date', DateFormat('MMM dd, yyyy').format(trade.createdAt)),
            _buildDetailRow('Time', DateFormat('HH:mm:ss').format(trade.createdAt)),
            
            if (trade.executedAt != null)
              _buildDetailRow('Executed At', DateFormat('MMM dd, yyyy HH:mm:ss').format(trade.executedAt!)),
            
            const SizedBox(height: AppSizes.paddingLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.body2.copyWith(
              color: AppColors.onBackground.withOpacity(0.7),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.body2.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}


