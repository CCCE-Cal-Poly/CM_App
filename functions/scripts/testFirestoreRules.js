/* eslint-disable no-console, max-len */
// Compiles ../../firestore.rules and runs allow/deny cases via the Firebase Rules
// projects.test API. Nothing is created or deployed.
//
//   RULES_TOKEN=$(gcloud auth print-access-token) node scripts/testFirestoreRules.js
//
// (The service account key lacks firebaserules.rulesets.test, so pass a user token.)
const admin = require("firebase-admin");
const fs = require("fs");
const sa = require("../serviceAccountKey.json");

const source = fs.readFileSync(require("path").join(__dirname, "../../firestore.rules"), "utf8");
const D = "/databases/(default)/documents";
const student = {uid: "stu1", token: {}};
const other = {uid: "stu2", token: {}};
const adminUser = {uid: "adm1", token: {role: "admin"}};
const mocks = [
  {function: "get", args: [{anyValue: {}}], result: {value: {data: {role: "student", eventType: "x"}}}},
  {function: "exists", args: [{anyValue: {}}], result: {value: false}},
];

const cases = [
  ["notifications: user reads own user-targeted", "ALLOW",
    {auth: student, path: `${D}/notifications/n1`, method: "get"}, {data: {targetType: "user", targetId: "stu1"}}],
  ["notifications: user reads someone else's user-targeted", "DENY",
    {auth: other, path: `${D}/notifications/n1`, method: "get"}, {data: {targetType: "user", targetId: "stu1"}}],
  ["notifications: user reads broadcast", "ALLOW",
    {auth: other, path: `${D}/notifications/n2`, method: "get"}, {data: {targetType: "broadcast"}}],
  ["notifications: non-admin create", "DENY",
    {auth: student, path: `${D}/notifications/n3`, method: "create", resource: {data: {targetType: "broadcast"}}}, null],
  ["notifications: non-admin update", "DENY",
    {auth: student, path: `${D}/notifications/n2`, method: "update", resource: {data: {targetType: "broadcast", title: "x"}}},
    {data: {targetType: "broadcast"}}],
  ["notifications: admin create", "ALLOW",
    {auth: adminUser, path: `${D}/notifications/n3`, method: "create", resource: {data: {targetType: "broadcast"}}}, null],
  ["notifications: target user deletes own", "ALLOW",
    {auth: student, path: `${D}/notifications/n1`, method: "delete"}, {data: {targetType: "user", targetId: "stu1"}}],
  ["events: admin creates interview block", "ALLOW",
    {auth: adminUser, path: `${D}/events/b1`, method: "create", resource: {data: {eventType: "interviewBlock"}}}, null],
  ["events: admin cannot create info session via interview rule", "DENY",
    {auth: adminUser, path: `${D}/events/b2`, method: "create", resource: {data: {eventType: "infoSession"}}}, null],
  ["events: student creates interview block", "DENY",
    {auth: student, path: `${D}/events/b1`, method: "create", resource: {data: {eventType: "interviewBlock"}}}, null],
  ["events: admin deletes interview block", "ALLOW",
    {auth: adminUser, path: `${D}/events/b1`, method: "delete"}, {data: {eventType: "interviewBlock"}}],
  ["events: admin cannot turn block into info session", "DENY",
    {auth: adminUser, path: `${D}/events/b1`, method: "update", resource: {data: {eventType: "infoSession"}}},
    {data: {eventType: "interviewBlock"}}],
  ["interviewSlots: student reads", "ALLOW",
    {auth: student, path: `${D}/events/b1/interviewSlots/123`, method: "get"}, {data: {booked: 1}}],
  ["interviewSlots: student writes", "DENY",
    {auth: student, path: `${D}/events/b1/interviewSlots/123`, method: "update", resource: {data: {booked: 0}}}, {data: {booked: 1}}],
  ["interviewSignups: owner reads", "ALLOW",
    {auth: student, path: `${D}/events/b1/interviewSignups/stu1`, method: "get"}, {data: {uid: "stu1"}}],
  ["interviewSignups: other student reads", "DENY",
    {auth: other, path: `${D}/events/b1/interviewSignups/stu1`, method: "get"}, {data: {uid: "stu1"}}],
  ["interviewSignups: admin lists", "ALLOW",
    {auth: adminUser, path: `${D}/events/b1/interviewSignups/stu1`, method: "list"}, {data: {uid: "stu1"}}],
  ["interviewSignups: owner writes directly", "DENY",
    {auth: student, path: `${D}/events/b1/interviewSignups/stu1`, method: "create", resource: {data: {uid: "stu1"}}}, null],
  ["user mirror: owner reads", "ALLOW",
    {auth: student, path: `${D}/users/stu1/interviewSignups/b1`, method: "get"}, {data: {}}],
  ["user mirror: owner writes", "DENY",
    {auth: student, path: `${D}/users/stu1/interviewSignups/b1`, method: "create", resource: {data: {}}}, null],
  ["user mirror: other reads", "DENY",
    {auth: other, path: `${D}/users/stu1/interviewSignups/b1`, method: "get"}, {data: {}}],
  ["allCompanies: student reads", "ALLOW",
    {auth: student, path: `${D}/allCompanies/c1`, method: "get"}, {data: {name: "X"}}],
  ["allCompanies: student writes", "DENY",
    {auth: student, path: `${D}/allCompanies/c1`, method: "create", resource: {data: {name: "X"}}}, null],
  ["careerFairCompanies: student reads (deployed rule kept)", "ALLOW",
    {auth: student, path: `${D}/careerFairCompanies/c1`, method: "get"}, {data: {}}],
];

(async () => {
  const token = process.env.RULES_TOKEN || (await admin.credential.cert(sa).getAccessToken()).access_token;
  const body = {
    source: {files: [{name: "firestore.rules", content: source}]},
    testSuite: {testCases: cases.map(([, expectation, request, resource]) =>
      Object.assign({expectation, request, functionMocks: mocks}, resource ? {resource} : {}))},
  };
  const res = await fetch(`https://firebaserules.googleapis.com/v1/projects/${sa.project_id}:test`, {
    method: "POST",
    headers: {"Authorization": `Bearer ${token}`, "Content-Type": "application/json"},
    body: JSON.stringify(body),
  });
  const json = await res.json();
  if (!res.ok) {
    console.log("HTTP", res.status, JSON.stringify(json, null, 1).slice(0, 3000));
    process.exit(1);
  }
  (json.issues || []).forEach((i) => console.log("ISSUE", i.severity, i.description, JSON.stringify(i.sourcePosition)));
  let failed = 0;
  (json.testResults || []).forEach((r, idx) => {
    const ok = r.state === "SUCCESS";
    if (!ok) failed++;
    console.log(`${ok ? "PASS" : "FAIL"}  ${cases[idx][0]}${ok ? "" : "  -> " + JSON.stringify(r.debugMessages || r.errorPosition || r)}`);
  });
  console.log(`\n${cases.length - failed}/${cases.length} passed`);
  process.exit(failed ? 1 : 0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
