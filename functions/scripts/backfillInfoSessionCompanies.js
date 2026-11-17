/* eslint-disable no-console */
// One-time backfill that links every info session to an `allCompanies` doc.
//
//   node scripts/backfillInfoSessionCompanies.js                       dry run: prints a report, writes nothing
//   node scripts/backfillInfoSessionCompanies.js --apply               writes the changes in the report
//   node scripts/backfillInfoSessionCompanies.js --migrate-favorites   (with or without --apply) also re-keys
//                                                                      users/*/favoriteCompanies from `companies`
//                                                                      doc ids to `allCompanies` doc ids
//
// Review scripts/backfill-aliases.json before running with --apply:
//   "aliases": { "<info session company name>": "<allCompanies doc id or exact name>" }
//   "skip":    [ "<info session company name that is not a company, e.g. 'Heavy Civil BBQ'>" ]
//
// With --apply it:
//   1. sets `nameKey` on every allCompanies doc
//   2. adds each alias's key to the target doc's `aliases` array (so the live trigger matches it later)
//   3. creates placeholder allCompanies docs (isStub: true) for companies that are still missing
//   4. sets `companyId` + `companyNameKey` on each info session (or `skipCompanySync: true` for skipped ones)

const admin = require("firebase-admin");
const path = require("path");
const {companyNameKey, stubCompanyData, stubCompanyDocId} = require("../companyKey");

const serviceAccount = require("../serviceAccountKey.json");
admin.initializeApp({credential: admin.credential.cert(serviceAccount)});

const db = admin.firestore();
const APPLY = process.argv.includes("--apply");
const MIGRATE_FAVORITES = process.argv.includes("--migrate-favorites");
const config = require(path.join(__dirname, "backfill-aliases.json"));

async function commitInChunks(ops) {
  for (let i = 0; i < ops.length; i += 400) {
    const batch = db.batch();
    ops.slice(i, i + 400).forEach((op) => op(batch));
    await batch.commit();
  }
}

function suggestionsFor(key, companiesByKey) {
  if (key.length < 4) return [];
  const out = [];
  for (const [existingKey, doc] of companiesByKey) {
    if (existingKey.length < 4) continue;
    if (existingKey.startsWith(key) || key.startsWith(existingKey)) out.push(`${doc.data().name} [${doc.id}]`);
  }
  return out.slice(0, 3);
}

