import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:invest_mate/models/user_model.dart';
import 'package:invest_mate/services/auth_service.dart';

enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthState _state = AuthState.initial;
  UserModel? _user;
  String? _errorMessage;

  // Getters
  AuthState get state => _state;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == AuthState.loading;
  bool get isAuthenticated => _state == AuthState.authenticated && _user != null;
  bool get isUnauthenticated => _state == AuthState.unauthenticated;

  AuthProvider() {
    _initializeAuthState();
  }

  // Initialize auth state and listen to changes
  void _initializeAuthState() {
    _authService.authStateChanges.listen((User? firebaseUser) async {
      if (firebaseUser != null) {
        try {
          final userModel = await _authService.getCurrentUserModel();
          if (userModel != null) {
            _user = userModel;
            _state = AuthState.authenticated;
            _errorMessage = null;
          } else {
            _state = AuthState.unauthenticated;
            _user = null;
          }
        } catch (e) {
          _state = AuthState.error;
          _errorMessage = e.toString();
          _user = null;
        }
      } else {
        _state = AuthState.unauthenticated;
        _user = null;
        _errorMessage = null;
      }
      notifyListeners();
    });
  }

  // Sign in with email and password
  Future<bool> signInWithEmail(String email, String password) async {
    try {
      _setState(AuthState.loading);
      
      final userModel = await _authService.signInWithEmail(email, password);
      if (userModel != null) {
        _user = userModel;
        _setState(AuthState.authenticated);
        return true;
      } else {
        _setState(AuthState.error, 'Failed to sign in');
        return false;
      }
    } catch (e) {
      _setState(AuthState.error, e.toString());
      return false;
    }
  }

  // Create account with email and password
  Future<bool> createAccount(String email, String password, String displayName) async {
    try {
      _setState(AuthState.loading);
      
      final userModel = await _authService.createAccount(email, password, displayName);
      if (userModel != null) {
        _user = userModel;
        _setState(AuthState.authenticated);
        return true;
      } else {
        _setState(AuthState.error, 'Failed to create account');
        return false;
      }
    } catch (e) {
      _setState(AuthState.error, e.toString());
      return false;
    }
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      _setState(AuthState.loading);
      
      final userModel = await _authService.signInWithGoogle();
      if (userModel != null) {
        _user = userModel;
        _setState(AuthState.authenticated);
        return true;
      } else {
        _setState(AuthState.unauthenticated);
        return false; // User canceled
      }
    } catch (e) {
      _setState(AuthState.error, e.toString());
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _setState(AuthState.loading);
      
      await _authService.signOut();
      _user = null;
      _setState(AuthState.unauthenticated);
    } catch (e) {
      _setState(AuthState.error, e.toString());
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      _setState(AuthState.loading);
      
      await _authService.resetPassword(email);
      _setState(AuthState.unauthenticated);
      return true;
    } catch (e) {
      _setState(AuthState.error, e.toString());
      return false;
    }
  }

  // Update user profile
  Future<bool> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      if (_user == null) return false;
      
      _setState(AuthState.loading);
      
      // Update Firebase Auth profile
      await _authService.updateProfile(
        displayName: displayName,
        photoURL: photoURL,
      );
      
      // Update user model
      final updatedUser = _user!.copyWith(
        displayName: displayName ?? _user!.displayName,
        photoURL: photoURL ?? _user!.photoURL,
      );
      
      // Update Firestore document
      await _authService.updateUserData(updatedUser);
      
      _user = updatedUser;
      _setState(AuthState.authenticated);
      return true;
    } catch (e) {
      _setState(AuthState.error, e.toString());
      return false;
    }
  }

  // Delete account
  Future<bool> deleteAccount() async {
    try {
      _setState(AuthState.loading);
      
      await _authService.deleteAccount();
      _user = null;
      _setState(AuthState.unauthenticated);
      return true;
    } catch (e) {
      _setState(AuthState.error, e.toString());
      return false;
    }
  }

  // Update user watchlist
  Future<void> updateWatchlist(List<String> watchlist) async {
    if (_user == null) return;
    
    try {
      final updatedUser = _user!.copyWith(watchlist: watchlist);
      await _authService.updateUserData(updatedUser);
      _user = updatedUser;
      notifyListeners();
    } catch (e) {
      _setState(AuthState.error, e.toString());
    }
  }

  // Add stock to watchlist
  Future<void> addToWatchlist(String symbol) async {
    if (_user == null) return;
    
    try {
      if (!_user!.watchlist.contains(symbol)) {
        final updatedWatchlist = [..._user!.watchlist, symbol];
        await updateWatchlist(updatedWatchlist);
      }
    } catch (e) {
      _setState(AuthState.error, e.toString());
    }
  }

  // Remove stock from watchlist
  Future<void> removeFromWatchlist(String symbol) async {
    if (_user == null) return;
    
    try {
      final updatedWatchlist = _user!.watchlist.where((s) => s != symbol).toList();
      await updateWatchlist(updatedWatchlist);
    } catch (e) {
      _setState(AuthState.error, e.toString());
    }
  }

  // Join club
  Future<void> joinClub(String clubId) async {
    if (_user == null) return;
    
    try {
      if (!_user!.clubIds.contains(clubId)) {
        final updatedClubIds = [..._user!.clubIds, clubId];
        final updatedUser = _user!.copyWith(clubIds: updatedClubIds);
        await _authService.updateUserData(updatedUser);
        _user = updatedUser;
        notifyListeners();
      }
    } catch (e) {
      _setState(AuthState.error, e.toString());
    }
  }

  // Leave club
  Future<void> leaveClub(String clubId) async {
    if (_user == null) return;
    
    try {
      final updatedClubIds = _user!.clubIds.where((id) => id != clubId).toList();
      final updatedUser = _user!.copyWith(clubIds: updatedClubIds);
      await _authService.updateUserData(updatedUser);
      _user = updatedUser;
      notifyListeners();
    } catch (e) {
      _setState(AuthState.error, e.toString());
    }
  }

  // Check if user needs profile completion
  Future<bool> needsProfileCompletion() async {
    return await _authService.needsProfileCompletion();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    if (_state == AuthState.error) {
      _state = _user != null ? AuthState.authenticated : AuthState.unauthenticated;
    }
    notifyListeners();
  }

  // Set state helper
  void _setState(AuthState newState, [String? error]) {
    _state = newState;
    _errorMessage = error;
    notifyListeners();
  }

  // Refresh user data
  Future<void> refreshUserData() async {
    if (_authService.currentUser != null) {
      try {
        final userModel = await _authService.getCurrentUserModel();
        if (userModel != null) {
          _user = userModel;
          notifyListeners();
        }
      } catch (e) {
        print('Error refreshing user data: $e');
      }
    }
  }
}
