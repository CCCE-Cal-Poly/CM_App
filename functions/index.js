const admin = require("firebase-admin");

admin.initializeApp();

const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");

const ALLOWED_ROLES = new Set(["student", "faculty", "club admin", "admin"]);

exports.setUserRole = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const callerUid = request.auth.uid;
  const callerRecord = await admin.auth().getUser(callerUid);
  const callerRole = (callerRecord.customClaims && callerRecord.customClaims.role);

  if (callerRole !== "admin") {
    throw new HttpsError("permission-denied", "Only admins can set user roles");
  }

  const {uid, role, clubs} = request.data;

  if (!uid || typeof uid !== "string") {
    throw new HttpsError("invalid-argument", "Must provide a valid uid");
  }

  if (!role || typeof role !== "string") {
    throw new HttpsError("invalid-argument", "Must provide a valid role string");
  }

  const normalizedRole = role.trim().toLowerCase();
  if (!ALLOWED_ROLES.has(normalizedRole)) {
    throw new HttpsError(
      "invalid-argument",
      `Invalid role. Allowed roles: ${[...ALLOWED_ROLES].join(", ")}`,
    );
  }

  if (clubs !== undefined) {
    if (!Array.isArray(clubs) || !clubs.every((c) => typeof c === "string")) {
      throw new HttpsError(
        "invalid-argument",
        "If provided, 'clubs' must be an array of club id strings",
      );
    }
  }

  try {
    const claims = {role: normalizedRole};
    let mergedClubs = [];

    if (normalizedRole === "club admin") {
      const userDoc = await admin.firestore().collection("users").doc(uid).get();
      const existing =
        userDoc.exists &&
        userDoc.data() &&
        Array.isArray(userDoc.data().clubsAdminOf) ? userDoc.data().clubsAdminOf : [];
      const newClubs = Array.isArray(clubs) ? clubs : [];
      const set = new Set([...(existing || []), ...newClubs]);
      mergedClubs = Array.from(set);
      claims.clubsAdminOf = mergedClubs;
    }

    const userUpdate = {role: normalizedRole};
    if (normalizedRole === "club admin") {
      userUpdate.clubsAdminOf = mergedClubs;
    } else {
      userUpdate.clubsAdminOf = [];
    }

    await Promise.all([
      admin.auth().setCustomUserClaims(uid, claims),
      admin
        .firestore()
        .collection("users")
        .doc(uid)
        .set(userUpdate, {merge: true}),
    ]);

    return {
      success: true,
      message: `User ${uid} is now a ${normalizedRole}`,
      clubs: userUpdate.clubsAdminOf,
    };
  } catch (error) {
    console.error("Error setting custom claim:", error);
    throw new HttpsError("internal", error.message || "Internal server error");
  }
});

exports.approveClubEvent = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "Request not authenticated",
    );
  }

  const callerClaims = request.auth.token || {};
  if (callerClaims.role !== "admin") {
    throw new HttpsError(
      "permission-denied",
      "Only admins can approve events",
    );
  }

  const requestId = request.data.requestId;
  if (!requestId) {
    throw new HttpsError(
      "invalid-argument",
      "requestId is required",
    );
  }

  const db = admin.firestore();
  const reqRef = db.collection("clubEventRequests").doc(requestId);
  const reqSnap = await reqRef.get();

  if (!reqSnap.exists) {
    throw new HttpsError("not-found", "Request not found");
  }

  const reqData = reqSnap.data() || {};
  const eventDoc = {
    company: reqData.clubName || "",
    eventName: reqData.eventName || "",
    startTime:
      reqData.startTime || admin.firestore.FieldValue.serverTimestamp(),
    endTime:
      reqData.endTime ||
      reqData.startTime ||
      admin.firestore.FieldValue.serverTimestamp(),
    mainLocation: reqData.eventLocation || "",
    eventType: ("club").toString().trim().toLowerCase(),
    logo: reqData.logoUrl || reqData.logo || "",
    Status: "approved",
    description: reqData.description || "",
    submittedBy: {
      uid: reqData.requestedByUid || null,
      name: reqData.requestedByName || null,
      email: reqData.requestedByEmail || null,
    },
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  try {
    const newEventRef = await db.collection("events").add(eventDoc);
    await reqRef.delete();
    return {success: true, eventId: newEventRef.id};
  } catch (err) {
    console.error("approveClubEvent error", err);
    throw new HttpsError(
      "internal",
      "Failed to approve request",
    );
  }
});

exports.denyClubEvent = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "Request not authenticated",
    );
  }

  const callerClaims = request.auth.token || {};
  if (callerClaims.role !== "admin") {
    throw new HttpsError(
      "permission-denied",
      "Only admins can deny events",
    );
  }

  const requestId = request.data.requestId;
  const reason = request.data.reason || "";
  if (!requestId) {
    throw new HttpsError(
        "invalid-argument",
        "requestId is required",
    );
  }

  const db = admin.firestore();
  const reqRef = db.collection("clubEventRequests").doc(requestId);
  const reqSnap = await reqRef.get();

  if (!reqSnap.exists) {
    throw new HttpsError("not-found", "Request not found");
  }

  try {
    await reqRef.update({
      status: "denied",
      reviewedBy: request.auth.uid || null,
      reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
      adminComment: reason,
    });
    return {success: true};
  } catch (err) {
    console.error("denyClubEvent error", err);
    throw new HttpsError("internal", "Failed to deny request");
  }
});

exports.sendNotificationOnCreate = onDocumentCreated("notifications/{notificationId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) {
    console.log("No data associated with the event");
    return;
  }

  const notification = snapshot.data();
  const uid = notification.uid;
  
  if (!uid) {
    console.error("No uid found in notification document");
    return;
  }

  try {
    const tokensSnapshot = await admin.firestore()
      .collection("users")
      .doc(uid)
      .collection("fcmTokens")
      .get();

    if (tokensSnapshot.empty) {
      console.log("No FCM tokens found for user:", uid);
      return;
    }

    const tokens = tokensSnapshot.docs.map(doc => doc.data().token);

    const message = {
      notification: {
        title: notification.title || "New Notification",
        body: notification.message || "",
      },
      data: {
        notificationId: event.params.notificationId,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      tokens: tokens,
    };

    const response = await admin.messaging().sendMulticast(message);

    if (response.failureCount > 0) {
      const invalidTokens = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          invalidTokens.push(tokens[idx]);
        }
      });

      const deletePromises = invalidTokens.map(token => {
        return admin.firestore()
          .collection("users")
          .doc(uid)
          .collection("fcmTokens")
          .where("token", "==", token)
          .get()
          .then(querySnapshot => {
            const batch = admin.firestore().batch();
            querySnapshot.forEach(doc => {
              batch.delete(doc.ref);
            });
            return batch.commit();
          });
      });

      await Promise.all(deletePromises);
      console.log(`Removed ${invalidTokens.length} invalid tokens`);
    }

    console.log(`Successfully sent notifications to ${response.successCount} devices`);
    
  } catch (error) {
    console.error("Error sending notification:", error);
  }
});
