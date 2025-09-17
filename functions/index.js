const {onRequest} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp({});

exports.setUserRole = onRequest(async (req, res) => {
  if (
    !req.auth ||
    !(req.auth.token.role == "admin")
  ) {
    res.status(403).json({
      error: "Only admins can set user roles.",
    });
    return;
  }

  const uid = req.body.uid;
  const role = req.body.role;

  if (!uid || !role) {
    res.status(400).json({
      error: "Must provide both uid and role.",
    });
    return;
  }

  try {
    await admin.auth().setCustomUserClaims(uid, {role: [role]});
    await admin.firestore().collection("users").doc(uid).update({role: role});
    res.json({
      success: true,
      message: `User ${uid} is now a ${role}`,
    });
  } catch (error) {
    console.error("Error setting custom claim:", error);
    res.status(500).json({error: error.message});
  }
});
