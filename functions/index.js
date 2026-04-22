/**
 * Yogya App – Scheduled Sync Cloud Function
 * -----------------------------------------
 * Ye function har 6 ghante automatically chalti hai.
 * RapidAPI (Sarkari Result) se data fetch karke Firestore mein push karti hai.
 *
 * Deploy:  cd functions && npm install && firebase deploy --only functions
 *
 * Environment Variables (Firebase Functions config):
 *   firebase functions:config:set rapidapi.key="YOUR_KEY" rapidapi.host="sarkari-result.p.rapidapi.com"
 *
 * Ya .env file use karo (see below — defineString).
 */

import { onSchedule } from "firebase-functions/v2/scheduler";
import { defineString } from "firebase-functions/params";
import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue, Timestamp } from "firebase-admin/firestore";
import axios from "axios";

// ── Firebase init ──────────────────────────────────────
initializeApp();
const db = getFirestore();

// ── Config params (set via Firebase Console → Functions → Env) ──
const RAPIDAPI_KEY = defineString("RAPIDAPI_KEY");
const RAPIDAPI_HOST = defineString("RAPIDAPI_HOST", {
  default: "sarkari-result.p.rapidapi.com",
});
const RAPIDAPI_URL_RESULTS = defineString("RAPIDAPI_URL_RESULTS", {
  default: "https://sarkari-result.p.rapidapi.com/results/",
});
const RAPIDAPI_URL_JOBS = defineString("RAPIDAPI_URL_JOBS", {
  default: "https://sarkari-result.p.rapidapi.com/jobs/",
});

// ── Helpers ────────────────────────────────────────────
function safeLower(v) {
  return (v || "").toString().toLowerCase();
}

function parseExamId(title = "") {
  const t = safeLower(title);
  if (t.includes("upsc")) return "upsc";
  if (t.includes("ssc")) return "ssc";
  if (t.includes("ibps")) return "ibps";
  if (t.includes("rrb") || t.includes("railway")) return "rrb";
  if (t.includes("bpsc")) return "bpsc";
  if (t.includes("uppsc")) return "uppsc";
  if (t.includes("rpsc")) return "rpsc";
  if (t.includes("bank") || t.includes("sbi") || t.includes("rbi"))
    return "banking";
  if (
    t.includes("nda") ||
    t.includes("cds") ||
    t.includes("afcat") ||
    t.includes("airforce")
  )
    return "defence";
  if (
    t.includes("nta") ||
    t.includes("jee") ||
    t.includes("neet") ||
    t.includes("cuet")
  )
    return "nta";
  return "other";
}

function parseEventType(title = "") {
  const t = safeLower(title);
  if (t.includes("admit card")) return "admit_card";
  if (t.includes("answer key")) return "answer_key";
  if (t.includes("syllabus")) return "syllabus";
  if (t.includes("admission")) return "admission";
  if (
    t.includes("result") ||
    t.includes("score card") ||
    t.includes("merit list")
  )
    return "result";
  if (t.includes("notification")) return "notification";
  if (t.includes("apply") || t.includes("application")) return "application";
  return "update";
}

function parseStatus(title = "") {
  const t = safeLower(title);
  if (t.includes("out") || t.includes("declared") || t.includes("released"))
    return "published";
  if (t.includes("soon")) return "soon";
  if (t.includes("updated")) return "updated";
  return "published";
}

function parseYear(title = "") {
  const m = title.match(/\b(20\d{2})\b/);
  if (m) return Number(m[1]);
  return null;
}

function inferDateFromTitle(title = "") {
  const year = parseYear(title);
  const d = year ? new Date(Date.UTC(year, 0, 1)) : new Date();
  return Timestamp.fromDate(d);
}

function makeDeterministicId(prefix, title, link) {
  const raw = `${prefix}__${title}__${link}`.trim();
  return Buffer.from(raw).toString("base64url").slice(0, 120);
}

// ── API fetch ──────────────────────────────────────────
async function fetchEndpoint(url, apiKey, apiHost) {
  const res = await axios.get(url, {
    headers: {
      "x-rapidapi-key": apiKey,
      "x-rapidapi-host": apiHost,
      "Content-Type": "application/json",
    },
    timeout: 30000,
  });

  if (!res?.data?.success) {
    throw new Error(`API returned non-success for ${url}`);
  }

  return Array.isArray(res.data.data) ? res.data.data : [];
}

// ── Doc builders ───────────────────────────────────────
function toTimelineDoc(item, sourceType) {
  const title = (item.title || "").toString().trim();
  const link = (item.link || "").toString().trim();
  if (!title || !link) return null;

  const type = parseEventType(title);
  const examId = parseExamId(title);
  const status = parseStatus(title);
  const eventDate = inferDateFromTitle(title);

  return {
    examId,
    examName: title,
    event: title,
    type,
    date: eventDate,
    completed: type === "result" || status === "published",
    source: `rapidapi_${sourceType}`,
    sourceUrl: link,
    status,
    updatedAt: FieldValue.serverTimestamp(),
    createdAt: FieldValue.serverTimestamp(),
  };
}

