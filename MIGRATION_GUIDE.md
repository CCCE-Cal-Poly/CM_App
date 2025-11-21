# Company Logo Linking Migration Guide

## Overview
The app now supports a proper relational design for linking events to companies using `companyId` instead of name matching.

## Data Structure Changes

### Event Document (Firestore)
Add a new field to info session events:

```javascript
{
  "eventName": "Fall Career Fair Workshop",  // Can be anything now!
  "eventType": "infoSession",
  "company": "Anning-Johnson",  // Keep for display/legacy
  "companyId": "abc123xyz",  // NEW: Reference to company document ID
  "logo": "",  // Will be auto-populated if empty
  // ... other fields
}
```

## Migration Options

### Option 1: Gradual Migration (RECOMMENDED)
The code now supports **both** approaches:
- Events with `companyId` → Uses ID lookup (preferred)
- Events without `companyId` → Falls back to name matching (legacy)

**Action Required:**
1. Keep existing events as-is (they'll work with name matching)
2. Add `companyId` to new events going forward
3. Gradually update old events when convenient

### Option 2: Bulk Migration Script
Run this in your Firebase console or Cloud Functions:

```javascript
const admin = require('firebase-admin');
const db = admin.firestore();

async function migrateEvents() {
  // 1. Get all companies and create name-to-ID map
  const companiesSnapshot = await db.collection('companies').get();
  const companyMap = {};
  companiesSnapshot.forEach(doc => {
    const name = doc.data().name?.toLowerCase().trim();
    if (name) {
      companyMap[name] = doc.id;
    }
  });
  
  // 2. Update all info sessions
  const eventsSnapshot = await db.collection('events')
    .where('eventType', '==', 'infoSession')
    .get();
    
  const batch = db.batch();
  let updateCount = 0;
  
  eventsSnapshot.forEach(doc => {
    const data = doc.data();
    const companyName = data.company?.toLowerCase().trim();
    
    if (companyName && companyMap[companyName] && !data.companyId) {
      batch.update(doc.ref, { companyId: companyMap[companyName] });
      updateCount++;
    }
  });
  
  await batch.commit();
  console.log(`✅ Migrated ${updateCount} events to use companyId`);
}

// Run the migration
migrateEvents().catch(console.error);
```

## Benefits of New Approach

### Before (Name Matching)
```javascript
// Event must be named exactly like company
{
  "eventName": "Anning-Johnson",  // Must match company name
  "company": "Anning-Johnson",
  "eventType": "infoSession"
}
```
❌ Event name constrained by company name  
❌ Breaks if company name changes  
❌ No support for multiple events from same company  

### After (ID Reference)
```javascript
// Event can have any name
{
  "eventName": "Fall Internship Opportunities",  // Can be anything!
  "companyId": "company_doc_id_123",  // Stable reference
  "eventType": "infoSession"
}
```
✅ Event name can be descriptive/creative  
✅ Survives company name changes  
✅ Multiple events per company work perfectly  
✅ Proper relational database design  

## Testing

1. **Test legacy events** (without companyId):
   - Should still link logos via name matching
   - Anning-Johnson event should get logo if names match exactly

2. **Test new events** (with companyId):
   - Should link logos via ID lookup
   - Event name can be anything

3. **Check console logs**:
   ```
   ✅ Linked X company logos to info sessions
   ```

## Firestore Rules
No changes needed - `companyId` is just a string field.

## Next Steps

1. **Immediate**: Everything works as-before (backward compatible)
2. **Short-term**: Start adding `companyId` to new events
3. **Long-term**: Run migration script to update all existing events
4. **Future**: Remove legacy name-matching code once all events migrated

## Questions?
This is a non-breaking change. Old events work exactly as before, new events can use the better approach.
