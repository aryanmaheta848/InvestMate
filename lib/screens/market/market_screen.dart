import 'package:flutter/material.dart';
import 'package:invest_mate/constants/app_constants.dart';

class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Market'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implement filter functionality
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Market Overview Section
            _buildSectionTitle('Market Overview'),
            const SizedBox(height: AppSizes.padding),
            _buildMarketOverviewCards(),
            
            const SizedBox(height: AppSizes.paddingLarge),
            
            // Top Gainers Section
            _buildSectionTitle('Top Gainers'),
            const SizedBox(height: AppSizes.padding),
            _buildStockList(isGainers: true),
            
            const SizedBox(height: AppSizes.paddingLarge),
            
            // Top Losers Section
            _buildSectionTitle('Top Losers'),
            const SizedBox(height: AppSizes.padding),
            _buildStockList(isGainers: false),
            
            const SizedBox(height: AppSizes.paddingLarge),
            
            // Market News Section
            _buildSectionTitle('Market News'),
            const SizedBox(height: AppSizes.padding),
            _buildNewsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppSizes.paddingSmall),
        Text(
          title,
          style: AppTextStyles.heading3,
        ),
      ],
    );
  }

  Widget _buildMarketOverviewCards() {
    final marketData = [
      {'name': 'NIFTY 50', 'price': '19,435.50', 'change': '+2.45%', 'isPositive': true},
      {'name': 'SENSEX', 'price': '65,220.30', 'change': '+1.89%', 'isPositive': true},
      {'name': 'BANK NIFTY', 'price': '44,125.80', 'change': '-0.67%', 'isPositive': false},
    ];

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: marketData.length,
        separatorBuilder: (context, index) => const SizedBox(width: AppSizes.padding),
        itemBuilder: (context, index) {
          final data = marketData[index];
          return Container(
            width: 180,
            padding: const EdgeInsets.all(AppSizes.padding),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizes.borderRadius),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  data['name'] as String,
                  style: AppTextStyles.body2.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['price'] as String,
                      style: AppTextStyles.heading3.copyWith(
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      data['change'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: (data['isPositive'] as bool) 
                          ? AppColors.bullish 
                          : AppColors.bearish,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStockList({required bool isGainers}) {
    final stocks = isGainers
        ? [
            {'symbol': 'RELIANCE', 'price': '2,450.30', 'change': '+5.67%'},
            {'symbol': 'TCS', 'price': '3,220.45', 'change': '+3.42%'},
            {'symbol': 'HDFC BANK', 'price': '1,680.20', 'change': '+2.89%'},
          ]
        : [
            {'symbol': 'ZOMATO', 'price': '85.40', 'change': '-4.23%'},
            {'symbol': 'PAYTM', 'price': '720.15', 'change': '-3.78%'},
            {'symbol': 'NYKAA', 'price': '145.30', 'change': '-2.95%'},
          ];

    return Column(
      children: stocks.map((stock) => Container(
        margin: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
        padding: const EdgeInsets.all(AppSizes.padding),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              stock['symbol'] as String,
              style: AppTextStyles.body1.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${stock['price']}',
                  style: AppTextStyles.body1,
                ),
                Text(
                  stock['change'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isGainers ? AppColors.bullish : AppColors.bearish,
                  ),
                ),
              ],
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildNewsList() {
    final news = [
      {
        'title': 'Market hits new high as IT stocks surge',
        'time': '2 hours ago',
      },
      {
        'title': 'Banking sector shows strong performance',
        'time': '4 hours ago',
      },
      {
        'title': 'FII inflows boost market sentiment',
        'time': '6 hours ago',
      },
    ];

    return Column(
      children: news.map((article) => Container(
        margin: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
        padding: const EdgeInsets.all(AppSizes.padding),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusSmall),
              ),
              child: Icon(
                Icons.article,
                color: AppColors.primary,
                size: AppSizes.iconSize,
              ),
            ),
            const SizedBox(width: AppSizes.padding),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article['title'] as String,
                    style: AppTextStyles.body1.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    article['time'] as String,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.onBackground,
            ),
          ],
        ),
      )).toList(),
    );
  }
}
