const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendMessageNotification = functions.firestore
    .document("messages/{messageId}")
    .onCreate(async (snapshot) => {
      const message = snapshot.data();

      const receiverId = message.receiverId;
      const senderId = message.senderId;
      const text = message.text;

      const receiverDoc = await admin
          .firestore()
          .collection("users")
          .doc(receiverId)
          .get();

      const senderDoc = await admin
          .firestore()
          .collection("users")
          .doc(senderId)
          .get();

      const receiverData = receiverDoc.data();
      const senderData = senderDoc.data();

      if (!receiverData || !senderData) {
        return null;
      }

      const token = receiverData.fcmToken;

      if (!token) {
        return null;
      }

      const payload = {
        notification: {
          title: senderData.name || "Новое сообщение",
          body: text,
        },
        token: token,
      };

      await admin.messaging().send(payload);

      return null;
    });
