// import admin from "firebase-admin";
// import fs from "fs";
// import axios from "axios";
// import dotenv from "dotenv";

// dotenv.config();

// const serviceAccount = JSON.parse(
//   fs.readFileSync(new URL("./serviceAccountKey.json", import.meta.url), "utf8")
// );

// admin.initializeApp({
//   credential: admin.credential.cert(serviceAccount),
// });

// const db = admin.firestore();
// const now = admin.firestore.FieldValue.serverTimestamp();

// function toTimestamp(value) {
//   const d = new Date(value);
//   if (Number.isNaN(d.getTime())) return null;
//   return admin.firestore.Timestamp.fromDate(d);
// }

// function mapExamId(name = "") {
//   const n = name.toLowerCase();
//   if (n.includes("upsc")) return "upsc_cse";
//   if (n.includes("ssc cgl") || n.includes("ssc")) return "ssc_cgl";
//   if (n.includes("ibps")) return "ibps_po";
//   if (n.includes("rrb")) return "rrb_ntpc";
//   if (n.includes("bpsc")) return "bpsc";
//   if (n.includes("uppsc")) return "uppsc_pcs";
//   return "other_exam";
// }

// function mapType(event = "") {
//   const e = event.toLowerCase();
//   if (e.includes("notification")) return "notification";
//   if (e.includes("start")) return "application_start";
//   if (e.includes("deadline") || e.includes("last date") || e.includes("end"))
//     return "application_end";
//   if (e.includes("prelims")) return "prelims";
//   if (e.includes("mains")) return "mains";
//   if (e.includes("interview")) return "interview";
//   if (e.includes("result")) return "result";
//   return "other";
// }

// function urgencyFromDate(ts) {
//   const diffDays = Math.ceil((ts.toDate().getTime() - Date.now()) / (1000 * 60 * 60 * 24));
//   if (diffDays <= 7) return "high";
//   if (diffDays <= 30) return "medium";
//   return "low";
// }

// async function fetchApiRows() {
//   const { RAPIDAPI_KEY, RAPIDAPI_HOST, RAPIDAPI_URL } = process.env;
//   if (!RAPIDAPI_KEY || !RAPIDAPI_HOST || !RAPIDAPI_URL) {
//     throw new Error("Missing RAPIDAPI env vars");
//   }

//   const res = await axios.get(RAPIDAPI_URL, {
//     headers: {
//       "x-rapidapi-key": RAPIDAPI_KEY,
//       "x-rapidapi-host": RAPIDAPI_HOST,
//     },
//     timeout: 20000,
//   });

//   // Expect array; if nested response adjust here
//   return Array.isArray(res.data) ? res.data : (res.data?.data ?? []);
// }

// function normalizeRows(rows) {
//   const timeline = [];
//   const deadlines = [];

//   for (const r of rows) {
//     // Adjust these keys as per your API response
//     const examName = (r.examName || r.title || r.exam || "").toString().trim();
//     const event = (r.event || r.stage || r.type || "").toString().trim();
//     const dateRaw = r.date || r.eventDate || r.deadline;

//     if (!examName || !event || !dateRaw) continue;

//     const ts = toTimestamp(dateRaw);
//     if (!ts) continue;

//     const examId = mapExamId(examName);
//     const type = mapType(event);

//     timeline.push({
//       examId,
//       examName,
//       event,
//       type,
//       date: ts,
//       completed: ts.toDate().getTime() < Date.now(),
//       source: "rapidapi",
//       updatedAt: now,
//     });

//     if (type === "application_end" || event.toLowerCase().includes("deadline")) {
//       deadlines.push({
//         examId,
//         examName,
//         event: "Application Deadline",
//         date: ts,
//         urgency: urgencyFromDate(ts),
//         source: "rapidapi",
//         updatedAt: now,
//       });
//     }
//   }

//   return { timeline, deadlines };
// }

// function dedupeKey(obj) {
//   return `${obj.examId}__${obj.event}__${obj.date.toDate().toISOString()}`;
// }

