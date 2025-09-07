import 'package:flutter/material.dart';
import 'package:invest_mate/constants/app_constants.dart';
import 'package:invest_mate/models/stock_model.dart';
import 'package:invest_mate/widgets/common/common_widgets.dart';

class StockCard extends StatelessWidget {
  final StockModel stock;
  final VoidCallback? onTap;
  final bool isCompact;
  final bool showWatchlistButton;

  const StockCard({
    super.key,
    required this.stock,
    this.onTap,
    this.isCompact = false,
    this.showWatchlistButton = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactCard();
    } else {
      return _buildFullCard();
    }
  }

  Widget _buildCompactCard() {
    return CustomCard(
      onTap: onTap,
      margin: const EdgeInsets.only(right: AppSizes.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stock header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getDisplaySymbol(),
                      style: AppTextStyles.body1.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      stock.name,
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              TrendingIcon(change: stock.changeAmount),
            ],
          ),
          
          const SizedBox(height: AppSizes.paddingSmall),
          
          // Price and change
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                stock.formattedPrice,
                style: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              PriceChangeIndicator(
                change: stock.changeAmount,
                percentage: stock.changePercentage,
                showIcon: false,
                textStyle: AppTextStyles.body2,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFullCard() {
    return CustomCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with symbol and watchlist button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getDisplaySymbol(),
                      style: AppTextStyles.heading3.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      stock.name,
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.onBackground.withOpacity(0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (showWatchlistButton)
                IconButton(
                  onPressed: () {
                    // TODO: Add/remove from watchlist
                  },
                  icon: const Icon(Icons.bookmark_border),
                  color: AppColors.primary,
                ),
            ],
          ),

          const SizedBox(height: AppSizes.padding),

          // Price section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stock.formattedPrice,
                    style: AppTextStyles.heading2.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  PriceChangeIndicator(
                    change: stock.changeAmount,
                    percentage: stock.changePercentage,
                    showIcon: true,
                    textStyle: AppTextStyles.body1,
                  ),
                ],
              ),
              // Sentiment indicator
              _buildSentimentIndicator(),
            ],
          ),

          const SizedBox(height: AppSizes.padding),

          // Additional info
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Volume',
                  stock.formattedVolume,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  'Market Cap',
                  stock.formattedMarketCap,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  'P/E Ratio',
                  stock.pe > 0 ? stock.pe.toStringAsFixed(1) : 'N/A',
                ),
              ),
            ],
          ),

          if (stock.sparklineData.isNotEmpty) ...[
            const SizedBox(height: AppSizes.padding),
            // Mini sparkline chart
            SizedBox(
              height: 40,
              child: _buildSparklineChart(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSentimentIndicator() {
    Color sentimentColor;
    IconData sentimentIcon;
    String sentimentText;

    switch (stock.sentiment) {
      case SentimentType.bullish:
        sentimentColor = AppColors.success;
        sentimentIcon = Icons.sentiment_very_satisfied;
        sentimentText = 'Bullish';
        break;
      case SentimentType.bearish:
        sentimentColor = AppColors.error;
        sentimentIcon = Icons.sentiment_very_dissatisfied;
        sentimentText = 'Bearish';
        break;
      default:
        sentimentColor = AppColors.neutral;
        sentimentIcon = Icons.sentiment_neutral;
        sentimentText = 'Neutral';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingSmall,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: sentimentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusSmall),
        border: Border.all(color: sentimentColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            sentimentIcon,
            size: 16,
            color: sentimentColor,
          ),
          const SizedBox(width: 4),
          Text(
            sentimentText,
            style: AppTextStyles.caption.copyWith(
              color: sentimentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.onBackground.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.body2.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSparklineChart() {
    if (stock.sparklineData.isEmpty) {
      return const SizedBox.shrink();
    }

    return CustomPaint(
      painter: SparklinePainter(
        data: stock.sparklineData,
        color: stock.isPositive ? AppColors.success : AppColors.error,
      ),
      size: const Size(double.infinity, 40),
    );
  }

  String _getDisplaySymbol() {
    // Remove .NS suffix for cleaner display
    return stock.symbol.replaceAll('.NS', '');
  }
}

class SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  SparklinePainter({
    required this.data,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || data.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();

    // Find min and max values for normalization
    double minValue = data.reduce((a, b) => a < b ? a : b);
    double maxValue = data.reduce((a, b) => a > b ? a : b);
    double range = maxValue - minValue;

    if (range == 0) range = 1; // Avoid division by zero

    // Calculate points
    for (int i = 0; i < data.length; i++) {
      double x = (i / (data.length - 1)) * size.width;
      double y = size.height - ((data[i] - minValue) / range) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Add gradient fill
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0.3),
          color.withOpacity(0.05),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, gradientPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate != this;
  }
}
