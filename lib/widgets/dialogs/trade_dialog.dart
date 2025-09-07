import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:invest_mate/constants/app_constants.dart';
import 'package:invest_mate/models/stock_model.dart';
import 'package:invest_mate/models/trade_model.dart';
import 'package:invest_mate/models/holding_model.dart';
import 'package:invest_mate/providers/portfolio_provider.dart';
import 'package:invest_mate/providers/auth_provider.dart';
import 'package:invest_mate/services/firebase/firebase_service.dart';
import 'package:invest_mate/widgets/common/common_widgets.dart';
import 'package:invest_mate/utils/utils.dart';
import 'package:uuid/uuid.dart';

class TradeDialog extends StatefulWidget {
  final StockModel stock;
  final bool isBuyOrder;

  const TradeDialog({
    super.key,
    required this.stock,
    required this.isBuyOrder,
  });

  @override
  State<TradeDialog> createState() => _TradeDialogState();
}

class _TradeDialogState extends State<TradeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  
  bool _isMarketOrder = true;
  bool _isLoading = false;
  
  double get _currentPrice => widget.stock.currentPrice;
  int get _quantity => int.tryParse(_quantityController.text) ?? 0;
  double get _price => _isMarketOrder ? _currentPrice : (double.tryParse(_priceController.text) ?? 0.0);
  double get _totalAmount => _quantity * _price;

  @override
  void initState() {
    super.initState();
    _priceController.text = _currentPrice.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    widget.isBuyOrder ? Icons.trending_up : Icons.trending_down,
                    color: widget.isBuyOrder ? AppColors.success : AppColors.error,
                    size: 24,
                  ),
                  const SizedBox(width: AppSizes.paddingSmall),
                  Text(
                    '${widget.isBuyOrder ? 'Buy' : 'Sell'} ${widget.stock.symbol.replaceAll('.NS', '')}',
                    style: AppTextStyles.heading3.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              
              const SizedBox(height: AppSizes.padding),
              
              // Content with proper padding
              Padding(
                padding: const EdgeInsets.all(AppSizes.paddingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Enhanced Stock Info Card with improved UI
                    Container(
                      padding: const EdgeInsets.all(AppSizes.paddingMedium),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
                        border: Border.all(
                          color: AppColors.borderLight,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Stock Icon
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                            ),
                            child: Center(
                              child: Text(
                                widget.stock.symbol.substring(0, 1),
                                style: AppTextStyles.heading3.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSizes.paddingMedium),
                          
                          // Stock Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.stock.companyName ?? widget.stock.symbol,
                                  style: AppTextStyles.body1.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${Utils.formatCurrency(_currentPrice)} / share',
                                  style: AppTextStyles.body2.copyWith(
                                    color: AppColors.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Price Change
                          Container(
                             padding: const EdgeInsets.symmetric(
                               horizontal: AppSizes.paddingSmall,
                               vertical: 4,
                             ),
                             decoration: BoxDecoration(
                               color: (widget.stock.currentPrice >= widget.stock.previousClose)
                                   ? AppColors.success.withOpacity(0.1)
                                   : AppColors.error.withOpacity(0.1),
                               borderRadius: BorderRadius.circular(AppSizes.borderRadiusSmall),
                             ),
                             child: Text(
                               '${(widget.stock.currentPrice >= widget.stock.previousClose) ? '+' : ''}${((widget.stock.currentPrice - widget.stock.previousClose) / widget.stock.previousClose * 100).toStringAsFixed(2)}%',
                               style: AppTextStyles.caption.copyWith(
                                 color: (widget.stock.currentPrice >= widget.stock.previousClose)
                                     ? AppColors.success
                                     : AppColors.error,
                                 fontWeight: FontWeight.bold,
                               ),
                             ),
                           ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: AppSizes.paddingLarge),
                    
                    // Order Type
                    Text(
                      'Order Type',
                      style: AppTextStyles.body1.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingSmall),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Market'),
                            selected: _isMarketOrder,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _isMarketOrder = true;
                                  _priceController.text = _currentPrice.toStringAsFixed(2);
                                });
                              }
                            },
                            backgroundColor: AppColors.surface,
                            selectedColor: AppColors.primary.withOpacity(0.1),
                            labelStyle: TextStyle(
                              color: _isMarketOrder
                                  ? AppColors.primary
                                  : AppColors.onSurface,
                              fontWeight: _isMarketOrder
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSizes.paddingSmall),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Limit'),
                            selected: !_isMarketOrder,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _isMarketOrder = false;
                                });
                              }
                            },
                            backgroundColor: AppColors.surface,
                            selectedColor: AppColors.primary.withOpacity(0.1),
                            labelStyle: TextStyle(
                              color: !_isMarketOrder
                                  ? AppColors.primary
                                  : AppColors.onSurface,
                              fontWeight: !_isMarketOrder
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppSizes.paddingLarge),
                    
                    // Quantity
                    Text(
                      'Quantity',
                      style: AppTextStyles.body1.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingSmall),
                    TextFormField(
                      controller: _quantityController,
                      decoration: InputDecoration(
                        hintText: 'Enter quantity',
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.paddingMedium,
                          vertical: AppSizes.paddingMedium,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter quantity';
                        }
                        if (int.tryParse(value) == null || int.parse(value) <= 0) {
                          return 'Please enter a valid quantity';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                    
                    const SizedBox(height: AppSizes.paddingLarge),
                    
                    // Price (editable only for limit orders)
                    Text(
                      'Price',
                      style: AppTextStyles.body1.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingSmall),
                    TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        hintText: 'Enter price',
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.paddingMedium,
                          vertical: AppSizes.paddingMedium,
                        ),
                        prefixText: '₹ ',
                      ),
                      enabled: !_isMarketOrder,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter price';
                        }
                        if (double.tryParse(value) == null || double.parse(value) <= 0) {
                          return 'Please enter a valid price';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                    
                    const SizedBox(height: AppSizes.paddingLarge),
                    
                    // Total Amount
                    Container(
                      padding: const EdgeInsets.all(AppSizes.paddingMedium),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
                        border: Border.all(
                          color: AppColors.borderLight,
                        ),
                      ),
                      child: Row(
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
                              color: widget.isBuyOrder ? AppColors.success : AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: AppSizes.paddingLarge),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.paddingLarge,
                                vertical: AppSizes.paddingMedium,
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(color: AppColors.onSurface.withOpacity(0.8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSizes.padding),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitTrade,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.isBuyOrder 
                                  ? AppColors.success 
                                  : AppColors.error,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.paddingLarge,
                                vertical: AppSizes.paddingMedium,
                              ),
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        widget.isBuyOrder ? Icons.add_circle : Icons.remove_circle,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        widget.isBuyOrder ? 'Buy Now' : 'Sell Now',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitTrade() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final portfolioProvider = Provider.of<PortfolioProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Ensure we have valid values before executing trade
      final symbol = widget.stock.symbol;
      final companyName = widget.stock.companyName ?? symbol;
      final quantity = _quantity;
      final price = _price;
      
      // Validate values
      if (quantity <= 0) {
        throw Exception('Quantity must be greater than zero');
      }
      
      if (price <= 0) {
        throw Exception('Price must be greater than zero');
      }
      
      // Pre-validate trade conditions
      if (widget.isBuyOrder) {
        final totalAmount = quantity * price;
        if (!portfolioProvider.canBuy(totalAmount)) {
          throw Exception('Insufficient cash balance to complete this purchase');
        }
      } else {
        if (!portfolioProvider.canSell(symbol, quantity)) {
          throw Exception('Insufficient shares to complete this sale');
        }
      }
      
      final success = await portfolioProvider.executeTrade(
        symbol: symbol,
        companyName: companyName,
        quantity: quantity,
        price: price,
        isBuy: widget.isBuyOrder,
        isMarketOrder: _isMarketOrder,
      );

      if (!mounted) return;

      if (success) {
        // Refresh portfolio data after successful trade
        await portfolioProvider.refreshPortfolioData();
        
        Navigator.of(context).pop(true); // Return true to indicate successful trade
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.isBuyOrder ? 'Bought' : 'Sold'} $_quantity shares of ${widget.stock.symbol.replaceAll('.NS', '')} at ${Utils.formatCurrency(_price)}',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        // Show error message based on the specific error from provider
        final errorMsg = portfolioProvider.errorMessage ?? 
          'Failed to execute trade. ${!widget.isBuyOrder ? 'Insufficient shares or ' : ''}Please try again.';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
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

// Helper function to show the trade dialog
Future<bool?> showTradeDialog({
  required BuildContext context,
  required StockModel stock,
  required bool isBuyOrder,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => TradeDialog(
      stock: stock,
      isBuyOrder: isBuyOrder,
    ),
  );
}
