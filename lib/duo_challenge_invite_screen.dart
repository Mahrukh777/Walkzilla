import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/friend_service.dart';
import 'services/duo_challenge_service.dart';

class DuoChallengeInviteScreen extends StatefulWidget {
  const DuoChallengeInviteScreen({super.key});

  @override
  State<DuoChallengeInviteScreen> createState() =>
      _DuoChallengeInviteScreenState();
}

class _DuoChallengeInviteScreenState extends State<DuoChallengeInviteScreen> {
  final FriendService _friendService = FriendService();
  final DuoChallengeService _duoChallengeService = DuoChallengeService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _selectedFriendId;
  bool _isInviting = false;

  Future<Map<String, dynamic>> _loadFriendsAndPendingInvites() async {
    final friends = await _friendService.getFriends().first;
    final sentInvites = await _duoChallengeService.getSentInvites();
    final pending = sentInvites
        .map((invite) => invite['recipientUserId'] as String)
        .toSet();
    return {'friends': friends, 'pending': pending};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Invite Friend to Duo Challenge',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose a friend to challenge:',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87),
              ),
              const SizedBox(height: 8),
              const Text(
                'You can only invite one friend at a time',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _loadFriendsAndPendingInvites(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF7C4DFF)));
                    }
                    final friends =
                        snapshot.data!['friends'] as List<Map<String, dynamic>>;
                    final pending = snapshot.data!['pending'] as Set<String>;
                    if (friends.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.people_outline,
                                size: 60, color: Color(0xFF7C4DFF)),
                            SizedBox(height: 24),
                            Text('No friends yet',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87)),
                            SizedBox(height: 8),
                            Text(
                                'Add some friends first to start duo challenges!',
                                style:
                                    TextStyle(fontSize: 14, color: Colors.grey),
                                textAlign: TextAlign.center),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: friends.length,
                      itemBuilder: (context, index) {
                        final friend = friends[index];
                        final friendId = friend['userId'];
                        final isSelected = _selectedFriendId == friendId;
                        final hasPendingInvite = pending.contains(friendId);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
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
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            leading: CircleAvatar(
                              radius: 28,
                              backgroundColor:
                                  const Color(0xFF7C4DFF).withOpacity(0.1),
                              backgroundImage:
                                  (friend['profileImage'] != null &&
                                          friend['profileImage'] != '')
                                      ? NetworkImage(friend['profileImage'])
                                      : null,
                              child: (friend['profileImage'] == null ||
                                      friend['profileImage'] == '')
                                  ? Text(
                                      (friend['displayName'] ??
                                                  friend['username'] ??
                                                  '?')
                                              .toString()
                                              .isNotEmpty
                                          ? (friend['displayName'] ??
                                                  friend['username'] ??
                                                  '?')
                                              .toString()[0]
                                              .toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF7C4DFF)),
                                    )
                                  : null,
                            ),
                            title: Text(
                                friend['displayName'] ??
                                    friend['username'] ??
                                    'Unknown',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87)),
                            subtitle: Text(
                                '@${friend['username'] ?? 'unknown'}',
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.grey)),
                            trailing: Container(
                              decoration: BoxDecoration(
                                color: hasPendingInvite
                                    ? Colors.grey.withOpacity(0.2)
                                    : isSelected
                                        ? const Color(0xFF7C4DFF)
                                        : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: hasPendingInvite
                                      ? Colors.grey.withOpacity(0.3)
                                      : isSelected
                                          ? const Color(0xFF7C4DFF)
                                          : const Color(0xFF7C4DFF)
                                              .withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: hasPendingInvite
                                  ? const Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      child: Text(
                                        'Request Sent',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    )
                                  : IconButton(
                                      icon: Icon(
                                          isSelected ? Icons.check : Icons.add,
                                          color: isSelected
                                              ? Colors.white
                                              : const Color(0xFF7C4DFF)),
                                      onPressed: () {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedFriendId = null;
                                          } else {
                                            _selectedFriendId = friendId;
                                          }
                                        });
                                      },
                                    ),
                            ),
                            onTap: hasPendingInvite
                                ? null
                                : () {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedFriendId = null;
                                      } else {
                                        _selectedFriendId = friendId;
                                      }
                                    });
                                  },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              if (_selectedFriendId != null) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isInviting ? null : _sendDuoChallengeInvite,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C4DFF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isInviting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Send Duo Challenge Invite',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendDuoChallengeInvite() async {
    if (_selectedFriendId == null) return;
    setState(() {
      _isInviting = true;
    });
    try {
      final success = await _duoChallengeService.sendInvite(_selectedFriendId!);
      // Always reload the Future after sending
      setState(() {});
      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Duo challenge invite sent successfully!'),
              backgroundColor: Color(0xFF7C4DFF)),
        );
        Navigator.pop(context);
      }
      // If already sent, UI will update and show 'Request Sent' automatically
    } catch (e) {
      print('Error sending duo challenge invite: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error sending invite: ${e.toString()}'),
            backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isInviting = false;
        });
      }
    }
  }
}
