FROM python:3.10-slim

# Install system dependencies (Tesseract OCR and Poppler for PDF-to-image)
RUN apt-get update && apt-get install -y \
    tesseract-ocr \
    poppler-utils \
    libgl1-mesa-glx \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements and install
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Expose port (Render will inject the PORT environment variable)
EXPOSE 5050

# Run the app with Gunicorn
CMD ["gunicorn", "pdf_parser:app", "--bind", "0.0.0.0:${PORT:-5050}", "--timeout", "120"]
