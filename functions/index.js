const admin = require("firebase-admin");

admin.initializeApp();

const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {onDocumentCreated, onDocumentWritten} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");

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

  const targetType = notification.targetType || (notification.uid ? "user" : null);
  const targetId = notification.targetId || notification.uid || null;
  const sendAt = notification.sendAt || null;

  if (sendAt && sendAt.toMillis && sendAt.toMillis() > Date.now()) {
    await snapshot.ref.set({status: "pending"}, {merge: true});
    console.log(`Notification ${event.params.notificationId} scheduled for ${sendAt.toDate()}`);
    return;
  }

  try {
    let targetUids = [];
    if (targetType === "user") {
      if (!targetId) {
        console.error("No targetId/uid for user-targeted notification");
        return;
      }
      targetUids = [targetId];
    } else if (targetType === "club") {
      if (!targetId) {
        console.error("No targetId/clubId for club-targeted notification");
        return;
      }
      const membersSnap = await admin.firestore().collection("clubs").doc(targetId).collection("members").get();
      targetUids = membersSnap.docs.map((d) => d.id || (d.data() && d.data().uid)).filter(Boolean);
    } else if (targetType === "event") {
      if (!targetId) {
        console.error("No targetId/eventId for event-targeted notification");
        return;
      }
      const attendingSnap = await admin.firestore().collection("events").doc(targetId).collection("attending").get();
      targetUids = attendingSnap.docs.map((d) => d.id || (d.data() && d.data().uid)).filter(Boolean);
    } else if (targetType === "broadcast") {
      const usersSnap = await admin.firestore().collection("users").get();
      targetUids = usersSnap.docs.map((d) => d.id).filter(Boolean);
    } else {
      console.error("Unknown targetType for notification:", targetType);
      return;
    }

    if (!targetUids.length) {
      console.log("No target uids found for notification", event.params.notificationId);
      await snapshot.ref.set({status: "no-targets"}, {merge: true});
      return;
    }

    const tokens = await collectTokensForUids(targetUids);
    if (!tokens.length) {
      console.log("No FCM tokens found for target uids");
      await snapshot.ref.set({status: "no-tokens"}, {merge: true});
      return;
    }

    const payload = {
      notification: {
        title: notification.title || notification.eventName || "CCCE Notification",
        body: notification.message || notification.body || notification.description || "",
      },
      data: {
        notificationId: event.params.notificationId,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
    };

    const {sent, failed, invalidTokenMap} =
      await sendMulticastBatched(tokens, payload);
    await snapshot.ref.set({
      status: "sent",
      sent,
      failed,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});

    await pruneInvalidTokensMap(invalidTokenMap);
    console.log(
        `Notification ${event.params.notificationId} sent.` +
        ` success=${sent} failed=${failed}`,
    );
  } catch (error) {
    console.error("Error sending notification:", error);
    await snapshot.ref.set({status: "error", error: String(error)}, {merge: true});
  }
});

exports.sendTestNotification = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated to call this function");
  }

  const {uid, title, message} = request.data || {};
  if (!uid || typeof uid !== "string") {
    throw new HttpsError("invalid-argument", "Must provide a valid uid");
  }

  try {
    const tokensSnapshot = await admin.firestore()
      .collection("users")
      .doc(uid)
      .collection("fcmTokens")
      .get();

    if (tokensSnapshot.empty) {
      return {success: false, message: "No tokens found for user"};
    }

    const tokens = tokensSnapshot.docs.map((d) => d.data().token).filter((t) => !!t);

    const payload = {
      notification: {
        title: title || "Test Notification",
        body: message || "This is a test notification from CCCE app",
      },
      data: {test: "true"},
      tokens: tokens,
    };

    const response = await admin.messaging().sendMulticast(payload);

    if (response.failureCount > 0) {
      const invalidTokens = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          invalidTokens.push(tokens[idx]);
        }
      });

      const deletePromises = invalidTokens.map((token) => {
        return admin.firestore()
          .collection("users")
          .doc(uid)
          .collection("fcmTokens")
          .where("token", "==", token)
          .get()
          .then((querySnapshot) => {
            const batch = admin.firestore().batch();
            querySnapshot.forEach((doc) => batch.delete(doc.ref));
            return batch.commit();
          });
      });
      await Promise.all(deletePromises);
    }

    return {success: true, sent: response.successCount, failed: response.failureCount};
  } catch (err) {
    console.error("sendTestNotification error", err);
    throw new HttpsError("internal", err.message || "Internal error");
  }
});
async function collectTokensForUids(uids) {
  const tokenPairs = [];
  await Promise.all(uids.map(async (uid) => {
    try {
      const snap = await admin.firestore().collection("users").doc(uid).collection("fcmTokens").get();
      snap.forEach((d) => {
        const t = d.data() && d.data().token;
        if (t) tokenPairs.push({uid, token: t});
      });
    } catch (err) {
      console.error("Error collecting tokens for uid", uid, err);
    }
  }));
  const seen = new Set();
  const dedup = [];
  tokenPairs.forEach(({uid, token}) => {
    if (!seen.has(token)) {
      seen.add(token);
      dedup.push({uid, token});
    }
  });
  return dedup;
}

