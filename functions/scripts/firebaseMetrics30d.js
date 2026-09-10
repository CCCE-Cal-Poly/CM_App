/* eslint-disable no-console */
const admin = require("firebase-admin");

const serviceAccount = require("../serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const DAYS = (() => {
  const raw = process.argv[2] || process.env.DAYS || "30";
  const parsed = Number.parseInt(raw, 10);
  if (Number.isNaN(parsed) || parsed <= 0) return 30;
  return parsed;
})();

function dayKey(date) {
  return date.toISOString().slice(0, 10);
}

function addToMap(map, key, inc = 1) {
  map.set(key, (map.get(key) || 0) + inc);
}

function addToSetMap(map, key, value) {
  if (!map.has(key)) {
    map.set(key, new Set());
  }
  map.get(key).add(value);
}

function mergeSetMaps(target, source) {
  for (const [key, set] of source.entries()) {
    if (!target.has(key)) {
      target.set(key, new Set());
    }
    const targetSet = target.get(key);
    for (const value of set) {
      targetSet.add(value);
    }
  }
}

function formatMap(map) {
  return Object.fromEntries(
    [...map.entries()].sort((a, b) => a[0].localeCompare(b[0])),
  );
}

function extractUid(path) {
  const parts = path.split("/");
  const usersIndex = parts.indexOf("users");
  if (usersIndex >= 0 && parts.length > usersIndex + 1) {
    return parts[usersIndex + 1];
  }
  const attendingIndex = parts.indexOf("attending");
  if (attendingIndex >= 0 && parts.length > attendingIndex + 1) {
    return parts[attendingIndex + 1];
  }
  return null;
}

function readTimestamp(data, field) {
  const value = data[field];
  if (!value) return null;
  if (typeof value.toDate === "function") return value.toDate();
  if (value instanceof Date) return value;
  return null;
}

function setIntersectionCount(a, b) {
  let count = 0;
  for (const value of a) {
    if (b.has(value)) count++;
  }
  return count;
}

async function getTotalUsers() {
  const usersRef = db.collection("users");
  if (typeof usersRef.count === "function") {
    const snap = await usersRef.count().get();
    return snap.data().count;
  }
  const snap = await usersRef.get();
  return snap.size;
}

async function getNewUsers(startTs) {
  const snap = await db
    .collection("users")
    .where("createdAt", ">=", startTs)
    .get();

  const ids = new Set();
  const byDay = new Map();
  snap.docs.forEach((doc) => {
    ids.add(doc.id);
    const ts = readTimestamp(doc.data(), "createdAt");
    if (ts) addToMap(byDay, dayKey(ts));
  });

  return {count: snap.size, ids, byDay};
}

async function queryActivitySource(startTs, config) {
  const {name, collectionGroup, timeField} = config;
  try {
    const snap = await db
      .collectionGroup(collectionGroup)
      .where(timeField, ">=", startTs)
      .get();

    const ids = new Set();
    const byDay = new Map();
    const byDayUsers = new Map();

    snap.docs.forEach((doc) => {
      const uid = extractUid(doc.ref.path);
      if (uid) ids.add(uid);

      const ts = readTimestamp(doc.data(), timeField);
      if (ts) {
        const key = dayKey(ts);
        addToMap(byDay, key);
        if (uid) addToSetMap(byDayUsers, key, uid);
      }
    });

    return {
      name,
      total: snap.size,
      ids,
      byDay,
      byDayUsers,
    };
  } catch (error) {
    return {name, error};
  }
}

async function getNotifications(startTs) {
  try {
    const snap = await db
      .collection("notifications")
      .where("createdAt", ">=", startTs)
      .get();

    const byType = new Map();
    snap.docs.forEach((doc) => {
      const type = (doc.data().targetType || "unknown").toString();
      addToMap(byType, type);
    });

    return {total: snap.size, byType};
  } catch (error) {
    return {error};
  }
}

async function getEventsCreated(startTs) {
  try {
    const snap = await db
      .collection("events")
      .where("createdAt", ">=", startTs)
      .get();

    const byType = new Map();
    snap.docs.forEach((doc) => {
      const type = (doc.data().eventType || "unknown").toString();
      addToMap(byType, type);
    });

    return {total: snap.size, byType};
  } catch (error) {
    return {error};
  }
}

