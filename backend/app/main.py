from __future__ import annotations

import json
import logging
import os
import secrets
import time
import uuid
from datetime import date, datetime
from typing import Annotated, Any
from dotenv import load_dotenv

load_dotenv()

from fastapi import Depends, FastAPI, HTTPException, Request, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.security import HTTPBasic, HTTPBasicCredentials
from contextlib import asynccontextmanager

# Rate limiting
try:
    from slowapi import Limiter, _rate_limit_exceeded_handler
    from slowapi.util import get_remote_address
    from slowapi.errors import RateLimitExceeded
    limiter = Limiter(key_func=get_remote_address)
except ImportError:
    limiter = None

# Sentry — error tracking (configure SENTRY_DSN in env)
try:
    import sentry_sdk
    from sentry_sdk.integrations.fastapi import FastApiIntegration
    from sentry_sdk.integrations.starlette import StarletteIntegration
    _sentry_dsn = os.getenv("SENTRY_DSN")
    if _sentry_dsn:
        sentry_sdk.init(
            dsn=_sentry_dsn,
            traces_sample_rate=0.3,  # 30% of requests for performance monitoring
            profiles_sample_rate=0.1,
            environment=os.getenv("ENVIRONMENT", "production"),
            release=f"yogya-backend@{os.getenv('APP_VERSION', '0.1.0')}",
            integrations=[StarletteIntegration(), FastApiIntegration()],
        )
        logging.info("Sentry initialized for error tracking")
except ImportError:
    pass

from .database import init_db, close_db, fetch_all, fetch_one, execute
from .cache import cache
from .eligibility_engine import EligibilityEngine
from .marksheet_validation import validate_marksheet
from .models import EligibilityResponse, MarksheetData, MarksheetValidationResponse, StudentProfile, ExamCriteria, RegistrationStatus
from .scraper import run_scraper_pipeline
from .ai_extractor import init_ai, extract_marksheet_raw_text, structure_marksheet_data
from .seed_data import get_seed_criteria

try:
    from apscheduler.schedulers.asyncio import AsyncIOScheduler
except Exception:
    AsyncIOScheduler = None

# ─── Logging setup ──────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger("yogya")

scheduler: Any = None
security = HTTPBasic()

ADMIN_USERNAME = os.getenv("ADMIN_USERNAME", "admin")
ADMIN_PASSWORD = os.getenv("ADMIN_PASSWORD", "changeme")


def verify_admin(credentials: Annotated[HTTPBasicCredentials, Depends(security)]) -> str:
    """Verify admin credentials using HTTP Basic Auth."""
    username_ok = secrets.compare_digest(credentials.username.encode(), ADMIN_USERNAME.encode())
    password_ok = secrets.compare_digest(credentials.password.encode(), ADMIN_PASSWORD.encode())
    if not (username_ok and password_ok):
        raise HTTPException(
            status_code=401,
            detail="Invalid admin credentials",
            headers={"WWW-Authenticate": "Basic"},
        )
    return credentials.username


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    logger.info("Starting Yogya backend...")
    try:
        await init_db()
        logger.info("Database initialized")
    except Exception as e:
        logger.warning(f"Database init failed; continuing with seed data: {e}")
    await cache.init()
    logger.info("Cache initialized")
    await init_ai()
    logger.info("AI services initialized")

    global scheduler
    if AsyncIOScheduler is not None:
        scheduler = AsyncIOScheduler(timezone="Asia/Kolkata")
        scheduler.add_job(
            run_scraper_pipeline,
            trigger="interval",
            hours=6,
            id="main_scraper",
            next_run_time=datetime.now()
            if os.getenv("RUN_SCRAPER_ON_STARTUP", "false").lower() == "true"
            else None,
        )
        scheduler.start()
        logger.info("Scraper scheduler started (every 6 hours)")

    logger.info("Yogya backend ready")
    yield

    # Shutdown
    logger.info("Shutting down Yogya backend...")
    if scheduler:
        scheduler.shutdown()
    await close_db()
    await cache.close()
    logger.info("Shutdown complete")


app = FastAPI(
    title="Yogya Eligibility Engine",
    version="0.1.0",
    description="REST backend for marksheet validation, exam criteria review, and student eligibility checks.",
    lifespan=lifespan,
)

