from datetime import datetime
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak


OUTPUT_FILE = "Istanbul_Traffic_Forecast_Acceptance_Test_Report_Uzay_Demir_210218027.pdf"


def section_title(text, styles):
    return Paragraph(text, styles["Heading2"])


def paragraph(text, styles):
    return Paragraph(text, styles["BodyText"])


def test_table(rows):
    data = [["Action / Test", "Reference", "Expected", "Result"]] + rows
    tbl = Table(data, colWidths=[7.4 * cm, 2.2 * cm, 6.0 * cm, 2.0 * cm])
    tbl.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#1f2937")),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#94a3b8")),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                ("FONTSIZE", (0, 0), (-1, -1), 9),
                ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#f8fafc")]),
            ]
        )
    )
    return tbl


def build_pdf():
    doc = SimpleDocTemplate(
        OUTPUT_FILE,
        pagesize=A4,
        leftMargin=2 * cm,
        rightMargin=2 * cm,
        topMargin=2 * cm,
        bottomMargin=2 * cm,
    )
    styles = getSampleStyleSheet()
    styles["Title"].alignment = 1
    styles["Heading2"].spaceBefore = 10
    styles["Heading2"].spaceAfter = 6
    styles["BodyText"].leading = 14
    styles.add(ParagraphStyle(name="CenterBody", parent=styles["BodyText"], alignment=1))

    story = []

    # Cover
    story.append(Paragraph("Acceptance Test Report", styles["Title"]))
    story.append(Spacer(1, 10))
    story.append(Paragraph("for", styles["CenterBody"]))
    story.append(Spacer(1, 8))
    story.append(Paragraph("Istanbul Traffic Forecast (TrafikPuls)", styles["Title"]))
    story.append(Spacer(1, 8))
    story.append(Paragraph("Version 1.0", styles["CenterBody"]))
    story.append(Spacer(1, 18))
    story.append(Paragraph("Prepared by: Uzay Demir", styles["CenterBody"]))
    story.append(Paragraph("Student NO: 210218027", styles["CenterBody"]))
    story.append(Paragraph("Department of Computer Engineering", styles["CenterBody"]))
    story.append(Paragraph("Istanbul Okan University", styles["CenterBody"]))
    story.append(Paragraph(f"Date: {datetime.now().strftime('%d/%m/%Y')}", styles["CenterBody"]))
    story.append(PageBreak())

    # Intro
    story.append(section_title("1 INTRODUCTION", styles))
    story.append(paragraph("<b>1.1 Purpose Of This Report</b>", styles))
    story.append(
        paragraph(
            "This report documents the acceptance testing process carried out for the Istanbul Traffic "
            "Forecast (TrafikPuls) mobile application and backend system. The purpose is to verify that "
            "core requirements are implemented, test outcomes meet expected behavior, and the solution is "
            "ready for graduation project demonstration.",
            styles,
        )
    )
    story.append(paragraph("<b>1.2 Scope Of The Development Project</b>", styles))
    story.append(
        paragraph(
            "The project includes a Flutter mobile app, Firebase services (Auth + Firestore + Messaging), "
            "and a Python Flask ML backend. The platform provides route-based occupancy prediction, stop ETA, "
            "confidence score, user feedback integration, incident alerts, profile/settings management, and "
            "an admin dashboard for monitoring and operational triggers.",
            styles,
        )
    )
    story.append(paragraph("<b>1.3 Summary of the Results</b>", styles))
    story.append(
        paragraph(
            "Core features were tested and passed, including authentication, route prediction, feedback flow, "
            "localization, profile/settings, incident/alternative route support, deploy readiness, and admin-side "
            "monitoring and trigger endpoints.",
            styles,
        )
    )
    story.append(PageBreak())

    story.append(section_title("2 PERFORMED TESTS AND TEST RESULTS", styles))

    story.append(paragraph("<b>2.1 Authentication & Profile Tests</b>", styles))
    story.append(
        test_table(
            [
                ["Register with name/email/password", "DR 4.1", "User profile created in Firebase + Firestore", "Pass"],
                ["Login with valid credentials", "DR 4.1", "Session opens and map screen loads", "Pass"],
                ["Invalid login", "DR 4.1", "Error shown and access denied", "Pass"],
                ["Profile header name priority", "DR 4.5", "Firestore name > Auth name > email fallback", "Pass"],
                ["Language switch TR/EN", "DR 4.5", "UI labels update based on selected language", "Pass"],
                ["Notification threshold update", "DR 4.5", "Selected threshold persisted in local settings", "Pass"],
                ["Privacy and About dialogs", "DR 4.5", "Localized informational content displayed correctly", "Pass"],
            ]
        )
    )
    story.append(Spacer(1, 10))

    story.append(paragraph("<b>2.2 Prediction, ETA and Feedback Tests</b>", styles))
    story.append(
        test_table(
            [
                ["Route prediction request (M4 sample)", "DR 5.2", "Density score + confidence score returned", "Pass"],
                ["Stop list and ETA generation", "DR 5.3", "Stops listed with deterministic location and ETA", "Pass"],
                ["Feedback submission", "DR 6.2", "Feedback stored and backend receives report_density", "Pass"],
                ["Feedback impacts subsequent predictions", "DR 6.2", "Recent report blended into prediction score", "Pass"],
                ["Draggable bottom prediction sheet", "UI Acceptance", "Sheet supports up/down drag and internal scroll", "Pass"],
            ]
        )
    )
    story.append(PageBreak())

    story.append(paragraph("<b>2.3 Alerts, Alternative Routes and Deployment Tests</b>", styles))
    story.append(
        test_table(
            [
                ["Threshold-based density alert", "DR 7.1", "Favorite route + threshold triggers local alert", "Pass"],
                ["Incident mock feed", "DR 7.2", "Active incidents displayed and route alert produced", "Pass"],
                ["Alternative route suggestions", "DR 7.3", "Lower-density same-type alternatives shown", "Pass"],
                ["Cloud deployment readiness", "DR 8.1", "Procfile/requirements/render.yaml configured", "Pass"],
                ["HTTPS health endpoint", "DR 8.1", "Render deployment returns status ok on /health", "Pass"],
            ]
        )
    )
    story.append(Spacer(1, 10))

    story.append(paragraph("<b>2.4 Admin, Monitoring and Operations Tests</b>", styles))
    story.append(
        test_table(
            [
                ["Admin dashboard metrics cards", "DR 9.1", "Feedback, suspicious records, unique users visible", "Pass"],
                ["Model metrics endpoint", "DR 9.2", "MAE/RMSE/Drift/version returned", "Pass"],
                ["Manual retrain endpoint (prototype)", "DR 9.3", "Retrain job simulated and metrics updated", "Pass"],
                ["Backend push trigger endpoint (prototype)", "DR 9.4", "Push event simulated and logged", "Pass"],
            ]
        )
    )
    story.append(Spacer(1, 10))
    story.append(paragraph("<b>2.5 General & Integration Tests</b>", styles))
    story.append(
        test_table(
            [
                ["Cloud API health check", "DR 8.1", "Render HTTPS endpoint returns status ok", "Pass"],
                ["API base URL runtime switch", "DR 8.1", "App uses --dart-define API_BASE_URL without code changes", "Pass"],
                ["Fallback behavior on live-data failure", "DR 5.4", "Prediction flow continues with mock bus source", "Pass"],
                ["Feedback-to-prediction integration", "DR 6.2", "Recent user report affects route prediction output", "Pass"],
                ["Stop endpoint consistency", "DR 5.3", "Same route returns stable stop names/locations", "Pass"],
                ["Incident + route suggestion coexistence", "DR 7.2/7.3", "Bottom sheet shows both modules without conflict", "Pass"],
            ]
        )
    )
    story.append(PageBreak())

    story.append(section_title("3 CONCLUSION AND RECOMMENDATIONS", styles))
    story.append(paragraph("<b>3.1 Acceptance Criteria</b>", styles))
    story.append(
        paragraph(
            "The project is considered acceptable if core user flows (auth, prediction, feedback, profile/settings), "
            "integration flows (backend API, cloud health), and operational visibility (admin monitoring) are all "
            "functional with no blocking defects.",
            styles,
        )
    )
    story.append(paragraph("<b>3.2 Acceptance Results</b>", styles))
    story.append(paragraph("Number of test cases performed: 27", styles))
    story.append(paragraph("Number of Pass results: 27", styles))
    story.append(paragraph("Number of Fail results: 0", styles))
    story.append(Spacer(1, 8))
    story.append(
        paragraph(
            "Result: The current implementation is accepted as a working and deployable graduation prototype.",
            styles,
        )
    )
    story.append(paragraph("<b>3.3 Recommendations for Future Iteration</b>", styles))
    story.append(
        paragraph(
            "1) Replace prototype retrain/push with production pipelines and FCM Admin SDK. "
            "2) Integrate fully validated real IBB datasets with robust schema contract. "
            "3) Add role-based access control and audit logs for admin operations. "
            "4) Extend model monitoring with persistent historical metrics and drift alarms.",
            styles,
        )
    )
    story.append(PageBreak())

    story.append(section_title("4 REFERENCES", styles))
    story.append(paragraph("Project source code and implementation artifacts (Flutter + Firebase + Flask).", styles))
    story.append(paragraph("Istanbul Traffic Forecast - SRS/SDD and acceptance criteria documents.", styles))
    story.append(paragraph("Flask, Firebase, and Flutter official documentation.", styles))

    story.append(section_title("5 APPENDIX A: ACRONYMS AND GLOSSARY", styles))
    story.append(paragraph("<b>SRS</b> - Software Requirements Specification", styles))
    story.append(paragraph("<b>SDD</b> - Software Design Document", styles))
    story.append(paragraph("<b>FCM</b> - Firebase Cloud Messaging", styles))
    story.append(paragraph("<b>ETA</b> - Estimated Time of Arrival", styles))
    story.append(paragraph("<b>MAE/RMSE</b> - Regression error metrics for model evaluation", styles))
    story.append(paragraph("<b>Drift Score</b> - Indicator of distribution shift in model input/output behavior", styles))

    doc.build(story)
    print(OUTPUT_FILE)


if __name__ == "__main__":
    build_pdf()
