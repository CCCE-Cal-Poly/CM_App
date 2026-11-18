const test = require("node:test");
const assert = require("node:assert");
const {
  validateSignupPayload, slotProblem, formatUsPhone, ValidationError, slotCapacity,
} = require("../interviews");

const NOW = Date.UTC(2026, 10, 10, 18, 0); // 2026-11-10 18:00Z
const HOUR = 60 * 60 * 1000;

const validPayload = {
  blockId: "block1",
  slotStartMs: NOW + 24 * HOUR,
  fullName: "  Pat   Mustang ",
  major: "Construction Management",
  minor: "",
  gradTerm: "Spring",
  gradYear: 2027,
  localPhone: "805.555.1234",
  email: " Pat@CalPoly.edu ",
};

test("cleans a valid payload", () => {
  const out = validateSignupPayload(validPayload, NOW);
  assert.strictEqual(out.fullName, "Pat Mustang");
  assert.strictEqual(out.email, "pat@calpoly.edu");
  assert.strictEqual(out.localPhone, "(805) 555-1234");
  assert.strictEqual(out.minor, "");
  assert.strictEqual(out.gradYear, 2027);
});

test("rejects bad fields", () => {
  const bad = [
    {fullName: ""},
    {major: " "},
    {gradTerm: "Winter"},
    {gradYear: 2015},
    {gradYear: "2027.5"},
    {localPhone: "555-1234"},
    {email: "not-an-email"},
    {slotStartMs: "abc"},
    {blockId: "a/b"},
  ];
  for (const patch of bad) {
    assert.throws(() => validateSignupPayload({...validPayload, ...patch}, NOW), ValidationError, JSON.stringify(patch));
  }
});

test("phone formatting accepts a leading 1", () => {
  assert.strictEqual(formatUsPhone("+1 (805) 555-0000"), "(805) 555-0000");
});

test("slotProblem enforces block bounds, grid, deadline and past times", () => {
  const block = {
    eventType: "interviewBlock",
    startMs: NOW + 24 * HOUR,
    endMs: NOW + 26 * HOUR, // 2 hours
    slotMinutes: 30,
    signupsOpen: true,
  };
  assert.strictEqual(slotProblem(block, block.startMs, NOW), null);
  assert.strictEqual(slotProblem(block, block.startMs + 90 * 60 * 1000, NOW), null); // last slot
  assert.match(slotProblem(block, block.endMs, NOW), /outside/);
  assert.match(slotProblem(block, block.startMs + 10 * 60 * 1000, NOW), /not a valid/);
  assert.match(slotProblem({...block, signupsOpen: false}, block.startMs, NOW), /closed/);
  assert.match(slotProblem({...block, signupDeadlineMs: NOW - 1}, block.startMs, NOW), /deadline/);
  assert.match(slotProblem(block, block.startMs, block.startMs + 1), /passed/);
  assert.match(slotProblem({...block, eventType: "infoSession"}, block.startMs, NOW), /no longer exists/);
});

test("slotCapacity defaults to 1", () => {
  assert.strictEqual(slotCapacity({}), 1);
  assert.strictEqual(slotCapacity({interviewersPerSlot: 3}), 3);
});
