import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/duo_challenge_service.dart';
import 'dart:async';

class DuoChallengeInviteDialog extends StatefulWidget {
  final String inviterUsername;
  final String inviteId;

  const DuoChallengeInviteDialog({
    super.key,
    required this.inviterUsername,
    required this.inviteId,
  });

  @override
  State<DuoChallengeInviteDialog> createState() =>
      _DuoChallengeInviteDialogState();
}

class _DuoChallengeInviteDialogState extends State<DuoChallengeInviteDialog> {
  final DuoChallengeService _duoChallengeService = DuoChallengeService();
  bool _isProcessing = false;
  String? _currentStatus;
  Stream<DocumentSnapshot>? _inviteStream;
  StreamSubscription<DocumentSnapshot>? _lobbyListener;

  @override
  void initState() {
    super.initState();
    _listenForLobbyStart();
  }

  @override
  void dispose() {
    _lobbyListener?.cancel();
    super.dispose();
  }

  void _listenForLobbyStart() {
    _lobbyListener = FirebaseFirestore.instance
        .collection('duo_challenge_invites')
        .doc(widget.inviteId)
        .snapshots()
        .listen((doc) {
      if (doc.exists && doc.data()?['lobbyStarted'] == true) {
        // Navigate to lobby
        Navigator.of(context).popUntil((route) => route.isFirst);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DuoChallengeLobbyScreen(
              inviteId: widget.inviteId,
              user1Uid: doc.data()?['fromUserId'] ?? '',
              user2Uid: doc.data()?['toUserId'] ?? '',
              user1Name: doc.data()?['inviterDisplayName'],
              user2Name: doc.data()?['recipientDisplayName'],
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('duo_challenge_invites')
          .doc(widget.inviteId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorDialog();
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildExpiredDialog();
        }

        final inviteData = snapshot.data!.data() as Map<String, dynamic>?;
        if (inviteData == null) {
          return _buildExpiredDialog();
        }

        final status = inviteData['status'] as String? ?? 'pending';

        if (status == 'cancelled') {
          return _buildCancelledDialog();
        }

        if (status == 'accepted' || status == 'declined') {
          return _buildProcessedDialog(status);
        }

        return _buildInviteDialog();
      },
    );
  }

  Widget _buildInviteDialog() {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF7C4DFF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.emoji_events,
              color: Color(0xFF7C4DFF),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Duo Challenge Invite',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.inviterUsername} is inviting you to a Duo Challenge right now!',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Do you want to accept this challenge?',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => _declineInvite(context),
          child: const Text(
            'Decline',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : () => _acceptInvite(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7C4DFF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isProcessing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : const Text(
                  'Accept',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildCancelledDialog() {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.cancel,
              color: Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Invite Cancelled',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
      content: const Text(
        'This duo challenge invite has been cancelled by the sender.',
        style: TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('OK'),
        ),
      ],
    );
  }

  Widget _buildExpiredDialog() {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.access_time,
              color: Colors.orange,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Invite Expired',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
      content: const Text(
        'This duo challenge invite has expired or is no longer available.',
        style: TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('OK'),
        ),
      ],
    );
  }

  Widget _buildProcessedDialog(String status) {
    final isAccepted = status == 'accepted';
    final color = isAccepted ? Colors.green : Colors.red;
    final icon = isAccepted ? Icons.check_circle : Icons.cancel;
    final title = isAccepted ? 'Challenge Accepted!' : 'Challenge Declined';
    final message = isAccepted
        ? 'You have accepted the duo challenge. Get ready to compete!'
        : 'You have declined the duo challenge.';

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('OK'),
        ),
      ],
    );
  }

  Widget _buildErrorDialog() {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.error,
              color: Colors.red,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Error',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
      content: const Text(
        'There was an error loading the invite. Please try again.',
        style: TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('OK'),
        ),
      ],
    );
  }

  Future<void> _acceptInvite(BuildContext context) async {
    try {
      setState(() {
        _isProcessing = true;
      });

      final success = await _duoChallengeService.acceptInvite(widget.inviteId);

      if (context.mounted) {
        if (success) {
          Navigator.of(context).pop('accepted');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Challenge accepted!'),
              backgroundColor: Color(0xFF7C4DFF),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error accepting invite. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting invite: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _declineInvite(BuildContext context) async {
    try {
      setState(() {
        _isProcessing = true;
      });

      final success = await _duoChallengeService.declineInvite(widget.inviteId);

      if (context.mounted) {
        if (success) {
          Navigator.of(context).pop('declined');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Challenge declined.'),
              backgroundColor: Colors.grey,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error declining invite. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error declining invite: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}

class DuoChallengeLobbyScreen extends StatefulWidget {
  final String inviteId;
  final String user1Uid;
  final String user2Uid;
  final String? user1Name;
  final String? user2Name;
  const DuoChallengeLobbyScreen({
    super.key,
    required this.inviteId,
    required this.user1Uid,
    required this.user2Uid,
    this.user1Name,
    this.user2Name,
  });

  @override
  State<DuoChallengeLobbyScreen> createState() =>
      _DuoChallengeLobbyScreenState();
}

class _DuoChallengeLobbyScreenState extends State<DuoChallengeLobbyScreen> {
  late String currentUid;
  late String otherUid;
  late String currentName;
  late String otherName;

  @override
  void initState() {
    super.initState();
    currentUid = FirebaseAuth.instance.currentUser!.uid;
    if (currentUid == widget.user1Uid) {
      otherUid = widget.user2Uid;
      currentName = widget.user1Name ?? 'You';
      otherName = widget.user2Name ?? 'Friend';
    } else {
      otherUid = widget.user1Uid;
      currentName = widget.user2Name ?? 'You';
      otherName = widget.user1Name ?? 'Friend';
    }
  }

  Future<void> _setReady() async {
    final docRef = FirebaseFirestore.instance
        .collection('duo_challenge_invites')
        .doc(widget.inviteId);
    await docRef.set({
      'ready': {currentUid: true},
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    final docRef = FirebaseFirestore.instance
        .collection('duo_challenge_invites')
        .doc(widget.inviteId);
    return Scaffold(
      appBar: AppBar(title: const Text('Duo Challenge Lobby')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: docRef.snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() as Map<String, dynamic>?;
          final readyMap = (data?['ready'] as Map<String, dynamic>?) ?? {};
          final isReady = readyMap[currentUid] == true;
          final otherReady = readyMap[otherUid] == true;
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildUserCard(currentName, isReady),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: const Text('VS',
                          style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple)),
                    ),
                    _buildUserCard(otherName, otherReady),
                  ],
                ),
                const SizedBox(height: 40),
                if (!isReady)
                  ElevatedButton(
                    onPressed: _setReady,
                    child: const Text('I am Ready!'),
                  ),
                if (isReady && !otherReady)
                  const Padding(
                    padding: EdgeInsets.only(top: 24.0),
                    child: Text('Waiting for your friend to be ready...',
                        style: TextStyle(fontSize: 16)),
                  ),
                if (isReady && otherReady)
                  const Padding(
                    padding: EdgeInsets.only(top: 24.0),
                    child: Text('Both players are ready! Starting soon...',
                        style: TextStyle(
                            fontSize: 18,
                            color: Colors.green,
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserCard(String name, bool isReady) {
    return Column(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: isReady ? Colors.green : Colors.grey[400],
          child: Icon(isReady ? Icons.check : Icons.person,
              color: Colors.white, size: 32),
        ),
        const SizedBox(height: 8),
        Text(name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(isReady ? 'Ready' : 'Not Ready',
            style: TextStyle(color: isReady ? Colors.green : Colors.grey)),
      ],
    );
  }
}