// async function upsertByDeterministicId(collection, docs) {
//   const batch = db.batch();

//   for (const d of docs) {
//     const id = Buffer.from(dedupeKey(d)).toString("base64url").slice(0, 120);
//     const ref = db.collection(collection).doc(id);
//     batch.set(ref, d, { merge: true });
//   }

//   await batch.commit();
// }

// async function runSync() {
//   try {
//     const rows = await fetchApiRows();
//     const { timeline, deadlines } = normalizeRows(rows);

//     await upsertByDeterministicId("timeline_events", timeline);
//     await upsertByDeterministicId("exam_deadlines", deadlines);

//     await db.collection("sync_meta").doc("meta").set(
//       {
//         lastSyncAt: now,
//         lastSyncStatus: "success",
//         error: "",
//         lastCounts: {
//           timeline: timeline.length,
//           deadlines: deadlines.length,
//           raw: rows.length,
//         },
//       },
//       { merge: true }
//     );

//     console.log("✅ Sync success", {
//       raw: rows.length,
//       timeline: timeline.length,
//       deadlines: deadlines.length,
//     });
//   } catch (e) {
//     console.error("❌ Sync failed:", e.message);

//     await db.collection("sync_meta").doc("meta").set(
//       {
//         lastSyncAt: now,
//         lastSyncStatus: "failed",
//         error: e.message || "unknown error",
//       },
//       { merge: true }
//     );

//     process.exit(1);
//   }
// }

// runSync();






// import admin from "firebase-admin";
// import fs from "fs";
// import axios from "axios";
// import dotenv from "dotenv";

// dotenv.config();

// /**
//  * ENV required:
//  * RAPIDAPI_KEY=...
//  * RAPIDAPI_HOST=sarkari-result.p.rapidapi.com
//  * RAPIDAPI_URL_RESULTS=https://sarkari-result.p.rapidapi.com/results/
//  * RAPIDAPI_URL_JOBS=https://sarkari-result.p.rapidapi.com/latest-jobs/
//  */

// let serviceAccount;
// try {
//   if (process.env.FIREBASE_SERVICE_ACCOUNT) {
//     serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
//   } else {
//     serviceAccount = JSON.parse(
//       fs.readFileSync(new URL("./serviceAccountKey.json", import.meta.url), "utf8")
//     );
//   }
// } catch (e) {
//   console.error("❌ Failed to load Firebase credentials:", e.message);
//   process.exit(1);
// }

// admin.initializeApp({
//   credential: admin.credential.cert(serviceAccount),
// });

// const db = admin.firestore();
// const nowServer = admin.firestore.FieldValue.serverTimestamp();

// function safeLower(v) {
//   return (v || "").toString().toLowerCase();
// }

// function parseExamId(title = "") {
//   const t = safeLower(title);

//   if (t.includes("upsc")) return "upsc";
//   if (t.includes("ssc")) return "ssc";
//   if (t.includes("ibps")) return "ibps";
//   if (t.includes("rrb") || t.includes("railway")) return "rrb";
//   if (t.includes("bpsc")) return "bpsc";
//   if (t.includes("uppsc")) return "uppsc";
//   if (t.includes("rpsc")) return "rpsc";
//   if (t.includes("bank") || t.includes("sbi") || t.includes("rbi")) return "banking";
//   if (t.includes("nda") || t.includes("cds") || t.includes("afcat") || t.includes("airforce"))
//     return "defence";
//   if (t.includes("nta") || t.includes("jee") || t.includes("neet") || t.includes("cuet"))
//     return "nta";
//   return "other";
// }

// function parseEventType(title = "") {
//   const t = safeLower(title);

//   if (t.includes("admit card")) return "admit_card";
//   if (t.includes("answer key")) return "answer_key";
//   if (t.includes("syllabus")) return "syllabus";
//   if (t.includes("admission")) return "admission";
//   if (t.includes("result") || t.includes("score card") || t.includes("merit list"))
//     return "result";
//   if (t.includes("notification")) return "notification";
//   if (t.includes("apply") || t.includes("application")) return "application";
//   return "update";
// }

