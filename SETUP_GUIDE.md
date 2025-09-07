# TickerTracker - Setup Guide

## Overview
This guide will help you complete the setup of your TickerTracker investment app with all required APIs and Firebase services.

## ✅ Already Configured
- NewsAPI key: `f944b9fcf341485cb11652accf5689cf` ✓
- Firebase project: `investmate-5c14b` ✓
- Firebase configuration files ✓
- Firebase options integration ✓

## 🔧 Firebase Console Setup Required

### 1. Enable Required Firebase Services

Go to [Firebase Console](https://console.firebase.google.com/project/investmate-5c14b) and enable:

#### Authentication
1. Go to **Authentication > Sign-in method**
2. Enable **Google** provider
3. Add your project's support email
4. Download the updated `google-services.json` if needed

#### Cloud Firestore Database
1. Go to **Firestore Database**
2. Click **Create database**
3. Choose **Start in test mode** (temporarily)
4. Select your region (preferably `asia-south1` for India)

#### Cloud Messaging
1. Go to **Cloud Messaging**
2. Already configured based on your setup

### 2. Set Up Firestore Security Rules

Replace the default rules with these production-ready rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Public stock data (read-only for users)
    match /stocks/{symbol} {
      allow read: if true;
      allow write: if false; // Only server/admin can write
    }
    
    // Club data - authenticated users can read, members can write
    match /clubs/{clubId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        request.auth.uid in resource.data.members;
    }
    
    // News data - read-only for users
    match /news/{newsId} {
      allow read: if true;
      allow write: if false;
    }
    
    // Portfolio data - users can access their own
    match /portfolios/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 3. Create Firestore Collections Structure

Create these collections manually or they'll be created automatically when the app first writes data:

```
/users
  - Document ID: User UID
  - Fields: email, displayName, watchlist[], portfolio{}, clubs[], createdAt

/stocks  
  - Document ID: Stock symbol (e.g., "RELIANCE.NS")
  - Fields: symbol, name, price, change, changePercent, lastUpdated

/clubs
  - Document ID: Auto-generated
  - Fields: name, description, members[], portfolio{}, trades[], createdAt

/news
  - Document ID: Auto-generated  
  - Fields: title, description, source, url, publishedAt, symbols[], sentiment

/portfolios
  - Document ID: User UID
  - Fields: cash, totalValue, holdings{}, transactions[]
```

## 🔑 Additional API Keys Needed

### Optional but Recommended APIs

1. **Better Stock Data API** (Current: Yahoo Finance - unofficial)
   - **Alpha Vantage**: Get free API key from [alphavantage.co](https://www.alphavantage.co/)
   - **Zerodha Kite**: Get API access from [kite.trade](https://kite.trade/) (paid)
   - **NSE Official**: Contact NSE for official API access

2. **Sentiment Analysis** (Current: Local keyword-based)
   - **Google Cloud Natural Language**: Enable in Google Cloud Console
   - **AWS Comprehend**: Get from AWS Console  
   - **Azure Text Analytics**: Get from Azure Portal

3. **Additional News Sources**
   - **Financial Modeling Prep**: Free tier available
   - **IEX Cloud**: Free tier for basic data

## 🚀 Running the App

### Prerequisites
```bash
# Check Flutter version
flutter --version

# Should be >= 3.9.0 as specified in pubspec.yaml
```

### Setup Steps
```bash
# Install dependencies
flutter pub get

# For background tasks (Hive code generation)
flutter packages pub run build_runner build

# Run on Android
flutter run

# Run on specific device
flutter devices
flutter run -d <device_id>
```

### Testing Firebase Connection
1. Run the app
2. Try to sign in with Google
3. Check Firebase Console > Authentication for new users
4. Check Firestore for automatically created collections

## 📱 Android Specific Setup

### Signing Configuration (for Google Sign-In)
If Google Sign-In fails, you may need to:

1. Get your SHA-1 fingerprint:
```bash
# For debug
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# For release (when you have release keystore)
keytool -list -v -keystore /path/to/your/release.keystore -alias your_alias_name
```

2. Add SHA-1 to Firebase Console:
   - Go to Project Settings > General
   - Under "Your apps" > Android app
   - Add the SHA certificate fingerprint

### Permissions Check
Verify these permissions are in `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

## 🔄 Background Services

### Stock Price Updates
Your app uses periodic updates. For production, consider:
- Firebase Cloud Functions for server-side updates
- Background sync for offline support
- Push notifications for price alerts

### News Updates
- Current: 30-minute cache expiry
- Consider: Real-time updates via WebSocket or Firebase Realtime Database

## 🛡️ Security Best Practices

### API Key Security
- Never commit API keys to version control
- Use environment variables or secure storage
- Consider using Firebase Remote Config for dynamic keys

### Production Checklist
- [ ] Update Firestore rules to production mode
- [ ] Set up proper error logging (Firebase Crashlytics)
- [ ] Enable Firebase App Check for API security
- [ ] Set up proper backup strategy for Firestore
- [ ] Configure rate limiting for APIs

## 🐛 Common Issues & Solutions

### Firebase Issues
- **"No Firebase App"**: Ensure Firebase.initializeApp() is called before runApp()
- **Google Sign-In fails**: Check SHA-1 fingerprints in Firebase Console
- **Firestore permission denied**: Check security rules

### API Issues
- **NewsAPI quota exceeded**: You have 1000 requests/day on free tier
- **Yahoo Finance fails**: It's unofficial - consider Alpha Vantage as backup
- **CORS issues**: Not applicable for mobile apps

### Build Issues
- **Missing google-services.json**: File should be in `android/app/`
- **Dependency conflicts**: Run `flutter pub deps` to check
- **Gradle build fails**: Check Android SDK and build tools versions

## 📞 Support

### Resources
- [Firebase Documentation](https://firebase.google.com/docs)
- [Flutter Documentation](https://docs.flutter.dev/)
- [NewsAPI Documentation](https://newsapi.org/docs)

### Your Current Configuration
- **Project ID**: investmate-5c14b
- **Package Name**: com.example.invest_mate
- **NewsAPI Key**: f944b9fcf341485cb11652accf5689cf (1000 requests/day)

## 🚀 Next Steps

1. **Test the current setup**:
   ```bash
   flutter run
   ```

2. **Enable Firebase services** in console (Authentication, Firestore)

3. **Test key features**:
   - Google Sign-In
   - Stock data loading
   - News feed
   - Paper trading functionality

4. **Consider premium APIs** for production:
   - Alpha Vantage for stock data
   - Google Cloud Natural Language for sentiment
   - Real-time WebSocket feeds for live prices

Your app is well-architected and ready for testing! The main APIs (NewsAPI and Firebase) are configured and ready to use.
