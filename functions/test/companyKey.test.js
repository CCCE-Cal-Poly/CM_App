const test = require("node:test");
const assert = require("node:assert");
const {companyNameKey, stubCompanyData, stubCompanyDocId} = require("../companyKey");

test("strips legal suffixes, punctuation and case", () => {
  assert.strictEqual(companyNameKey("The Whiting-Turner Contracting Co."), "whitingturnercontracting");
  assert.strictEqual(companyNameKey("The Whiting-Turner Contracting Company"), "whitingturnercontracting");
  assert.strictEqual(companyNameKey("C.W. Driver, LLC"), "cwdriver");
  assert.strictEqual(companyNameKey("Cupertino Electric, Inc."), "cupertinoelectric");
  assert.strictEqual(companyNameKey("Plant Construction Company, L.P."), companyNameKey("Plant Construction"));
});

test("drops parentheticals and normalizes ampersands", () => {
  assert.strictEqual(companyNameKey("Performance Contracting, Inc. (PCI)"), "performancecontracting");
  assert.strictEqual(companyNameKey("McGuire and Hester"), companyNameKey("McGuire & Hester"));
});

test("does not merge genuinely different names", () => {
  assert.notStrictEqual(companyNameKey("Bernards"), companyNameKey("Bernards Construction"));
  assert.notStrictEqual(companyNameKey("Vance Brown"), companyNameKey("Vance Brown Builders"));
});

test("returns empty for non-strings and meaningless names", () => {
  assert.strictEqual(companyNameKey(undefined), "");
  assert.strictEqual(companyNameKey(null), "");
  assert.strictEqual(companyNameKey("  "), "");
  assert.strictEqual(companyNameKey("Inc."), "");
});

test("stub doc matches existing allCompanies field shape", () => {
  const stub = stubCompanyData(" Webcor ", {website: "https://webcor.com", sourceEventId: "e1"}, "TS");
  for (const f of ["name", "about", "location", "msg", "logo", "recruiterName", "recruiterTitle", "recruiterEmail"]) {
    assert.strictEqual(typeof stub[f], "string", f);
  }
  assert.strictEqual(stub.name, "Webcor");
  assert.strictEqual(stub.nameKey, "webcor");
  assert.strictEqual(stub.isStub, true);
  assert.strictEqual(stubCompanyDocId("webcor"), "auto_webcor");
});