# ─── Rate Limiting ──────────────────────────────────────────
if limiter is not None:
    app.state.limiter = limiter
    app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# ─── CORS (locked to allowed origins) ───────────────────────
_allowed_origins_str = os.getenv("ALLOWED_ORIGINS", "")
if _allowed_origins_str:
    _allowed_origins = [origin.strip() for origin in _allowed_origins_str.split(",") if origin.strip()]
else:
    # Development fallback — in production, always set ALLOWED_ORIGINS env var
    _allowed_origins = ["*"]
    logger.warning("CORS: ALLOWED_ORIGINS not set — using wildcard (not safe for production!)")

app.add_middleware(
    CORSMiddleware,
    allow_origins=_allowed_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["Content-Type", "Authorization", "X-Request-ID"],
)

@app.get("/api/v1/debug/criteria")
async def debug_criteria():
    """Temporary debug endpoint to see actual DB errors."""
    import traceback
    result = {"step": "start", "errors": []}
    try:
        result["step"] = "fetching rows"
        rows = await fetch_all("SELECT * FROM exam_criteria WHERE is_active = TRUE")
        result["row_count"] = len(rows) if rows else 0
        if rows:
            result["first_row_keys"] = list(dict(rows[0]).keys())
            result["first_row_name"] = rows[0].get("exam_short_name", "UNKNOWN")
            # Try parsing first row
            result["step"] = "parsing first row"
            row = dict(rows[0])
            result["raw_min_education"] = str(row.get("min_education"))
            
            reg_row = await fetch_one("SELECT * FROM exam_registration_status WHERE exam_short_name = %s", row["exam_short_name"])
            result["reg_row_found"] = reg_row is not None
            
            reg_status = RegistrationStatus()
            row["registration"] = reg_status.model_dump()
            row["exam_full_name"] = row.get("exam_full_name") or "Unknown"
            row["conducting_body"] = row.get("conducting_body") or ""
            row["exam_category"] = row.get("exam_category") or "OTHER"
            row["min_education"] = row.get("min_education") or "10TH"
            for field in ["required_stream", "required_subjects", "required_degree", "additional_rules"]:
                if isinstance(row.get(field), str):
                    row[field] = json.loads(row[field])
            
            result["step"] = "creating ExamCriteria"
            criteria = ExamCriteria(**row)
            result["step"] = "success"
            result["parsed_name"] = criteria.exam_short_name
    except Exception as e:
        result["error"] = str(e)
        result["traceback"] = traceback.format_exc()
    return result


async def load_all_criteria() -> list[ExamCriteria]:
    try:
        rows = await fetch_all("SELECT * FROM exam_criteria WHERE is_active = TRUE")
    except Exception as e:
        print(f"Criteria DB unavailable, using seed data: {e}")
        return get_seed_criteria()

    if not rows:
        return get_seed_criteria()

    criteria_list = []
    for row in rows:
        try:
            reg_row = await fetch_one("SELECT * FROM exam_registration_status WHERE exam_short_name = %s", row["exam_short_name"])
            reg_status = RegistrationStatus()
            if reg_row:
                reg_status = RegistrationStatus(
                    registration_open=reg_row.get("registration_open", False),
                    registration_start=reg_row.get("registration_start"),
                    registration_end=reg_row.get("registration_end"),
                    exam_date_text=reg_row.get("exam_date_text"),
                    admit_card_date=reg_row.get("admit_card_date"),
                    result_date=reg_row.get("result_date"),
                    apply_url=reg_row.get("apply_url"),
                    official_url=reg_row.get("official_url"),
                    notification_pdf_url=reg_row.get("notification_pdf_url"),
                    correction_window_start=reg_row.get("correction_window_start"),
                    correction_window_end=reg_row.get("correction_window_end"),
                    last_scraped_at=reg_row.get("last_scraped_at"),
                )

            row = dict(row)
            row["registration"] = reg_status.model_dump()
            row["exam_full_name"] = row.get("exam_full_name") or row.get("exam_short_name") or "Unknown Exam"
            row["conducting_body"] = row.get("conducting_body") or ""
            row["exam_category"] = row.get("exam_category") or "OTHER"
            row["min_education"] = row.get("min_education") or "10TH"
            # Handle JSONB fields correctly
            for field in ["required_stream", "required_subjects", "required_degree", "additional_rules"]:
                if isinstance(row.get(field), str):
                    row[field] = json.loads(row[field])
            criteria_list.append(ExamCriteria(**row))
        except Exception as e:
            print(f"Error parsing criteria {row.get('exam_short_name')}: {e}")

    return criteria_list or get_seed_criteria()