async function sendMulticastBatched(tokenPairs, payloadBase) {
  const tokens = tokenPairs.map((tp) => tp.token);
  const BATCH_SIZE = 500;
  let sent = 0; let failed = 0;
  const invalidTokenMap = {};

  for (let i = 0; i < tokens.length; i += BATCH_SIZE) {
    const batchTokens = tokens.slice(i, i + BATCH_SIZE);
    const payload = Object.assign({}, payloadBase, {tokens: batchTokens});
    try {
      const resp = await admin.messaging().sendMulticast(payload);
      sent += resp.successCount;
      failed += resp.failureCount;
      if (resp.failureCount > 0) {
        resp.responses.forEach((r, idx) => {
          if (!r.success) {
            const badToken = batchTokens[idx];
            tokenPairs.forEach((tp) => {
              if (tp.token === badToken) {
                invalidTokenMap[tp.uid] = invalidTokenMap[tp.uid] || [];
                invalidTokenMap[tp.uid].push(badToken);
              }
            });
          }
        });
      }
    } catch (err) {
      console.error("sendMulticast error for batch", err);
      failed += batchTokens.length;
    }
  }
  return {sent, failed, invalidTokenMap};
}

async function pruneInvalidTokensMap(map) {
  const promises = Object.keys(map).map(async (uid) => {
    const tokens = map[uid] || [];
    if (!tokens.length) return;
    try {
      const deletes = [];
      for (const token of tokens) {
        const q = await admin.firestore()
            .collection("users").doc(uid).collection("fcmTokens")
            .where("token", "==", token)
            .get();
        const batch = admin.firestore().batch();
        q.forEach((d) => batch.delete(d.ref));
        deletes.push(batch.commit());
      }
      await Promise.all(deletes);
    } catch (err) {
      console.error("Error pruning tokens for uid", uid, err);
    }
  });
  await Promise.all(promises);
}

exports.cleanupOldNotifications = onSchedule("every 24 hours", async () => {
  console.log("Scheduled run: cleaning up old notifications");
  const db = admin.firestore();
  try {
    const threeDaysAgo = admin.firestore.Timestamp.fromMillis(
        Date.now() - (3 * 24 * 60 * 60 * 1000),
    );

    const oldNotifications = await db.collection("notifications")
      .where("status", "in", ["sent", "failed"])
      .where("createdAt", "<", threeDaysAgo)
      .limit(500)
      .get();

    if (oldNotifications.empty) {
      console.log("No old notifications to clean up");
      return;
    }

    const batch = db.batch();
    let deleteCount = 0;

    oldNotifications.docs.forEach((doc) => {
      batch.delete(doc.ref);
      deleteCount++;
    });

    await batch.commit();
    console.log(`Cleaned up ${deleteCount} old notifications`);
  } catch (err) {
    console.error("Error cleaning up old notifications:", err);
  }
});

exports.processPendingNotifications = onSchedule("every 15 minutes", async (event) => {
  console.log("Scheduled run: processing pending notifications");
  const db = admin.firestore();
  const now = admin.firestore.Timestamp.fromMillis(Date.now());
  try {
    const q = await db.collection("notifications")
        .where("status", "==", "pending")
        .where("sendAt", "<=", now)
        .limit(50)
        .get();
    if (q.empty) {
      console.log("No pending notifications ready to send");
      return;
    }
    const sends = [];
    q.forEach((doc) => {
      sends.push(sendNotificationDocNow(doc));
    });
    await Promise.all(sends);
  } catch (err) {
    console.error("Error in scheduled processing", err);
  }
});