async function main() {
  console.log(APPLY ? "=== APPLY MODE: writing changes ===" : "=== DRY RUN: nothing will be written ===");

  // ---- allCompanies -------------------------------------------------------------------------
  const companiesSnap = await db.collection("allCompanies").get();
  const companiesByKey = new Map();
  const companiesById = new Map();
  const keyCollisions = [];
  const aliasKeyToDoc = new Map();
  for (const doc of companiesSnap.docs) {
    companiesById.set(doc.id, doc);
    const key = companyNameKey(doc.data().name);
    if (!key) continue;
    if (companiesByKey.has(key)) keyCollisions.push([companiesByKey.get(key).data().name, doc.data().name]);
    else companiesByKey.set(key, doc);
    for (const a of doc.data().aliases || []) aliasKeyToDoc.set(a, doc);
  }

  // Resolve configured aliases: info-session name -> allCompanies doc id. A target that isn't
  // in allCompanies yet is treated as the name of a placeholder this script will create.
  const configAliases = new Map(); // key of info-session name -> target doc id
  const stubAliasTargets = new Map(); // stub key -> name, for alias targets that become placeholders
  const badAliases = [];
  for (const [fromName, target] of Object.entries(config.aliases || {})) {
    const doc = companiesById.get(target) || companiesByKey.get(companyNameKey(target));
    const targetKey = companyNameKey(target);
    if (doc) {
      configAliases.set(companyNameKey(fromName), doc.id);
    } else if (targetKey) {
      configAliases.set(companyNameKey(fromName), stubCompanyDocId(targetKey));
      stubAliasTargets.set(targetKey, target);
    } else {
      badAliases.push(`${fromName} -> ${target}`);
    }
  }
  const skipKeys = new Set((config.skip || []).map(companyNameKey));

  // ---- info sessions ------------------------------------------------------------------------
  const eventsSnap = await db.collection("events").where("eventType", "==", "infoSession").get();
  const eventOps = [];
  const stubsToCreate = new Map(); // key -> {name, website, sourceEventId}
  const aliasesToAdd = new Map(); // docId -> Set(keys)
  const counts = {direct: 0, alias: 0, stub: 0, skipped: 0, noName: 0, unchanged: 0};

  for (const ev of eventsSnap.docs) {
    const data = ev.data();
    const name = typeof data.company === "string" ? data.company.trim() : "";
    const key = companyNameKey(name);

    if (!key) {
      counts.noName++;
      continue;
    }
    if (skipKeys.has(key)) {
      counts.skipped++;
      if (data.skipCompanySync !== true) eventOps.push((b) => b.update(ev.ref, {skipCompanySync: true}));
      continue;
    }

    const direct = companiesByKey.get(key) || aliasKeyToDoc.get(key);
    let companyId;
    if (direct) {
      counts.direct++;
      companyId = direct.id;
    } else if (configAliases.has(key)) {
      counts.alias++;
      companyId = configAliases.get(key);
      if (!aliasesToAdd.has(companyId)) aliasesToAdd.set(companyId, new Set());
      aliasesToAdd.get(companyId).add(key);
    } else {
      counts.stub++;
      companyId = stubCompanyDocId(key);
      if (!stubsToCreate.has(key)) stubsToCreate.set(key, {name, website: data.website, sourceEventId: ev.id});
    }

    if (data.companyId === companyId && data.companyNameKey === key) {
      counts.unchanged++;
    } else {
      eventOps.push((b) => b.update(ev.ref, {companyId, companyNameKey: key}));
    }
  }

  // Alias targets that are new placeholders must be created even if no session uses that exact name.
  for (const [targetKey, targetName] of stubAliasTargets) {
    if (!stubsToCreate.has(targetKey)) stubsToCreate.set(targetKey, {name: targetName});
  }

  // ---- report -------------------------------------------------------------------------------
  console.log(`\nallCompanies docs: ${companiesSnap.size}`);
  console.log(`info sessions: ${eventsSnap.size}`);
  console.log(`  matched by name:        ${counts.direct}`);
  console.log(`  matched by alias:       ${counts.alias}`);
  console.log(`  -> new placeholder:     ${counts.stub}`);
  console.log(`  skipped (not company):  ${counts.skipped}`);
  console.log(`  no company name:        ${counts.noName}`);
  console.log(`  already linked:         ${counts.unchanged}`);

  if (keyCollisions.length) {
    console.log("\n!! allCompanies docs whose names normalize to the same key (possible duplicates):");
    keyCollisions.forEach(([a, b]) => console.log(`   "${a}"  ==  "${b}"`));
  }
  if (badAliases.length) {
    console.log("\n!! aliases in backfill-aliases.json whose target was not found:");
    badAliases.forEach((a) => console.log(`   ${a}`));
  }
  if (stubsToCreate.size) {
    console.log("\nPlaceholders that will be created (add to \"aliases\" or \"skip\" in backfill-aliases.json if wrong):");
    for (const [key, s] of [...stubsToCreate].sort((a, b) => a[1].name.localeCompare(b[1].name))) {
      const sugg = suggestionsFor(key, companiesByKey);
      console.log(`   ${s.name}${sugg.length ? `   (similar: ${sugg.join("; ")})` : ""}`);
    }
  }

  // ---- favorites migration plan ---------------------------------------------------------------
  const favoriteOps = [];
  let favoritesUnmatched = 0;
  if (MIGRATE_FAVORITES) {
    const oldCompanies = await db.collection("companies").get();
    const oldIdToNewId = new Map();
    for (const doc of oldCompanies.docs) {
      const target = companiesByKey.get(companyNameKey(doc.data().name));
      if (target) oldIdToNewId.set(doc.id, target.id);
    }
    const favs = await db.collectionGroup("favoriteCompanies").get();
    for (const fav of favs.docs) {
      const newId = oldIdToNewId.get(fav.id);
      if (!newId) {
        if (!companiesById.has(fav.id)) favoritesUnmatched++;
        continue;
      }
      if (newId === fav.id) continue;
      const newRef = fav.ref.parent.doc(newId);
      favoriteOps.push((b) => b.set(newRef, Object.assign({}, fav.data(), {companyId: newId}), {merge: true}));
      favoriteOps.push((b) => b.delete(fav.ref));
    }
    console.log(`\nfavoriteCompanies docs: ${favs.size}, to re-key: ${favoriteOps.length / 2}, unmatched: ${favoritesUnmatched}`);
  }

  if (!APPLY) {
    console.log("\nDry run complete. Re-run with --apply to write these changes.");
    return;
  }

  // ---- writes -------------------------------------------------------------------------------
  const companyOps = [];
  for (const doc of companiesSnap.docs) {
    const key = companyNameKey(doc.data().name);
    const existingAliases = Array.isArray(doc.data().aliases) ? doc.data().aliases : [];
    const newAliases = [...(aliasesToAdd.get(doc.id) || [])].filter((a) => !existingAliases.includes(a));
    const update = {};
    if (key && doc.data().nameKey !== key) update.nameKey = key;
    if (!Array.isArray(doc.data().aliases) || newAliases.length) update.aliases = [...existingAliases, ...newAliases];
    if (Object.keys(update).length) companyOps.push((b) => b.update(doc.ref, update));
  }
  await commitInChunks(companyOps);
  console.log(`Updated ${companyOps.length} allCompanies docs`);

  let created = 0;
  for (const [key, s] of stubsToCreate) {
    const ref = db.collection("allCompanies").doc(stubCompanyDocId(key));
    const aliases = [...(aliasesToAdd.get(ref.id) || [])];
    try {
      await ref.create(Object.assign(
        stubCompanyData(s.name, s, admin.firestore.FieldValue.serverTimestamp()), {aliases}));
      created++;
    } catch (err) {
      if (err.code !== 6) throw err; // 6 = already exists (e.g. created by the live trigger)
      if (aliases.length) await ref.update({aliases: admin.firestore.FieldValue.arrayUnion(...aliases)});
    }
  }
  console.log(`Created ${created} placeholder companies`);

  await commitInChunks(eventOps);
  console.log(`Updated ${eventOps.length} info sessions`);

  if (favoriteOps.length) {
    await commitInChunks(favoriteOps);
    console.log(`Re-keyed ${favoriteOps.length / 2} favorite companies`);
  }
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