# ─── Request Logging Middleware ────────────────────────────
@app.middleware("http")
async def request_logging_middleware(request: Request, call_next):
    """Log every request with timing and request ID for debugging."""
    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4())[:8])
    start_time = time.time()

    response = await call_next(request)

    duration_ms = (time.time() - start_time) * 1000
    log_level = logging.WARNING if response.status_code >= 400 else logging.INFO
    # Don't log health checks to avoid noise
    if request.url.path != "/health":
        logger.log(
            log_level,
            f"{request_id} | {request.method} {request.url.path} | {response.status_code} | {duration_ms:.0f}ms",
        )
    if duration_ms > 5000:
        logger.warning(f"{request_id} | SLOW REQUEST: {request.url.path} took {duration_ms:.0f}ms")

    response.headers["X-Request-ID"] = request_id
    return response


@app.get("/health")
async def health() -> dict[str, Any]:
    return {
        "status": "ok",
        "scheduler_enabled": scheduler is not None,
        "sentry_enabled": bool(os.getenv("SENTRY_DSN")),
        "rate_limiting": limiter is not None,
        "integrations": {
            "database": bool(os.getenv("DATABASE_URL")),
            "redis": bool(os.getenv("REDIS_URL") or os.getenv("UPSTASH_REDIS_REST_URL")),
            "gemini": bool(os.getenv("GEMINI_API_KEY")),
            "groq": bool(os.getenv("GROQ_API_KEY")),
            "supabase_storage": bool(os.getenv("SUPABASE_URL") and os.getenv("SUPABASE_SERVICE_ROLE_KEY")),
            "resend": bool(os.getenv("RESEND_API_KEY")),
        },
    }


_check_eligibility_limit = "30/minute" if limiter else None

@app.post("/api/v1/check-eligibility", response_model=EligibilityResponse)
async def check_eligibility(request: Request, student: StudentProfile) -> EligibilityResponse:
    if limiter:
        await limiter.check("30/minute", request)
    criteria_list = await load_all_criteria()
    engine = EligibilityEngine(criteria_list)
    return engine.check_all(student)


@app.get("/api/v1/exams/open")
async def open_exams() -> dict[str, Any]:
    cached = await cache.get("open_exams_list")
    if cached:
        return cached

    criteria_list = await load_all_criteria()
    engine = EligibilityEngine(criteria_list)
    exams = engine.open_exams()
    
    payload = []
    today = date.today()
    for exam in exams:
        end = exam.registration.registration_end
        days_rem = (end.date() - today).days if end else None
        payload.append(
            {
                "exam_short_name": exam.exam_short_name,
                "exam_full_name": exam.exam_full_name,
                "registration_end": end.isoformat() if end else None,
                "days_remaining": days_rem,
                "apply_url": exam.registration.apply_url,
                "official_url": exam.registration.official_url,
            }
        )
        
    result = {"count": len(payload), "exams": payload}
    await cache.set("open_exams_list", result, 3600)  # 1 hour
    return result


