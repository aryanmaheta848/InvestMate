import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:invest_mate/constants/app_constants.dart';
import 'package:invest_mate/models/stock_model.dart';
import 'package:invest_mate/providers/portfolio_provider.dart';
import 'package:invest_mate/screens/trading/trade_history_screen.dart';
import 'package:invest_mate/utils/utils.dart';

enum OrderType { market, limit, stopLoss }
enum OrderDuration { day, gtc }

class TradeScreen extends StatefulWidget {
  final StockModel stock;
  final bool isBuyOrder;

  const TradeScreen({
    super.key,
    required this.stock,
    required this.isBuyOrder,
  });

  @override
  State<TradeScreen> createState() => _TradeScreenState();
}

class _TradeScreenState extends State<TradeScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _stopLossController = TextEditingController();

  OrderType _orderType = OrderType.market;
  OrderDuration _orderDuration = OrderDuration.day;
  bool _isLoading = false;

  double get _currentPrice => widget.stock.currentPrice ?? 0.0;
  int get _quantity => int.tryParse(_quantityController.text) ?? 0;
  double get _price {
    switch (_orderType) {
      case OrderType.market:
        return _currentPrice;
      case OrderType.limit:
      case OrderType.stopLoss:
        return double.tryParse(_priceController.text) ?? 0.0;
    }
  }

  double get _totalAmount => _quantity * _price;
  double get _stopLossPrice => double.tryParse(_stopLossController.text) ?? 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _priceController.text = _currentPrice.toStringAsFixed(2);
    _stopLossController.text = (_currentPrice * 0.95).toStringAsFixed(2);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _stopLossController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.isBuyOrder ? 'Buy' : 'Sell'} ${widget.stock.symbol.replaceAll('.NS', '')}'),
        backgroundColor: widget.isBuyOrder ? AppColors.success : AppColors.error,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showStockInfo,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              widget.isBuyOrder 
                  ? AppColors.success.withOpacity(0.05)
                  : AppColors.error.withOpacity(0.05),
              AppColors.background,
            ],
            stops: const [0.0, 0.3],
          ),
        ),
        child: Column(
          children: [
            // Stock Info Header
            _buildStockInfoHeader(),
            
            // Trading Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.padding),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order Type Selection
                      _buildOrderTypeSection(),
                      
                      const SizedBox(height: AppSizes.paddingLarge),
                      
                      // Quantity Input
                      _buildQuantitySection(),
                      
                      const SizedBox(height: AppSizes.paddingLarge),
                      
                      // Price Input (for non-market orders)
                      if (_orderType != OrderType.market) ...[
                        _buildPriceSection(),
                        const SizedBox(height: AppSizes.paddingLarge),
                      ],
                      
                      // Stop Loss (for stop loss orders)
                      if (_orderType == OrderType.stopLoss) ...[
                        _buildStopLossSection(),
                        const SizedBox(height: AppSizes.paddingLarge),
                      ],
                      
                      // Order Duration
                      _buildOrderDurationSection(),
                      
                      const SizedBox(height: AppSizes.paddingLarge),
                      
                      // Order Summary
                      _buildOrderSummary(),
                      
                      const SizedBox(height: AppSizes.paddingLarge * 2),
                    ],
                  ),
                ),
              ),
            ),
            
            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStockInfoHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.padding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Stock Logo/Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
              borderRadius: BorderRadius.circular(AppSizes.borderRadius),
            ),
            child: Center(
              child: Text(
                widget.stock.symbol.replaceAll('.NS', '').substring(0, 
                    widget.stock.symbol.replaceAll('.NS', '').length > 3 ? 3 : widget.stock.symbol.replaceAll('.NS', '').length),
                style: AppTextStyles.body1.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: AppSizes.padding),
          
          // Stock Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.stock.companyName ?? widget.stock.symbol.replaceAll('.NS', ''),
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'NSE: ${widget.stock.symbol.replaceAll('.NS', '')}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.onBackground.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(width: AppSizes.paddingSmall),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'EQUITY',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Current Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Utils.formatCurrency(_currentPrice),
                style: AppTextStyles.heading3.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              if (widget.stock.changePercent != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingSmall,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: (widget.stock.changePercent! >= 0
                        ? AppColors.success
                        : AppColors.error).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.stock.changePercent! >= 0
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 12,
                        color: widget.stock.changePercent! >= 0
                            ? AppColors.success
                            : AppColors.error,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${widget.stock.changePercent! >= 0 ? '+' : ''}${widget.stock.changePercent!.toStringAsFixed(2)}%',
                        style: AppTextStyles.caption.copyWith(
                          color: widget.stock.changePercent! >= 0
                              ? AppColors.success
                              : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Type',
          style: AppTextStyles.body1.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSizes.paddingSmall),
        Row(
          children: OrderType.values.map((type) {
            final isSelected = _orderType == type;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: type != OrderType.values.last ? AppSizes.paddingSmall : 0,
                ),
                child: GestureDetector(
                  onTap: () => setState(() => _orderType = type),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSizes.padding,
                      horizontal: AppSizes.paddingSmall,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _getOrderTypeIcon(type),
                          color: isSelected ? Colors.white : AppColors.onBackground,
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getOrderTypeName(type),
                          style: AppTextStyles.caption.copyWith(
                            color: isSelected ? Colors.white : AppColors.onBackground,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuantitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quantity',
          style: AppTextStyles.body1.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSizes.paddingSmall),
        TextFormField(
          controller: _quantityController,
          decoration: InputDecoration(
            hintText: 'Enter number of shares',
            prefixIcon: const Icon(Icons.format_list_numbered_rounded),
            suffixText: 'shares',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.borderRadius),
            ),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter quantity';
            }
            final quantity = int.tryParse(value);
            if (quantity == null || quantity <= 0) {
              return 'Please enter a valid quantity';
            }
            if (quantity > 10000) {
              return 'Maximum 10,000 shares allowed';
            }
            return null;
          },
          onChanged: (_) => setState(() {}),
        ),
        // Quick quantity buttons
        const SizedBox(height: AppSizes.paddingSmall),
        Row(
          children: [10, 50, 100, 500].map((qty) {
            return Padding(
              padding: const EdgeInsets.only(right: AppSizes.paddingSmall),
              child: OutlinedButton(
                onPressed: () {
                  _quantityController.text = qty.toString();
                  setState(() {});
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.padding,
                    vertical: AppSizes.paddingSmall,
                  ),
                ),
                child: Text(qty.toString()),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _orderType == OrderType.limit ? 'Limit Price' : 'Trigger Price',
          style: AppTextStyles.body1.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSizes.paddingSmall),
        TextFormField(
          controller: _priceController,
          decoration: InputDecoration(
            hintText: 'Enter price per share',
            prefixIcon: const Icon(Icons.currency_rupee_rounded),
            suffixText: 'per share',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.borderRadius),
            ),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\\d+\\.?\\d{0,2}')),
          ],
          validator: (value) {
            if (_orderType != OrderType.market) {
              if (value == null || value.isEmpty) {
                return 'Please enter price';
              }
              final price = double.tryParse(value);
              if (price == null || price <= 0) {
                return 'Please enter a valid price';
              }
            }
            return null;
          },
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildStopLossSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stop Loss Price',
          style: AppTextStyles.body1.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSizes.paddingSmall),
        TextFormField(
          controller: _stopLossController,
          decoration: InputDecoration(
            hintText: 'Enter stop loss price',
            prefixIcon: const Icon(Icons.stop_circle_outlined),
            suffixText: 'per share',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.borderRadius),
            ),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\\d+\\.?\\d{0,2}')),
          ],
          validator: (value) {
            if (_orderType == OrderType.stopLoss) {
              if (value == null || value.isEmpty) {
                return 'Please enter stop loss price';
              }
              final price = double.tryParse(value);
              if (price == null || price <= 0) {
                return 'Please enter a valid price';
              }
            }
            return null;
          },
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildOrderDurationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Duration',
          style: AppTextStyles.body1.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSizes.paddingSmall),
        Row(
          children: OrderDuration.values.map((duration) {
            final isSelected = _orderDuration == duration;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: duration != OrderDuration.values.last ? AppSizes.paddingSmall : 0,
                ),
                child: GestureDetector(
                  onTap: () => setState(() => _orderDuration = duration),
                  child: Container(
                    padding: const EdgeInsets.all(AppSizes.padding),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Text(
                      duration == OrderDuration.day ? 'Day Order' : 'Good Till Cancel',
                      style: AppTextStyles.body2.copyWith(
                        color: isSelected ? Colors.white : AppColors.onBackground,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.padding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surfaceVariant,
            AppColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: AppSizes.paddingSmall),
              Text(
                'Order Summary',
                style: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.padding),
          
          // Summary rows
          _buildSummaryRow('Order Type', _getOrderTypeName(_orderType)),
          _buildSummaryRow('Quantity', '$_quantity shares'),
          _buildSummaryRow('Price per Share', Utils.formatCurrency(_price)),
          if (_orderType == OrderType.stopLoss)
            _buildSummaryRow('Stop Loss', Utils.formatCurrency(_stopLossPrice)),
          _buildSummaryRow('Duration', _orderDuration == OrderDuration.day ? 'Day' : 'GTC'),
          
          const Divider(height: AppSizes.paddingLarge),
          
          // Total amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                Utils.formatCurrency(_totalAmount),
                style: AppTextStyles.heading3.copyWith(
                  fontWeight: FontWeight.bold,
                  color: widget.isBuyOrder ? AppColors.error : AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
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

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.padding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.padding),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: AppSizes.padding),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isLoading || _quantity <= 0 ? null : _submitTrade,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.isBuyOrder ? AppColors.success : AppColors.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.padding),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        '${widget.isBuyOrder ? 'Buy' : 'Sell'} ${Utils.formatCurrency(_totalAmount)}',
                        style: AppTextStyles.button.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getOrderTypeIcon(OrderType type) {
    switch (type) {
      case OrderType.market:
        return Icons.flash_on_rounded;
      case OrderType.limit:
        return Icons.schedule_rounded;
      case OrderType.stopLoss:
        return Icons.stop_circle_rounded;
    }
  }

  String _getOrderTypeName(OrderType type) {
    switch (type) {
      case OrderType.market:
        return 'Market';
      case OrderType.limit:
        return 'Limit';
      case OrderType.stopLoss:
        return 'Stop Loss';
    }
  }

  void _showStockInfo() {
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
              'Stock Information',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: AppSizes.padding),
            Text(
              'Company: ${widget.stock.companyName ?? 'N/A'}',
              style: AppTextStyles.body1,
            ),
            Text(
              'Symbol: ${widget.stock.symbol}',
              style: AppTextStyles.body1,
            ),
            Text(
              'Current Price: ${Utils.formatCurrency(_currentPrice)}',
              style: AppTextStyles.body1,
            ),
            const SizedBox(height: AppSizes.padding),
          ],
        ),
      ),
    );
  }

  void _submitTrade() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final portfolioProvider = Provider.of<PortfolioProvider>(context, listen: false);
      
      final success = await portfolioProvider.executeTrade(
        symbol: widget.stock.symbol,
        companyName: widget.stock.companyName ?? widget.stock.symbol,
        quantity: _quantity,
        price: _price,
        isBuy: widget.isBuyOrder,
        isMarketOrder: _orderType == OrderType.market,
      );

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop(true);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.isBuyOrder ? 'Bought' : 'Sold'} $_quantity shares of ${widget.stock.symbol.replaceAll('.NS', '')}',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to execute trade. Please try again.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
