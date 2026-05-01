# Istanbul Traffic Forecast
## Acceptance Test Report

**Course/Project:** Graduation Project  
**Submission Date:** May 1, 2026  
**Prepared by:** Uzay Demir  

---

## 1. Introduction

### 1.1 Purpose of this document
This Acceptance Test Report records the test results of the `Istanbul Traffic Forecast` system and evaluates whether the implementation satisfies the core requirements promised in the project requirement and design documents.

### 1.2 Scope of the development project
The system is a mobile decision-support application for Istanbul public transport users and includes:

- Flutter mobile client (route search, map UI, feedback screens)
- Firebase services (authentication and user feedback storage)
- Python Flask backend (ML-based density prediction APIs)

### 1.3 Summary of results
The end-to-end core flow is operational:

- User authentication
- Route selection and map visualization
- Stop listing on map
- ETA presentation for stops
- Real-time density prediction and 30/60-minute forecast
- User crowd feedback integration into live density score

The system is accepted as a **working prototype** with planned improvements for production deployment and real external data integration.

### 1.4 Definitions and abbreviations
- **ML:** Machine Learning
- **API:** Application Programming Interface
- **ETA:** Estimated Time of Arrival
- **FCM:** Firebase Cloud Messaging

---

## 2. Performed Tests and Results

| # | Action | Expected | Result | Comment |
|---|---|---|---|---|
| 1 | User login/logout | Correct authentication flow | **Pass** | Firebase auth works |
| 2 | Route search and selection | User can find and select a line | **Pass** | Search and selection active |
| 3 | Stop markers on map | Selected route stops visible | **Pass** | `/get_stops` integrated |
| 4 | Stop ETA display | ETA shown in stop info | **Pass** | ETA now returned by backend |
| 5 | Live density score | Current crowd score visible | **Pass** | Bottom sheet updates correctly |
| 6 | Forecast display | +30/+60 minute forecast visible | **Pass** | Forecast cards render |
| 7 | Feedback submission | Empty/Standing/Full feedback stored | **Pass** | Firebase + backend post |
| 8 | Feedback effect on score | New feedback changes live density | **Pass** | Route-based blending active |
| 9 | Confidence score display | Confidence % and label shown | **Pass** | Added to API payload/UI |
|10| App stability in demo flow | No blocking runtime crash | **Pass** | Main flow stable |
|11| Real IBB live data integration | Uses real live external feed | **Fail (Planned)** | Mock data layer currently used |
|12| Auto push notification trigger | Favorite route threshold alert | **Partial (Planned)** | Infrastructure exists, full trigger pending |
|13| Cloud deployment | Public 24/7 API available | **Fail (Planned)** | Backend currently local |

---

## 3. Conclusion

### 3.1 Acceptance criteria
The following vital processes were defined as acceptance criteria:

- Secure user authentication
- Usable mobile user interface
- Route search and map-based monitoring
- ML-based density estimation
- Crowdsourced user feedback affecting predictions

### 3.2 Acceptance results
The project is accepted as a **functional prototype** suitable for demonstration and academic evaluation.

Core architecture (`Flutter + Firebase + Flask + ML`) is implemented and integrated successfully.  
The remaining items are non-blocking for prototype acceptance but required for production maturity:

- Real external live transport data integration
- Fully automated push notification pipeline
- Cloud deployment and operational hardening

---

## 4. Success Performance

- Number of test cases performed: **13**
- Number of **Pass** results: **10**
- Number of **Partial** results: **1**
- Number of **Fail (Planned Scope)** results: **2**

**Prototype success performance:**  
`Pass / Total = 10 / 13 = 76.9%`

**Decision:** Accepted as a **successful prototype**.

---

## 5. References

- Istanbul Traffic Forecast requirement and design documents
- Flutter documentation
- Firebase Authentication and Firestore documentation
- Flask documentation
- Scikit-learn documentation

