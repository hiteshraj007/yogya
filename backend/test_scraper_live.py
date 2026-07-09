"""
Scraper Live Test — Step-by-step test against ONE real government website.
Tests: Playwright page load → PDF link finding → PDF download → hash check → AI extraction
"""
import asyncio
import hashlib
import os
import sys
import time
from urllib.parse import urljoin

from dotenv import load_dotenv
load_dotenv()

from bs4 import BeautifulSoup
from playwright.async_api import async_playwright
import httpx


async def test_scraper():
    print("=" * 60)
    print("  YOGYA SCRAPER LIVE TEST")
    print("=" * 60)

    # --- Step 1: Pick a test source ---
    # Using SSC (most reliable government site)
    test_sources = [
        {
            "name": "UPSC",
            "url": "https://upsc.gov.in/examinations/active-examinations",
            "keyword": "notification",
        },
        {
            "name": "SSC",
            "url": "https://ssc.gov.in",
            "keyword": "notification",
        },
        {
            "name": "NTA",
            "url": "https://nta.ac.in/",
            "keyword": "information bulletin",
        },
    ]

    for source in test_sources:
        print(f"\n{'─' * 60}")
        print(f"  Testing: {source['name']} — {source['url']}")
        print(f"{'─' * 60}")

        # --- Step 2: Playwright page load ---
        print("\n[Step 1] Playwright — Loading page...")
        start = time.time()
        page_html = None

        try:
            async with async_playwright() as p:
                browser = await p.chromium.launch(headless=True)
                page = await browser.new_page()
                
                try:
                    await page.goto(source["url"], wait_until="domcontentloaded", timeout=30000)
                    page_html = await page.content()
                    elapsed = time.time() - start
                    print(f"  ✅ Page loaded ({elapsed:.1f}s)")
                    print(f"  HTML length: {len(page_html):,} chars")
                except Exception as e:
                    elapsed = time.time() - start
                    print(f"  ❌ Page load FAILED ({elapsed:.1f}s): {e}")
                finally:
                    await page.close()
                    await browser.close()
        except Exception as e:
            print(f"  ❌ Playwright error: {e}")
            continue

        if not page_html:
            continue

        # --- Step 3: Find PDF links ---
        print("\n[Step 2] BeautifulSoup — Finding PDF links...")
        soup = BeautifulSoup(page_html, "html.parser")
        links = soup.find_all("a", href=True)
        print(f"  Total links found: {len(links)}")

        pdf_links = []
        keyword = source["keyword"].lower()

        for link in links:
            href = link["href"]
            text = link.text.strip()
            if ".pdf" in href.lower():
                full_url = urljoin(source["url"], href)
                matches_keyword = keyword in text.lower() or keyword in href.lower()
                pdf_links.append({
                    "url": full_url,
                    "text": text[:80] if text else "(no text)",
                    "matches_keyword": matches_keyword,
                })

        if pdf_links:
            print(f"  ✅ Found {len(pdf_links)} PDF links:")
            for i, pdf in enumerate(pdf_links[:5]):  # Show first 5
                match = "✓" if pdf["matches_keyword"] else "✗"
                print(f"    {i+1}. [{match}] {pdf['text']}")
                print(f"       URL: {pdf['url'][:100]}...")
            if len(pdf_links) > 5:
                print(f"    ... and {len(pdf_links) - 5} more")
        else:
            print(f"  ⚠️ No PDF links found!")
            # Show all links for debugging
            print(f"  Showing first 10 links for debugging:")
            for i, link in enumerate(links[:10]):
                print(f"    {i+1}. {link.text.strip()[:60]} → {link['href'][:80]}")
            continue

        # --- Step 4: Download first matching PDF ---
        matching = [p for p in pdf_links if p["matches_keyword"]]
        target_pdf = matching[0] if matching else pdf_links[0]
        
        print(f"\n[Step 3] Downloading PDF: {target_pdf['text'][:50]}...")
        start = time.time()
        
        try:
            async with httpx.AsyncClient() as client:
                res = await client.get(target_pdf["url"], follow_redirects=True, timeout=30.0)
                elapsed = time.time() - start
                
                if res.status_code == 200:
                    pdf_bytes = res.content
                    pdf_hash = hashlib.sha256(pdf_bytes).hexdigest()
                    size_kb = len(pdf_bytes) / 1024
                    print(f"  ✅ Downloaded ({elapsed:.1f}s)")
                    print(f"  Size: {size_kb:.1f} KB")
                    print(f"  SHA-256: {pdf_hash[:16]}...")
                    print(f"  Content-Type: {res.headers.get('content-type', 'unknown')}")
                else:
                    print(f"  ❌ Download failed: HTTP {res.status_code}")
                    continue
        except Exception as e:
            print(f"  ❌ Download error: {e}")
            continue

        # --- Step 5: Test AI extraction (optional, costs API credits) ---
        if os.getenv("GEMINI_API_KEY") and size_kb < 5000:
            print(f"\n[Step 4] Gemini AI — Extracting criteria (this may take 10-20s)...")
            try:
                import google.generativeai as genai
                genai.configure(api_key=os.getenv("GEMINI_API_KEY"))
                
                model_name = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")
                model = genai.GenerativeModel(model_name)
                
                prompt = f"""Extract key eligibility info from this exam notification PDF.
Return a brief JSON with: min_education, min_age, max_age_general, registration_start, registration_end.
Only extract what is explicitly written. Return null for missing fields."""

                start = time.time()
                response = await model.generate_content_async(
                    contents=[
                        {"mime_type": "application/pdf", "data": pdf_bytes},
                        prompt,
                    ],
                    generation_config={"response_mime_type": "application/json"}
                )
                elapsed = time.time() - start
                
                print(f"  ✅ AI extraction done ({elapsed:.1f}s)")
                print(f"  Response preview:")
                text = response.text[:500]
                for line in text.split("\n"):
                    print(f"    {line}")
            except Exception as e:
                print(f"  ❌ AI extraction error: {e}")
        else:
            print(f"\n[Step 4] AI extraction — SKIPPED (no API key or PDF too large)")

        print(f"\n{'─' * 60}")
        print(f"  {source['name']}: ALL STEPS PASSED ✅")
        print(f"{'─' * 60}")

    print("\n" + "=" * 60)
    print("  SCRAPER LIVE TEST COMPLETE")
    print("=" * 60)


if __name__ == "__main__":
    asyncio.run(test_scraper())
