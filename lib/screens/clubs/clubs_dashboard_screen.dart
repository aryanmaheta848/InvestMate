import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:invest_mate/constants/app_constants.dart';
import 'package:invest_mate/providers/club_provider.dart';
import 'package:invest_mate/providers/auth_provider.dart';
import 'package:invest_mate/models/club_model.dart';
import 'package:invest_mate/widgets/common/common_widgets.dart';
import 'package:invest_mate/utils/utils.dart';

class ClubsDashboardScreen extends StatefulWidget {
  const ClubsDashboardScreen({super.key});

  @override
  State<ClubsDashboardScreen> createState() => _ClubsDashboardScreenState();
}

class _ClubsDashboardScreenState extends State<ClubsDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ClubProvider, AuthProvider>(
      builder: (context, clubProvider, authProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Investment Clubs'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  // TODO: Implement club search
                },
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showCreateClubDialog(context),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: 'My Clubs'),
                Tab(text: 'Proposals'),
                Tab(text: 'Discover'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildMyClubsTab(clubProvider, authProvider),
              _buildProposalsTab(clubProvider, authProvider),
              _buildDiscoverTab(clubProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMyClubsTab(ClubProvider clubProvider, AuthProvider authProvider) {
    // Mock data for demonstration
    final mockClubs = [
      ClubModel(
        id: 'club1',
        name: 'Tech Growth Club',
        description: 'Focused on high-growth technology stocks',
        createdBy: authProvider.user?.uid ?? 'demo_user',
        members: [
          ClubMember(
            userId: authProvider.user?.uid ?? 'demo_user',
            displayName: authProvider.user?.displayName ?? 'John Doe',
            role: ClubMemberRole.admin,
          ),
          ClubMember(
            userId: 'user2',
            displayName: 'Jane Smith',
            role: ClubMemberRole.member,
          ),
        ],
        portfolioBalance: 750000.0,
        totalInvested: 250000.0,
        totalCurrentValue: 287500.0,
        totalPL: 37500.0,
        totalPLPercentage: 15.0,
      ),
      ClubModel(
        id: 'club2',
        name: 'Value Investors',
        description: 'Long-term value investing strategy',
        createdBy: 'other_user',
        members: [
          ClubMember(
            userId: authProvider.user?.uid ?? 'demo_user',
            displayName: authProvider.user?.displayName ?? 'John Doe',
            role: ClubMemberRole.member,
          ),
        ],
        portfolioBalance: 800000.0,
        totalInvested: 200000.0,
        totalCurrentValue: 195000.0,
        totalPL: -5000.0,
        totalPLPercentage: -2.5,
      ),
    ];

    if (mockClubs.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.groups,
        title: 'No Clubs Yet',
        message: 'Join or create your first investment club to get started',
        actionText: 'Create Club',
        onAction: () => _showCreateClubDialog(context),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.padding),
      itemCount: mockClubs.length,
      itemBuilder: (context, index) {
        final club = mockClubs[index];
        return _buildClubCard(club, authProvider.user?.uid ?? 'demo_user');
      },
    );
  }

  Widget _buildClubCard(ClubModel club, String currentUserId) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppSizes.padding),
      child: InkWell(
        onTap: () => _navigateToClubDetail(club),
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Icon(
                      Icons.groups,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSizes.padding),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          club.name,
                          style: AppTextStyles.body1.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${club.memberCount} members',
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.onBackground.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (club.isAdmin(currentUserId))
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingSmall,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSizes.borderRadiusSmall),
                      ),
                      child: Text(
                        'Admin',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: AppSizes.padding),
              
              // Description
              Text(
                club.description,
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.onBackground.withOpacity(0.8),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: AppSizes.padding),
              
              // Performance Stats
              Row(
                children: [
                  Expanded(
                    child: _buildStatColumn(
                      'Portfolio Value',
                      club.formattedTotalPortfolioValue,
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildStatColumn(
                      'Total P/L',
                      club.formattedTotalPL,
                      club.isProfitable ? AppColors.success : AppColors.error,
                    ),
                  ),
                  Expanded(
                    child: _buildStatColumn(
                      'Returns',
                      club.formattedTotalPLPercentage,
                      club.isProfitable ? AppColors.success : AppColors.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.onBackground.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.body2.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildProposalsTab(ClubProvider clubProvider, AuthProvider authProvider) {
    // Mock proposals for demonstration
    final mockProposals = [
      ProposalModel(
        id: 'proposal1',
        clubId: 'club1',
        proposedBy: 'user2',
        proposerName: 'Jane Smith',
        type: ProposalType.buy,
        symbol: 'RELIANCE.NS',
        stockName: 'Reliance Industries Ltd',
        quantity: 100,
        targetPrice: 2450.0,
        reason: 'Strong quarterly results and upcoming expansion plans',
        votes: [
          Vote(
            userId: 'user1',
            displayName: 'John Doe',
            vote: VoteType.yes,
          ),
        ],
      ),
      ProposalModel(
        id: 'proposal2',
        clubId: 'club1',
        proposedBy: authProvider.user?.uid ?? 'demo_user',
        proposerName: authProvider.user?.displayName ?? 'John Doe',
        type: ProposalType.sell,
        symbol: 'TCS.NS',
        stockName: 'Tata Consultancy Services',
        quantity: 50,
        reason: 'Technical indicators suggest overbought condition',
        votes: [],
        status: ProposalStatus.active,
      ),
    ];

    if (mockProposals.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.how_to_vote,
        title: 'No Active Proposals',
        message: 'Create a proposal or wait for club members to propose trades',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.padding),
      itemCount: mockProposals.length,
      itemBuilder: (context, index) {
        final proposal = mockProposals[index];
        return _buildProposalCard(proposal, authProvider.user?.uid ?? 'demo_user');
      },
    );
  }

  Widget _buildProposalCard(ProposalModel proposal, String currentUserId) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppSizes.padding),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSizes.paddingSmall),
                  decoration: BoxDecoration(
                    color: proposal.isBuy 
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.borderRadiusSmall),
                  ),
                  child: Icon(
                    proposal.isBuy ? Icons.trending_up : Icons.trending_down,
                    color: proposal.isBuy ? AppColors.success : AppColors.error,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSizes.padding),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${proposal.isBuy ? 'BUY' : 'SELL'} ${proposal.symbol.replaceAll('.NS', '')}',
                        style: AppTextStyles.body1.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'by ${proposal.proposerName}',
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.onBackground.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  proposal.formattedTimeRemaining,
                  style: AppTextStyles.caption.copyWith(
                    color: proposal.isExpired ? AppColors.error : AppColors.onBackground.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSizes.padding),
            
            // Details
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Quantity: ${proposal.formattedQuantity}',
                    style: AppTextStyles.body2,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Price: ${proposal.formattedTargetPrice}',
                    style: AppTextStyles.body2,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSizes.paddingSmall),
            
            Text(
              proposal.reason,
              style: AppTextStyles.body2.copyWith(
                color: AppColors.onBackground.withOpacity(0.8),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: AppSizes.padding),
            
            // Voting Progress
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Votes: ${proposal.yesVotes}/${proposal.totalVotes}',
                            style: AppTextStyles.body2.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${proposal.yesPercentage.toInt()}% approval',
                            style: AppTextStyles.body2.copyWith(
                              color: proposal.hasEnoughVotes ? AppColors.success : AppColors.onBackground.withOpacity(0.7),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: proposal.yesPercentage / 100,
                        backgroundColor: AppColors.surface,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          proposal.hasEnoughVotes ? AppColors.success : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSizes.padding),
            
            // Action Buttons
            if (!proposal.hasUserVoted(currentUserId) && proposal.isActive) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _voteOnProposal(proposal, VoteType.no),
                      icon: const Icon(Icons.thumb_down, size: 16),
                      label: const Text('Against'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.padding),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _voteOnProposal(proposal, VoteType.yes),
                      icon: const Icon(Icons.thumb_up, size: 16),
                      label: const Text('Support'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (proposal.hasUserVoted(currentUserId)) ...[
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingSmall),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusSmall),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      proposal.getUserVote(currentUserId)?.isYes ?? false
                          ? Icons.thumb_up
                          : Icons.thumb_down,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'You voted ${proposal.getUserVote(currentUserId)?.isYes ?? false ? 'Yes' : 'No'}',
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoverTab(ClubProvider clubProvider) {
    return const EmptyStateWidget(
      icon: Icons.explore,
      title: 'Discover Clubs',
      message: 'Find and join public investment clubs',
    );
  }

  void _showCreateClubDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Investment Club'),
        content: const Text('Club creation feature will be available soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _navigateToClubDetail(ClubModel club) {
    Utils.showSnackbar(
      context,
      'Club detail screen will be available soon!',
    );
  }

  void _voteOnProposal(ProposalModel proposal, VoteType voteType) {
    Utils.showSnackbar(
      context,
      'Voted ${voteType == VoteType.yes ? 'Yes' : 'No'} on ${proposal.symbol}',
    );
  }
}
