const admin = require("firebase-admin");

admin.initializeApp();

const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {onDocumentCreated, onDocumentWritten} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {user} = require("firebase-functions/v1/auth");

const ALLOWED_ROLES = new Set(["student", "faculty", "club admin", "admin", "recruiter"]);

// Clean up all user data when their account is deleted
exports.onUserDeleted = user().onDelete(async (userRecord) => {
  const uid = userRecord.uid;
  if (!uid) {
    console.log("No UID provided for user deletion");
    return;
  }

  console.log(`Cleaning up data for deleted user: ${uid}`);
  const db = admin.firestore();

  try {
    // 1. Delete user document and subcollections
    const userDocRef = db.collection("users").doc(uid);
    const subcollections = ["checkedInEvents", "fcmTokens", "favoriteCompanies", "joinedClubs"];

    for (const subcol of subcollections) {
      const snapshot = await userDocRef.collection(subcol).get();
      const batch = db.batch();
      snapshot.docs.forEach((doc) => batch.delete(doc.ref));
      if (!snapshot.empty) {
        await batch.commit();
        console.log(`Deleted ${snapshot.size} docs from users/${uid}/${subcol}`);
      }
    }

    await userDocRef.delete();
    console.log(`Deleted user document: ${uid}`);

    // 2. Remove user from all club memberships
    const clubMemberships = await db.collectionGroup("members").where("uid", "==", uid).get();
    if (!clubMemberships.empty) {
      const batch = db.batch();
      clubMemberships.docs.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
      console.log(`Removed user from ${clubMemberships.size} club memberships`);
    }

    // 3. Remove user from all event attendance records
    const eventAttendance = await db.collectionGroup("attending").where("uid", "==", uid).get();
    if (!eventAttendance.empty) {
      const batch = db.batch();
      eventAttendance.docs.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
      console.log(`Removed user from ${eventAttendance.size} event attendance records`);
    }

    // 4. Delete notifications targeted at this user
    const userNotifications = await db.collection("notifications")
      .where("targetType", "==", "user")
      .where("targetId", "==", uid)
      .get();
    if (!userNotifications.empty) {
      const batch = db.batch();
      userNotifications.docs.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
      console.log(`Deleted ${userNotifications.size} notifications for user`);
    }

    // 5. Delete profile picture from Storage
    try {
      const bucket = admin.storage().bucket();
      await bucket.file(`profile_pictures/${uid}.jpg`).delete();
      console.log(`Deleted profile picture for user ${uid}`);
    } catch (storageErr) {
      // Profile picture might not exist
      console.log(`No profile picture to delete for user ${uid}`);
    }

    console.log(`Successfully cleaned up all data for user: ${uid}`);
  } catch (err) {
    console.error(`Error cleaning up user ${uid}:`, err);
    // Don't throw - allow the deletion to proceed even if cleanup fails
  }
});

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

    const promises = [
      admin.auth().setCustomUserClaims(uid, claims),
      admin
        .firestore()
        .collection("users")
        .doc(uid)
        .set(userUpdate, {merge: true}),
    ];

    // If making someone a club admin, also add them as members of those clubs
    if (normalizedRole === "club admin" && mergedClubs.length > 0) {
      // Get user's name from users collection
      const userDocSnap = await admin.firestore().collection("users").doc(uid).get();
      const userData = userDocSnap.data() || {};
      const userName = userData.name || `${userData.firstName || ""} ${userData.lastName || ""}`.trim() || "Unknown";

      for (const clubId of mergedClubs) {
        promises.push(
          admin
            .firestore()
            .collection("clubs")
            .doc(clubId)
            .collection("members")
            .doc(uid)
            .set({
              uid: uid,
              name: userName,
              joinedAt: admin.firestore.FieldValue.serverTimestamp(),
              isAdmin: true,
            }, {merge: true}),
        );
      }
    }

    await Promise.all(promises);

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
  const clubId = reqData.clubId || null;
  const eventDoc = {
    company: reqData.clubName || "",
    clubId: clubId,
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
    recurrenceType: reqData.recurrenceType || "Never",
    recurrenceInterval: reqData.recurrenceInterval || null,
    recurrenceEndDate: reqData.recurrenceEndDate || null,
    submittedBy: {
      uid: reqData.requestedByUid || null,
      name: reqData.requestedByName || null,
      email: reqData.requestedByEmail || null,
    },
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  try {
    // // Create a new doc with a generated id so we can include the id as a field on the document
    // const newEventRef = db.collection("events").doc();
    // await newEventRef.set({...eventDoc, eventId: newEventRef.id});
    const newEventRef = await db.collection("events").add(eventDoc);

    console.log(`✅ Created event ${newEventRef.id} for club ${clubId}`);

    // Add event reference to club's events array if clubId exists
    if (clubId) {
      const clubRef = db.collection("clubs").doc(clubId);
      const clubSnap = await clubRef.get();

      if (clubSnap.exists) {
        console.log(`✅ Club ${clubId} exists, adding event to array`);

        // Get the club's logo to use for the event
        const clubData = clubSnap.data() || {};
        const clubLogo = clubData.logo || "";

        // Update event with club logo if not already set
        if (!eventDoc.logo && clubLogo) {
          await newEventRef.update({logo: clubLogo});
        }

        // Add document reference to club's events array (lowercase 'events')
        await clubRef.update({
          events: admin.firestore.FieldValue.arrayUnion(newEventRef),
        });

        console.log(`✅ Added event ${newEventRef.id} to club ${clubId} events array`);
      } else {
        console.warn(`⚠️ Club ${clubId} does not exist, cannot add event to array`);
      }
    } else {
      console.warn(`⚠️ No clubId provided, cannot add event to club array`);
    }

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

  if (sendAt && sendAt.toMillis() && sendAt.toMillis() > Date.now()) {
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
    } else if (targetType === "clubEvent") {
      if (!targetId) {
        console.error("No targetId/eventId for clubEvent-targeted notification");
        return;
      }
      // For club events, get the clubId from the event and notify all club members
      const eventSnap = await admin.firestore().collection("events").doc(targetId).get();
      if (!eventSnap.exists) {
        console.error("Event not found for clubEvent notification:", targetId);
        return;
      }
      const eventData = eventSnap.data();
      const clubId = eventData.clubId;
      if (!clubId) {
        console.error("No clubId found for clubEvent:", targetId);
        return;
      }
      const membersSnap = await admin.firestore().collection("clubs").doc(clubId).collection("members").get();
      targetUids = membersSnap.docs.map((d) => d.id || (d.data() && d.data().uid)).filter(Boolean);
    } else if (targetType === "infoSession") {
      if (!targetId) {
        console.error("No targetId/eventId for infoSession-targeted notification");
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

exports.notifyOnClubJoin = onDocumentCreated("clubs/{clubId}/members/{uid}", async (event) => {
  const {clubId, uid} = event.params || {};
  if (!clubId || !uid) return;
  try {
    const clubSnap = await admin.firestore().collection("clubs").doc(clubId).get();
    const clubData = clubSnap.exists ? (clubSnap.data() || {}) : {};
    const clubName = clubData.Name || clubData.name || clubData.Acronym || "club";

    await admin.firestore().collection("notifications").add({
      targetType: "user",
      targetId: uid,
      title: "Joined club",
      message: `You joined ${clubName}.`,
      createdBy: "system",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (err) {
    console.error("notifyOnClubJoin error", err);
  }
});

exports.notifyOnEventCheckIn = onDocumentCreated("events/{eventId}/attending/{uid}", async (event) => {
  const {eventId, uid} = event.params || {};
  if (!eventId || !uid) return;
  try {
    const eventSnap = await admin.firestore().collection("events").doc(eventId).get();
    const eventData = eventSnap.exists ? (eventSnap.data() || {}) : {};
    const eventName = eventData.eventName || eventData.company || "event";

    await admin.firestore().collection("notifications").add({
      targetType: "user",
      targetId: uid,
      title: "Checked in",
      message: `You're checked in to ${eventName}.`,
      createdBy: "system",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (err) {
    console.error("notifyOnEventCheckIn error", err);
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
      const resp = await admin.messaging().sendEachForMulticast(payload);
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
      console.error("sendEachForMulticast error for batch", err);
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

exports.cleanupStaleFcmTokens = onSchedule("every 24 hours", async () => {
  console.log("Scheduled run: cleaning stale FCM tokens");
  const db = admin.firestore();
  const ninetyDaysAgo = admin.firestore.Timestamp.fromMillis(
      Date.now() - (90 * 24 * 60 * 60 * 1000),
  );

  let deleted = 0;
  let batches = 0;

  try {
    for (let i = 0; i < 10; i++) {
      const snap = await db.collectionGroup("fcmTokens")
        .where("createdAt", "<", ninetyDaysAgo)
        .limit(500)
        .get();

      if (snap.empty) break;

      const batch = db.batch();
      snap.docs.forEach((doc) => {
        batch.delete(doc.ref);
        deleted++;
      });
      await batch.commit();
      batches++;
    }

    console.log(`Stale FCM token cleanup complete: deleted=${deleted} batches=${batches}`);
  } catch (err) {
    console.error("Error cleaning stale FCM tokens:", err);
  }
});

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

exports.processPendingNotifications = onSchedule("every 5 minutes", async (event) => {
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
    q.forEach(async (doc) => {
      if (doc.data().eventData.recurrenceType && doc.data().eventData.recurrenceType !== "Never") {
            sends.push(scheduleRecurringEventNotification(doc));
      }
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

  if (!startTime || !startTime.toMillis() || typeof startTime.toMillis !== "function") {
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

    const eventType = eventData.eventType || "infoSession";
    const targetType = (eventType === "club") ? "clubEvent" : "infoSession";

    const existingReminders = await admin.firestore()
      .collection("notifications")
      .where("targetType", "==", targetType)
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

    const eventName = eventData.eventName || eventData.company || "Upcoming Event";
    const eventLocation = eventData.mainLocation || "No Listed Location";
    const eventDescription = eventData.description || "";

    const notification = {
      targetType: targetType,
      targetId: eventId,
      title: `${eventName} starts in 1 hour`,
      message: `${eventName} at ${eventLocation}. ${eventDescription}`.trim(),
      sendAt: admin.firestore.Timestamp.fromMillis(sendAtMillis),
      createdBy: "system",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      status: "pending",
      eventData: {
        eventId: eventId,
        eventName: eventName,
        company: eventData.company || null,
        startTime: startTime,
        location: eventLocation,
        recurrenceInterval: eventData.recurrenceInterval || null,
        recurrenceEndDate: eventData.recurrenceEndDate || null,
      },
    };

    await admin.firestore().collection("notifications").add(notification);
    console.log(
        `Scheduled reminder for event ${eventId} (${eventName})` +
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
    } else if (targetType === "clubEvent") {
      // For club events, get the clubId from the event and notify all club members
      const eventSnap = await admin.firestore().collection("events").doc(targetId).get();
      if (eventSnap.exists) {
        const eventData = eventSnap.data();
        const clubId = eventData.clubId;
        if (clubId) {
          const membersSnap = await admin.firestore().collection("clubs").doc(clubId).collection("members").get();
          targetUids = membersSnap.docs.map((d) => d.id || (d.data() && d.data().uid)).filter(Boolean);
        }
      }
    } else if (targetType === "infoSession") {
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

function computeNextOccurrence(ev, currentStart) {
  const recurrenceType = (ev.recurrenceType || "").toString();
  if (!recurrenceType || recurrenceType === "Never") return null;


  // Interval (days)
  if (recurrenceType === "Interval (days)") {
    const intervalDays = parseInt(ev.recurrenceInterval) || 1;
    const nextDate = new Date(currentStart);
    nextDate.setDate(nextDate.getDate() + intervalDays);
    return nextDate;
  }


  // Weekly: either specific weekdays in recurrenceDays or weekly intervals
  if (recurrenceType === "Weekly") {
    const daysRaw = ev.recurrenceDays;
    let days = null;
    if (Array.isArray(daysRaw)) {
      days = daysRaw.map((d) => parseInt(d)).filter((n) => !Number.isNaN(n));
    }


    if (days && days.length > 0) {
      // Search up to 4 weeks ahead for the next matching weekday
      let dt = new Date(currentStart.getTime() + 24 * 60 * 60 * 1000);
      for (let i = 0; i < 28; i++) {
        const w = dt.getDay(); // 0=Sun..6=Sat
        if (days.includes(w)) return dt;
        dt = new Date(dt.getTime() + 24 * 60 * 60 * 1000);
      }
      return null;
    }


    const weeks = parseInt(ev.recurrenceInterval) || 1;
    return new Date(currentStart.getTime() + weeks * 7 * 24 * 60 * 60 * 1000);
  }


  // Monthly: advance by recurrenceInterval months and try to keep the same day-of-month
  if (recurrenceType === "Monthly") {
    const intervalMonths = parseInt(ev.recurrenceInterval) || 1;
    const dayOfMonth = parseInt(ev.recurrenceInterval) || currentStart.getDate();


    let dt = new Date(currentStart.getTime());
    dt.setMonth(dt.getMonth() + intervalMonths);
    dt.setDate(dayOfMonth);


    // If result is not after currentStart, advance again
    if (dt <= currentStart) {
      dt = new Date(currentStart.getTime());
      dt.setMonth(dt.getMonth() + intervalMonths);
      dt.setDate(dayOfMonth);
    }


    // If dayOfMonth doesn't exist in that month (Date rolls), try the next several months
    if (dt.getDate() !== dayOfMonth) {
      for (let i = 0; i < 12; i++) {
        dt.setMonth(dt.getMonth() + 1);
        dt.setDate(dayOfMonth);
        if (dt.getDate() === dayOfMonth) return dt;
      }
      return null;
    }


    return dt;
  }


  return null;
}


async function scheduleRecurringEventNotification(notificationDoc) {
  // Pre-schedule the next occurrence (idempotent)
  const notificationData = notificationDoc.data() || {};
  const eventData = notificationData.eventData || {};
  if (!eventData.recurrenceInterval) return;


  const currentStartTs = eventData.startTime;
  let currentStart = null;
  if (currentStartTs) {
    currentStart = currentStartTs.toDate ? currentStartTs.toDate() : new Date(currentStartTs);
    // currentStart = currentStartTs.toMillis();
  }
  if (!currentStart) return;


  const eventId = eventData.eventId || notificationData.targetId || notificationData.targetId;
  if (!eventId) return;


  try {
    const eventSnap = await admin.firestore().collection("events").doc(eventId).get();
    if (!eventSnap.exists) return;
    const ev = eventSnap.data() || {};


    const nextStart = computeNextOccurrence(ev, currentStart);
    if (!nextStart) return;


    const recurrenceEndTs = ev.recurrenceEndDate;
    if (recurrenceEndTs && recurrenceEndTs.toMillis() && nextStart.getTime() > recurrenceEndTs.toMillis()) return;


    const sendAt = new Date(nextStart.getTime() - (60 * 60 * 1000));
    if (sendAt.getTime() <= Date.now()) return;

    // Avoid duplicates
    const eventType = ev.eventType || "infoSession";
    const targetType = (eventType === "club") ? "clubEvent" : "infoSession";

    const existing = await admin.firestore().collection("notifications")
      .where("targetType", "==", targetType)
      .where("targetId", "==", eventId)
      .where("createdBy", "==", "system")
      .where("status", "==", "pending")
      .where("sendAt", "==", admin.firestore.Timestamp.fromDate(sendAt))
      .limit(1)
      .get();

    if (!existing.empty) return;

    const eventName = ev.eventName || ev.company || "Upcoming Event";
    const eventLocation = ev.mainLocation || "No Listed Location";
    const eventDescription = ev.description || "";

    const notification = {
      targetType: targetType,
      targetId: eventId,
      title: `${eventName} starts in 1 hour`,
      message: `${eventName} at ${eventLocation}. ${eventDescription}`.trim(),
      sendAt: admin.firestore.Timestamp.fromDate(sendAt),
      createdBy: "system",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      status: "pending",
      eventData: {
        eventId: eventId,
        eventName: eventName,
        company: ev.company || null,
        startTime: admin.firestore.Timestamp.fromDate(nextStart),
        location: eventLocation,
        recurrenceInterval: ev.recurrenceInterval || null,
        recurrenceEndDate: ev.recurrenceEndDate || null,
      },
    };

    await admin.firestore().collection("notifications").add(notification);
    console.log(`Pre-scheduled next recurring reminder for event ${eventId} at ${sendAt.toISOString()}`);
  } catch (err) {
    console.error("Error in pre-scheduling recurring notification:", err);
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

exports.backfillNotificationIndexes = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const callerUid = request.auth.uid;
  const callerRecord = await admin.auth().getUser(callerUid);
  const callerRole = (callerRecord.customClaims && callerRecord.customClaims.role);

  if (callerRole !== "admin") {
    throw new HttpsError("permission-denied", "Only admins can run backfill");
  }

  const db = admin.firestore();
  const usersSnap = await db.collection("users").get();

  let joinedClubsBackfilled = 0;
  let checkedInBackfilled = 0;
  let batchesCommitted = 0;
  let batch = db.batch();
  let ops = 0;

  const commitIfNeeded = async (force = false) => {
    if (ops === 0) return;
    if (ops >= 400 || force) {
      await batch.commit();
      batchesCommitted++;
      batch = db.batch();
      ops = 0;
    }
  };

  for (const userDoc of usersSnap.docs) {
    const uid = userDoc.id;
    const userData = userDoc.data() || {};
    const userName = userData.name || `${userData.firstName || ""} ${userData.lastName || ""}`.trim() || userData.email || "Unknown";

    const joinedClubsSnap = await db.collection("users").doc(uid).collection("joinedClubs").get();
    for (const clubDoc of joinedClubsSnap.docs) {
      const clubId = clubDoc.id;
      const joinedData = clubDoc.data() || {};
      const memberRef = db.collection("clubs").doc(clubId).collection("members").doc(uid);
      batch.set(memberRef, {
        uid,
        name: userName,
        joinedAt: joinedData.joinedAt || admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});
      joinedClubsBackfilled++;
      ops++;
      await commitIfNeeded();
    }

    const checkedInSnap = await db.collection("users").doc(uid).collection("checkedInEvents").get();
    for (const eventDoc of checkedInSnap.docs) {
      const eventId = eventDoc.id;
      const checkedData = eventDoc.data() || {};
      const attendRef = db.collection("events").doc(eventId).collection("attending").doc(uid);
      batch.set(attendRef, {
        uid,
        checkedInAt: checkedData.checkedInAt || admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});
      checkedInBackfilled++;
      ops++;
      await commitIfNeeded();
    }
  }

  await commitIfNeeded(true);

  return {
    success: true,
    usersProcessed: usersSnap.size,
    joinedClubsBackfilled,
    checkedInBackfilled,
    batchesCommitted,
  };
});

exports.rebuildEventNotifications = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const callerUid = request.auth.uid;
  const callerRecord = await admin.auth().getUser(callerUid);
  const callerRole = (callerRecord.customClaims && callerRecord.customClaims.role);

  if (callerRole !== "admin") {
    throw new HttpsError("permission-denied", "Only admins can rebuild notifications");
  }

  const db = admin.firestore();
  let deletedCount = 0;
  let createdCount = 0;
  let skippedCount = 0;

  try {
    // Step 1: Delete all system-created event notifications
    const notificationsSnapshot = await db
      .collection("notifications")
      .where("createdBy", "==", "system")
      .get();

    if (!notificationsSnapshot.empty) {
      const batch = db.batch();
      notificationsSnapshot.docs.forEach((doc) => {
        batch.delete(doc.ref);
      });
      await batch.commit();
      deletedCount = notificationsSnapshot.size;
      console.log(`Deleted ${deletedCount} system notifications`);
    }

    // Step 2: Rebuild notifications for all future events
    const now = Date.now();
    const eventsSnapshot = await db.collection("events").get();

    for (const eventDoc of eventsSnapshot.docs) {
      const eventData = eventDoc.data() || {};
      const eventId = eventDoc.id;
      const startTime = eventData.startTime;

      if (!startTime || !startTime.toMillis || typeof startTime.toMillis !== "function") {
        console.log(`Event ${eventId} has invalid startTime, skipping`);
        skippedCount++;
        continue;
      }

      const startMillis = startTime.toMillis();

      // Skip events that have already passed or start too soon
      if (startMillis <= now + (60 * 60 * 1000)) {
        console.log(`Event ${eventId} starts too soon or in past, skipping`);
        skippedCount++;
        continue;
      }

      const sendAtMillis = startMillis - (60 * 60 * 1000);
      const eventType = eventData.eventType || "infoSession";
      const targetType = (eventType === "club") ? "clubEvent" : "infoSession";

      const eventName = eventData.eventName || eventData.company || "Upcoming Event";
      const eventLocation = eventData.mainLocation || "No Listed Location";
      const eventDescription = eventData.description || "";

      const notification = {
        targetType: targetType,
        targetId: eventId,
        title: `${eventName} starts in 1 hour`,
        message: `${eventName} at ${eventLocation}. ${eventDescription}`.trim(),
        sendAt: admin.firestore.Timestamp.fromMillis(sendAtMillis),
        createdBy: "system",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        status: "pending",
        eventData: {
          eventId: eventId,
          eventName: eventName,
          company: eventData.company || null,
          startTime: startTime,
          location: eventLocation,
          recurrenceInterval: eventData.recurrenceInterval || null,
          recurrenceEndDate: eventData.recurrenceEndDate || null,
        },
      };

      await db.collection("notifications").add(notification);
      createdCount++;
      console.log(`Created notification for event ${eventId} (${eventName})`);
    }

    return {
      success: true,
      deleted: deletedCount,
      created: createdCount,
      skipped: skippedCount,
      message: `Rebuilt notifications: deleted ${deletedCount}, created ${createdCount}, skipped ${skippedCount}`,
    };
  } catch (error) {
    console.error("Error rebuilding notifications:", error);
    throw new HttpsError("internal", error.message || "Internal server error");
  }
});

exports.analyzeEvents = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const callerUid = request.auth.uid;
  const callerRecord = await admin.auth().getUser(callerUid);
  const callerRole = (callerRecord.customClaims && callerRecord.customClaims.role);

  if (callerRole !== "admin") {
    throw new HttpsError("permission-denied", "Only admins can analyze events");
  }

  const db = admin.firestore();
  const now = Date.now();
  const oneHourFromNow = now + (60 * 60 * 1000);

  try {
    const eventsSnapshot = await db.collection("events").get();
    const analysis = {
      totalEvents: eventsSnapshot.size,
      invalidStartTime: 0,
      pastEvents: 0,
      withinOneHour: 0,
      futureEvents: 0,
      eventsList: [],
    };

    eventsSnapshot.docs.forEach((doc) => {
      const eventData = doc.data() || {};
      const eventId = doc.id;
      const startTime = eventData.startTime;
      const eventName = eventData.eventName || eventData.company || "Unnamed";

      if (!startTime || !startTime.toMillis || typeof startTime.toMillis !== "function") {
        analysis.invalidStartTime++;
        analysis.eventsList.push({
          id: eventId,
          name: eventName,
          status: "Invalid startTime",
          startTime: String(startTime),
        });
      } else {
        const startMillis = startTime.toMillis();
        const startDate = new Date(startMillis).toISOString();

        if (startMillis < now) {
          analysis.pastEvents++;
          analysis.eventsList.push({
            id: eventId,
            name: eventName,
            status: "Past event",
            startTime: startDate,
          });
        } else if (startMillis <= oneHourFromNow) {
          analysis.withinOneHour++;
          analysis.eventsList.push({
            id: eventId,
            name: eventName,
            status: "Within 1 hour",
            startTime: startDate,
          });
        } else {
          analysis.futureEvents++;
          analysis.eventsList.push({
            id: eventId,
            name: eventName,
            status: "Future (will get notification)",
            startTime: startDate,
          });
        }
      }
    });

    return analysis;
  } catch (error) {
    console.error("Error analyzing events:", error);
    throw new HttpsError("internal", error.message || "Internal server error");
  }
});

exports.setEventUpdatedAt = onDocumentWritten("events/{eventId}", async (event) => {
  const beforeSnap = event.data.before;
  const afterSnap = event.data.after;

  if (!afterSnap || !afterSnap.exists) {
    return;
  }

  // If this is a new document, skip (createdAt will be set by creator)
  if (!beforeSnap || !beforeSnap.exists) {
    return;
  }

  const beforeData = beforeSnap.data();
  const afterData = afterSnap.data();

  // Check if ONLY updatedAt changed - if so, don't trigger again (prevent infinite loop)
  const beforeCopy = {...beforeData};
  const afterCopy = {...afterData};
  delete beforeCopy.updatedAt;
  delete afterCopy.updatedAt;

  if (JSON.stringify(beforeCopy) === JSON.stringify(afterCopy)) {
    // Only updatedAt changed, skip to prevent infinite loop
    return;
  }

  // A meaningful field changed, update the timestamp
  try {
    await afterSnap.ref.update({
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log(`Set updatedAt for event ${event.params.eventId}`);
  } catch (err) {
    console.error(`Error setting updatedAt for event ${event.params.eventId}:`, err);
  }
});

exports.deleteClubEvent = onCall(async (request) => {
  console.log("DELETE FUNC CALLED - deleteClubEvent called with data:", request.data);
  if (!request.auth) {
    console.log("Unauthenticated request to deleteClubEvent ERRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR");
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const callerUid = request.auth.uid;
  const eventId = request.data.eventId;

  if (!eventId || typeof eventId !== "string") {
    throw new HttpsError("invalid-argument", "Must provide a valid eventId");
  }

  try {
    const db = admin.firestore();
    const eventRef = db.collection("events").doc(eventId);
    const eventSnap = await eventRef.get();

    if (!eventSnap.exists) {
      throw new HttpsError("not-found", "Event not found");
    }

    const eventData = eventSnap.data();
    console.log("Event data retrieved for deletion:", eventData);
    const clubId = eventData.clubId;

    if (!clubId) {
      throw new HttpsError("invalid-argument", "Event is not associated with a club");
    }

    // Verify caller is a club admin of this club or a system admin
    const callerRecord = await admin.auth().getUser(callerUid);
    const callerRole = (callerRecord.customClaims && callerRecord.customClaims.role);

    if (callerRole !== "admin") {
      // Check if user is club admin for this specific club
      const userDoc = await db.collection("users").doc(callerUid).get();
      const userData = userDoc.data() || {};
      const clubsAdminOf = userData.clubsAdminOf || [];

      if (!clubsAdminOf.includes(clubId)) {
        throw new HttpsError(
          "permission-denied",
          "You do not have permission to delete this event",
        );
      }
    }

    // Delete the event document
    await eventRef.delete();
    console.log(`Deleted event ${eventId} by user ${callerUid}`);

    // Delete all notifications for this event
    const notificationsSnapshot = await db
      .collection("notifications")
      .where("eventId", "==", eventId)
      .get();

    if (!notificationsSnapshot.empty) {
      const batch = db.batch();
      notificationsSnapshot.docs.forEach((doc) => {
        batch.delete(doc.ref);
      });
      await batch.commit();
      console.log(`Deleted ${notificationsSnapshot.size} notifications for event ${eventId}`);
    }

    // Check both clubEvent and infoSession targetTypes
    const targetNotificationsSnapshot1 = await db
      .collection("notifications")
      .where("targetId", "==", eventId)
      .where("targetType", "==", "clubEvent")
      .get();

    const targetNotificationsSnapshot2 = await db
      .collection("notifications")
      .where("targetId", "==", eventId)
      .where("targetType", "==", "infoSession")
      .get();

    const allTargetDocs = [...targetNotificationsSnapshot1.docs, ...targetNotificationsSnapshot2.docs];
    if (allTargetDocs.length > 0) {
      const batch = db.batch();
      allTargetDocs.forEach((doc) => {
        batch.delete(doc.ref);
      });
      await batch.commit();
      console.log(`Deleted ${allTargetDocs.length} target notifications for event ${eventId}`);
    }

    // Remove event reference from club's events array
    if (clubId) {
      try {
        const clubRef = db.collection("clubs").doc(clubId);
        await clubRef.update({
          events: admin.firestore.FieldValue.arrayRemove(eventRef),
        });
        console.log(`Removed event ${eventId} from club ${clubId} events array`);
      } catch (err) {
        console.warn(`Could not remove event from club events array: ${err.message}`);
      }
    }

    return {
      success: true,
      message: `Event ${eventId} deleted successfully`,
    };
  } catch (error) {
    console.error("Error deleting club event:", error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError("internal", error.message || "Internal server error");
  }
});

exports.autoDeleteOldClubEvents = onSchedule("every day 02:00", async () => {
  console.log("Scheduled run: auto-deleting old club events");
  const db = admin.firestore();

  try {
    const sevenDaysAgo = admin.firestore.Timestamp.fromMillis(
      Date.now() - (7 * 24 * 60 * 60 * 1000),
    );

    const oldEventsSnapshot = await db
      .collection("events")
      .where("eventType", "==", "club")
      .where("endTime", "<", sevenDaysAgo)
      .limit(100)
      .get();

    if (oldEventsSnapshot.empty) {
      console.log("No old club events to delete");
      return;
    }

    let deletedCount = 0;
    let errorCount = 0;

    for (const eventDoc of oldEventsSnapshot.docs) {
      try {
        const eventId = eventDoc.id;
        const eventData = eventDoc.data();
        const clubId = eventData.clubId;

        if (eventDoc.ref.recurrenceType &&
          eventDoc.ref.recurrenceType != "Never" &&
          eventDoc.ref.recurrenceEndDate > sevenDaysAgo) {
          // Skip recurring events that may have future occurrences
          continue;
        }
        // Delete the event
        await eventDoc.ref.delete();

        // Delete associated notifications by eventId field
        const notificationsSnapshot = await db
          .collection("notifications")
          .where("eventId", "==", eventId)
          .get();

        if (!notificationsSnapshot.empty) {
          const batch = db.batch();
          notificationsSnapshot.docs.forEach((doc) => {
            batch.delete(doc.ref);
          });
          await batch.commit();
        }

        // Delete associated notifications by targetId field for both targetTypes
        const targetNotificationsSnapshot1 = await db
          .collection("notifications")
          .where("targetId", "==", eventId)
          .where("targetType", "==", "clubEvent")
          .get();

        const targetNotificationsSnapshot2 = await db
          .collection("notifications")
          .where("targetId", "==", eventId)
          .where("targetType", "==", "infoSession")
          .get();

        const allTargetDocs = [...targetNotificationsSnapshot1.docs, ...targetNotificationsSnapshot2.docs];
        if (allTargetDocs.length > 0) {
          const batch = db.batch();
          allTargetDocs.forEach((doc) => {
            batch.delete(doc.ref);
          });
          await batch.commit();
        }

        // Remove event reference from club's events array
        if (clubId) {
          try {
            const clubRef = db.collection("clubs").doc(clubId);
            await clubRef.update({
              events: admin.firestore.FieldValue.arrayRemove(eventDoc.ref),
            });
          } catch (err) {
            console.warn(`Could not remove event ${eventId} from club ${clubId}: ${err.message}`);
          }
        }

        deletedCount++;
        console.log(`Auto-deleted old event ${eventId} (${eventData.eventName || "unnamed"})`);
      } catch (err) {
        errorCount++;
        console.error(`Error deleting event ${eventDoc.id}:`, err);
      }
    }

    console.log(
      `Auto-delete complete: ${deletedCount} events deleted, ${errorCount} errors`,
    );
  } catch (err) {
    console.error("Error in auto-delete old club events:", err);
  }
});