@app.get("/api/v1/exam/{exam_short_name}")
async def exam_detail(exam_short_name: str) -> dict[str, Any]:
    try:
        cache_key = f"eligibility:{exam_short_name}"
        cached = await cache.get(cache_key)
        if cached:
            return cached
    except Exception:
        pass  # Cache miss is fine

    criteria_list = await load_all_criteria()
    # Find criteria directly — EligibilityEngine has no get_detail() method
    exam_name_lower = exam_short_name.strip().lower()
    criteria = next(
        (c for c in criteria_list if c.exam_short_name.strip().lower() == exam_name_lower),
        None,
    )
    
    if criteria is None:
        raise HTTPException(status_code=404, detail="Exam not found")

    try:
        # Safely get min_education value (might be enum or string)
        min_edu = criteria.min_education
        min_edu_str = min_edu.value if hasattr(min_edu, 'value') else str(min_edu)

        res = {
            "exam_short_name": criteria.exam_short_name,
            "exam_full_name": criteria.exam_full_name,
            "conducting_body": criteria.conducting_body,
            "exam_category": criteria.exam_category,
            "criteria": {
                "min_education": min_edu_str,
                "required_stream": criteria.required_stream,
                "required_subjects": criteria.required_subjects,
                "required_degree": criteria.required_degree,
                "age_limits": {
                    "general": {
                        "min": criteria.min_age,
                        "max": criteria.max_age_general,
                    },
                    "obc": {"min": criteria.min_age, "max": criteria.max_age_obc},
                    "sc_st": {"min": criteria.min_age, "max": criteria.max_age_sc_st},
                },
                "attempt_limits": {
                    "general": criteria.max_attempts_general,
                    "obc": criteria.max_attempts_obc,
                    "sc_st": criteria.max_attempts_sc_st,
                },
                "min_percentage": {
                    "general": criteria.min_percentage_general,
                    "obc": criteria.min_percentage_obc,
                    "sc_st": criteria.min_percentage_sc_st,
                    "ews": criteria.min_percentage_ews,
                },
            },
            "registration": {
                "open": getattr(criteria.registration, 'registration_open', False),
                "start": criteria.registration.registration_start.isoformat() if getattr(criteria.registration, 'registration_start', None) else None,
                "end": criteria.registration.registration_end.isoformat() if getattr(criteria.registration, 'registration_end', None) else None,
                "apply_url": getattr(criteria.registration, 'apply_url', None),
            },
            "notification_year": criteria.notification_year,
            "source_pdf_url": criteria.source_pdf_url,
            "last_verified": criteria.verified_at.isoformat() if criteria.verified_at else None,
        }
        try:
            await cache.set(cache_key, res, 6 * 3600)
        except Exception:
            pass
        return res
    except Exception as e:
        import traceback
        return JSONResponse(
            status_code=500,
            content={"error": str(e), "traceback": traceback.format_exc()},
        )


@app.post("/api/v1/extract-marksheet")
async def extract_marksheet(
    request: Request,
    file: UploadFile = File(...),
    marksheet_type: str = Form("auto"),
) -> JSONResponse:
    if limiter:
        await limiter.check("10/minute", request)  # Expensive AI operation — strict limit
    supported = ("image/jpeg", "image/png", "application/pdf")
    if file.content_type not in supported:
        return JSONResponse(status_code=400, content={"success": False, "error": "Unsupported file type"})

    # Limit file size to 10MB
    content = await file.read()
    if len(content) > 10 * 1024 * 1024:
        return JSONResponse(status_code=400, content={"success": False, "error": "File too large (max 10MB)"})

    try:
        raw_text = await extract_marksheet_raw_text(content, file.content_type)
        structured = await structure_marksheet_data(raw_text, marksheet_type)
        
        validation = validate_marksheet(structured, marksheet_type)
        
        return JSONResponse(status_code=200, content=validation.model_dump())
    except Exception as e:
        logger.error(f"Marksheet extraction failed: {e}")
        return JSONResponse(status_code=500, content={"success": False, "error": str(e)})


@app.post("/api/v1/validate-marksheet-data", response_model=MarksheetValidationResponse)
async def validate_marksheet_data(
    data: MarksheetData,
    marksheet_type: str = "auto",
) -> MarksheetValidationResponse:
    return validate_marksheet(data, marksheet_type)


@app.get("/api/v1/admin/queue")
async def admin_queue(admin: str = Depends(verify_admin)) -> dict[str, Any]:
    pending = await fetch_all("SELECT * FROM admin_review_queue WHERE status = 'PENDING'")
    # Format datetimes
    for item in pending:
        if isinstance(item.get("created_at"), datetime):
            item["created_at"] = item["created_at"].isoformat()
    return {"count": len(pending), "items": pending}


