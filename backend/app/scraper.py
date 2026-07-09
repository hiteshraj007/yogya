import asyncio
import hashlib
import json
import os
from datetime import datetime, timezone
from urllib.parse import urljoin

from bs4 import BeautifulSoup
from playwright.async_api import async_playwright
import httpx
from supabase import create_client, Client

from .database import execute, fetch_all, fetch_one
from .ai_extractor import extract_criteria_from_pdf, extract_registration_dates_from_pdf


def get_supabase_client() -> Client:
    url = os.getenv("SUPABASE_URL")
    key = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
    if not url or not key:
        raise ValueError("SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set")
    return create_client(url, key)


async def run_scraper_pipeline() -> None:
    sources = await fetch_all("SELECT * FROM exam_sources WHERE is_active = TRUE")
    if not sources:
        return

    start_time = datetime.now(timezone.utc)
    pdfs_found = 0
    new_pdfs = 0
    updates = 0
    errors = []

    try:
        async with async_playwright() as p:
            browser = await p.chromium.launch(headless=True)
            for source in sources:
                try:
                    res = await _scrape_source(browser, source)
                    if res:
                        pdfs_found += res.get("pdfs_found", 0)
                        if res.get("is_new"):
                            new_pdfs += 1
                        if res.get("updates_made"):
                            updates += 1
                except Exception as e:
                    errors.append(f"Source {source['exam_short_name']} error: {str(e)}")
            
            await browser.close()
    except Exception as e:
        errors.append(f"Scraper error: {str(e)}")

    status = "FAILED" if errors and len(errors) == len(sources) else "PARTIAL" if errors else "SUCCESS"
    duration = (datetime.now(timezone.utc) - start_time).total_seconds()
    
    await execute(
        """INSERT INTO scraper_logs (source_name, status, pdfs_found, new_pdfs_detected, updates_made, error_message, duration_seconds)
           VALUES (%s, %s, %s, %s, %s, %s, %s)""",
        "SYSTEM", status, pdfs_found, new_pdfs, updates, "\n".join(errors), duration
    )


