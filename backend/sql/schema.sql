CREATE TABLE IF NOT EXISTS exam_sources (
    id SERIAL PRIMARY KEY,
    exam_short_name VARCHAR NOT NULL,
    conducting_body VARCHAR NOT NULL,
    notification_page_url VARCHAR NOT NULL,
    pdf_keyword_filter VARCHAR,
    last_checked_at TIMESTAMPTZ,
    last_pdf_hash VARCHAR,
    last_pdf_url VARCHAR,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS exam_criteria (
    id SERIAL PRIMARY KEY,
    exam_short_name VARCHAR NOT NULL UNIQUE,
    exam_full_name VARCHAR NOT NULL,
    conducting_body VARCHAR,
    exam_category VARCHAR,
    min_education VARCHAR,
    required_stream JSONB,
    required_subjects JSONB,
    required_degree JSONB,
    min_percentage_general DOUBLE PRECISION DEFAULT 0,
    min_percentage_obc DOUBLE PRECISION DEFAULT 0,
    min_percentage_sc_st DOUBLE PRECISION DEFAULT 0,
    min_percentage_ews DOUBLE PRECISION DEFAULT 0,
    min_age INTEGER DEFAULT 0,
    max_age_general INTEGER DEFAULT 0,
    max_age_obc INTEGER DEFAULT 0,
    max_age_sc_st INTEGER DEFAULT 0,
    max_age_ews INTEGER DEFAULT 0,
    max_age_pwbd_general INTEGER DEFAULT 0,
    max_age_pwbd_obc INTEGER DEFAULT 0,
    max_age_pwbd_sc_st INTEGER DEFAULT 0,
    age_cutoff_day INTEGER,
    age_cutoff_month INTEGER,
    max_attempts_general INTEGER DEFAULT -1,
    max_attempts_obc INTEGER DEFAULT -1,
    max_attempts_sc_st INTEGER DEFAULT -1,
    max_attempts_ews INTEGER DEFAULT -1,
    additional_rules JSONB,
    notification_year INTEGER,
    source_pdf_url VARCHAR,
    admin_verified BOOLEAN DEFAULT FALSE,
    verified_by VARCHAR,
    verified_at TIMESTAMPTZ,
    verification_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS exam_registration_status (
    id SERIAL PRIMARY KEY,
    exam_short_name VARCHAR UNIQUE REFERENCES exam_criteria(exam_short_name),
    registration_open BOOLEAN DEFAULT FALSE,
    registration_start TIMESTAMPTZ,
    registration_end TIMESTAMPTZ,
    exam_date_text VARCHAR,
    admit_card_date TIMESTAMPTZ,
    result_date TIMESTAMPTZ,
    apply_url VARCHAR,
    official_url VARCHAR,
    notification_pdf_url VARCHAR,
    correction_window_start TIMESTAMPTZ,
    correction_window_end TIMESTAMPTZ,
    last_scraped_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS admin_review_queue (
    id SERIAL PRIMARY KEY,
    exam_short_name VARCHAR,
    pdf_url VARCHAR,
    pdf_hash VARCHAR,
    extracted_criteria JSONB,
    confidence_scores JSONB,
    overall_confidence DOUBLE PRECISION,
    previous_criteria_id INTEGER,
    changes_detected JSONB,
    status VARCHAR DEFAULT 'PENDING',
    admin_edited_criteria JSONB,
    admin_notes VARCHAR,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    reviewed_at TIMESTAMPTZ,
    reviewed_by VARCHAR
);

CREATE TABLE IF NOT EXISTS criteria_history (
    id SERIAL PRIMARY KEY,
    exam_short_name VARCHAR,
    criteria_snapshot JSONB,
    notification_year INTEGER,
    valid_from TIMESTAMPTZ,
    replaced_at TIMESTAMPTZ,
    source_pdf_url VARCHAR
);

CREATE TABLE IF NOT EXISTS scraper_logs (
    id SERIAL PRIMARY KEY,
    source_name VARCHAR,
    run_at TIMESTAMPTZ DEFAULT NOW(),
    status VARCHAR,
    pdfs_found INTEGER DEFAULT 0,
    new_pdfs_detected INTEGER DEFAULT 0,
    updates_made INTEGER DEFAULT 0,
    error_message TEXT,
    duration_seconds DOUBLE PRECISION
);