@app.post("/api/v1/admin/queue/{review_id}/approve")
async def approve_review(review_id: int, body: dict[str, Any] | None = None, admin: str = Depends(verify_admin)) -> dict[str, Any]:
    item = await fetch_one("SELECT * FROM admin_review_queue WHERE id = %s", review_id)
    if not item:
        raise HTTPException(status_code=404, detail="Review item not found")
        
    edited = (body or {}).get("edited_criteria")
    final_criteria = edited if edited else item.get("extracted_criteria", {})
    if isinstance(final_criteria, str):
        final_criteria = json.loads(final_criteria)

    # 1. Archive old criteria
    exam_short_name = item["exam_short_name"]
    old_c = await fetch_one("SELECT * FROM exam_criteria WHERE exam_short_name = %s", exam_short_name)
    if old_c:
        await execute(
            """INSERT INTO criteria_history (exam_short_name, criteria_snapshot, notification_year, valid_from, replaced_at, source_pdf_url)
               VALUES (%s, %s, %s, %s, NOW(), %s)""",
            exam_short_name, json.dumps(old_c, default=str), old_c.get("notification_year"), old_c.get("verified_at"), old_c.get("source_pdf_url")
        )

    # 2. Update or Insert new criteria
    # This requires unpacking final_criteria into the exam_criteria table.
    # Since final_criteria maps to the schema closely:
    fields = [
        "min_education", "required_stream", "required_subjects", "required_degree",
        "min_percentage_general", "min_percentage_obc", "min_percentage_sc_st", "min_percentage_ews",
        "min_age", "max_age_general", "max_age_obc", "max_age_sc_st", "max_age_ews",
        "max_age_pwbd_general", "max_age_pwbd_obc", "max_age_pwbd_sc_st",
        "age_cutoff_day", "age_cutoff_month", "max_attempts_general", "max_attempts_obc",
        "max_attempts_sc_st", "max_attempts_ews", "additional_rules", "notification_year"
    ]
    
    set_clauses = []
    values = []
    nullable_rule_fields = {"required_stream", "required_subjects", "required_degree", "additional_rules"}
    for f in fields:
        if f not in final_criteria:
            continue
        val = final_criteria.get(f)
        if val is None and f not in nullable_rule_fields:
            continue
        if isinstance(val, (dict, list)):
            val = json.dumps(val)
        set_clauses.append(f"{f} = %s")
        values.append(val)
        
    set_clauses.extend(["source_pdf_url = %s", "admin_verified = TRUE", "verified_at = NOW()", "updated_at = NOW()"])
    values.extend([item["pdf_url"]])
    
    if old_c:
        query = f"UPDATE exam_criteria SET {', '.join(set_clauses)} WHERE exam_short_name = %s"
        values.append(exam_short_name)
        await execute(query, *values)
    else:
        # Fallback if first time (ensure full_name etc exists or create stub)
        await execute(f"INSERT INTO exam_criteria (exam_short_name, exam_full_name, admin_verified, verified_at, updated_at) VALUES (%s, %s, TRUE, NOW(), NOW()) ON CONFLICT (exam_short_name) DO NOTHING", exam_short_name, exam_short_name)
        query = f"UPDATE exam_criteria SET {', '.join(set_clauses)} WHERE exam_short_name = %s"
        values.append(exam_short_name)
        await execute(query, *values)

    # 3. Update queue status
    await execute(
        "UPDATE admin_review_queue SET status = 'APPROVED', reviewed_at = NOW(), admin_edited_criteria = %s WHERE id = %s",
        json.dumps(edited) if edited else None, review_id
    )
    
    # 4. Invalidate cache
    await cache.delete(f"eligibility:{exam_short_name}")
    await cache.delete("open_exams_list")
    
    return {"success": True, "status": "APPROVED"}


@app.post("/api/v1/admin/queue/{review_id}/reject")
async def reject_review(review_id: int, body: dict[str, Any] | None = None, admin: str = Depends(verify_admin)) -> dict[str, Any]:
    item = await fetch_one("SELECT id FROM admin_review_queue WHERE id = %s", review_id)
    if not item:
        raise HTTPException(status_code=404, detail="Review item not found")
        
    notes = (body or {}).get("notes")
    await execute(
        "UPDATE admin_review_queue SET status = 'REJECTED', reviewed_at = NOW(), admin_notes = %s WHERE id = %s",
        notes, review_id
    )
    return {"success": True, "status": "REJECTED"}


