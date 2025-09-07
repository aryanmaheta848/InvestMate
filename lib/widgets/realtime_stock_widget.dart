import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:invest_mate/providers/stock_provider.dart';
import 'package:invest_mate/models/stock_model.dart';
import 'package:invest_mate/constants/app_constants.dart';

class RealtimeStockWidget extends StatefulWidget {
  final String symbol;
  final Widget Function(StockModel stock) builder;
  final bool showLoadingIndicator;
  final Duration? refreshInterval;

  const RealtimeStockWidget({
    super.key,
    required this.symbol,
    required this.builder,
    this.showLoadingIndicator = true,
    this.refreshInterval,
  });

  @override
  State<RealtimeStockWidget> createState() => _RealtimeStockWidgetState();
}

class _RealtimeStockWidgetState extends State<RealtimeStockWidget> {
  StockModel? _currentStock;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _startRealtimeUpdates();
  }

  void _loadInitialData() async {
    final stockProvider = Provider.of<StockProvider>(context, listen: false);
    final stock = await stockProvider.getStock(widget.symbol);
    
    if (mounted) {
      setState(() {
        _currentStock = stock;
        _isLoading = false;
        _error = stock == null ? 'Failed to load stock data' : null;
      });
    }
  }

  void _startRealtimeUpdates() {
    final stockProvider = Provider.of<StockProvider>(context, listen: false);
    
    if (stockProvider.isRealtimeEnabled) {
      stockProvider.getRealtimeStockStream(widget.symbol).listen(
        (updatedStock) {
          if (mounted) {
            setState(() {
              _currentStock = updatedStock;
              _isLoading = false;
              _error = null;
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _error = error.toString();
              _isLoading = false;
            });
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && widget.showLoadingIndicator) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              'Error loading data',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.error,
              ),
            ),
          ],
        ),
      );
    }

    if (_currentStock == null) {
      return const Center(
        child: Text(
          'No data available',
          style: AppTextStyles.caption,
        ),
      );
    }

    return widget.builder(_currentStock!);
  }
}

// Specialized widget for displaying stock price with real-time updates
class RealtimeStockPrice extends StatelessWidget {
  final String symbol;
  final TextStyle? priceStyle;
  final TextStyle? changeStyle;
  final bool showChange;
  final bool showChangePercent;
  final bool showVolume;
  final bool showLastUpdate;

  const RealtimeStockPrice({
    super.key,
    required this.symbol,
    this.priceStyle,
    this.changeStyle,
    this.showChange = true,
    this.showChangePercent = true,
    this.showVolume = false,
    this.showLastUpdate = false,
  });

  @override
  Widget build(BuildContext context) {
    return RealtimeStockWidget(
      symbol: symbol,
      builder: (stock) => _buildPriceDisplay(stock),
    );
  }

  Widget _buildPriceDisplay(StockModel stock) {
    final isPositive = stock.changeAmount >= 0;
    final changeColor = isPositive ? AppColors.bullish : AppColors.bearish;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Current Price
        Text(
          '₹${stock.currentPrice.toStringAsFixed(2)}',
          style: priceStyle ?? AppTextStyles.heading3.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        if (showChange || showChangePercent) ...[
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showChange) ...[
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  size: 16,
                  color: changeColor,
                ),
                const SizedBox(width: 4),
                Text(
                  '₹${stock.changeAmount.abs().toStringAsFixed(2)}',
                  style: changeStyle ?? AppTextStyles.body2.copyWith(
                    color: changeColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              
              if (showChange && showChangePercent) ...[
                const SizedBox(width: 8),
                Container(
                  width: 1,
                  height: 12,
                  color: AppColors.border,
                ),
                const SizedBox(width: 8),
              ],
              
              if (showChangePercent) ...[
                Text(
                  '${isPositive ? '+' : ''}${stock.changePercent.toStringAsFixed(2)}%',
                  style: changeStyle ?? AppTextStyles.body2.copyWith(
                    color: changeColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ],
        
        if (showVolume) ...[
          const SizedBox(height: 4),
          Text(
            'Vol: ${_formatVolume(stock.volume)}',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.onBackground,
            ),
          ),
        ],
        
        if (showLastUpdate) ...[
          const SizedBox(height: 2),
          Text(
            'Updated: ${_formatTime(stock.lastUpdated)}',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.onBackground,
              fontSize: 10,
            ),
          ),
        ],
      ],
    );
  }

  String _formatVolume(int volume) {
    if (volume >= 1000000) {
      return '${(volume / 1000000).toStringAsFixed(1)}M';
    } else if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}K';
    } else {
      return volume.toString();
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

// Widget for displaying stock price with animation
class AnimatedStockPrice extends StatefulWidget {
  final String symbol;
  final TextStyle? priceStyle;
  final Duration animationDuration;

  const AnimatedStockPrice({
    super.key,
    required this.symbol,
    this.priceStyle,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<AnimatedStockPrice> createState() => _AnimatedStockPriceState();
}

class _AnimatedStockPriceState extends State<AnimatedStockPrice>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation;
  StockModel? _previousStock;
  StockModel? _currentStock;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _colorAnimation = ColorTween(
      begin: AppColors.neutral,
      end: AppColors.neutral,
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updateStock(StockModel newStock) {
    if (_currentStock != null) {
      _previousStock = _currentStock;
      _currentStock = newStock;
      
      // Animate color change based on price movement
      final isPositive = newStock.currentPrice > (_previousStock?.currentPrice ?? 0);
      _colorAnimation = ColorTween(
        begin: _colorAnimation.value ?? AppColors.neutral,
        end: isPositive ? AppColors.bullish : AppColors.bearish,
      ).animate(_animationController);
      
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
    } else {
      _currentStock = newStock;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RealtimeStockWidget(
      symbol: widget.symbol,
      builder: (stock) {
        _updateStock(stock);
        return AnimatedBuilder(
          animation: _colorAnimation,
          builder: (context, child) {
            return Text(
              '₹${stock.currentPrice.toStringAsFixed(2)}',
              style: widget.priceStyle ?? AppTextStyles.heading3.copyWith(
                color: _colorAnimation.value ?? AppColors.onSurface,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        );
      },
    );
  }
}
