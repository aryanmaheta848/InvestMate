import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:invest_mate/models/user_model.dart';
import 'package:invest_mate/models/stock_model.dart';
import 'package:invest_mate/models/club_model.dart';
import 'package:invest_mate/models/trade_model.dart';
import 'package:invest_mate/models/news_model.dart';
import 'package:invest_mate/models/portfolio_model.dart';
import 'package:invest_mate/models/holding_model.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Collections
  CollectionReference get users => _firestore.collection('users');
  CollectionReference get stocks => _firestore.collection('stocks');
  CollectionReference get clubs => _firestore.collection('clubs');
  CollectionReference get trades => _firestore.collection('trades');
  CollectionReference get news => _firestore.collection('news');
  CollectionReference get portfolios => _firestore.collection('portfolios');
  CollectionReference get proposals => _firestore.collection('proposals');
  CollectionReference get holdings => _firestore.collection('holdings');

  // Current user
  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;
  bool get isAuthenticated => _auth.currentUser != null;

  // Initialize FCM
  Future<void> initializeMessaging() async {
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        String? token = await _messaging.getToken();
        if (token != null && currentUserId != null) {
          await updateUserFCMToken(token);
        }
      }

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Received a message: ${message.messageId}');
        // Handle the message in the foreground
      });
      
    } catch (e) {
      print('Error initializing messaging: $e');
    }
  }

  // User operations
  Future<void> createUserDocument(UserModel user) async {
    try {
      await users.doc(user.uid).set(user.toFirestore());
    } catch (e) {
      throw Exception('Failed to create user document: $e');
    }
  }

  Future<UserModel?> getUserDocument(String uid) async {
    try {
      DocumentSnapshot doc = await users.doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user document: $e');
    }
  }

  Future<void> updateUserDocument(String uid, Map<String, dynamic> data) async {
    try {
      await users.doc(uid).update(data);
    } catch (e) {
      throw Exception('Failed to update user document: $e');
    }
  }

  Future<void> updateUserFCMToken(String token) async {
    try {
      if (currentUserId != null) {
        await users.doc(currentUserId).update({
          'fcmToken': token,
          'lastActive': Timestamp.now(),
        });
      }
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }

  // Watchlist operations
  Future<void> addToWatchlist(String symbol) async {
    try {
      if (currentUserId != null) {
        await users.doc(currentUserId).update({
          'watchlist': FieldValue.arrayUnion([symbol])
        });
      }
    } catch (e) {
      throw Exception('Failed to add to watchlist: $e');
    }
  }

  Future<void> removeFromWatchlist(String symbol) async {
    try {
      if (currentUserId != null) {
        await users.doc(currentUserId).update({
          'watchlist': FieldValue.arrayRemove([symbol])
        });
      }
    } catch (e) {
      throw Exception('Failed to remove from watchlist: $e');
    }
  }

  // Stock operations
  Future<void> cacheStockData(StockModel stock) async {
    try {
      await stocks.doc(stock.symbol).set(stock.toFirestore());
    } catch (e) {
      print('Error caching stock data: $e');
    }
  }

  Future<List<StockModel>> getCachedStocks(List<String> symbols) async {
    try {
      if (symbols.isEmpty) return [];
      
      QuerySnapshot snapshot = await stocks
          .where(FieldPath.documentId, whereIn: symbols)
          .get();
      
      return snapshot.docs
          .map((doc) => StockModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting cached stocks: $e');
      return [];
    }
  }

  // Portfolio operations
  Future<void> updatePortfolio(String userId, PortfolioModel portfolio) async {
    try {
      await portfolios.doc(userId).set(portfolio.toFirestore());
    } catch (e) {
      throw Exception('Failed to update portfolio: $e');
    }
  }

  Future<PortfolioModel?> getPortfolio(String userId) async {
    try {
      DocumentSnapshot doc = await portfolios.doc(userId).get();
      if (doc.exists) {
        return PortfolioModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get portfolio: $e');
    }
  }

  // Holdings operations
  Future<void> updateHolding(String userId, HoldingModel holding) async {
    try {
      await holdings
          .doc(userId)
          .collection('stocks')
          .doc(holding.symbol)
          .set(holding.toFirestore());
    } catch (e) {
      throw Exception('Failed to update holding: $e');
    }
  }

  Future<List<HoldingModel>> getUserHoldings(String userId) async {
    try {
      QuerySnapshot snapshot = await holdings
          .doc(userId)
          .collection('stocks')
          .get();
      
      return snapshot.docs
          .map((doc) => HoldingModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user holdings: $e');
    }
  }

  Future<void> deleteHolding(String userId, String symbol) async {
    try {
      await holdings
          .doc(userId)
          .collection('stocks')
          .doc(symbol)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete holding: $e');
    }
  }

  // Trade operations
  Future<String> createTrade(TradeModel trade) async {
    try {
      DocumentReference docRef = await trades.add(trade.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create trade: $e');
    }
  }

  Future<void> updateTrade(String tradeId, Map<String, dynamic> data) async {
    try {
      await trades.doc(tradeId).update(data);
    } catch (e) {
      throw Exception('Failed to update trade: $e');
    }
  }

  Future<List<TradeModel>> getUserTrades(String userId, {int? limit}) async {
    try {
      Query query = trades
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true);
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      QuerySnapshot snapshot = await query.get();
      
      return snapshot.docs
          .map((doc) => TradeModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user trades: $e');
    }
  }

  // Club operations
  Future<String> createClub(ClubModel club) async {
    try {
      DocumentReference docRef = await clubs.add(club.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create club: $e');
    }
  }

  Future<ClubModel?> getClub(String clubId) async {
    try {
      DocumentSnapshot doc = await clubs.doc(clubId).get();
      if (doc.exists) {
        return ClubModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get club: $e');
    }
  }

  Future<void> updateClub(String clubId, Map<String, dynamic> data) async {
    try {
      await clubs.doc(clubId).update(data);
    } catch (e) {
      throw Exception('Failed to update club: $e');
    }
  }

  Future<List<ClubModel>> getUserClubs(String userId) async {
    try {
      QuerySnapshot snapshot = await clubs
          .where('members', arrayContainsAny: [
            {'userId': userId}
          ])
          .get();
      
      return snapshot.docs
          .map((doc) => ClubModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting user clubs: $e');
      return [];
    }
  }

  Future<void> joinClub(String clubId, ClubMember member) async {
    try {
      await clubs.doc(clubId).update({
        'members': FieldValue.arrayUnion([member.toFirestore()])
      });
      
      // Update user's club list
      if (currentUserId != null) {
        await users.doc(currentUserId).update({
          'clubIds': FieldValue.arrayUnion([clubId])
        });
      }
    } catch (e) {
      throw Exception('Failed to join club: $e');
    }
  }

  Future<void> leaveClub(String clubId, String userId) async {
    try {
      ClubModel? club = await getClub(clubId);
      if (club != null) {
        List<ClubMember> updatedMembers = club.members
            .where((member) => member.userId != userId)
            .toList();
        
        await clubs.doc(clubId).update({
          'members': updatedMembers.map((m) => m.toFirestore()).toList()
        });
        
        // Update user's club list
        await users.doc(userId).update({
          'clubIds': FieldValue.arrayRemove([clubId])
        });
      }
    } catch (e) {
      throw Exception('Failed to leave club: $e');
    }
  }

  // Proposal operations
  Future<String> createProposal(ProposalModel proposal) async {
    try {
      DocumentReference docRef = await proposals.add(proposal.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create proposal: $e');
    }
  }

  Future<void> voteOnProposal(String proposalId, Vote vote) async {
    try {
      ProposalModel? proposal = await getProposal(proposalId);
      if (proposal != null) {
        List<Vote> updatedVotes = proposal.votes
            .where((v) => v.userId != vote.userId)
            .toList();
        updatedVotes.add(vote);
        
        await proposals.doc(proposalId).update({
          'votes': updatedVotes.map((v) => v.toFirestore()).toList()
        });
      }
    } catch (e) {
      throw Exception('Failed to vote on proposal: $e');
    }
  }

  Future<ProposalModel?> getProposal(String proposalId) async {
    try {
      DocumentSnapshot doc = await proposals.doc(proposalId).get();
      if (doc.exists) {
        return ProposalModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get proposal: $e');
    }
  }

  Future<List<ProposalModel>> getClubProposals(String clubId) async {
    try {
      QuerySnapshot snapshot = await proposals
          .where('clubId', isEqualTo: clubId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => ProposalModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get club proposals: $e');
    }
  }

  // News operations
  Future<void> cacheNews(List<NewsModel> newsItems) async {
    try {
      WriteBatch batch = _firestore.batch();
      
      for (NewsModel item in newsItems) {
        DocumentReference docRef = news.doc(item.id);
        batch.set(docRef, item.toFirestore());
      }
      
      await batch.commit();
    } catch (e) {
      print('Error caching news: $e');
    }
  }

  Future<List<NewsModel>> getCachedNews({
    List<String>? symbols,
    int limit = 20,
  }) async {
    try {
      Query query = news.orderBy('publishedAt', descending: true);
      
      if (symbols != null && symbols.isNotEmpty) {
        query = query.where('symbols', arrayContainsAny: symbols);
      }
      
      query = query.limit(limit);
      QuerySnapshot snapshot = await query.get();
      
      return snapshot.docs
          .map((doc) => NewsModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting cached news: $e');
      return [];
    }
  }

  // Batch operations
  Future<void> executeBatchWrite(List<BatchOperation> operations) async {
    try {
      WriteBatch batch = _firestore.batch();
      
      for (BatchOperation operation in operations) {
        switch (operation.type) {
          case BatchOperationType.set:
            batch.set(operation.reference, operation.data!);
            break;
          case BatchOperationType.update:
            batch.update(operation.reference, operation.data!);
            break;
          case BatchOperationType.delete:
            batch.delete(operation.reference);
            break;
        }
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to execute batch write: $e');
    }
  }

  // Stream operations
  Stream<UserModel?> getUserStream(String uid) {
    return users.doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    });
  }

  Stream<List<ClubModel>> getUserClubsStream(String userId) {
    return clubs
        .where('members', arrayContainsAny: [
          {'userId': userId}
        ])
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ClubModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<ProposalModel>> getClubProposalsStream(String clubId) {
    return proposals
        .where('clubId', isEqualTo: clubId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProposalModel.fromFirestore(doc))
            .toList());
  }
}

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
}

// Batch operation classes
enum BatchOperationType {
  set,
  update,
  delete,
}

class BatchOperation {
  final BatchOperationType type;
  final DocumentReference reference;
  final Map<String, dynamic>? data;

  BatchOperation({
    required this.type,
    required this.reference,
    this.data,
  });
}
