# Alpha Vantage API Integration Guide

## Overview
This guide shows how to integrate Alpha Vantage API into your TickerTracker app for more reliable stock data.

## 🔑 Required API Functions & Usage

### 1. **GLOBAL_QUOTE** - Most Important
**Usage**: Real-time prices for watchlists and portfolio updates
**Current Code**: `StockService._fetchFromYahooFinance()`
**API Call**: 
```
https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol={SYMBOL}&apikey={API_KEY}
```

**Replace in**: `lib/services/stock_service.dart`
```dart
// Current Yahoo Finance call
final url = '${AppConstants.yahooFinanceUrl}/$symbol';

// New Alpha Vantage call  
final url = 'https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=$symbol&apikey=$apiKey';
```

### 2. **TIME_SERIES_INTRADAY** - Real-time Updates
**Usage**: Live price updates during market hours
**Current Code**: `StockService.getStockPriceStream()`
**API Call**:
```
https://www.alphavantage.co/query?function=TIME_SERIES_INTRADAY&symbol={SYMBOL}&interval=1min&apikey={API_KEY}
```

### 3. **TIME_SERIES_DAILY** - Historical Charts
**Usage**: Chart data for technical analysis
**Current Code**: `StockService.getHistoricalData()`
**API Call**:
```
https://www.alphavantage.co/query?function=TIME_SERIES_DAILY&symbol={SYMBOL}&outputsize=full&apikey={API_KEY}
```

### 4. **SYMBOL_SEARCH** - Stock Search
**Usage**: Search functionality in your app
**Current Code**: `StockService.searchStocks()`
**API Call**:
```
https://www.alphavantage.co/query?function=SYMBOL_SEARCH&keywords={QUERY}&apikey={API_KEY}
```

## 📈 **Technical Indicators for Advanced Features**

### RSI - Oversold/Overbought Detection
```
https://www.alphavantage.co/query?function=RSI&symbol={SYMBOL}&interval=daily&time_period=14&series_type=close&apikey={API_KEY}
```

### Moving Averages - Trend Analysis
```
https://www.alphavantage.co/query?function=SMA&symbol={SYMBOL}&interval=daily&time_period=20&series_type=close&apikey={API_KEY}
```

### MACD - Momentum Analysis
```
https://www.alphavantage.co/query?function=MACD&symbol={SYMBOL}&interval=daily&series_type=close&apikey={API_KEY}
```

## 🔄 **API Call Frequency & Limits**

### Free Tier (25 calls/day)
- **Not suitable for your app** - You need real-time updates
- Only use for testing/development

### Premium Tiers Recommended:
- **$25/month**: 1,200 calls/day (suitable for testing)
- **$50/month**: 5,000 calls/day (good for moderate usage)  
- **$150/month**: 15,000 calls/day (production ready)
- **$300/month**: 60,000 calls/day (high frequency)

## 🎯 **Optimized Usage Strategy**

### Minimum API Calls Needed:
```javascript
// Per user session (typical usage)
Watchlist (10 stocks) × GLOBAL_QUOTE = 10 calls
Portfolio updates (5 stocks) = 5 calls  
Search queries = 5 calls
Historical data (2 stocks) = 2 calls
Technical indicators (1 stock) = 3 calls

Total per active user session: ~25 calls
```

### For 100 Daily Active Users:
- **Conservative**: 2,500 calls/day → $50/month plan
- **Active usage**: 5,000 calls/day → $150/month plan

## 💰 **Cost-Benefit Analysis**

### Current Yahoo Finance (Free)
✅ **Pros**: Free, no limits
❌ **Cons**: Unreliable, no guarantees, may break anytime

### Alpha Vantage ($50/month)
✅ **Pros**: Reliable, official API, technical indicators
✅ **Real-time data** with guaranteed uptime
✅ **Professional support**
❌ **Cons**: Monthly cost

### ROI Calculation:
- **Cost**: $50/month = $600/year
- **Value**: Reliable data for investment app
- **Risk**: Yahoo Finance could stop working anytime

## 🔧 **Implementation Priority**

### Phase 1 - Essential (Start with these)
1. **GLOBAL_QUOTE** - Replace Yahoo Finance for current prices
2. **TIME_SERIES_DAILY** - Replace for historical charts  
3. **SYMBOL_SEARCH** - Improve search functionality

### Phase 2 - Enhanced Features
4. **TIME_SERIES_INTRADAY** - Real-time price updates
5. **Technical Indicators** - RSI, SMA, MACD for analysis

### Phase 3 - Advanced Features  
6. **OVERVIEW** - Company fundamentals
7. **EARNINGS** - Earnings data integration

## 🔑 **Getting Started**

### 1. Sign Up & Get API Key
1. Go to [alphavantage.co](https://www.alphavantage.co/support/#api-key)
2. Get free API key (for testing)
3. Upgrade to paid plan when ready

### 2. Test API Calls
```bash
# Test with curl
curl "https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=RELIANCE.NS&apikey=YOUR_API_KEY"

# Expected response
{
    "Global Quote": {
        "01. symbol": "RELIANCE.NS",
        "05. price": "2450.30",
        "09. change": "+12.50",
        "10. change percent": "+0.51%"
    }
}
```

### 3. Update Constants
```dart
// Add to app_constants.dart
class AppConstants {
  static const String alphaVantageApiKey = 'YOUR_ALPHA_VANTAGE_KEY';
  static const String alphaVantageBaseUrl = 'https://www.alphavantage.co/query';
}
```

## 🌏 **Indian Stock Market Symbols**

### NSE Symbols Format:
- **Reliance**: `RELIANCE.NS`
- **TCS**: `TCS.NS`  
- **HDFC Bank**: `HDFCBANK.NS`

### Alternative: Use Indian Market Specific APIs
- **NSE Official API** (if available)
- **BSE API** (if available)
- **Zerodha Kite API** (paid, but very reliable for Indian markets)

## 📊 **Example Integration**

### Replace Yahoo Finance with Alpha Vantage:

```dart
// OLD: Yahoo Finance
Future<StockModel?> _fetchFromYahooFinance(String symbol) async {
  final url = '${AppConstants.yahooFinanceUrl}/$symbol';
  // ... Yahoo Finance parsing
}

// NEW: Alpha Vantage
Future<StockModel?> _fetchFromAlphaVantage(String symbol) async {
  final url = '${AppConstants.alphaVantageBaseUrl}?function=GLOBAL_QUOTE&symbol=$symbol&apikey=${AppConstants.alphaVantageApiKey}';
  
  final response = await http.get(Uri.parse(url));
  
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final quote = data['Global Quote'];
    
    return StockModel(
      symbol: quote['01. symbol'],
      price: double.parse(quote['05. price']),
      change: double.parse(quote['09. change']),
      changePercent: quote['10. change percent'],
      // ... other fields
    );
  }
  return null;
}
```

## 🎯 **Recommendation**

### For Your Investment App:
1. **Start with $50/month plan** (5,000 calls/day)
2. **Focus on essential endpoints**: GLOBAL_QUOTE, TIME_SERIES_DAILY
3. **Monitor usage** and scale up if needed
4. **Keep Yahoo Finance as fallback** during transition

### Expected Monthly Cost: $50-150
### Expected Reliability: 99.9% uptime
### Expected Performance: Much faster than Yahoo Finance

This investment in reliable data will significantly improve your app's user experience and reliability!
