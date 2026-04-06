/* eslint-disable no-console */
const admin = require('firebase-admin');

const serviceAccount = require('../serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const conferenceId = 'asc_2026';
const sessionsRef = db.collection('conferences').doc(conferenceId).collection('sessions');

const missingPresentationSessionUpdates = [
  {
    sessionNumber: 14,
    update: {
      presentationStatus: 'missing',
      notes: 'Presentation not yet received.',
    },
  },
  {
    sessionNumber: 21,
    update: {
      presentationStatus: 'missing',
      notes: 'Presentation not yet received.',
    },
  },
  {
    sessionNumber: 97,
    update: {
      presentationStatus: 'pending_author',
      notes: 'Author travel visa pending; attendance not confirmed.',
    },
  },
  {
    sessionNumber: 99,
    update: {
      presentationStatus: 'missing',
      notes: 'Missing presentation from Scott Kelting and Andrew Kline.',
    },
  },
];

async function upsertBySessionNumber(sessionNumber, update) {
  const query = await sessionsRef.where('sessionNumber', '==', sessionNumber).limit(1).get();

  const payload = {
    sessionNumber,
    paperStatus: update.paperStatus || 'missing',
    presentationStatus: update.presentationStatus || 'missing',
    notes: update.notes || '',
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  if (!query.empty) {
    await query.docs[0].ref.set(payload, {merge: true});
    console.log(`Updated session #${sessionNumber}: ${query.docs[0].id}`);
    return;
  }

  const docId = `session_${sessionNumber}`;
  await sessionsRef.doc(docId).set(
    {
      ...payload,
      title: `Session ${sessionNumber}`,
      location: 'TBD',
      moderators: [],
      startTime: admin.firestore.Timestamp.fromDate(new Date()),
      endTime: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 60 * 60 * 1000)),
    },
    {merge: true},
  );
  console.log(`Created placeholder for session #${sessionNumber}: ${docId}`);
}

async function updateHousingPanelToTent() {
  const allSessions = await sessionsRef.get();
  const housingPanel = allSessions.docs.find((doc) => {
    const title = (doc.data().title || '').toString().toLowerCase();
    return title.includes('housing panel');
  });

  if (!housingPanel) {
    console.log('No housing panel session found by title search. Skipping location move.');
    return;
  }

  await housingPanel.ref.set(
    {
      location: 'Tent',
      notes: 'Updated per Joe Cleary: Cal Poly Housing Panel Friday moved to Tent (2-3pm).',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    {merge: true},
  );

  console.log(`Moved housing panel to Tent: ${housingPanel.id}`);
}

async function run() {
  console.log(`Syncing schedule updates for conference: ${conferenceId}`);

  for (const item of missingPresentationSessionUpdates) {
    await upsertBySessionNumber(item.sessionNumber, item.update);
  }

  await updateHousingPanelToTent();

  console.log('ASC schedule sync completed.');
}

run()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('ASC schedule sync failed:', err);
    process.exit(1);
  });
