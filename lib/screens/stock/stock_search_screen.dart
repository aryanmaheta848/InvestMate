import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:invest_mate/constants/app_constants.dart';
import 'package:invest_mate/providers/stock_provider.dart';
import 'package:invest_mate/providers/auth_provider.dart';
import 'package:invest_mate/models/stock_model.dart';
import 'package:invest_mate/widgets/common/common_widgets.dart';
import 'package:invest_mate/widgets/cards/stock_card.dart';
import 'package:invest_mate/screens/stock/stock_detail_screen.dart';
import 'package:invest_mate/utils/utils.dart';

class StockSearchScreen extends StatefulWidget {
  const StockSearchScreen({super.key});

  @override
  State<StockSearchScreen> createState() => _StockSearchScreenState();
}

class _StockSearchScreenState extends State<StockSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    final stockProvider = Provider.of<StockProvider>(context, listen: false);
    
    // Debounce search
    Utils.debounce(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        stockProvider.searchStocks(query);
      } else {
        stockProvider.clearSearchResults();
      }
    });
  }

  Future<void> _addToWatchlist(StockModel stock) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.user != null) {
      await authProvider.addToWatchlist(stock.symbol);
      
      if (mounted) {
        Utils.showSuccessSnackbar(
          context,
          '${stock.symbol} added to watchlist',
        );
      }
    }
  }

  Future<void> _removeFromWatchlist(StockModel stock) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.user != null) {
      await authProvider.removeFromWatchlist(stock.symbol);
      
      if (mounted) {
        Utils.showSuccessSnackbar(
          context,
          '${stock.symbol} removed from watchlist',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Stocks'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.all(AppSizes.padding),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search stocks (e.g., RELIANCE, TCS, INFY)',
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70),
                        onPressed: () {
                          _searchController.clear();
                          Provider.of<StockProvider>(context, listen: false)
                              .clearSearchResults();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                  borderSide: const BorderSide(color: Colors.white30),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                  borderSide: const BorderSide(color: Colors.white30),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                  borderSide: const BorderSide(color: Colors.white),
                ),
                hintStyle: const TextStyle(color: Colors.white70),
                contentPadding: const EdgeInsets.all(AppSizes.padding),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: _onSearchChanged,
            ),
          ),

          // Search Results
          Expanded(
            child: Consumer2<StockProvider, AuthProvider>(
              builder: (context, stockProvider, authProvider, child) {
                if (_searchController.text.isEmpty) {
                  return _buildPopularStocks(stockProvider, authProvider);
                }

                if (stockProvider.isSearching) {
                  return const LoadingIndicator(
                    message: 'Searching stocks...',
                  );
                }

                if (stockProvider.errorMessage != null) {
                  return ErrorStateWidget(
                    message: stockProvider.errorMessage!,
                    onRetry: () => _onSearchChanged(_searchController.text),
                  );
                }

                if (stockProvider.searchResults.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.search_off,
                    title: 'No Results Found',
                    message: 'Try searching with different keywords',
                    actionText: 'Clear Search',
                    onAction: () {
                      _searchController.clear();
                      stockProvider.clearSearchResults();
                    },
                  );
                }

                return _buildSearchResults(
                  stockProvider.searchResults,
                  authProvider,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularStocks(StockProvider stockProvider, AuthProvider authProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSizes.padding),
          child: Text(
            'Popular Stocks',
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<StockModel>>(
            future: stockProvider.isLoading 
                ? null 
                : Future.value(stockProvider.trendingStocks.isNotEmpty 
                    ? stockProvider.trendingStocks 
                    : null),
            builder: (context, snapshot) {
              // Load trending stocks if not already loaded
              if (stockProvider.trendingStocks.isEmpty && !stockProvider.isLoading) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  stockProvider.loadTrendingStocks();
                });
              }

              if (stockProvider.isLoading) {
                return const LoadingIndicator(
                  message: 'Loading popular stocks...',
                );
              }

              if (stockProvider.trendingStocks.isEmpty) {
                return const EmptyStateWidget(
                  icon: Icons.trending_up,
                  title: 'No Popular Stocks',
                  message: 'Unable to load popular stocks at the moment',
                );
              }

              return _buildStocksList(stockProvider.trendingStocks, authProvider);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults(List<StockModel> stocks, AuthProvider authProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSizes.padding),
          child: Text(
            'Search Results (${stocks.length})',
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: _buildStocksList(stocks, authProvider),
        ),
      ],
    );
  }

  Widget _buildStocksList(List<StockModel> stocks, AuthProvider authProvider) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding),
      itemCount: stocks.length,
      itemBuilder: (context, index) {
        final stock = stocks[index];
        final isInWatchlist = authProvider.user?.hasStockInWatchlist(stock.symbol) ?? false;

        return Container(
          margin: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
          child: CustomCard(
            onTap: () => Get.to(() => StockDetailScreen(stock: stock)),
            child: Row(
              children: [
                // Stock info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stock.symbol.replaceAll('.NS', ''),
                        style: AppTextStyles.body1.copyWith(
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
                      const SizedBox(height: AppSizes.paddingSmall),
                      Row(
                        children: [
                          Text(
                            stock.formattedPrice,
                            style: AppTextStyles.body1.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: AppSizes.paddingSmall),
                          PriceChangeIndicator(
                            change: stock.changeAmount,
                            percentage: stock.changePercentage,
                            showIcon: true,
                            textStyle: AppTextStyles.body2,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Watchlist button
                Column(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (isInWatchlist) {
                          _removeFromWatchlist(stock);
                        } else {
                          _addToWatchlist(stock);
                        }
                      },
                      icon: Icon(
                        isInWatchlist 
                            ? Icons.bookmark 
                            : Icons.bookmark_border,
                        color: isInWatchlist 
                            ? AppColors.primary 
                            : AppColors.onBackground.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      isInWatchlist ? 'Added' : 'Add',
                      style: AppTextStyles.caption.copyWith(
                        color: isInWatchlist 
                            ? AppColors.primary 
                            : AppColors.onBackground.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
