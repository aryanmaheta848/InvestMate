import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:invest_mate/models/user_model.dart';
import 'package:invest_mate/constants/app_constants.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '115248817960-al6jhii456afo42ecdu7ilbkg278shps.apps.googleusercontent.com',
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Initialize GoogleSignIn
  Future<void> initGoogleSignIn() async {
    // No initialization needed for version 6.x
  }

  // Get current user
  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserModel?> signInWithEmail(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (result.user != null) {
        return await _getUserData(result.user!.uid);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An error occurred during sign in: $e');
    }
  }

  // Create account with email and password
  Future<UserModel?> createAccount(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        // Update display name
        await result.user!.updateDisplayName(displayName);
        
        // Create user document
        final userModel = UserModel.fromAuth(
          uid: result.user!.uid,
          email: email,
          displayName: displayName,
          photoURL: result.user!.photoURL,
        );
        
        await _createUserDocument(userModel);
        return userModel;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An error occurred during account creation: $e');
    }
  }

  // Sign in with Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      // Initialize Google Sign In if not already done
      await initGoogleSignIn();
      
      // Try sign in
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User canceled

      // Get authentication tokens
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final UserCredential result = await _auth.signInWithCredential(credential);
      
      if (result.user != null) {
        // Check if user document exists, create if not
        final userDoc = await _firestore.collection('users').doc(result.user!.uid).get();
        
        if (!userDoc.exists) {
          final userModel = UserModel.fromAuth(
            uid: result.user!.uid,
            email: result.user!.email!,
            displayName: result.user!.displayName ?? result.user!.email!.split('@')[0],
            photoURL: result.user!.photoURL,
          );
          
          await _createUserDocument(userModel);
          return userModel;
        } else {
          return await _getUserData(result.user!.uid);
        }
      }
      return null;
    } catch (e) {
      throw Exception('An error occurred during Google sign in: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw Exception('An error occurred during sign out: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An error occurred during password reset: $e');
    }
  }

  // Update user profile
  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      if (currentUser != null) {
        if (displayName != null) {
          await currentUser!.updateDisplayName(displayName);
        }
        if (photoURL != null) {
          await currentUser!.updatePhotoURL(photoURL);
        }
        await currentUser!.reload();
      }
    } catch (e) {
      throw Exception('An error occurred during profile update: $e');
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      if (currentUser != null) {
        // Delete user data from Firestore
        await _deleteUserData(currentUser!.uid);
        
        // Delete Firebase Auth account
        await currentUser!.delete();
      }
    } catch (e) {
      throw Exception('An error occurred during account deletion: $e');
    }
  }

  // Get user data from Firestore
  Future<UserModel?> _getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set(user.toFirestore());
      
      // Create initial portfolio
      await _firestore.collection('portfolios').doc(user.uid).set({
        'cashBalance': AppConstants.initialBalance,
        'totalInvested': 0.0,
        'totalCurrentValue': 0.0,
        'totalPL': 0.0,
        'totalPLPercentage': 0.0,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to create user document: $e');
    }
  }

  // Delete user data from Firestore
  Future<void> _deleteUserData(String uid) async {
    try {
      final batch = _firestore.batch();
      
      // Delete user document
      batch.delete(_firestore.collection('users').doc(uid));
      
      // Delete portfolio
      batch.delete(_firestore.collection('portfolios').doc(uid));
      
      // Delete user's holdings
      final holdings = await _firestore
          .collection('portfolios')
          .doc(uid)
          .collection('holdings')
          .get();
      
      for (final doc in holdings.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete user's trades
      final trades = await _firestore
          .collection('trades')
          .where('userId', isEqualTo: uid)
          .get();
      
      for (final doc in trades.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete user data: $e');
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided for that user.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      default:
        return 'An authentication error occurred: ${e.message}';
    }
  }

  // Check if user needs to complete profile
  Future<bool> needsProfileCompletion() async {
    if (currentUser == null) return false;
    
    try {
      final userModel = await _getUserData(currentUser!.uid);
      if (userModel == null) return true;
      
      return userModel.displayName.isEmpty;
    } catch (e) {
      return true;
    }
  }

  // Get current user model
  Future<UserModel?> getCurrentUserModel() async {
    if (currentUser == null) return null;
    return await _getUserData(currentUser!.uid);
  }

  // Update user data in Firestore
  Future<void> updateUserData(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).update(user.toFirestore());
    } catch (e) {
      throw Exception('Failed to update user data: $e');
    }
  }

  // Listen to user data changes
  Stream<UserModel?> getUserDataStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists) {
            return UserModel.fromFirestore(snapshot);
          }
          return null;
        });
  }
}
