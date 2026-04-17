import admin from "firebase-admin";
import fs from "fs";

const serviceAccount = JSON.parse(
    fs.readFileSync(new URL("./serviceAccountKey.json", import.meta.url), "utf8")
);

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const now = admin.firestore.FieldValue.serverTimestamp();

// -------- SAMPLE DATA --------
const timelineEvents = [
    { examId: "upsc_cse", examName: "UPSC CSE", event: "Notification Released", type: "notification", date: "2026-02-14T10:00:00+05:30", completed: true },
    { examId: "upsc_cse", examName: "UPSC CSE", event: "Application Start", type: "application_start", date: "2026-02-14T10:05:00+05:30", completed: true },
    { examId: "upsc_cse", examName: "UPSC CSE", event: "Application Deadline", type: "application_end", date: "2026-03-20T23:59:00+05:30", completed: true },
    { examId: "upsc_cse", examName: "UPSC CSE", event: "Prelims Exam", type: "prelims", date: "2026-06-07T09:30:00+05:30", completed: false },

    { examId: "ssc_cgl", examName: "SSC CGL", event: "Notification Released", type: "notification", date: "2026-04-10T11:00:00+05:30", completed: true },
    { examId: "ssc_cgl", examName: "SSC CGL", event: "Application Start", type: "application_start", date: "2026-04-18T00:00:00+05:30", completed: false },
    { examId: "ssc_cgl", examName: "SSC CGL", event: "Application Deadline", type: "application_end", date: "2026-05-20T23:59:00+05:30", completed: false },

    { examId: "ibps_po", examName: "IBPS PO", event: "Notification Released", type: "notification", date: "2026-07-25T10:00:00+05:30", completed: false },
    { examId: "rrb_ntpc", examName: "RRB NTPC", event: "Application Deadline", type: "application_end", date: "2026-08-30T23:59:00+05:30", completed: false },
    { examId: "bpsc", examName: "BPSC", event: "Prelims Exam", type: "prelims", date: "2026-09-12T10:00:00+05:30", completed: false }
];

const examDeadlines = [
    { examId: "upsc_cse", examName: "UPSC CSE", event: "Application Deadline", date: "2026-03-20T23:59:00+05:30", urgency: "high" },
    { examId: "ssc_cgl", examName: "SSC CGL", event: "Application Deadline", date: "2026-05-20T23:59:00+05:30", urgency: "high" },
    { examId: "ibps_po", examName: "IBPS PO", event: "Registration Ends", date: "2026-08-18T23:59:00+05:30", urgency: "medium" },
    { examId: "rrb_ntpc", examName: "RRB NTPC", event: "Application Deadline", date: "2026-08-30T23:59:00+05:30", urgency: "medium" },
    { examId: "bpsc", examName: "BPSC", event: "Form Correction Last Date", date: "2026-07-15T23:59:00+05:30", urgency: "low" },
    { examId: "uppsc_pcs", examName: "UPPSC PCS", event: "Application Deadline", date: "2026-06-28T23:59:00+05:30", urgency: "high" }
];

// -------- BULK WRITE --------
async function seed() {
    const batch = db.batch();

    for (const item of timelineEvents) {
        const ref = db.collection("timeline_events").doc();
        batch.set(ref, {
            ...item,
            date: admin.firestore.Timestamp.fromDate(new Date(item.date)),
            source: "manual_seed",
            updatedAt: now,
        });
    }

    for (const item of examDeadlines) {
        const ref = db.collection("exam_deadlines").doc();
        batch.set(ref, {
            ...item,
            date: admin.firestore.Timestamp.fromDate(new Date(item.date)),
            source: "manual_seed",
            updatedAt: now,
        });
    }

    const syncMetaRef = db.collection("sync_meta").doc("meta");
    batch.set(syncMetaRef, {
        lastSyncAt: now,
        lastSyncStatus: "success",
        error: ""
    }, { merge: true });

    await batch.commit();
    console.log("✅ Seed completed successfully.");
}

seed().catch((e) => {
    console.error("❌ Seed failed:", e);
    process.exit(1);
});