// function parseStatus(title = "") {
//   const t = safeLower(title);
//   if (t.includes("out") || t.includes("declared") || t.includes("released")) return "published";
//   if (t.includes("soon")) return "soon";
//   if (t.includes("updated")) return "updated";
//   return "published";
// }

// function parseYear(title = "") {
//   const m = title.match(/\b(20\d{2})\b/);
//   if (m) return Number(m[1]);
//   return null;
// }

// function inferDateFromTitle(title = "") {
//   // API me exact date nahi hai, fallback use kar rahe:
//   // 1) year मिले तो Jan 1 of that year
//   // 2) warna current date
//   const year = parseYear(title);
//   const d = year ? new Date(Date.UTC(year, 0, 1)) : new Date();
//   return admin.firestore.Timestamp.fromDate(d);
// }

// function makeDeterministicId(prefix, title, link) {
//   const raw = `${prefix}__${title}__${link}`.trim();
//   return Buffer.from(raw).toString("base64url").slice(0, 120);
// }

// async function fetchEndpoint(url) {
//   const { RAPIDAPI_KEY, RAPIDAPI_HOST } = process.env;
//   if (!RAPIDAPI_KEY || !RAPIDAPI_HOST) {
//     throw new Error("Missing RAPIDAPI_KEY or RAPIDAPI_HOST in .env");
//   }

//   const res = await axios.get(url, {
//     headers: {
//       "x-rapidapi-key": RAPIDAPI_KEY,
//       "x-rapidapi-host": RAPIDAPI_HOST,
//       "Content-Type": "application/json",
//     },
//     timeout: 30000,
//   });

//   if (!res?.data?.success) {
//     throw new Error(`API returned non-success for ${url}`);
//   }

//   return Array.isArray(res.data.data) ? res.data.data : [];
// }

// function toTimelineDoc(item, sourceType) {
//   const title = (item.title || "").toString().trim();
//   const link = (item.link || "").toString().trim();

//   if (!title || !link) return null;

//   const type = parseEventType(title);
//   const examId = parseExamId(title);
//   const status = parseStatus(title);
//   const eventDate = inferDateFromTitle(title);

//   return {
//     examId,
//     examName: title, // since clean exam name not provided by API
//     event: title,
//     type,
//     date: eventDate,
//     completed: type === "result" || status === "published",
//     source: `rapidapi_${sourceType}`,
//     sourceUrl: link,
//     status,
//     updatedAt: nowServer,
//     createdAt: nowServer,
//   };
// }

// function toDeadlineDoc(item, sourceType) {
//   const title = (item.title || "").toString().trim();
//   const link = (item.link || "").toString().trim();
//   if (!title || !link) return null;

//   const t = safeLower(title);

//   // deadline-like only
//   const looksDeadline =
//     t.includes("last date") ||
//     t.includes("deadline") ||
//     t.includes("apply") ||
//     t.includes("application");

//   if (!looksDeadline) return null;

//   const date = inferDateFromTitle(title);
//   const examId = parseExamId(title);

//   return {
//     examId,
//     examName: title,
//     event: "Application Deadline",
//     date,
//     urgency: "medium",
//     source: `rapidapi_${sourceType}`,
//     sourceUrl: link,
//     updatedAt: nowServer,
//     createdAt: nowServer,
//   };
// }

// async function upsertDocs(collectionName, docs, prefix) {
//   const batchSize = 400;
//   let index = 0;

//   while (index < docs.length) {
//     const chunk = docs.slice(index, index + batchSize);
//     const batch = db.batch();

//     for (const d of chunk) {
//       const id = makeDeterministicId(prefix, d.event || d.examName, d.sourceUrl || "");
//       const ref = db.collection(collectionName).doc(id);
//       batch.set(ref, d, { merge: true });
//     }

//     await batch.commit();
//     index += batchSize;
//   }
// }

// async function run() {
//   const { RAPIDAPI_URL_RESULTS, RAPIDAPI_URL_JOBS } = process.env;

