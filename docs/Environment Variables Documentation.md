## Environment Variables Documentation (Draft 1)

This document lists the environment variables required for the Firebase Cloud Functions backend of the "Growth" application. These variables are used to configure the functions and connect to various Google Cloud services without hardcoding sensitive information or configuration details.

Environment variables in Cloud Functions can be set during deployment via the `gcloud` CLI, the Google Cloud Console, or by defining them in `.env` files for local emulation (e.g., `.env.<project_alias>` or `.env.local`).

**I. General GCP Configuration (Automatically available in Cloud Functions environment)**

* `GCLOUD_PROJECT` (String): The Google Cloud Project ID. Automatically populated by the Cloud Functions runtime.
* `FUNCTION_TARGET` (String): The name of the function being executed. Automatically populated.
* `FUNCTION_SIGNATURE_TYPE` (String): The type of the function trigger (e.g., `http_trigger`, `event_trigger`). Automatically populated.
* `FUNCTION_REGION` (String): The region where the function is deployed. Automatically populated.

**II. Firebase Cloud Functions Specific Variables**

These variables will be set during the deployment of the Cloud Functions.

1.  **`AI_COACH_GEMINI_MODEL_NAME`**
    * **Description:** Specifies the exact Gemini model endpoint/name to be used by the AI Chat Coach.
    * **Example (Production):** `gemini-2.0-flash-lite-001` (or the latest stable GA version identified in the Technology Stack)
    * **Example (Development/Staging):** Might be the same, or a different version for testing.
    * **Used By:** `RAGOrchestrator.py` (or equivalent module in `src/ai_coach/`)
    * **Required:** Yes

2.  **`AI_COACH_VERTEX_AI_SEARCH_DATATORE_ID`**
    * **Description:** The ID of the Vertex AI Search Data Store containing the indexed knowledge base.
    * **Example:** `growth_methods_articles_prod_v1`
    * **Used By:** `RAGOrchestrator.py`, `src/knowledge_base/firestore_triggers.py`
    * **Required:** Yes

3.  **`AI_COACH_VERTEX_AI_SEARCH_LOCATION`**
    * **Description:** The GCP location/region of the Vertex AI Search datastore and endpoint.
    * **Example:** `eu` (for multi-region) or a specific EU region like `europe-west1` if applicable to specific API calls.
    * **Used By:** `RAGOrchestrator.py`, `src/knowledge_base/firestore_triggers.py`
    * **Required:** Yes

4.  **`AI_COACH_VERTEX_AI_PROJECT_ID`** (Potentially same as `GCLOUD_PROJECT`)
    * **Description:** The Google Cloud Project ID where the Vertex AI services (Search, Gemini) are enabled and billed. Usually the same as `GCLOUD_PROJECT` but can be specified if Vertex AI resources reside in a different project (not recommended for simplicity).
    * **Example:** `your-gcp-project-id`
    * **Used By:** `RAGOrchestrator.py` (GCP client initialization)
    * **Required:** Yes

5.  **`AI_COACH_VERTEX_AI_LOCATION`** (Potentially same as `FUNCTION_REGION` or `AI_COACH_VERTEX_AI_SEARCH_LOCATION`)
    * **Description:** The GCP location/region for Vertex AI API calls (e.g., for Gemini model endpoint).
    * **Example:** `europe-west1` (matching function deployment and data residency goals)
    * **Used By:** `RAGOrchestrator.py` (GCP client initialization for Vertex AI Platform)
    * **Required:** Yes

6.  **`DLP_PROJECT_ID`** (Potentially same as `GCLOUD_PROJECT`)
    * **Description:** The Google Cloud Project ID where the Cloud DLP API is enabled.
    * **Example:** `your-gcp-project-id`
    * **Used By:** `src/core/dlp_service.py`
    * **Required:** Yes (if DLP is used for masking logs, which is recommended)

7.  **`DLP_LOCATION_ID`**
    * **Description:** The location ID for Cloud DLP API requests (e.g., `global` or a specific regional endpoint if preferred and available).
    * **Example:** `global`
    * **Used By:** `src/core/dlp_service.py`
    * **Required:** Yes (if DLP is used)

8.  **`LOG_LEVEL`** (Optional)
    * **Description:** Sets the logging verbosity for the application logs within Cloud Functions.
    * **Example:** `INFO`, `DEBUG`, `WARNING`, `ERROR`
    * **Default:** `INFO`
    * **Used By:** Python `logging` module configuration in `src/core/config.py` or `main.py`.
    * **Required:** No (defaults to a sensible level like INFO)

**III. Local Emulation (`.env` files)**

For local development and testing using the Firebase Emulator Suite, corresponding `.env` files (e.g., `.env.local`) should be created within the `functions/` directory to set these variables. These files **must not** be committed to version control.

Example `.env.local`:
```env
GCLOUD_PROJECT="your-dev-project-id"
AI_COACH_GEMINI_MODEL_NAME="gemini-2.0-flash-lite-001"
AI_COACH_VERTEX_AI_SEARCH_DATATORE_ID="growth_methods_articles_dev_v1"
AI_COACH_VERTEX_AI_SEARCH_LOCATION="eu"
AI_COACH_VERTEX_AI_PROJECT_ID="your-dev-project-id"
AI_COACH_VERTEX_AI_LOCATION="europe-west1"
DLP_PROJECT_ID="your-dev-project-id"
DLP_LOCATION_ID="global"
LOG_LEVEL="DEBUG"
```

**Notes:**

* Access to these environment variables within the Python Cloud Functions will typically be via `os.environ.get('VARIABLE_NAME')`.
* No API keys or other direct credentials should be stored as environment variables. Authentication to GCP services from Cloud Functions should rely on the inherent Application Default Credentials (ADC) of the function's runtime service account.
* The specific values for these variables will differ between deployment environments (development, staging, production).

---
