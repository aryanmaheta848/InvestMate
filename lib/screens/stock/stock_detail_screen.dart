import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:invest_mate/constants/app_constants.dart';
import 'package:invest_mate/models/stock_model.dart';
import 'package:invest_mate/providers/stock_provider.dart';
import 'package:invest_mate/providers/portfolio_provider.dart';
import 'package:invest_mate/providers/auth_provider.dart';
import 'package:invest_mate/widgets/common/common_widgets.dart';
import 'package:invest_mate/widgets/dialogs/trade_dialog.dart';
import 'package:invest_mate/widgets/charts/stock_chart_widget.dart';
import 'package:invest_mate/utils/utils.dart';

class StockDetailScreen extends StatefulWidget {
  final StockModel stock;

  const StockDetailScreen({
    super.key,
    required this.stock,
  });

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> with TickerProviderStateMixin {
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

  Future<void> _toggleWatchlist() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.user != null) {
      final isInWatchlist = authProvider.user!.hasStockInWatchlist(widget.stock.symbol);
      
      if (isInWatchlist) {
        await authProvider.removeFromWatchlist(widget.stock.symbol);
        if (mounted) {
          Utils.showSuccessSnackbar(context, 'Removed from watchlist');
        }
      } else {
        await authProvider.addToWatchlist(widget.stock.symbol);
        if (mounted) {
          Utils.showSuccessSnackbar(context, 'Added to watchlist');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final isInWatchlist = authProvider.user?.hasStockInWatchlist(widget.stock.symbol) ?? false;
        
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                backgroundColor: AppColors.primary,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    widget.stock.symbol.replaceAll('.NS', ''),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.padding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              widget.stock.name,
                              style: AppTextStyles.body1.copyWith(
                                color: Colors.white70,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppSizes.paddingSmall),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  widget.stock.formattedPrice,
                                  style: AppTextStyles.heading1.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: AppSizes.padding),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSizes.paddingSmall,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: widget.stock.isPositive 
                                        ? AppColors.success 
                                        : AppColors.error,
                                    borderRadius: BorderRadius.circular(AppSizes.borderRadiusSmall),
                                  ),
                                  child: Text(
                                    Utils.formatPercentage(widget.stock.changePercentage),
                                    style: AppTextStyles.body2.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: _toggleWatchlist,
                    icon: Icon(
                      isInWatchlist ? Icons.bookmark : Icons.bookmark_border,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // TODO: Share stock
                    },
                    icon: const Icon(Icons.share, color: Colors.white),
                  ),
                ],
              ),

              // Content
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // Quick Stats
                    _buildQuickStats(),
                    
                    // Tab Section
                    _buildTabSection(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickStats() {
    return CustomCard(
      margin: const EdgeInsets.all(AppSizes.padding),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Open',
                  Utils.formatCurrency(widget.stock.open),
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'High',
                  Utils.formatCurrency(widget.stock.dayHigh),
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Low',
                  Utils.formatCurrency(widget.stock.dayLow),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.padding),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Volume',
                  Utils.formatVolume(widget.stock.volume),
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Market Cap',
                  widget.stock.formattedMarketCap,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'P/E Ratio',
                  widget.stock.pe > 0 ? widget.stock.pe.toStringAsFixed(1) : 'N/A',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.onBackground.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.body1.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTabSection() {
    return Column(
      children: [
        // Tab Bar
        Container(
          color: Theme.of(context).cardColor,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.onBackground.withOpacity(0.6),
            tabs: const [
              Tab(text: 'Chart'),
              Tab(text: 'News'),
              Tab(text: 'About'),
            ],
          ),
        ),
        
        // Tab Content
        SizedBox(
          height: 400,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildChartTab(),
              _buildNewsTab(),
              _buildAboutTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChartTab() {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.padding),
      child: StockChartWidget(
        stock: widget.stock,
        height: 250,
      ),
    );
  }

  Widget _buildNewsTab() {
    // Mock news data
    final newsItems = [
      {
        'title': 'Q3 Earnings Beat Expectations',
        'summary': 'Strong quarterly performance with revenue growth of 15% YoY',
        'time': '2 hours ago',
        'sentiment': 'positive',
      },
      {
        'title': 'New Product Launch Announcement',
        'summary': 'Company announces expansion into new market segment',
        'time': '4 hours ago',
        'sentiment': 'positive',
      },
      {
        'title': 'Analyst Rating Upgrade',
        'summary': 'Morgan Stanley raises target price citing strong fundamentals',
        'time': '1 day ago',
        'sentiment': 'positive',
      },
      {
        'title': 'Market Volatility Impact',
        'summary': 'Stock affected by broader market concerns over inflation',
        'time': '2 days ago',
        'sentiment': 'neutral',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.padding),
      itemCount: newsItems.length,
      itemBuilder: (context, index) {
        final news = newsItems[index];
        return CustomCard(
          margin: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        news['title']!,
                        style: AppTextStyles.body1.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingSmall,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getSentimentColor(news['sentiment']!).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSizes.borderRadiusSmall),
                      ),
                      child: Text(
                        news['sentiment']!.toUpperCase(),
                        style: AppTextStyles.caption.copyWith(
                          color: _getSentimentColor(news['sentiment']!),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.paddingSmall),
                Text(
                  news['summary']!,
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.onBackground.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: AppSizes.paddingSmall),
                Text(
                  news['time']!,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.onBackground.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getSentimentColor(String sentiment) {
    switch (sentiment) {
      case 'positive':
        return AppColors.success;
      case 'negative':
        return AppColors.error;
      default:
        return Colors.orange;
    }
  }

  Widget _buildAboutTab() {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Company Information',
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSizes.padding),
          
          _buildInfoRow('Symbol', widget.stock.symbol),
          _buildInfoRow('Name', widget.stock.name),
          _buildInfoRow('Sector', widget.stock.sector),
          _buildInfoRow('Industry', widget.stock.industry),
          _buildInfoRow('Exchange', widget.stock.exchange),
          
          const SizedBox(height: AppSizes.padding),
          
          Text(
            'Key Metrics',
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSizes.padding),
          
          _buildInfoRow('Market Cap', widget.stock.formattedMarketCap),
          _buildInfoRow('P/E Ratio', widget.stock.pe > 0 ? widget.stock.pe.toStringAsFixed(2) : 'N/A'),
          _buildInfoRow('EPS', widget.stock.eps > 0 ? '₹${widget.stock.eps.toStringAsFixed(2)}' : 'N/A'),
          _buildInfoRow('Dividend Yield', '${widget.stock.dividendYield.toStringAsFixed(2)}%'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingSmall),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.body1.copyWith(
              color: AppColors.onBackground.withOpacity(0.7),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.body1.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
