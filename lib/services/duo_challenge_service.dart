import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DuoChallengeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check for pending duo challenge invites for the current user
  /// Returns a list of invite data if any pending invites exist
  Future<List<Map<String, dynamic>>> checkPendingInvites() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      final pendingInvites = await _firestore
          .collection('duo_challenge_invites')
          .where('toUserId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      final invites = <Map<String, dynamic>>[];

      for (final doc in pendingInvites.docs) {
        final inviteData = doc.data();
        final fromUserId = inviteData['fromUserId'] as String;

        // Get the inviter's user data
        final inviterDoc =
            await _firestore.collection('users').doc(fromUserId).get();

        if (inviterDoc.exists) {
          final inviterData = inviterDoc.data()!;
          invites.add({
            'inviteId': doc.id,
            'inviterUsername': inviterData['username'] ??
                inviterData['displayName'] ??
                'Someone',
            'inviterDisplayName': inviterData['displayName'] ??
                inviterData['username'] ??
                'Someone',
            'createdAt': inviteData['createdAt'],
            'expiresAt': inviteData['expiresAt'],
          });
        }
      }

      return invites;
    } catch (e) {
      print('Error checking pending invites: $e');
      return [];
    }
  }

  /// Stream of pending invites for real-time updates
  Stream<List<Map<String, dynamic>>> getPendingInvitesStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _firestore
        .collection('duo_challenge_invites')
        .where('toUserId', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final invites = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final inviteData = doc.data();
        final fromUserId = inviteData['fromUserId'] as String;

        // Get the inviter's user data
        final inviterDoc =
            await _firestore.collection('users').doc(fromUserId).get();

        if (inviterDoc.exists) {
          final inviterData = inviterDoc.data()!;
          invites.add({
            'inviteId': doc.id,
            'inviterUsername': inviterData['username'] ??
                inviterData['displayName'] ??
                'Someone',
            'inviterDisplayName': inviterData['displayName'] ??
                inviterData['username'] ??
                'Someone',
            'createdAt': inviteData['createdAt'],
            'expiresAt': inviteData['expiresAt'],
          });
        }
      }

      return invites;
    });
  }

  /// Stream to listen for invite status changes (for the sender)
  Stream<List<Map<String, dynamic>>> getSentInvitesStatusStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _firestore
        .collection('duo_challenge_invites')
        .where('fromUserId', isEqualTo: currentUser.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final invites = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final inviteData = doc.data();
        final toUserId = inviteData['toUserId'] as String;
        final status = inviteData['status'] as String;

        // Get the recipient's user data
        final recipientDoc =
            await _firestore.collection('users').doc(toUserId).get();

        if (recipientDoc.exists) {
          final recipientData = recipientDoc.data()!;
          invites.add({
            'inviteId': doc.id,
            'recipientUserId': toUserId,
            'recipientUsername': recipientData['username'] ??
                recipientData['displayName'] ??
                'Unknown',
            'recipientDisplayName': recipientData['displayName'] ??
                recipientData['username'] ??
                'Unknown',
            'status': status,
            'createdAt': inviteData['createdAt'],
            'expiresAt': inviteData['expiresAt'],
            'acceptedAt': inviteData['acceptedAt'],
            'declinedAt': inviteData['declinedAt'],
          });
        }
      }

      return invites;
    });
  }

  /// Accept a duo challenge invite
  Future<bool> acceptInvite(String inviteId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      await _firestore
          .collection('duo_challenge_invites')
          .doc(inviteId)
          .update({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error accepting invite: $e');
      return false;
    }
  }

  /// Decline a duo challenge invite
  Future<bool> declineInvite(String inviteId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      await _firestore
          .collection('duo_challenge_invites')
          .doc(inviteId)
          .update({
        'status': 'declined',
        'declinedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error declining invite: $e');
      return false;
    }
  }

  /// Send a duo challenge invite
  Future<bool> sendInvite(String toUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Check if there's already a pending invite
      final existingInvite = await _firestore
          .collection('duo_challenge_invites')
          .where('fromUserId', isEqualTo: currentUser.uid)
          .where('toUserId', isEqualTo: toUserId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (existingInvite.docs.isNotEmpty) {
        return false; // Invite already exists
      }

      await _firestore.collection('duo_challenge_invites').add({
        'fromUserId': currentUser.uid,
        'toUserId': toUserId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'challengeType': 'duo',
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(hours: 24)),
        ),
      });

      return true;
    } catch (e) {
      print('Error sending invite: $e');
      return false;
    }
  }

  /// Get sent invites by the current user
  Future<List<Map<String, dynamic>>> getSentInvites() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      final sentInvites = await _firestore
          .collection('duo_challenge_invites')
          .where('fromUserId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      final invites = <Map<String, dynamic>>[];

      for (final doc in sentInvites.docs) {
        final inviteData = doc.data();
        final toUserId = inviteData['toUserId'] as String;

        // Get the recipient's user data
        final recipientDoc =
            await _firestore.collection('users').doc(toUserId).get();

        if (recipientDoc.exists) {
          final recipientData = recipientDoc.data()!;
          invites.add({
            'inviteId': doc.id,
            'recipientUserId': toUserId,
            'recipientUsername': recipientData['username'] ??
                recipientData['displayName'] ??
                'Unknown',
            'recipientDisplayName': recipientData['displayName'] ??
                recipientData['username'] ??
                'Unknown',
            'createdAt': inviteData['createdAt'],
            'expiresAt': inviteData['expiresAt'],
          });
        }
      }

      return invites;
    } catch (e) {
      print('Error getting sent invites: $e');
      return [];
    }
  }

  /// Cancel a sent invite
  Future<bool> cancelInvite(String inviteId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      await _firestore
          .collection('duo_challenge_invites')
          .doc(inviteId)
          .update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error cancelling invite: $e');
      return false;
    }
  }
}
