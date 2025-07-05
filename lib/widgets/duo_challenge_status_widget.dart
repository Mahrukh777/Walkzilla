import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/duo_challenge_service.dart';

class DuoChallengeStatusWidget extends StatefulWidget {
  const DuoChallengeStatusWidget({super.key});

  @override
  State<DuoChallengeStatusWidget> createState() =>
      _DuoChallengeStatusWidgetState();
}

class _DuoChallengeStatusWidgetState extends State<DuoChallengeStatusWidget> {
  final DuoChallengeService _duoChallengeService = DuoChallengeService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _duoChallengeService.getSentInvitesStatusStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final invites = snapshot.data ?? [];
        final pendingInvites =
            invites.where((invite) => invite['status'] == 'pending').toList();
        final acceptedInvites =
            invites.where((invite) => invite['status'] == 'accepted').toList();
        final declinedInvites =
            invites.where((invite) => invite['status'] == 'declined').toList();

        if (pendingInvites.isEmpty &&
            acceptedInvites.isEmpty &&
            declinedInvites.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Duo Challenge Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              if (pendingInvites.isNotEmpty) ...[
                _buildStatusSection('Pending', pendingInvites, Colors.orange),
                const SizedBox(height: 8),
              ],
              if (acceptedInvites.isNotEmpty) ...[
                _buildStatusSection('Accepted', acceptedInvites, Colors.green),
                const SizedBox(height: 8),
              ],
              if (declinedInvites.isNotEmpty) ...[
                _buildStatusSection('Declined', declinedInvites, Colors.red),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusSection(
      String title, List<Map<String, dynamic>> invites, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ...invites.map((invite) => _buildInviteTile(invite, color)),
      ],
    );
  }

  Widget _buildInviteTile(Map<String, dynamic> invite, Color color) {
    final recipientName = invite['recipientDisplayName'] as String;
    final createdAt = invite['createdAt'] as Timestamp?;
    final status = invite['status'] as String;
    final inviteId = invite['inviteId'] as String;

    String statusText = '';
    if (status == 'accepted') {
      final acceptedAt = invite['acceptedAt'] as Timestamp?;
      statusText = acceptedAt != null
          ? 'Accepted ${_formatTimeAgo(acceptedAt.toDate())}'
          : 'Accepted';
    } else if (status == 'declined') {
      final declinedAt = invite['declinedAt'] as Timestamp?;
      statusText = declinedAt != null
          ? 'Declined ${_formatTimeAgo(declinedAt.toDate())}'
          : 'Declined';
    } else {
      statusText = createdAt != null
          ? 'Sent ${_formatTimeAgo(createdAt.toDate())}'
          : 'Sent recently';
    }

    return Container(
      margin: const EdgeInsets.only(left: 16, top: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipientName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          if (status == 'pending') ...[
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              onPressed: () => _cancelInvite(inviteId),
              color: Colors.grey,
            ),
          ],
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Future<void> _cancelInvite(String inviteId) async {
    try {
      final success = await _duoChallengeService.cancelInvite(inviteId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invite cancelled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling invite: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