exports.scheduleEventReminder = onDocumentCreated("events/{eventId}", async (event) => {
  const snap = event.data;
  if (!snap) return;

  const eventData = snap.data() || {};
  const eventId = event.params.eventId;
  const startTime = eventData.startTime;

  if (!startTime || !startTime.toMillis || typeof startTime.toMillis !== "function") {
    console.log(`Event ${eventId} has invalid startTime, skipping reminder`);
    return;
  }

  try {
    const startMillis = startTime.toMillis();
    const now = Date.now();

    if (startMillis <= now + (60 * 60 * 1000)) {
      console.log(`Event ${eventId} starts too soon or in past, skipping reminder`);
      return;
    }

    const sendAtMillis = startMillis - (60 * 60 * 1000);

    const existingReminders = await admin.firestore()
      .collection("notifications")
      .where("targetType", "==", "event")
      .where("targetId", "==", eventId)
      .where("createdBy", "==", "system")
      .where("status", "==", "pending")
      .get();

    if (!existingReminders.empty) {
      console.log(
          `Reminder already exists for event ${eventId}, skipping`,
      );
      return;
    }

    const notification = {
      targetType: "event",
      targetId: eventId,
      title: `${eventData.eventName || "Upcoming Event"} starts in 1 hour`,
      message: `${eventData.eventName || "Event"} at ` +
        `${eventData.mainLocation || "TBD"}. ` +
        `${eventData.description || ""}`.trim(),
      sendAt: admin.firestore.Timestamp.fromMillis(sendAtMillis),
      createdBy: "system",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      status: "pending",
      eventData: {
        eventId: eventId,
        eventName: eventData.eventName,
        startTime: startTime,
        location: eventData.mainLocation,
      },
    };

    await admin.firestore().collection("notifications").add(notification);
    console.log(
        `Scheduled reminder for event ${eventId} (${eventData.eventName})` +
        ` at ${new Date(sendAtMillis).toISOString()}`,
    );
  } catch (err) {
    console.error(`Error scheduling reminder for event ${eventId}:`, err);
  }
});

async function sendNotificationDocNow(docSnapshot) {
  const notification = docSnapshot.data();
  if (!notification) return;
  try {
    const targetType = notification.targetType || (notification.uid ? "user" : null);
    const targetId = notification.targetId || notification.uid || null;

    let targetUids = [];
    if (targetType === "user") {
      targetUids = [targetId];
    } else if (targetType === "club") {
      const membersSnap = await admin.firestore().collection("clubs").doc(targetId).collection("members").get();
      targetUids = membersSnap.docs.map((d) => d.id || (d.data() && d.data().uid)).filter(Boolean);
    } else if (targetType === "event") {
      const attendingSnap = await admin.firestore().collection("events").doc(targetId).collection("attending").get();
      targetUids = attendingSnap.docs.map((d) => d.id || (d.data() && d.data().uid)).filter(Boolean);
    } else if (targetType === "broadcast") {
      const usersSnap = await admin.firestore().collection("users").get();
      targetUids = usersSnap.docs.map((d) => d.id).filter(Boolean);
    }

    if (!targetUids.length) {
      await docSnapshot.ref.set({status: "no-targets"}, {merge: true});
      return;
    }

    const tokenPairs = await collectTokensForUids(targetUids);
    if (!tokenPairs.length) {
      await docSnapshot.ref.set({status: "no-tokens"}, {merge: true});
      return;
    }

    const payload = {
      notification: {
        title: notification.title || notification.eventName || "CCCE Notification",
        body: notification.message || notification.body || notification.description || "",
      },
      data: {
        notificationId: docSnapshot.id,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
    };

    const {sent, failed, invalidTokenMap} =
      await sendMulticastBatched(tokenPairs, payload);
    await docSnapshot.ref.set({
      status: "sent",
      sent,
      failed,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});
    await pruneInvalidTokensMap(invalidTokenMap);
  } catch (err) {
    console.error("Error sending scheduled notification", err);
    await docSnapshot.ref.set({status: "error", error: String(err)}, {merge: true});
  }
}

exports.sendBroadcastNotification = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated to call this function");
  }
  const callerUid = request.auth.uid;
  const callerRecord = await admin.auth().getUser(callerUid);
  const callerRole = (callerRecord.customClaims && callerRecord.customClaims.role);
  if (callerRole !== "admin") {
    throw new HttpsError("permission-denied", "Only admins can send broadcast notifications");
  }

  const {title, message, sendAt} = request.data || {};
  if (!title || !message) {
    throw new HttpsError("invalid-argument", "Must provide title and message");
  }

  const docRef = await admin.firestore().collection("notifications").add({
    targetType: "broadcast",
    title,
    message,
    sendAt: sendAt || admin.firestore.FieldValue.serverTimestamp(),
    createdBy: callerUid,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return {success: true, notificationId: docRef.id};
});

exports.setEventUpdatedAt = onDocumentWritten("events/{eventId}", async (event) => {
  const afterSnap = event.data.after;
  if (!afterSnap || !afterSnap.exists) {
    return;
  }

  const data = afterSnap.data();
  const now = admin.firestore.Timestamp.now();
  const existing = data.updatedAt;

  if (existing && existing.toMillis && (now.toMillis() - existing.toMillis()) < 5000) {
    return;
  }

  try {
    await afterSnap.ref.set({
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});
    console.log(`Set updatedAt for event ${event.params.eventId}`);
  } catch (err) {
    console.error(`Error setting updatedAt for event ${event.params.eventId}:`, err);
  }
});