//   if (!RAPIDAPI_URL_RESULTS || !RAPIDAPI_URL_JOBS) {
//     throw new Error("Missing RAPIDAPI_URL_RESULTS or RAPIDAPI_URL_JOBS in .env");
//   }

//   console.log("⏳ Fetching results endpoint...");
//   const resultsItems = await fetchEndpoint(RAPIDAPI_URL_RESULTS);

//   console.log("⏳ Fetching latest-jobs endpoint...");
//   const jobsItems = await fetchEndpoint(RAPIDAPI_URL_JOBS);

//   const rawAll = [
//     ...resultsItems.map((x) => ({ ...x, __sourceType: "results" })),
//     ...jobsItems.map((x) => ({ ...x, __sourceType: "latest_jobs" })),
//   ];

//   const timelineDocs = [];
//   const deadlineDocs = [];

//   for (const item of rawAll) {
//     const src = item.__sourceType;

//     const tDoc = toTimelineDoc(item, src);
//     if (tDoc) timelineDocs.push(tDoc);

//     const dDoc = toDeadlineDoc(item, src);
//     if (dDoc) deadlineDocs.push(dDoc);
//   }

//   // In-memory dedupe by sourceUrl + event
//   const timelineMap = new Map();
//   for (const d of timelineDocs) {
//     const k = `${d.sourceUrl}__${d.event}`;
//     timelineMap.set(k, d);
//   }

//   const deadlineMap = new Map();
//   for (const d of deadlineDocs) {
//     const k = `${d.sourceUrl}__${d.event}`;
//     deadlineMap.set(k, d);
//   }

//   const finalTimeline = [...timelineMap.values()];
//   const finalDeadlines = [...deadlineMap.values()];

//   console.log(`🧾 Timeline docs: ${finalTimeline.length}`);
//   console.log(`⏰ Deadline docs: ${finalDeadlines.length}`);

//   await upsertDocs("timeline_events", finalTimeline, "timeline");
//   await upsertDocs("exam_deadlines", finalDeadlines, "deadline");

//   await db.collection("sync_meta").doc("meta").set(
//     {
//       lastSyncAt: nowServer,
//       lastSyncStatus: "success",
//       error: "",
//       provider: "rapidapi_sarkari_result",
//       counts: {
//         resultsItems: resultsItems.length,
//         jobsItems: jobsItems.length,
//         timeline: finalTimeline.length,
//         deadlines: finalDeadlines.length,
//       },
//     },
//     { merge: true }
//   );

//   console.log("✅ Sync completed successfully");
// }

// run().catch(async (err) => {
//   console.error("❌ Sync failed:", err.message);

//   try {
//     await db.collection("sync_meta").doc("meta").set(
//       {
//         lastSyncAt: nowServer,
//         lastSyncStatus: "failed",
//         error: err.message || "unknown error",
//         provider: "rapidapi_sarkari_result",
//       },
//       { merge: true }
//     );
//   } catch (_) { }

//   process.exit(1);
// });
















import admin from "firebase-admin";
import fs from "fs";
import axios from "axios";
import dotenv from "dotenv";

dotenv.config();

function loadServiceAccount() {
  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    return JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
  }

  return JSON.parse(
    fs.readFileSync(new URL("./serviceAccountKey.json", import.meta.url), "utf8")
  );
}

const serviceAccount = loadServiceAccount();

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db = admin.firestore();
const serverNow = admin.firestore.FieldValue.serverTimestamp();

function toTimestamp(value) {
  if (!value) return null;
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return null;
  return admin.firestore.Timestamp.fromDate(d);
}

function mapExamId(name = "") {
  const n = name.toLowerCase();
  if (n.includes("upsc")) return "upsc_cse";
  if (n.includes("ssc")) return "ssc_cgl";
  if (n.includes("ibps")) return "ibps_po";
  if (n.includes("rrb")) return "rrb_ntpc";
  if (n.includes("sbi")) return "sbi_po";
  if (n.includes("rbi")) return "rbi_grade_b";
  return "other_exam";
}