async def _scrape_source(browser, source: dict) -> dict:
    async def load_page() -> str:
        page = await browser.new_page()
        try:
            await page.goto(source["notification_page_url"], wait_until="domcontentloaded", timeout=30000)
            return await page.content()
        finally:
            await page.close()

    content = await _retry(load_page)

    soup = BeautifulSoup(content, "html.parser")
    links = soup.find_all("a", href=True)
    
    pdf_links = []
    keyword = (source["pdf_keyword_filter"] or "").lower()
    
    for link in links:
        href = link["href"]
        if ".pdf" in href.lower() and (not keyword or keyword in link.text.lower() or keyword in href.lower()):
            pdf_links.append(urljoin(source["notification_page_url"], href))

    if not pdf_links:
        return {"pdfs_found": 0}

    latest_pdf = pdf_links[0]
    
    async def download_pdf() -> bytes:
        async with httpx.AsyncClient() as client:
            res = await client.get(latest_pdf, follow_redirects=True, timeout=30.0)
            if res.status_code != 200:
                raise Exception(f"Failed to download PDF {latest_pdf}")
            return res.content

    pdf_bytes = await _retry(download_pdf)

    pdf_hash = hashlib.sha256(pdf_bytes).hexdigest()
    
    if source["last_pdf_hash"] == pdf_hash:
        await execute(
            "UPDATE exam_sources SET last_checked_at = NOW() WHERE id = %s",
            source["id"]
        )
        return {"pdfs_found": len(pdf_links), "is_new": False}

    # Upload to Supabase Storage
    sb = get_supabase_client()
    bucket = os.getenv("SUPABASE_STORAGE_BUCKET", "pdfs")
    year = datetime.now().year
    filename = f"{source['exam_short_name']}_{year}_{pdf_hash[:8]}.pdf"
    path = f"{source['exam_short_name']}/{year}/{filename}"
    
    # Check if exists, else upload
    try:
        sb.storage.from_(bucket).upload(path, pdf_bytes, file_options={"content-type": "application/pdf"})
    except Exception:
        pass # probably already exists
    
    public_url = sb.storage.from_(bucket).get_public_url(path)

    # Update source
    await execute(
        "UPDATE exam_sources SET last_checked_at = NOW(), last_pdf_hash = %s, last_pdf_url = %s WHERE id = %s",
        pdf_hash, public_url, source["id"]
    )

    # Component 2 & 3: Extract and queue
    updates_made = False
    try:
        criteria_json = await extract_criteria_from_pdf(pdf_bytes, source["exam_short_name"])
        conf_scores = {k: v.get("confidence", 0) for k, v in criteria_json.items() if isinstance(v, dict)}
        avg_conf = sum(conf_scores.values()) / len(conf_scores) if conf_scores else 0
        
        # Format the actual extracted criteria (remove the wrapper)
        formatted_criteria = {k: v.get("value") for k, v in criteria_json.items() if isinstance(v, dict)}

        # Find previous criteria id
        prev_criteria = await fetch_one("SELECT * FROM exam_criteria WHERE exam_short_name = %s", source["exam_short_name"])
        prev_id = prev_criteria["id"] if prev_criteria else None

        await execute(
            """INSERT INTO admin_review_queue 
               (exam_short_name, pdf_url, pdf_hash, extracted_criteria, confidence_scores, overall_confidence, previous_criteria_id, changes_detected)
               VALUES (%s, %s, %s, %s, %s, %s, %s, %s)""",
            source["exam_short_name"], public_url, pdf_hash,
            json.dumps(formatted_criteria),
            json.dumps(conf_scores),
            avg_conf, prev_id, json.dumps(_changes_detected(prev_criteria, formatted_criteria))
        )
        await _notify_admin_review(source["exam_short_name"], public_url, avg_conf, formatted_criteria)
        updates_made = True
    except Exception as e:
        print(f"Extraction failed for {source['exam_short_name']}: {e}")

    try:
        reg_data = await extract_registration_dates_from_pdf(pdf_bytes)
        reg_start = reg_data.get("registration_start")
        reg_end = reg_data.get("registration_end")
        is_open = False
        if reg_start and reg_end:
            now = datetime.now(timezone.utc)
            start_dt = datetime.fromisoformat(reg_start.replace('Z', '+00:00'))
            end_dt = datetime.fromisoformat(reg_end.replace('Z', '+00:00'))
            is_open = start_dt <= now <= end_dt
            
        await execute(
            """INSERT INTO exam_registration_status (
               exam_short_name, registration_open, registration_start, registration_end,
               exam_date_text, admit_card_date, result_date, apply_url, official_url,
               notification_pdf_url, correction_window_start, correction_window_end, last_scraped_at
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, NOW())
            ON CONFLICT (exam_short_name) DO UPDATE SET
               registration_open = %s,
               registration_start = %s,
               registration_end = %s,
               exam_date_text = %s,
               admit_card_date = %s,
               result_date = %s,
               apply_url = %s,
               official_url = %s,
               notification_pdf_url = %s,
               correction_window_start = %s,
               correction_window_end = %s,
               last_scraped_at = NOW()""",
            source["exam_short_name"],
            is_open,
            reg_data.get("registration_start"),
            reg_data.get("registration_end"),
            reg_data.get("exam_date_text"),
            reg_data.get("admit_card_date"),
            reg_data.get("result_date"),
            reg_data.get("apply_url"),
            reg_data.get("official_url"),
            public_url,
            reg_data.get("correction_window_start"),
            reg_data.get("correction_window_end"),
            is_open,
            reg_data.get("registration_start"),
            reg_data.get("registration_end"),
            reg_data.get("exam_date_text"),
            reg_data.get("admit_card_date"),
            reg_data.get("result_date"),
            reg_data.get("apply_url"),
            reg_data.get("official_url"),
            public_url,
            reg_data.get("correction_window_start"),
            reg_data.get("correction_window_end"),
        )
    except Exception as e:
        print(f"Reg extraction failed for {source['exam_short_name']}: {e}")

    return {"pdfs_found": len(pdf_links), "is_new": True, "updates_made": updates_made}


async def _retry(coro_factory, attempts: int = 3, delay_seconds: float = 3.0):
    last_error = None
    for attempt in range(attempts):
        try:
            return await coro_factory()
        except Exception as exc:
            last_error = exc
            if attempt < attempts - 1:
                await asyncio.sleep(delay_seconds)
    raise last_error


def _changes_detected(previous: dict | None, current: dict) -> dict:
    if not previous:
        return {}
    changes = {}
    for key, new_value in current.items():
        old_value = previous.get(key)
        if old_value != new_value:
            changes[key] = {"old": old_value, "new": new_value}
    return changes


async def _notify_admin_review(
    exam_short_name: str,
    pdf_url: str,
    confidence: float,
    criteria: dict,
) -> None:
    api_key = os.getenv("RESEND_API_KEY")
    to_email = os.getenv("ADMIN_REVIEW_EMAIL")
    from_email = os.getenv("RESEND_FROM_EMAIL", "Yogya <onboarding@resend.dev>")
    if not api_key or not to_email:
        return

    summary = "\n".join(
        f"{key}: {value}" for key, value in list(criteria.items())[:10]
    )
    payload = {
        "from": from_email,
        "to": [to_email],
        "subject": f"[Review Needed] {exam_short_name} Notification",
        "text": (
            f"New eligibility criteria extracted for {exam_short_name}.\n"
            f"Overall confidence: {confidence:.1f}%\n"
            f"PDF: {pdf_url}\n\n"
            f"Summary:\n{summary}\n\nOpen /admin to review."
        ),
    }
    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            await client.post(
                "https://api.resend.com/emails",
                headers={
                    "Authorization": f"Bearer {api_key}",
                    "Content-Type": "application/json",
                },
                json=payload,
            )
    except Exception as exc:
        print(f"Admin notification failed for {exam_short_name}: {exc}")
