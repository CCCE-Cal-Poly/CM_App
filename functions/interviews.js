// Pure helpers for interview-block sign-ups (no Firestore access) so they can
// be unit tested. Used by signUpForInterview / cancelInterviewSignup in index.js.

const INTERVIEW_EVENT_TYPE = "interviewBlock";
const GRAD_TERMS = ["Fall", "Spring", "Summer"];
const STUDENT_CANCEL_CUTOFF_MS = 2 * 60 * 60 * 1000; // students may cancel until 2h before
const REMINDER_LEAD_MS = 60 * 60 * 1000; // reminder 1h before the slot
const DISPLAY_TIME_ZONE = "America/Los_Angeles";

class ValidationError extends Error {}

function cleanString(value, field, {min = 0, max = 100} = {}) {
  const s = typeof value === "string" ? value.trim().replace(/\s+/g, " ") : "";
  if (s.length < min) {
    throw new ValidationError(min <= 1 ? `${field} is required` : `${field} is too short`);
  }
  if (s.length > max) throw new ValidationError(`${field} is too long`);
  return s;
}

/**
 * Accepts US numbers in any common format; returns "(805) 555-1234".
 * @param {*} value
 * @return {string}
 */
function formatUsPhone(value) {
  let digits = typeof value === "string" ? value.replace(/\D/g, "") : "";
  if (digits.length === 11 && digits.startsWith("1")) digits = digits.slice(1);
  if (digits.length !== 10) {
    throw new ValidationError("Local phone must be a 10-digit US number");
  }
  return `(${digits.slice(0, 3)}) ${digits.slice(3, 6)}-${digits.slice(6)}`;
}

function cleanEmail(value) {
  const email = typeof value === "string" ? value.trim().toLowerCase() : "";
  if (email.length > 254 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    throw new ValidationError("A valid email is required");
  }
  return email;
}

/**
 * Validates the student-supplied part of a sign-up request.
 * @param {object} data request.data from the callable
 * @param {number} nowMs
 * @return {object} cleaned fields
 */
function validateSignupPayload(data, nowMs) {
  if (!data || typeof data !== "object") throw new ValidationError("Missing sign-up details");

  const blockId = cleanString(data.blockId, "blockId", {min: 1, max: 200});
  if (blockId.includes("/")) throw new ValidationError("Invalid blockId");

  const slotStartMs = Number(data.slotStartMs);
  if (!Number.isSafeInteger(slotStartMs) || slotStartMs <= 0) {
    throw new ValidationError("Choose an interview time");
  }

  const gradTerm = typeof data.gradTerm === "string" ? data.gradTerm.trim() : "";
  if (!GRAD_TERMS.includes(gradTerm)) {
    throw new ValidationError(`Graduation term must be one of ${GRAD_TERMS.join(", ")}`);
  }

  const currentYear = new Date(nowMs).getUTCFullYear();
  const gradYear = Number(data.gradYear);
  if (!Number.isInteger(gradYear) || gradYear < currentYear - 1 || gradYear > currentYear + 8) {
    throw new ValidationError("Graduation year is out of range");
  }

  return {
    blockId,
    slotStartMs,
    fullName: cleanString(data.fullName, "Full name", {min: 2, max: 100}),
    major: cleanString(data.major, "Major", {min: 1, max: 100}),
    minor: cleanString(data.minor, "Minor", {min: 0, max: 100}),
    gradTerm,
    gradYear,
    localPhone: formatUsPhone(data.localPhone),
    email: cleanEmail(data.email),
  };
}

/**
 * Checks that a block accepts a sign-up for the given slot right now.
 * Returns an error message, or null when the slot is valid.
 * @param {object} block events/{blockId} data with startMs/endMs already converted
 * @param {number} slotStartMs
 * @param {number} nowMs
 * @return {?string}
 */
function slotProblem(block, slotStartMs, nowMs) {
  if (!block || block.eventType !== INTERVIEW_EVENT_TYPE) return "This interview block no longer exists";
  if (block.signupsOpen === false) return "Sign-ups for this interview block are closed";
  if (block.signupDeadlineMs && nowMs > block.signupDeadlineMs) return "The sign-up deadline has passed";

  const slotMs = slotLengthMs(block);
  if (!slotMs) return "This interview block is misconfigured";
  if (slotStartMs < block.startMs || slotStartMs + slotMs > block.endMs) return "That time is outside this interview block";
  if ((slotStartMs - block.startMs) % slotMs !== 0) return "That is not a valid interview time";
  if (slotStartMs <= nowMs) return "That interview time has already passed";
  return null;
}

function slotLengthMs(block) {
  const minutes = Number(block && block.slotMinutes);
  return Number.isInteger(minutes) && minutes > 0 ? minutes * 60 * 1000 : 0;
}

function slotCapacity(block) {
  const n = Number(block && block.interviewersPerSlot);
  return Number.isInteger(n) && n > 0 ? n : 1;
}

function formatSlotTime(ms) {
  return new Date(ms).toLocaleString("en-US", {
    timeZone: DISPLAY_TIME_ZONE,
    weekday: "short",
    month: "short",
    day: "numeric",
    hour: "numeric",
    minute: "2-digit",
  });
}

module.exports = {
  INTERVIEW_EVENT_TYPE,
  GRAD_TERMS,
  STUDENT_CANCEL_CUTOFF_MS,
  REMINDER_LEAD_MS,
  ValidationError,
  validateSignupPayload,
  slotProblem,
  slotLengthMs,
  slotCapacity,
  formatUsPhone,
  formatSlotTime,
};
