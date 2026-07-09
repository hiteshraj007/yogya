# Yogya Eligibility Backend

FastAPI service for the eligibility engine described in the pasted system spec.

## Implemented now

- `POST /api/v1/check-eligibility`
- `GET /api/v1/exams/open`
- `GET /api/v1/exam/{exam_short_name}`
- `POST /api/v1/validate-marksheet-data`
- `POST /api/v1/extract-marksheet` guard with file-type validation
- `GET /api/v1/admin/queue`
- `POST /api/v1/admin/queue/{id}/approve`
- `POST /api/v1/admin/queue/{id}/reject`
- `GET /admin`
- PostgreSQL schema and seed source SQL in `sql/`

The scraper and cloud OCR adapters are intentionally placeholders until real
Supabase, Gemini, Groq, Redis, and Resend credentials are configured.

## Run locally

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

Open `http://127.0.0.1:8000/docs`.

## Test

```bash
cd backend
python -m unittest
```

## Manual setup still required

- Create Supabase PostgreSQL project and run `sql/schema.sql`.
- Run `sql/seed_exam_sources.sql`.
- Create Upstash Redis and set `REDIS_URL`.
- Create Gemini, Groq, and Resend API keys.
- Replace in-memory criteria store with PostgreSQL repository.
- Implement Playwright PDF monitoring and Supabase Storage upload.
- Enable `RUN_SCRAPER_ON_STARTUP=true` only after the live scraper adapter is ready.

