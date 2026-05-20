/* eslint-disable no-console */
const admin = require("firebase-admin");

const serviceAccount = require("../serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function run() {
  const usersRef = db.collection("users");

  let count = null;
  if (typeof usersRef.count === "function") {
    const snap = await usersRef.count().get();
    count = snap.data().count;
  } else {
    const snap = await usersRef.get();
    count = snap.size;
  }

  console.log(`users count: ${count}`);
}

run()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error("Failed to count users:", err);
    process.exit(1);
  });
