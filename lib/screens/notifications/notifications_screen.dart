import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:invest_mate/constants/app_constants.dart';
import 'package:invest_mate/providers/auth_provider.dart';
import 'package:invest_mate/widgets/common/common_widgets.dart';
import 'package:invest_mate/utils/utils.dart';

enum NotificationType {
  trade,
  proposal,
  priceAlert,
  news,
  system,
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.data,
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }

  IconData get icon {
    switch (type) {
      case NotificationType.trade:
        return Icons.swap_horiz;
      case NotificationType.proposal:
        return Icons.how_to_vote;
      case NotificationType.priceAlert:
        return Icons.notifications_active;
      case NotificationType.news:
        return Icons.article;
      case NotificationType.system:
        return Icons.info;
    }
  }

  Color get color {
    switch (type) {
      case NotificationType.trade:
        return AppColors.primary;
      case NotificationType.proposal:
        return Colors.orange;
      case NotificationType.priceAlert:
        return AppColors.error;
      case NotificationType.news:
        return Colors.blue;
      case NotificationType.system:
        return Colors.grey;
    }
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    setState(() {
      _isLoading = true;
    });

    // Mock notifications for demonstration
    _notifications = [
      NotificationModel(
        id: '1',
        title: 'Trade Executed',
        message: 'Successfully bought 100 shares of RELIANCE at ₹2,450.00',
        type: NotificationType.trade,
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      NotificationModel(
        id: '2',
        title: 'New Proposal',
        message: 'Jane Smith proposed to buy INFY in Tech Growth Club',
        type: NotificationType.proposal,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      NotificationModel(
        id: '3',
        title: 'Price Alert',
        message: 'TCS has reached your target price of ₹3,500',
        type: NotificationType.priceAlert,
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        isRead: true,
      ),
      NotificationModel(
        id: '4',
        title: 'Market News',
        message: 'RBI announces new monetary policy, markets expected to react',
        type: NotificationType.news,
        timestamp: DateTime.now().subtract(const Duration(hours: 6)),
        isRead: true,
      ),
      NotificationModel(
        id: '5',
        title: 'Proposal Approved',
        message: 'Your proposal to sell WIPRO has been approved by club members',
        type: NotificationType.proposal,
        timestamp: DateTime.now().subtract(const Duration(hours: 8)),
        isRead: true,
      ),
      NotificationModel(
        id: '6',
        title: 'Welcome to InvestMate!',
        message: 'Start your investment journey with our paper trading feature',
        type: NotificationType.system,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
      ),
    ];

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Notifications'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              if (_hasUnreadNotifications) ...[
                TextButton(
                  onPressed: _markAllAsRead,
                  child: const Text(
                    'Mark all read',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: _showNotificationSettings,
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildNotificationsList(),
        );
      },
    );
  }

  Widget _buildNotificationsList() {
    if (_notifications.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.notifications_none,
        title: 'No Notifications',
        message: 'You\'ll see trade updates, proposals, and alerts here',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _loadNotifications();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSizes.padding),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return _buildNotificationItem(notification);
        },
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
      backgroundColor: notification.isRead 
          ? null 
          : AppColors.primary.withOpacity(0.05),
      child: InkWell(
        onTap: () => _onNotificationTap(notification),
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.padding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingSmall),
                decoration: BoxDecoration(
                  color: notification.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusSmall),
                ),
                child: Icon(
                  notification.icon,
                  color: notification.color,
                  size: 20,
                ),
              ),
              
              const SizedBox(width: AppSizes.padding),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and timestamp
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: AppTextStyles.body1.copyWith(
                              fontWeight: notification.isRead 
                                  ? FontWeight.w600 
                                  : FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          _getRelativeTime(notification.timestamp),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.onBackground.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Message
                    Text(
                      notification.message,
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.onBackground.withOpacity(0.8),
                        fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Unread indicator
              if (!notification.isRead) ...[
                const SizedBox(width: AppSizes.paddingSmall),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getRelativeTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return Utils.formatDate(timestamp);
    }
  }

  bool get _hasUnreadNotifications {
    return _notifications.any((notification) => !notification.isRead);
  }

  void _markAllAsRead() {
    setState(() {
      _notifications = _notifications
          .map((notification) => notification.copyWith(isRead: true))
          .toList();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onNotificationTap(NotificationModel notification) {
    if (!notification.isRead) {
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = notification.copyWith(isRead: true);
        }
      });
    }

    // Handle navigation based on notification type
    switch (notification.type) {
      case NotificationType.trade:
        // Navigate to portfolio/trades
        Utils.showSnackbar(context, 'Navigate to portfolio/trades');
        break;
      case NotificationType.proposal:
        // Navigate to clubs/proposals
        Utils.showSnackbar(context, 'Navigate to clubs/proposals');
        break;
      case NotificationType.priceAlert:
        // Navigate to stock detail
        Utils.showSnackbar(context, 'Navigate to stock detail');
        break;
      case NotificationType.news:
        // Navigate to news section
        Utils.showSnackbar(context, 'Navigate to news');
        break;
      case NotificationType.system:
        // Show notification details
        _showNotificationDetails(notification);
        break;
    }
  }

  void _showNotificationDetails(NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Text(notification.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Settings'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: Text('Trade Notifications'),
              subtitle: Text('Get notified when trades are executed'),
              value: true,
              onChanged: null,
            ),
            SwitchListTile(
              title: Text('Proposal Notifications'),
              subtitle: Text('Get notified about club proposals'),
              value: true,
              onChanged: null,
            ),
            SwitchListTile(
              title: Text('Price Alerts'),
              subtitle: Text('Get notified when price targets are reached'),
              value: true,
              onChanged: null,
            ),
            SwitchListTile(
              title: Text('News Notifications'),
              subtitle: Text('Get notified about market news'),
              value: false,
              onChanged: null,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Utils.showSnackbar(context, 'Settings saved!');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