function toDeadlineDoc(item, sourceType) {
  const title = (item.title || "").toString().trim();
  const link = (item.link || "").toString().trim();
  if (!title || !link) return null;

  const t = safeLower(title);
  const looksDeadline =
    t.includes("last date") ||
    t.includes("deadline") ||
    t.includes("apply") ||
    t.includes("application");

  if (!looksDeadline) return null;

  const date = inferDateFromTitle(title);
  const examId = parseExamId(title);

  return {
    examId,
    examName: title,
    event: "Application Deadline",
    date,
    urgency: "medium",
    source: `rapidapi_${sourceType}`,
    sourceUrl: link,
    updatedAt: FieldValue.serverTimestamp(),
    createdAt: FieldValue.serverTimestamp(),
  };
}

// ── Batch upsert ───────────────────────────────────────
async function upsertDocs(collectionName, docs, prefix) {
  const batchSize = 400;
  let index = 0;

  while (index < docs.length) {
    const chunk = docs.slice(index, index + batchSize);
    const batch = db.batch();

    for (const d of chunk) {
      const id = makeDeterministicId(
        prefix,
        d.event || d.examName,
        d.sourceUrl || ""
      );
      const ref = db.collection(collectionName).doc(id);
      batch.set(ref, d, { merge: true });
    }

    await batch.commit();
    index += batchSize;
  }
}

// ══════════════════════════════════════════════════════════
//  SCHEDULED CLOUD FUNCTION — runs every 6 hours
// ══════════════════════════════════════════════════════════
export const scheduledSync = onSchedule(
  {
    // Cron: every 6 hours → 0:00, 6:00, 12:00, 18:00 IST
    schedule: "every 6 hours",
    timeZone: "Asia/Kolkata",
    // Keep retries low for free tier
    retryCount: 1,
    // Memory & timeout
    memory: "256MiB",
    timeoutSeconds: 120,
    region: "asia-south1",
  },
  async (_event) => {
    const apiKey = RAPIDAPI_KEY.value();
    const apiHost = RAPIDAPI_HOST.value();
    const urlResults = RAPIDAPI_URL_RESULTS.value();
    const urlJobs = RAPIDAPI_URL_JOBS.value();

    try {
      console.log("⏳ [scheduledSync] Fetching results endpoint...");
      const resultsItems = await fetchEndpoint(urlResults, apiKey, apiHost);

      console.log("⏳ [scheduledSync] Fetching latest-jobs endpoint...");
      const jobsItems = await fetchEndpoint(urlJobs, apiKey, apiHost);

      const rawAll = [
        ...resultsItems.map((x) => ({ ...x, __sourceType: "results" })),
        ...jobsItems.map((x) => ({ ...x, __sourceType: "latest_jobs" })),
      ];

      const timelineDocs = [];
      const deadlineDocs = [];

      for (const item of rawAll) {
        const src = item.__sourceType;
        const tDoc = toTimelineDoc(item, src);
        if (tDoc) timelineDocs.push(tDoc);
        const dDoc = toDeadlineDoc(item, src);
        if (dDoc) deadlineDocs.push(dDoc);
      }

      // In-memory dedupe
      const timelineMap = new Map();
      for (const d of timelineDocs) {
        timelineMap.set(`${d.sourceUrl}__${d.event}`, d);
      }
      const deadlineMap = new Map();
      for (const d of deadlineDocs) {
        deadlineMap.set(`${d.sourceUrl}__${d.event}`, d);
      }

      const finalTimeline = [...timelineMap.values()];
      const finalDeadlines = [...deadlineMap.values()];

      console.log(
        `🧾 [scheduledSync] Timeline: ${finalTimeline.length}, Deadlines: ${finalDeadlines.length}`
      );

      await upsertDocs("timeline_events", finalTimeline, "timeline");
      await upsertDocs("exam_deadlines", finalDeadlines, "deadline");

      await db.collection("sync_meta").doc("meta").set(
        {
          lastSyncAt: FieldValue.serverTimestamp(),
          lastSyncStatus: "success",
          error: "",
          provider: "rapidapi_sarkari_result",
          syncType: "cloud_function_scheduled",
          counts: {
            resultsItems: resultsItems.length,
            jobsItems: jobsItems.length,
            timeline: finalTimeline.length,
            deadlines: finalDeadlines.length,
          },
        },
        { merge: true }
      );

      console.log("✅ [scheduledSync] Sync completed successfully");
    } catch (err) {
      console.error("❌ [scheduledSync] Sync failed:", err.message);

      await db.collection("sync_meta").doc("meta").set(
        {
          lastSyncAt: FieldValue.serverTimestamp(),
          lastSyncStatus: "failed",
          error: err.message || "unknown error",
          provider: "rapidapi_sarkari_result",
          syncType: "cloud_function_scheduled",
        },
        { merge: true }
      );

      throw err; // Let Cloud Functions know it failed
    }
  }
);
