const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

initializeApp();

exports.sendDuoChallengeInvite = onDocumentCreated(
  "duo_challenge_invites/{inviteId}",
  async (event) => {
    const snap = event.data;
    const invite = snap.data();
    const toUserId = invite.toUserId;
    const fromUserId = invite.fromUserId;
    const inviteId = event.params.inviteId;

    const db = getFirestore();
    const userDoc = await db.collection("users").doc(toUserId).get();
    const inviterDoc = await db.collection("users").doc(fromUserId).get();

    const fcmToken = userDoc.get("fcmToken");
    const inviterUsername = inviterDoc.get("username") || "Someone";

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
      await getMessaging().sendToDevice(fcmToken, payload);
    }

    return;
  }
);
