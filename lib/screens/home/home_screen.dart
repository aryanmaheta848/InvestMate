import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:invest_mate/constants/app_constants.dart';
import 'package:invest_mate/providers/auth_provider.dart';
import 'package:invest_mate/providers/stock_provider.dart';
import 'package:invest_mate/models/stock_model.dart';
import 'package:invest_mate/widgets/common/common_widgets.dart';
import 'package:invest_mate/widgets/cards/stock_card.dart';
import 'package:invest_mate/widgets/realtime_stock_widget.dart';
import 'package:invest_mate/screens/stock/stock_search_screen.dart';
import 'package:invest_mate/screens/stock/stock_detail_screen.dart';
import 'package:invest_mate/screens/trading/trading_test_screen.dart';
import 'package:invest_mate/utils/utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  final PageController _pageController = PageController();
  int _currentBannerIndex = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final stockProvider = Provider.of<StockProvider>(context, listen: false);
    
    if (authProvider.user != null) {
      // Load watchlist stocks
      await stockProvider.loadWatchlistStocks(authProvider.user!.watchlist);
      // Load trending stocks
      await stockProvider.loadTrendingStocks();
    }
  }

  Future<void> _onRefresh() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final stockProvider = Provider.of<StockProvider>(context, listen: false);
    
    if (authProvider.user != null) {
      await stockProvider.refreshWatchlist(authProvider.user!.watchlist);
      await stockProvider.loadTrendingStocks();
    }
    
    _refreshController.refreshCompleted();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Consumer2<AuthProvider, StockProvider>(
      builder: (context, authProvider, stockProvider, child) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SmartRefresher(
            controller: _refreshController,
            onRefresh: _onRefresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // App Bar
                SliverAppBar(
                  expandedHeight: 140,
                  floating: false,
                  pinned: true,
                  elevation: 0,
                  backgroundColor: AppColors.primary,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      'TickerTracker',
                      style: AppTextStyles.heading3.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                    background: Container(
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
                    ),
                  ),
                  actions: [
                    // Real-time toggle button
                    IconButton(
                      icon: Icon(
                        stockProvider.isRealtimeEnabled 
                          ? Icons.wifi 
                          : Icons.wifi_off,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        stockProvider.toggleRealtimeUpdates();
                      },
                      tooltip: stockProvider.isRealtimeEnabled 
                        ? 'Disable Real-time Updates' 
                        : 'Enable Real-time Updates',
                    ),
                    IconButton(
                      icon: const Icon(Icons.search_rounded, color: Colors.white),
                      onPressed: () => Get.to(() => const StockSearchScreen()),
                      tooltip: 'Search Stocks',
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                      onPressed: () {
                        // TODO: Navigate to notifications
                      },
                      tooltip: 'Notifications',
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                
                // Market Status Banner
                SliverToBoxAdapter(
                  child: _buildMarketStatusBanner(stockProvider),
                ),
                
                // Quick Stats Cards
                SliverToBoxAdapter(
                  child: _buildQuickStatsCards(authProvider, stockProvider),
                ),
                
                // Watchlist Section
                if (authProvider.user?.watchlist.isNotEmpty == true)
                  SliverToBoxAdapter(
                    child: _buildWatchlistSection(authProvider, stockProvider),
                  ),
                
                // Trending Stocks Section
                SliverToBoxAdapter(
                  child: _buildTrendingSection(stockProvider),
                ),
                
                // Market Overview
                SliverToBoxAdapter(
                  child: _buildMarketOverview(),
                ),
                
                // News Highlights
                SliverToBoxAdapter(
                  child: _buildNewsHighlights(),
                ),
                
                // Bottom padding
                const SliverToBoxAdapter(
                  child: SizedBox(height: 20), // Bottom padding
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMarketStatusBanner(StockProvider stockProvider) {
    final marketStatus = stockProvider.getMarketStatus();
    final isOpen = stockProvider.isMarketOpen();
    
    Color statusColor;
    String statusText;
    IconData statusIcon;
    String statusDescription;
    
    switch (marketStatus) {
      case MarketStatus.open:
        statusColor = AppColors.success;
        statusText = 'Market Open';
        statusIcon = Icons.radio_button_checked;
        statusDescription = 'Live trading in progress';
        break;
      case MarketStatus.preMarket:
        statusColor = AppColors.warning;
        statusText = 'Pre-Market';
        statusIcon = Icons.schedule;
        statusDescription = 'Pre-market trading active';
        break;
      case MarketStatus.postMarket:
        statusColor = AppColors.warning;
        statusText = 'Post-Market';
        statusIcon = Icons.schedule;
        statusDescription = 'After hours trading';
        break;
      default:
        statusColor = AppColors.error;
        statusText = 'Market Closed';
        statusIcon = Icons.pause_circle_filled;
        statusDescription = 'Trading resumes tomorrow';
    }
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withOpacity(0.1),
            statusColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(statusIcon, color: statusColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: AppTextStyles.body1.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusDescription,
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.onBackground.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              Utils.formatTime(DateTime.now()),
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsCards(AuthProvider authProvider, StockProvider stockProvider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Watchlist',
                  value: '${authProvider.user?.watchlist.length ?? 0}',
                  subtitle: 'stocks tracking',
                  icon: Icons.bookmark_rounded,
                  color: AppColors.primary,
                  onTap: () {
                    // Scroll to watchlist section
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Portfolio',
                  value: '₹10.0L',
                  subtitle: 'total value',
                  icon: Icons.pie_chart_rounded,
                  color: AppColors.accent,
                  onTap: () {
                    // Navigate to portfolio
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Today P&L',
                  value: '+₹2,450',
                  subtitle: '+2.45% gain',
                  icon: Icons.trending_up_rounded,
                  color: AppColors.success,
                  onTap: () {
                    // Navigate to P&L details
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Alerts',
                  value: '3',
                  subtitle: 'price alerts',
                  icon: Icons.notifications_rounded,
                  color: AppColors.warning,
                  onTap: () {
                    // Navigate to alerts
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: color.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                color: AppColors.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: AppColors.onBackground.withOpacity(0.6),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWatchlistSection(AuthProvider authProvider, StockProvider stockProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Watchlist',
                      style: AppTextStyles.heading3.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${stockProvider.watchlistStocks.length} stocks',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.onBackground.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => Get.to(() => const StockSearchScreen()),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add More'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
              ],
            ),
          ),
          if (stockProvider.isLoading)
            Container(
              height: 120,
              padding: const EdgeInsets.all(16),
              child: const Center(
                child: LoadingIndicator(message: 'Loading watchlist...'),
              ),
            )
          else if (stockProvider.watchlistStocks.isEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: EmptyStateWidget(
                icon: Icons.bookmark_outline,
                title: 'No Stocks in Watchlist',
                message: 'Add stocks to your watchlist to track their performance',
                actionText: 'Add Stocks',
                onAction: () => Get.to(() => const StockSearchScreen()),
              ),
            )
          else
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: stockProvider.watchlistStocks.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final stock = stockProvider.watchlistStocks[index];
                  return SizedBox(
                    width: 280,
                    child: StockCard(
                      stock: stock,
                      onTap: () => Get.to(() => StockDetailScreen(stock: stock)),
                      isCompact: true,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTrendingSection(StockProvider stockProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trending Stocks',
                      style: AppTextStyles.heading3.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Popular picks today',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.onBackground.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.trending_up_rounded,
                        size: 14,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'HOT',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (stockProvider.isLoading)
            Container(
              height: 120,
              padding: const EdgeInsets.all(16),
              child: const Center(
                child: LoadingIndicator(message: 'Loading trending stocks...'),
              ),
            )
          else if (stockProvider.trendingStocks.isEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: const EmptyStateWidget(
                icon: Icons.trending_up,
                title: 'No Trending Data',
                message: 'Unable to load trending stocks at the moment',
              ),
            )
          else
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: stockProvider.trendingStocks.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final stock = stockProvider.trendingStocks[index];
                  return SizedBox(
                    width: 280,
                    child: StockCard(
                      stock: stock,
                      onTap: () => Get.to(() => StockDetailScreen(stock: stock)),
                      isCompact: true,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMarketOverview() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Market Overview',
                    style: AppTextStyles.heading3.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Major indices performance',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.onBackground.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'LIVE',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildIndexItem('NIFTY 50', '19,750.25', '+125.30', '+0.64%', true),
          const SizedBox(height: 12),
          _buildIndexItem('BANK NIFTY', '44,280.15', '-85.70', '-0.19%', false),
          const SizedBox(height: 12),
          _buildIndexItem('NIFTY IT', '32,145.80', '+245.60', '+0.77%', true),
        ],
      ),
    );
  }

  Widget _buildIndexItem(String name, String price, String change, String percentage, bool isPositive) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isPositive ? AppColors.success : AppColors.error).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  price,
                  style: AppTextStyles.heading3.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isPositive ? AppColors.success : AppColors.error).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      size: 14,
                      color: isPositive ? AppColors.success : AppColors.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      percentage,
                      style: TextStyle(
                        color: isPositive ? AppColors.success : AppColors.error,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${isPositive ? '+' : ''}$change',
                style: AppTextStyles.body2.copyWith(
                  color: (isPositive ? AppColors.success : AppColors.error),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNewsHighlights() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'News Highlights',
                    style: AppTextStyles.heading3.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Latest market updates',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.onBackground.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  // Navigate to full news page
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildNewsItem(
            'Market hits new record high amid strong earnings',
            '2 hours ago',
            Icons.trending_up_rounded,
            AppColors.success,
          ),
          const SizedBox(height: 12),
          _buildNewsItem(
            'RBI keeps repo rate unchanged at 6.5%',
            '4 hours ago',
            Icons.account_balance_rounded,
            AppColors.primary,
          ),
          const SizedBox(height: 12),
          _buildNewsItem(
            'Tech stocks surge on AI optimism',
            '6 hours ago',
            Icons.computer_rounded,
            AppColors.accent,
          ),
        ],
      ),
    );
  }

  Widget _buildNewsItem(String title, String time, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        time,
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: AppColors.onBackground.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}
