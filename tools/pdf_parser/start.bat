@echo off
title Yogya PDF Parser Service
echo ============================================
echo   Yogya PDF Parser Microservice
echo   Port: 5050
echo ============================================

REM Check if venv exists; create if not
if not exist ".venv" (
    echo [SETUP] Creating Python virtual environment...
    python -m venv .venv
    if errorlevel 1 (
        echo [ERROR] Python not found. Install Python 3.9+ from https://python.org
        pause
        exit /b 1
    )
)

REM Activate venv
call .venv\Scripts\activate.bat

REM Install/upgrade deps
echo [SETUP] Installing dependencies...
pip install -q -r requirements.txt

REM Start the server
echo.
echo [OK] Starting PDF parser on http://127.0.0.1:5050
echo      Press Ctrl+C to stop.
echo.
python pdf_parser.py

pause
