import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:invest_mate/constants/app_constants.dart';
import 'package:invest_mate/models/stock_model.dart';

enum ChartTimeframe {
  day('1D'),
  week('1W'),
  month('1M'),
  threeMonths('3M'),
  sixMonths('6M'),
  year('1Y');

  const ChartTimeframe(this.label);
  final String label;
}

class StockChartWidget extends StatefulWidget {
  final StockModel stock;
  final double height;

  const StockChartWidget({
    super.key,
    required this.stock,
    this.height = 300,
  });

  @override
  State<StockChartWidget> createState() => _StockChartWidgetState();
}

class _StockChartWidgetState extends State<StockChartWidget> {
  ChartTimeframe _selectedTimeframe = ChartTimeframe.day;
  bool _showVolume = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chart controls
        _buildChartControls(),
        
        const SizedBox(height: AppSizes.padding),
        
        // Price chart
        _buildPriceChart(),
        
        if (_showVolume) ...[
          const SizedBox(height: AppSizes.paddingSmall),
          _buildVolumeChart(),
        ],
      ],
    );
  }

  Widget _buildChartControls() {
    return Row(
      children: [
        // Timeframe selector
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ChartTimeframe.values.map((timeframe) {
                final isSelected = _selectedTimeframe == timeframe;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSizes.paddingSmall),
                  child: FilterChip(
                    label: Text(timeframe.label),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedTimeframe = timeframe;
                      });
                    },
                    selectedColor: AppColors.primary.withOpacity(0.2),
                    checkmarkColor: AppColors.primary,
                    labelStyle: AppTextStyles.caption.copyWith(
                      color: isSelected ? AppColors.primary : null,
                      fontWeight: isSelected ? FontWeight.bold : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        
        // Volume toggle
        IconButton(
          icon: Icon(
            _showVolume ? Icons.bar_chart : Icons.show_chart,
            color: _showVolume ? AppColors.primary : AppColors.onBackground.withOpacity(0.6),
          ),
          onPressed: () {
            setState(() {
              _showVolume = !_showVolume;
            });
          },
          tooltip: _showVolume ? 'Hide Volume' : 'Show Volume',
        ),
      ],
    );
  }

  Widget _buildPriceChart() {
    return Container(
      height: widget.height,
      padding: const EdgeInsets.all(AppSizes.padding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        border: Border.all(
          color: AppColors.onBackground.withOpacity(0.1),
        ),
      ),
      child: LineChart(
        _getPriceChartData(),
      ),
    );
  }

  Widget _buildVolumeChart() {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(AppSizes.padding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        border: Border.all(
          color: AppColors.onBackground.withOpacity(0.1),
        ),
      ),
      child: BarChart(
        _getVolumeChartData(),
      ),
    );
  }

  LineChartData _getPriceChartData() {
    // Generate mock historical data based on current price
    final currentPrice = widget.stock.currentPrice ?? 1000.0;
    final dataPoints = _generateMockPriceData(currentPrice);

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        drawHorizontalLine: true,
        horizontalInterval: currentPrice * 0.01, // 1% intervals
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: AppColors.onBackground.withOpacity(0.1),
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: AppColors.onBackground.withOpacity(0.1),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: dataPoints.length / 5,
            getTitlesWidget: (value, meta) {
              final hours = value.toInt();
              if (hours % (dataPoints.length ~/ 5) == 0) {
                return SideTitleWidget(
                  space: 4,
                  angle: 0,
                  meta: meta,
                  child: Text(
                    '${hours}h',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.onBackground.withOpacity(0.6),
                    ),
                  ),
                );
              }
              return Container();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: currentPrice * 0.02, // 2% intervals
            reservedSize: 60,
            getTitlesWidget: (value, meta) {
              return SideTitleWidget(
                  space: 4,
                  angle: 0,
                  meta: meta,
                  child: Text(
                  '₹${value.toStringAsFixed(0)}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.onBackground.withOpacity(0.6),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: dataPoints.length.toDouble() - 1,
      minY: dataPoints.map((p) => p.y).reduce((a, b) => a < b ? a : b) * 0.99,
      maxY: dataPoints.map((p) => p.y).reduce((a, b) => a > b ? a : b) * 1.01,
      lineBarsData: [
        LineChartBarData(
          spots: dataPoints,
          isCurved: true,
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primary.withOpacity(0.3),
            ],
          ),
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.3),
                AppColors.primary.withOpacity(0.1),
                AppColors.primary.withOpacity(0.02),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => AppColors.surface,
          tooltipBorder: BorderSide(
            color: AppColors.onBackground.withOpacity(0.2),
          ),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((LineBarSpot touchedSpot) {
              return LineTooltipItem(
                '₹${touchedSpot.y.toStringAsFixed(2)}',
                AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList();
          },
        ),
        handleBuiltInTouches: true,
      ),
    );
  }

  BarChartData _getVolumeChartData() {
    final volumeData = _generateMockVolumeData();

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: volumeData.map((d) => d.y).reduce((a, b) => a > b ? a : b) * 1.2,
      gridData: const FlGridData(show: false),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              if (value == 0) return Container();
              final vol = value / 1000000; // Convert to millions
              return SideTitleWidget(
                  space: 4,
                  angle: 0,
                  meta: meta,
                  child: Text(
                  '${vol.toStringAsFixed(1)}M',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.onBackground.withOpacity(0.6),
                    fontSize: 10,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      barGroups: volumeData.asMap().entries.map((entry) {
        return BarChartGroupData(
          x: entry.key,
          barRods: [
            BarChartRodData(
              toY: entry.value.y,
              color: AppColors.primary.withOpacity(0.7),
              width: 3,
              borderRadius: BorderRadius.zero,
            ),
          ],
        );
      }).toList(),
    );
  }

  List<FlSpot> _generateMockPriceData(double currentPrice) {
    final dataPoints = <FlSpot>[];
    final random = DateTime.now().millisecond; // Use for consistent randomness
    
    int points;
    switch (_selectedTimeframe) {
      case ChartTimeframe.day:
        points = 24; // Hourly data for 1 day
        break;
      case ChartTimeframe.week:
        points = 7; // Daily data for 1 week
        break;
      case ChartTimeframe.month:
        points = 30; // Daily data for 1 month
        break;
      case ChartTimeframe.threeMonths:
        points = 90; // Daily data for 3 months
        break;
      case ChartTimeframe.sixMonths:
        points = 180; // Daily data for 6 months
        break;
      case ChartTimeframe.year:
        points = 365; // Daily data for 1 year
        break;
    }

    double price = currentPrice * 0.95; // Start slightly lower
    for (int i = 0; i < points; i++) {
      // Simple random walk with slight upward trend
      final change = ((random + i) % 20 - 10) * currentPrice * 0.001;
      price += change + (currentPrice * 0.0001); // Small upward bias
      dataPoints.add(FlSpot(i.toDouble(), price));
    }

    return dataPoints;
  }

  List<FlSpot> _generateMockVolumeData() {
    final volumeData = <FlSpot>[];
    final baseVolume = (widget.stock.volume ?? 1000000).toDouble();
    final random = DateTime.now().millisecond;

    int points;
    switch (_selectedTimeframe) {
      case ChartTimeframe.day:
        points = 24;
        break;
      case ChartTimeframe.week:
        points = 7;
        break;
      default:
        points = 30;
    }

    for (int i = 0; i < points; i++) {
      final variation = ((random + i) % 50 - 25) * 0.02; // ±50% variation
      final volume = baseVolume * (1 + variation);
      volumeData.add(FlSpot(i.toDouble(), volume));
    }

    return volumeData;
  }
}
