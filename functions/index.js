const admin = require("firebase-admin");
const functions = require("firebase-functions");


admin.initializeApp();

const {onCall, HttpsError} = require("firebase-functions/v2/https");

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

exports.approveClubEvent = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Request not authenticated",
    );
  }

  const callerClaims = context.auth.token || {};
  if (callerClaims.role !== "admin") {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Only admins can approve events",
    );
  }

  const requestId = data.requestId;
  if (!requestId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "requestId is required",
    );
  }

  const db = admin.firestore();
  const reqRef = db.collection("clubEventRequests").doc(requestId);
  const reqSnap = await reqRef.get();

  if (!reqSnap.exists) {
    throw new functions.https.HttpsError("not-found", "Request not found");
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
    eventType: (reqData.eventType || "club").toString().trim().toLowerCase(),
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
    throw new functions.https.HttpsError(
      "internal",
      "Failed to approve request",
    );
  }
});

exports.denyClubEvent = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Request not authenticated",
    );
  }

  const callerClaims = context.auth.token || {};
  if (callerClaims.role !== "admin") {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Only admins can deny events",
    );
  }

  const requestId = data.requestId;
  const reason = data.reason || "";
  if (!requestId) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "requestId is required",
    );
  }

  const db = admin.firestore();
  const reqRef = db.collection("clubEventRequests").doc(requestId);
  const reqSnap = await reqRef.get();

  if (!reqSnap.exists) {
    throw new functions.https.HttpsError("not-found", "Request not found");
  }

  try {
    await reqRef.update({
      status: "denied",
      reviewedBy: context.auth.uid || null,
      reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
      adminComment: reason,
    });
    return {success: true};
  } catch (err) {
    console.error("denyClubEvent error", err);
    throw new functions.https.HttpsError("internal", "Failed to deny request");
  }
});
