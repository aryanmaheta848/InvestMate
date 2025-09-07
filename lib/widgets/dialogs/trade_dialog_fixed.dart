import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:invest_mate/constants/app_constants.dart';
import 'package:invest_mate/models/stock_model.dart';
import 'package:invest_mate/providers/portfolio_provider.dart';
import 'package:invest_mate/utils/utils.dart';

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
            
            // Stock Info
            Container(
              padding: const EdgeInsets.all(AppSizes.padding),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.stock.companyName ?? widget.stock.symbol,
                          style: AppTextStyles.body1.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Current Price: ${Utils.formatCurrency(_currentPrice)}',
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.onBackground.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Utils.formatCurrency(_currentPrice),
                        style: AppTextStyles.body1.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                      Text(
                        '${widget.stock.changePercent! >= 0 ? '+' : ''}${widget.stock.changePercent!.toStringAsFixed(2)}%',
                        style: AppTextStyles.body2.copyWith(
                          color: (widget.stock.changePercent ?? 0) >= 0
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppSizes.paddingLarge),
            
            // Trade Form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Type Toggle
                  Row(
                    children: [
                      Text(
                        'Order Type:',
                        style: AppTextStyles.body1.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: AppSizes.padding),
                      Expanded(
                        child: Row(
                          children: [
                            FilterChip(
                              label: const Text('Market'),
                              selected: _isMarketOrder,
                              onSelected: (selected) {
                                setState(() {
                                  _isMarketOrder = true;
                                });
                              },
                              selectedColor: AppColors.primary.withOpacity(0.2),
                              checkmarkColor: AppColors.primary,
                            ),
                            const SizedBox(width: AppSizes.paddingSmall),
                            FilterChip(
                              label: const Text('Limit'),
                              selected: !_isMarketOrder,
                              onSelected: (selected) {
                                setState(() {
                                  _isMarketOrder = false;
                                });
                              },
                              selectedColor: AppColors.primary.withOpacity(0.2),
                              checkmarkColor: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppSizes.paddingLarge),
                  
                  // Quantity Input
                  TextFormField(
                    controller: _quantityController,
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                      hintText: 'Enter number of shares',
                      prefixIcon: const Icon(Icons.format_list_numbered),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
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
                      final quantity = int.tryParse(value);
                      if (quantity == null || quantity <= 0) {
                        return 'Please enter a valid quantity';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                  
                  const SizedBox(height: AppSizes.padding),
                  
                  // Price Input (for limit orders)
                  if (!_isMarketOrder) ...[
                    TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: 'Limit Price',
                        hintText: 'Enter price per share',
                        prefixIcon: const Icon(Icons.currency_rupee),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\\d+\\.?\\d{0,2}')),
                      ],
                      validator: (value) {
                        if (!_isMarketOrder) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter limit price';
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
                    const SizedBox(height: AppSizes.padding),
                  ],
                  
                  // Order Summary
                  Container(
                    padding: const EdgeInsets.all(AppSizes.padding),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Order Type:',
                              style: AppTextStyles.body2,
                            ),
                            Text(
                              _isMarketOrder ? 'Market Order' : 'Limit Order',
                              style: AppTextStyles.body2.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Price per Share:',
                              style: AppTextStyles.body2,
                            ),
                            Text(
                              Utils.formatCurrency(_price),
                              style: AppTextStyles.body2.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Quantity:',
                              style: AppTextStyles.body2,
                            ),
                            Text(
                              _quantity.toString(),
                              style: AppTextStyles.body2.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Amount:',
                              style: AppTextStyles.body1.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              Utils.formatCurrency(_totalAmount),
                              style: AppTextStyles.body1.copyWith(
                                fontWeight: FontWeight.bold,
                                color: widget.isBuyOrder ? AppColors.error : AppColors.success,
                              ),
                            ),
                          ],
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
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
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
                              : Text('${widget.isBuyOrder ? 'Buy' : 'Sell'} Now'),
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
        isMarketOrder: _isMarketOrder,
      );

      if (!mounted) return;

      if (success) {
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
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to execute trade. ${!widget.isBuyOrder ? 'Insufficient shares or ' : ''}Please try again.',
            ),
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
