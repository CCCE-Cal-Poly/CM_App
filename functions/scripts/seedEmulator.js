const admin = require("firebase-admin");

const authEmulatorHost =
  process.env.FIREBASE_AUTH_EMULATOR_HOST || "127.0.0.1:9099";
const firestoreEmulatorHost =
  process.env.FIRESTORE_EMULATOR_HOST || "127.0.0.1:8080";

function assertLocalEmulator(host, expectedPort, name) {
  const [hostname, port, ...extra] = host.split(":");
  if (
    extra.length > 0 ||
    !["127.0.0.1", "localhost"].includes(hostname) ||
    port !== String(expectedPort)
  ) {
    throw new Error(
        `${name} must point to localhost:${expectedPort}; got "${host}"`,
    );
  }
}

async function ensureTestUser(auth, db, userData) {
  let user;
  try {
    user = await auth.getUserByEmail(userData.email);
    user = await auth.updateUser(user.uid, {
      displayName: `${userData.firstName} ${userData.lastName}`,
      password: "hello123",
      emailVerified: true,
      disabled: false,
    });
  } catch (error) {
    if (error.code !== "auth/user-not-found") throw error;
    user = await auth.createUser({
      email: userData.email,
      password: "hello123",
      displayName: `${userData.firstName} ${userData.lastName}`,
      emailVerified: true,
    });
  }

  if (userData.customClaims) {
    await auth.setCustomUserClaims(user.uid, userData.customClaims);
  }

  await db.collection("users").doc(user.uid).set({
    email: userData.email,
    clubsAdminOf: userData.clubsAdminOf ?? null,
    firstName: userData.firstName,
    lastName: userData.lastName,
    schoolYear: "Senior",
    company: "",
    role: userData.role,
    admin: userData.role === "admin",
  }, {merge: true});

  return user.uid;
}

async function seedEmulator() {
  assertLocalEmulator(authEmulatorHost, 9099, "Firebase Auth emulator");
  assertLocalEmulator(firestoreEmulatorHost, 8080, "Firestore emulator");

  process.env.FIREBASE_AUTH_EMULATOR_HOST = authEmulatorHost;
  process.env.FIRESTORE_EMULATOR_HOST = firestoreEmulatorHost;

  const projectId = process.env.GCLOUD_PROJECT || "cm-app-90d65";
  admin.initializeApp({projectId});
  const auth = admin.auth();
  const db = admin.firestore();

  const [adminUid, clubAdminUid, attendeeUid] = await Promise.all([
    ensureTestUser(auth, db, {
      email: "admin@example.test",
      firstName: "Local",
      lastName: "Admin",
      role: "admin",
      customClaims: {role: "admin"},
    }),
    ensureTestUser(auth, db, {
      email: "club-admin@example.test",
      clubsAdminOf: ["local-test-club"],
      firstName: "Club",
      lastName: "Admin",
      role: "club admin",
      customClaims: {role: "club admin"},
      admin: false,
    }),
    ensureTestUser(auth, db, {
      email: "attendee@example.test",
      firstName: "Test",
      lastName: "Attendee",
      role: "",
    }),
  ]);

  const now = new Date();
  const firstMonday = new Date(now);
  firstMonday.setUTCHours(17, 0, 0, 0);
  const daysUntilMonday = (8 - firstMonday.getUTCDay()) % 7 || 7;
  firstMonday.setUTCDate(firstMonday.getUTCDate() + daysUntilMonday);
  const weeklyEnd = new Date(firstMonday.getTime() + 60 * 60 * 1000);
  const oneTimeStart = new Date(now.getTime() + 3 * 24 * 60 * 60 * 1000);
  const oneTimeEnd = new Date(oneTimeStart.getTime() + 60 * 60 * 1000);
  const clubRef = db.collection("clubs").doc("local-test-club");

  const batch = db.batch();
  batch.set(clubRef, {
    Name: "Local Test Club",
    About: "Club seeded in the Firebase Emulator Suite.",
    Email: "club@example.test",
    Acronym: "LTC",
    Instagram: "",
    events: [],
  }, {merge: true});
  batch.set(
      clubRef.collection("members").doc(clubAdminUid),
      {uid: clubAdminUid, role: "club admin"},
      {merge: true},
  );
  batch.set(
      clubRef.collection("members").doc(attendeeUid),
      {uid: attendeeUid, role: "member"},
      {merge: true},
  );
  const joinedClubData = {
    clubId: clubRef.id,
    name: "Local Test Club",
    aboutMsg: "Club seeded in the Firebase Emulator Suite.",
    email: "club@example.test",
    acronym: "LTC",
    instagram: "",
    logo: "",
    joinedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
  for (const uid of [clubAdminUid, attendeeUid]) {
    batch.set(
        db.collection("users").doc(uid)
            .collection("joinedClubs").doc(clubRef.id),
        joinedClubData,
        {merge: true},
    );
  }
  batch.set(db.collection("companies").doc("local-test-company"), {
    name: "Local Test Company",
    location: "San Luis Obispo, CA",
    about: "Company seeded in the Firebase Emulator Suite.",
    msg: "Meet our local test recruiting team.",
    recruiterName: "Local Recruiter",
    recruiterTitle: "Recruiter",
    recruiterEmail: "recruiter@example.test",
    logo: "",
  }, {merge: true});
  batch.set(db.collection("events").doc("local-weekly-club-event"), {
    eventName: "LTC Event",
    company: "Local Test Club",
    clubId: clubRef.id,
    eventType: "club",
    startTime: admin.firestore.Timestamp.fromDate(firstMonday),
    endTime: admin.firestore.Timestamp.fromDate(weeklyEnd),
    mainLocation: "Local Test Room",
    description: "Recurring Monday event for emulator testing.",
    Status: "approved",
    recurrence: {
      rrule: "RRULE:FREQ=WEEKLY;BYDAY=MO",
      rdate: [],
      exdate: [],
    },
  }, {merge: true});
  batch.set(db.collection("events").doc("local-one-time-event"), {
    eventName: "Local One-time Event",
    company: "Local Test Company",
    eventType: "infoSession",
    startTime: admin.firestore.Timestamp.fromDate(oneTimeStart),
    endTime: admin.firestore.Timestamp.fromDate(oneTimeEnd),
    mainLocation: "Local Test Room",
    description: "One-time event for emulator testing.",
    status: "approved",
    recurrence: null,
  }, {merge: true});
  await batch.commit();

  console.log(`Seeded Firebase emulators for project "${projectId}".`);
  console.log("Test sign-in accounts (password for each: LocalTest123!):");
  console.log("  admin@example.test");
  console.log("  club-admin@example.test");
  console.log("  attendee@example.test");
  console.log(`Admin UID: ${adminUid}`);
  console.log(`Club admin UID: ${clubAdminUid}`);
  console.log(`Attendee UID: ${attendeeUid}`);
  console.log(`Weekly event starts: ${firstMonday.toISOString()}`);
  console.log(`One-time event starts: ${oneTimeStart.toISOString()}`);
}

seedEmulator().catch((error) => {
  console.error("Failed to seed Firebase emulators:", error);
  process.exitCode = 1;
});