async function getEventsByStart(startTs, endTs) {
  try {
    const snap = await db
      .collection("events")
      .where("startTime", ">=", startTs)
      .where("startTime", "<=", endTs)
      .get();

    const byType = new Map();
    snap.docs.forEach((doc) => {
      const type = (doc.data().eventType || "unknown").toString();
      addToMap(byType, type);
    });

    return {total: snap.size, byType};
  } catch (error) {
    return {error};
  }
}

async function run() {
  const now = new Date();
  const start = new Date(now.getTime() - DAYS * 24 * 60 * 60 * 1000);
  const startTs = admin.firestore.Timestamp.fromDate(start);
  const endTs = admin.firestore.Timestamp.fromDate(now);

  console.log(`Firebase metrics (last ${DAYS} days)`);
  console.log("Range:", start.toISOString(), "to", now.toISOString());
  console.log("---");

  const totalUsers = await getTotalUsers();
  const newUsers = await getNewUsers(startTs);

  console.log("Total users:", totalUsers);
  console.log(`New users (last ${DAYS} days):`, newUsers.count);
  console.log("New users by day:", formatMap(newUsers.byDay));
  console.log("---");

  const activityConfigs = [
    {
      name: "event_checkins",
      collectionGroup: "checkedInEvents",
      timeField: "checkedInAt",
    },
    {
      name: "event_attending",
      collectionGroup: "attending",
      timeField: "checkedInAt",
    },
    {
      name: "club_joins",
      collectionGroup: "joinedClubs",
      timeField: "joinedAt",
    },
    {
      name: "company_favorites",
      collectionGroup: "favoriteCompanies",
      timeField: "favoritedAt",
    },
  ];

  const activityResults = [];
  for (const config of activityConfigs) {
    const result = await queryActivitySource(startTs, config);
    activityResults.push(result);
  }

  const activeUserIds = new Set();
  const activeByDayUsers = new Map();

  for (const result of activityResults) {
    if (result.error) {
      console.log(`Activity ${result.name} error:`, result.error.message || result.error);
      continue;
    }
    for (const uid of result.ids) activeUserIds.add(uid);
    mergeSetMaps(activeByDayUsers, result.byDayUsers);
  }

  const newActiveCount = setIntersectionCount(activeUserIds, newUsers.ids);
  const returningActive = activeUserIds.size - newActiveCount;

  console.log("Active users (proxy):", activeUserIds.size);
  console.log("New active users (proxy):", newActiveCount);
  console.log("Returning active users (proxy):", returningActive);

  const activeByDayCounts = new Map();
  for (const [day, set] of activeByDayUsers.entries()) {
    activeByDayCounts.set(day, set.size);
  }
  console.log("Daily active users (proxy):", formatMap(activeByDayCounts));
  console.log("---");

  console.log(`Activity counts (last ${DAYS} days):`);
  for (const result of activityResults) {
    if (result.error) continue;
    console.log(`- ${result.name}: ${result.total}`);
  }
  console.log("---");

  const notifications = await getNotifications(startTs);
  if (notifications.error) {
    console.log("Notifications error:", notifications.error.message || notifications.error);
  } else {
    console.log(`Notifications created (last ${DAYS} days):`, notifications.total);
    console.log("Notifications by targetType:", formatMap(notifications.byType));
  }
  console.log("---");

  const eventsCreated = await getEventsCreated(startTs);
  if (eventsCreated.error) {
    console.log("Events created error:", eventsCreated.error.message || eventsCreated.error);
  } else {
    console.log(`Events created (last ${DAYS} days, createdAt):`, eventsCreated.total);
    console.log("Events created by eventType:", formatMap(eventsCreated.byType));
  }

  const eventsByStart = await getEventsByStart(startTs, endTs);
  if (eventsByStart.error) {
    console.log("Events by startTime error:", eventsByStart.error.message || eventsByStart.error);
  } else {
    console.log(`Events occurring in last ${DAYS} days (startTime):`, eventsByStart.total);
    console.log("Events occurring by eventType:", formatMap(eventsByStart.byType));
  }

  console.log("---");
  console.log("Notes:");
  console.log("- Active users are a proxy based on check-ins, club joins, attending, and favorites.");
  console.log("- Session length, retention, and page views require GA4/Analytics.");
  console.log("- Downloads require App Store / Google Play metrics.");
}

run()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error("Failed to fetch metrics:", err);
    process.exit(1);
  });
