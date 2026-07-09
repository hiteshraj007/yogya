"""API endpoint tests using FastAPI TestClient.

Tests the HTTP layer: status codes, response shapes, input validation,
and error handling — without needing a running database.
"""
import base64
import unittest
from unittest.mock import patch, AsyncMock

from fastapi.testclient import TestClient

from app.main import app


class TestHealthEndpoint(unittest.TestCase):
    """Health check endpoint should always respond."""

    def setUp(self):
        self.client = TestClient(app, raise_server_exceptions=False)

    def test_health_returns_200(self):
        response = self.client.get("/health")
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["status"], "ok")
        self.assertIn("integrations", data)
        self.assertIn("sentry_enabled", data)
        self.assertIn("rate_limiting", data)


class TestCheckEligibilityEndpoint(unittest.TestCase):
    """Eligibility check API tests."""

    def setUp(self):
        self.client = TestClient(app, raise_server_exceptions=False)

    def test_valid_student_returns_200(self):
        student = {
            "dob": "15/07/2001",
            "category": "GENERAL",
            "is_pwbd": False,
            "nationality": "INDIAN",
            "percentage_10": 85.0,
            "percentage_12": 78.0,
            "graduation_status": "COMPLETED",
            "degree": "BTech",
            "graduation_percentage": 72.0,
            "attempts_used": {},
        }
        response = self.client.post("/api/v1/check-eligibility", json=student)
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIn("summary", data)
        self.assertIn("results", data)
        self.assertGreater(data["summary"]["total_exams_checked"], 0)

    def test_invalid_dob_format_returns_422(self):
        student = {
            "dob": "2001-07-15",  # Wrong format (should be DD/MM/YYYY)
            "category": "GENERAL",
            "is_pwbd": False,
        }
        response = self.client.post("/api/v1/check-eligibility", json=student)
        self.assertEqual(response.status_code, 422)

    def test_missing_required_field_returns_422(self):
        student = {
            "category": "GENERAL",
            # Missing 'dob' which is required
        }
        response = self.client.post("/api/v1/check-eligibility", json=student)
        self.assertEqual(response.status_code, 422)

    def test_invalid_category_returns_422(self):
        student = {
            "dob": "15/07/2001",
            "category": "INVALID_CATEGORY",
            "is_pwbd": False,
        }
        response = self.client.post("/api/v1/check-eligibility", json=student)
        self.assertEqual(response.status_code, 422)


class TestExamDetailEndpoint(unittest.TestCase):
    """Exam detail lookup tests."""

    def setUp(self):
        self.client = TestClient(app, raise_server_exceptions=False)

    def test_existing_exam_returns_200(self):
        response = self.client.get("/api/v1/exam/UPSC CSE")
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["exam_short_name"], "UPSC CSE")
        self.assertIn("criteria", data)
        self.assertIn("registration", data)

    def test_nonexistent_exam_returns_404(self):
        response = self.client.get("/api/v1/exam/DOES_NOT_EXIST")
        self.assertEqual(response.status_code, 404)


class TestOpenExamsEndpoint(unittest.TestCase):
    """Open registration exams listing."""

    def setUp(self):
        self.client = TestClient(app, raise_server_exceptions=False)

    def test_open_exams_returns_200(self):
        response = self.client.get("/api/v1/exams/open")
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIn("count", data)
        self.assertIn("exams", data)
        self.assertIsInstance(data["exams"], list)


class TestAdminEndpoints(unittest.TestCase):
    """Admin endpoints require HTTP Basic Auth."""

    def setUp(self):
        self.client = TestClient(app, raise_server_exceptions=False)

    def test_admin_queue_without_auth_returns_401(self):
        response = self.client.get("/api/v1/admin/queue")
        self.assertEqual(response.status_code, 401)

    def test_admin_dashboard_without_auth_returns_401(self):
        response = self.client.get("/admin")
        self.assertEqual(response.status_code, 401)

    def test_approve_without_auth_returns_401(self):
        response = self.client.post("/api/v1/admin/queue/1/approve")
        self.assertEqual(response.status_code, 401)

    def test_reject_without_auth_returns_401(self):
        response = self.client.post("/api/v1/admin/queue/1/reject")
        self.assertEqual(response.status_code, 401)


class TestValidateMarksheetData(unittest.TestCase):
    """Marksheet validation endpoint tests."""

    def setUp(self):
        self.client = TestClient(app, raise_server_exceptions=False)

    def test_valid_10th_marksheet_returns_200(self):
        data = {
            "student_name": "Test Student",
            "board": "CBSE",
            "exam_year": 2020,
            "class_level": "10",
            "subjects": [
                {"name": "Mathematics", "marks_obtained": 85, "max_marks": 100},
                {"name": "Science", "marks_obtained": 78, "max_marks": 100},
            ],
            "total_marks": 400,
            "max_total_marks": 500,
            "percentage": 80.0,
            "result": "PASS",
        }
        response = self.client.post(
            "/api/v1/validate-marksheet-data?marksheet_type=10th",
            json=data,
        )
        self.assertEqual(response.status_code, 200)
        result = response.json()
        self.assertTrue(result["success"])

    def test_empty_marksheet_returns_200_with_warnings(self):
        """Empty marksheet should still return 200 but with validation issues."""
        data = {}
        response = self.client.post(
            "/api/v1/validate-marksheet-data",
            json=data,
        )
        self.assertEqual(response.status_code, 200)


class TestExtractMarksheetEndpoint(unittest.TestCase):
    """Marksheet extraction endpoint input validation."""

    def setUp(self):
        self.client = TestClient(app, raise_server_exceptions=False)

    def test_unsupported_file_type_returns_400(self):
        """Non-image/pdf files should be rejected."""
        response = self.client.post(
            "/api/v1/extract-marksheet",
            files={"file": ("test.txt", b"some text content", "text/plain")},
            data={"marksheet_type": "auto"},
        )
        self.assertEqual(response.status_code, 400)
        self.assertFalse(response.json()["success"])


if __name__ == "__main__":
    unittest.main()
