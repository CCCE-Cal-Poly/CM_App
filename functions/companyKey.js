// Shared company-name normalization used to match info-session `company`
// strings against `allCompanies` docs (index.js trigger + backfill script).

// Words that don't distinguish one company from another.
const IGNORED_WORDS = new Set([
  "the", "inc", "incorporated", "llc", "llp", "lp", "ltd", "co", "company",
  "companies", "corp", "corporation",
]);

/**
 * Normalizes a company name into a stable match key.
 *   "The Whiting-Turner Contracting Co."   -> "whitingturnercontracting"
 *   "Performance Contracting, Inc. (PCI)"  -> "performancecontracting"
 * Returns "" when nothing meaningful is left.
 * @param {*} name
 * @return {string}
 */
function companyNameKey(name) {
  if (typeof name !== "string") return "";
  return name
    .toLowerCase()
    .replace(/&/g, " and ")
    .replace(/\([^)]*\)/g, " ") // drop parentheticals like "(PCI)"
    .replace(/\./g, "") // "L.P." -> "lp", "C.W." -> "cw"
    .replace(/[^a-z0-9]+/g, " ")
    .trim()
    .split(/\s+/)
    .filter((w) => w && !IGNORED_WORDS.has(w))
    .join("");
}

/**
 * Fields for a placeholder `allCompanies` doc. Uses the same string fields
 * as the existing docs so Company.fromSnapshot parses it unchanged.
 * @param {string} name
 * @param {Object} extras optional {website, sourceEventId}
 * @param {*} createdAt Firestore timestamp/sentinel
 * @return {object}
 */
function stubCompanyData(name, extras, createdAt) {
  return {
    name: name.trim(),
    nameKey: companyNameKey(name),
    aliases: [],
    about: "",
    location: "",
    msg: "",
    logo: "",
    recruiterName: "",
    recruiterTitle: "",
    recruiterEmail: "",
    website: (extras && typeof extras.website === "string") ? extras.website : "",
    cmacData: null,
    isStub: true,
    createdFrom: "infoSession",
    sourceEventId: (extras && extras.sourceEventId) || null,
    createdAt: createdAt,
  };
}

function stubCompanyDocId(key) {
  return `auto_${key}`.slice(0, 1400);
}

module.exports = {companyNameKey, stubCompanyData, stubCompanyDocId};