function mapType(event = "") {
  const e = event.toLowerCase();
  if (e.includes("notification")) return "notification";
  if (e.includes("start") || e.includes("open")) return "application_start";
  if (e.includes("deadline") || e.includes("last date") || e.includes("end")) return "application_end";
  if (e.includes("prelims")) return "prelims";
  if (e.includes("mains")) return "mains";
  if (e.includes("interview")) return "interview";
  if (e.includes("result")) return "result";
  if (e.includes("exam")) return "exam";
  return "other";
}

function urgencyFromDate(ts) {
  const diffDays = Math.ceil((ts.toDate().getTime() - Date.now()) / (1000 * 60 * 60 * 24));
  if (diffDays <= 7) return "high";
  if (diffDays <= 30) return "medium";
  return "low";
}

async function fetchApiRows() {
  const { RAPIDAPI_KEY, RAPIDAPI_HOST, RAPIDAPI_URL, RAPIDAPI_URL_RESULTS, RAPIDAPI_URL_JOBS } = process.env;
  const urls = [RAPIDAPI_URL, RAPIDAPI_URL_RESULTS, RAPIDAPI_URL_JOBS].filter(Boolean);

  if (!RAPIDAPI_KEY || !RAPIDAPI_HOST || urls.length === 0) {
    throw new Error(
      "Missing RAPIDAPI_KEY / RAPIDAPI_HOST and at least one RAPIDAPI_URL value"
    );
  }

  const responses = await Promise.all(
    urls.map((url) =>
      axios.get(url, {
        headers: {
          "x-rapidapi-key": RAPIDAPI_KEY,
          "x-rapidapi-host": RAPIDAPI_HOST,
        },
        timeout: 20000,
      })
    )
  );

  return responses.flatMap((res) =>
    Array.isArray(res.data) ? res.data : (res.data?.data ?? [])
  );
}

function normalizeRows(rows) {
  const timeline = [];
  const deadlines = [];

  for (const r of rows) {
    const examName = (r.examName || r.title || r.exam || "").toString().trim();
    const event = (r.event || r.stage || r.type || "").toString().trim();
    const dateRaw = r.date || r.deadline || r.eventDate || r.lastDate || r.updatedAt;
    const sourceUrl = (r.sourceUrl || r.url || "").toString();
    const ts = toTimestamp(dateRaw);

    if (!examName || !event || !ts) continue;

    const examId = mapExamId(examName);
    const type = mapType(event);

    const baseDoc = {
      examId,
      examName,
      event,
      type,
      date: ts,
      sourceUrl,
      updatedAt: serverNow,
    };

    timeline.push({
      ...baseDoc,
      completed: ts.toDate().getTime() < Date.now(),
    });

    if (type === "application_end" || event.toLowerCase().includes("deadline")) {
      deadlines.push({
        ...baseDoc,
        urgency: urgencyFromDate(ts),
      });
    }
  }

  return { timeline, deadlines };
}

async function upsertCollection(collectionName, docs) {
  const chunkSize = 400;
  for (let i = 0; i < docs.length; i += chunkSize) {
    const chunk = docs.slice(i, i + chunkSize);
    const batch = db.batch();

    for (const doc of chunk) {
      const id = `${doc.examId}_${doc.type}_${doc.date.toMillis()}`;
      const ref = db.collection(collectionName).doc(id);
      batch.set(ref, { ...doc, createdAt: serverNow }, { merge: true });
    }

    await batch.commit();
  }
}

async function runSync() {
  console.log("Sync started...");
  const rows = await fetchApiRows();
  const { timeline, deadlines } = normalizeRows(rows);

  console.log(`Fetched rows: ${rows.length}`);
  console.log(`Timeline docs: ${timeline.length}`);
  console.log(`Deadline docs: ${deadlines.length}`);

  if (timeline.length > 0) await upsertCollection("timeline_events", timeline);
  if (deadlines.length > 0) await upsertCollection("exam_deadlines", deadlines);

  console.log("Sync completed.");
}

runSync().catch((err) => {
  console.error("Sync failed:", err);
  process.exit(1);
});
