# Yogya PDF Parser — Quick Setup

## What it does
A lightweight Python Flask microservice that:
- Accepts PDF or image uploads from the Flutter app
- Extracts structured academic data (name, DOB, board, subjects, marks, percentage)
- Returns JSON matching the `OcrResult` model in Flutter

## Requirements
- **Python 3.9+** — [Download here](https://python.org/downloads/)
- For scanned PDFs (image-based): **Tesseract OCR** — [Download here](https://github.com/UB-Mannheim/tesseract/wiki)

## Start (Windows)
```
cd tools/pdf_parser
start.bat
```
The service starts at **http://127.0.0.1:5050**

## Endpoints
| Method | URL | Description |
|--------|-----|-------------|
| GET | `/health` | Health check |
| POST | `/parse-pdf` | Upload a PDF file |
| POST | `/parse-image` | Upload an image (JPG/PNG) |

## Test it
```bash
curl http://127.0.0.1:5050/health
# → {"status": "ok", "ocr_available": true}
```
