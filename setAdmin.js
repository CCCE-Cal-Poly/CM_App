const admin = require("firebase-admin");
const serviceAccount = require("FIREBASESERVICEACCKEYHERE");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

async function makeAdmin(uid) {
  try {
    await admin.auth().setCustomUserClaims(uid, { role: "admin" });
    console.log(`User ${uid} is now an admin`);
  } catch (error) {
    console.error("Error setting custom claim:", error);
  }
}

makeAdmin("{INSERTUIDHERE}");
