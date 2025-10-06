const {onRequest} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp({});

const ALLOWED_ROLES = new Set(["admin", "student", "faculty", "club admin"]);

async function getAuthTokenFromRequest(req) {
  const authHeader = req.headers && req.headers.authorization;
  if (typeof authHeader === "string" && authHeader.startsWith("Bearer ")) {
    const idToken = authHeader.split("Bearer ")[1].trim();
    if (idToken) {
      try {
        return await admin.auth().verifyIdToken(idToken);
      } catch (e) {
        console.error("Failed to verify id token:", e);
        return null;
      }
    }
  }

  if (req.auth && req.auth.token) {
    return req.auth.token;
  }

  return null;
}

exports.setUserRole = onRequest(async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).json({ error: "Method not allowed. Use POST." });
    return;
  }

  const authToken = await getAuthTokenFromRequest(req);
  if (!authToken) {
    res.status(401).json({ error: "Unauthorized. No valid auth token provided." });
    return;
  }

  if (authToken.role !== "admin") {
    res.status(403).json({ error: "Only admins can set user roles." });
    return;
  }

  const { uid, role } = req.body || {};

  if (!uid || typeof uid !== "string") {
    res.status(400).json({ error: "Must provide a valid uid." });
    return;
  }

  if (!role || typeof role !== "string") {
    res.status(400).json({ error: "Must provide a valid role string." });
    return;
  }

  const normalizedRole = role.trim().toLowerCase();
  if (!ALLOWED_ROLES.has(normalizedRole)) {
    res.status(400).json({ error: `Invalid role. Allowed roles: ${[...ALLOWED_ROLES].join(", ")}` });
    return;
  }

  try {
    await admin.auth().setCustomUserClaims(uid, {role: normalizedRole});

    await admin.firestore().collection("users").doc(uid).update({role: normalizedRole});

    res.json({
      success: true,
      message: `User ${uid} is now a ${normalizedRole}`,
    });
  } catch (error) {
    console.error("Error setting custom claim:", error);
    res.status(500).json({ error: error.message || "Internal server error" });
  }
});

exports.approveClubEvent = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Request not authenticated');
  }
  const callerClaims = context.auth.token || {};
  if (callerClaims.role !== 'admin') {
    throw new functions.https.HttpsError('permission-denied', 'Only admins can approve events');
  }
  const requestId = data.requestId;
  if (!requestId) {
    throw new functions.https.HttpsError('invalid-argument', 'requestId is required');
  }

  const db = admin.firestore();
  const reqRef = db.collection('clubEventRequests').doc(requestId);
  const reqSnap = await reqRef.get();
  if (!reqSnap.exists) {
    throw new functions.https.HttpsError('not-found', 'Request not found');
  }
  const reqData = reqSnap.data() || {};

  const eventDoc = {
    company: reqData.clubName || '',
    eventName: reqData.eventName || '',
    startTime: reqData.startTime || admin.firestore.FieldValue.serverTimestamp(),
    endTime: reqData.endTime || reqData.startTime || admin.firestore.FieldValue.serverTimestamp(),
    mainLocation: reqData.eventLocation || '',
    eventType: (reqData.eventType || 'club').toString().trim().toLowerCase(),
    logo: reqData.logoUrl || reqData.logo || '',
    Status: 'approved',
    description: reqData.description || '',
    submittedBy: {
      uid: reqData.requestedByUid || null,
      name: reqData.requestedByName || null,
      email: reqData.requestedByEmail || null,
    },
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  try {
    const newEventRef = await db.collection('events').add(eventDoc);
    await reqRef.delete();
    return { success: true, eventId: newEventRef.id };
  } catch (err) {
    console.error('approveClubEvent error', err);
    throw new functions.https.HttpsError('internal', 'Failed to approve request');
  }
});

exports.denyClubEvent = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Request not authenticated');
  }
  const callerClaims = context.auth.token || {};
  if (callerClaims.role !== 'admin') {
    throw new functions.https.HttpsError('permission-denied', 'Only admins can deny events');
  }
  const requestId = data.requestId;
  const reason = data.reason || '';
  if (!requestId) {
    throw new functions.https.HttpsError('invalid-argument', 'requestId is required');
  }
  const db = admin.firestore();
  const reqRef = db.collection('clubEventRequests').doc(requestId);
  const reqSnap = await reqRef.get();
  if (!reqSnap.exists) {
    throw new functions.https.HttpsError('not-found', 'Request not found');
  }

  try {
    await reqRef.update({
      status: 'denied',
      reviewedBy: context.auth.uid || null,
      reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
      adminComment: reason,
    });
    return { success: true };
  } catch (err) {
    console.error('denyClubEvent error', err);
    throw new functions.https.HttpsError('internal', 'Failed to deny request');
  }
});