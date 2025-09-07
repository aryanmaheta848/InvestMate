# 📈 TickerTracker - Investment Clubs & Paper Trading App

[![Flutter](https://img.shields.io/badge/Flutter-3.9.0-blue.svg)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-Enabled-orange.svg)](https://firebase.google.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A comprehensive Flutter-based investment tracking and paper trading application that allows users to join investment clubs, track stocks, and practice trading with virtual money.

## 🚀 Features

### 📱 Core Functionality
- **Real-time Stock Tracking**: Live price updates with multiple data sources
- **Paper Trading**: Practice trading with virtual money
- **Investment Clubs**: Join and create investment clubs for collaborative trading
- **Portfolio Management**: Track your investments and performance
- **Watchlist**: Monitor your favorite stocks
- **Market Analysis**: Comprehensive market data and charts

### 🔐 Authentication & User Management
- **Firebase Authentication**: Secure user registration and login
- **Google Sign-In**: Quick authentication with Google accounts
- **User Profiles**: Personalized user experience
- **Onboarding**: Guided setup for new users

### 📊 Market Data & Analysis
- **Real-time Price Updates**: Live stock prices with WebSocket connections
- **Multiple Data Sources**: Alpha Vantage, Yahoo Finance integration
- **Interactive Charts**: Advanced charting with FL Chart and Syncfusion
- **Market Sentiment**: AI-powered sentiment analysis
- **News Integration**: Latest market news and updates

### 🏛️ Investment Clubs
- **Club Creation**: Create and manage investment clubs
- **Member Management**: Invite and manage club members
- **Collaborative Trading**: Share trading strategies and insights
- **Performance Tracking**: Track club performance and rankings

### 💼 Trading Features
- **Paper Trading**: Practice with virtual money
- **Trade History**: Complete transaction history
- **Order Management**: Buy/sell orders with various types
- **Risk Management**: Stop-loss and take-profit orders
- **Portfolio Analytics**: Detailed performance metrics

### 📈 Portfolio Management
- **Holdings Tracking**: Monitor all your investments
- **Performance Analytics**: P&L tracking and analysis
- **Asset Allocation**: Visual portfolio breakdown
- **Historical Performance**: Track performance over time

### 🔔 Notifications & Alerts
- **Price Alerts**: Get notified when stocks hit target prices
- **Market Updates**: Real-time market notifications
- **Club Activities**: Stay updated on club activities
- **Trade Confirmations**: Instant trade notifications

## 🛠️ Technology Stack

### Frontend
- **Flutter**: Cross-platform mobile development
- **Dart**: Programming language
- **Material Design**: Modern UI/UX design
- **Provider**: State management
- **GetX**: Navigation and state management

### Backend & Services
- **Firebase**: Authentication, Firestore database, messaging
- **Alpha Vantage API**: Stock market data
- **Yahoo Finance API**: Additional market data
- **REST APIs**: External service integrations

### Data Visualization
- **FL Chart**: Interactive charts and graphs
- **Syncfusion Flutter Charts**: Advanced charting capabilities
- **Custom Widgets**: Tailored UI components

### Storage & Caching
- **Firestore**: Cloud database
- **SharedPreferences**: Local storage
- **Hive**: Local database for caching

## 📱 Screenshots

*Screenshots will be added here showing the app's interface*

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.9.0 or higher)
- Dart SDK
- Android Studio / VS Code
- Firebase project setup
- Alpha Vantage API key

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/aryanmaheta848/InvestMate.git
   cd InvestMate
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a Firebase project
   - Download `google-services.json` for Android
   - Download `GoogleService-Info.plist` for iOS
   - Place them in the respective platform folders

4. **Configure API Keys**
   - Get Alpha Vantage API key from [Alpha Vantage](https://www.alphavantage.co/)
   - Update API keys in `lib/constants/app_constants.dart`

5. **Run the app**
   ```bash
   flutter run
   ```

### Firebase Setup

1. Create a new Firebase project
2. Enable Authentication (Email/Password and Google Sign-In)
3. Create a Firestore database
4. Enable Firebase Messaging for notifications
5. Download configuration files and place them in the project

### API Configuration

Update the following in `lib/constants/app_constants.dart`:

```dart
class AppConstants {
  static const String alphaVantageBaseUrl = 'https://www.alphavantage.co/query';
  static const String alphaVantageQuoteKey = 'YOUR_ALPHA_VANTAGE_API_KEY';
  static const String yahooFinanceUrl = 'https://query1.finance.yahoo.com/v8/finance/chart';
}
```

## 📁 Project Structure

```
lib/
├── constants/          # App constants and configuration
├── models/            # Data models
│   ├── club_model.dart
│   ├── holding_model.dart
│   ├── portfolio_model.dart
│   ├── stock_model.dart
│   ├── trade_model.dart
│   └── user_model.dart
├── providers/         # State management
│   ├── auth_provider.dart
│   ├── club_provider.dart
│   ├── portfolio_provider.dart
│   └── stock_provider.dart
├── screens/           # UI screens
│   ├── auth/          # Authentication screens
│   ├── clubs/         # Investment club screens
│   ├── home/          # Home and dashboard
│   ├── market/        # Market data screens
│   ├── portfolio/     # Portfolio management
│   ├── trading/       # Trading screens
│   └── watchlist/     # Watchlist screens
├── services/          # Business logic and API calls
│   ├── alpha_vantage_service.dart
│   ├── auth_service.dart
│   ├── realtime_stock_service.dart
│   ├── stock_service.dart
│   └── firebase/      # Firebase services
├── utils/             # Utility functions
└── widgets/           # Reusable UI components
    ├── cards/         # Card widgets
    ├── charts/        # Chart widgets
    ├── common/        # Common widgets
    └── forms/         # Form widgets
```

## 🔧 Configuration

### Environment Variables
Create a `.env` file in the root directory:

```env
ALPHA_VANTAGE_API_KEY=your_alpha_vantage_api_key
FIREBASE_PROJECT_ID=your_firebase_project_id
```

### Build Configuration

#### Android
- Minimum SDK: 21
- Target SDK: 34
- Compile SDK: 34

#### iOS
- Minimum iOS: 11.0
- Target iOS: 17.0

## 📊 API Integration

### Alpha Vantage
- **Global Quote**: Real-time stock quotes
- **Time Series**: Historical price data
- **Technical Indicators**: Technical analysis data

### Yahoo Finance
- **Chart Data**: Historical and real-time charts
- **Market Data**: Comprehensive market information

### Firebase
- **Authentication**: User management
- **Firestore**: Real-time database
- **Messaging**: Push notifications

## 🎨 UI/UX Features

- **Material Design 3**: Modern design language
- **Dark/Light Theme**: Theme switching capability
- **Responsive Design**: Optimized for different screen sizes
- **Smooth Animations**: Lottie animations and transitions
- **Pull-to-Refresh**: Intuitive data refresh
- **Loading States**: Shimmer effects and loading indicators

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/

# Run with coverage
flutter test --coverage
```

## 📦 Building for Production

### Android
```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Authors

- **Aryan Maheta** - *Initial work* - [aryanmaheta848](https://github.com/aryanmaheta848)

## 🙏 Acknowledgments

- Alpha Vantage for providing stock market data
- Yahoo Finance for additional market data
- Firebase for backend services
- Flutter team for the amazing framework
- All contributors and testers

## 📞 Support

If you have any questions or need help, please:

1. Check the [Issues](https://github.com/aryanmaheta848/InvestMate/issues) page
2. Create a new issue if your problem isn't already reported
3. Contact the maintainers

## 🔮 Roadmap

- [ ] Advanced charting features
- [ ] Options trading simulation
- [ ] Social trading features
- [ ] AI-powered investment recommendations
- [ ] Multi-language support
- [ ] Desktop application
- [ ] Web application
- [ ] Advanced portfolio analytics
- [ ] Integration with more data providers
- [ ] Real-time chat for investment clubs

---
