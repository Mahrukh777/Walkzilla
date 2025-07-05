const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

initializeApp();

exports.sendDuoChallengeInvite = onDocumentCreated(
  "duo_challenge_invites/{inviteId}",
  async (event) => {
    try {
      console.log('Duo challenge invite function triggered');
      
      const snap = event.data;
      if (!snap) {
        console.error('No data in the event');
        return;
      }
      
      const invite = snap.data();
      console.log('Invite data:', invite);
      
      const toUserId = invite.toUserId;
      const fromUserId = invite.fromUserId;
      const inviteId = event.params.inviteId;

      console.log('Processing invite:', { toUserId, fromUserId, inviteId });

      const db = getFirestore();
      const userDoc = await db.collection("users").doc(toUserId).get();
      const inviterDoc = await db.collection("users").doc(fromUserId).get();

      if (!userDoc.exists) {
        console.error('User document not found for:', toUserId);
        return;
      }

      if (!inviterDoc.exists) {
        console.error('Inviter document not found for:', fromUserId);
        return;
      }

      const fcmToken = userDoc.get("fcmToken");
      const inviterUsername = inviterDoc.get("username") || inviterDoc.get("displayName") || "Someone";

      console.log('FCM Token:', fcmToken ? 'Present' : 'Missing');
      console.log('Inviter username:', inviterUsername);

      if (fcmToken) {
        const payload = {
          notification: {
            title: "Duo Challenge Invite",
            body: `${inviterUsername} is inviting you to a Duo Challenge!`,
          },
          data: {
            type: "duo_challenge_invite",
            inviterUsername,
            inviteId,
          },
        };
        
        console.log('Sending FCM payload:', payload);
        
        const response = await getMessaging().sendToDevice(fcmToken, payload);
        console.log('FCM response:', response);
        
        if (response.failureCount > 0) {
          console.error('FCM send failed:', response.results[0].error);
        } else {
          console.log('FCM notification sent successfully');
        }
      } else {
        console.warn('No FCM token found for user:', toUserId);
      }

      return;
    } catch (error) {
      console.error('Error in sendDuoChallengeInvite function:', error);
      throw error;
    }
  }
);