@app.get("/admin", response_class=HTMLResponse)
async def admin_dashboard(admin: str = Depends(verify_admin)) -> str:
    pending = await fetch_one("SELECT COUNT(*) FROM admin_review_queue WHERE status = 'PENDING'")
    pending_count = pending["count"] if pending else 0
    
    criteria = await fetch_one("SELECT COUNT(*) FROM exam_criteria WHERE is_active = TRUE")
    criteria_count = criteria["count"] if criteria else 0
    
    return f"""
    <!doctype html>
    <html>
      <head><title>Yogya Admin</title></head>
      <body style="font-family: system-ui; margin: 40px;">
        <h1>Yogya Admin Dashboard</h1>
        <p>Pending reviews: <strong>{pending_count}</strong></p>
        <p>Active Criteria loaded: <strong>{criteria_count}</strong></p>
        <p>Scraper status: <strong>{'scheduled' if scheduler else 'disabled'}</strong></p>
        <p><a href="/api/v1/admin/queue">View Pending Queue (JSON)</a></p>
        <p><a href="/admin/queue">Review Pending Queue</a></p>
        <p><a href="/docs">Open API docs</a></p>
      </body>
    </html>
    """


@app.get("/admin/queue", response_class=HTMLResponse)
async def admin_queue_page(admin: str = Depends(verify_admin)) -> str:
    pending = await fetch_all("SELECT * FROM admin_review_queue WHERE status = 'PENDING' ORDER BY created_at DESC")
    items_html = []
    for item in pending:
        review_id = item["id"]
        criteria = item.get("extracted_criteria") or {}
        changes = item.get("changes_detected") or {}
        if isinstance(criteria, str):
            criteria_text = criteria
        else:
            criteria_text = json.dumps(criteria, indent=2, default=str)
        changes_text = changes if isinstance(changes, str) else json.dumps(changes, indent=2, default=str)
        items_html.append(
            f"""
            <section style="border:1px solid #ddd;border-radius:8px;padding:16px;margin:16px 0;">
              <h2>{item.get('exam_short_name')}</h2>
              <p>Confidence: <strong>{item.get('overall_confidence') or 0:.1f}%</strong></p>
              <p><a href="{item.get('pdf_url')}" target="_blank">Open source PDF</a></p>
              <details><summary>Changes detected</summary><pre>{changes_text}</pre></details>
              <label for="criteria-{review_id}">Editable criteria JSON</label>
              <textarea id="criteria-{review_id}" style="width:100%;height:260px;font-family:monospace;">{criteria_text}</textarea>
              <div style="margin-top:12px;display:flex;gap:8px;">
                <button onclick="approve({review_id})">Approve</button>
                <button onclick="rejectItem({review_id})">Reject</button>
              </div>
            </section>
            """
        )

    return f"""
    <!doctype html>
    <html>
      <head><title>Yogya Admin Queue</title></head>
      <body style="font-family: system-ui; margin: 40px; max-width: 1000px;">
        <h1>Pending Eligibility Reviews ({len(pending)})</h1>
        {''.join(items_html) if items_html else '<p>No pending reviews.</p>'}
        <script>
          async function approve(id) {{
            const raw = document.getElementById(`criteria-${{id}}`).value;
            const edited_criteria = JSON.parse(raw);
            const res = await fetch(`/api/v1/admin/queue/${{id}}/approve`, {{
              method: 'POST',
              headers: {{'Content-Type': 'application/json'}},
              body: JSON.stringify({{edited_criteria}})
            }});
            if (!res.ok) alert(await res.text());
            else location.reload();
          }}
          async function rejectItem(id) {{
            const notes = prompt('Reject notes') || '';
            const res = await fetch(`/api/v1/admin/queue/${{id}}/reject`, {{
              method: 'POST',
              headers: {{'Content-Type': 'application/json'}},
              body: JSON.stringify({{notes}})
            }});
            if (!res.ok) alert(await res.text());
            else location.reload();
          }}
        </script>
      </body>
    </html>
    """
