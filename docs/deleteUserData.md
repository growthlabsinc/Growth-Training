### 2. `deleteUserData` (HTTPS Callable Function)

**Description:**
Permanently deletes all data associated with the requesting authenticated user, in compliance with GDPR's Right to Erasure. This includes their AI Chat Coach conversation history, session logs, profile information (excluding the Firebase Auth record itself, which should be deleted separately via client SDK or admin action after this function confirms data deletion), and any other personal data stored by the application.

**Invoked By:** iOS Application (e.g., from a "Delete My Account" screen in Profile/Settings - Story 10.2)

**Firebase Function Name:** `deleteUserData` (Deployed in the EU region specified in the Technology Stack, e.g., `europe-west1`)

**Method:** `POST` (Implicit via Firebase Callable Functions SDK)

**Request Payload (`data` object when calling the function):**

* **Type:** `application/json`
* **Fields:**
    * `confirmation` (String, Required): A confirmation string that the user must have typed or explicitly agreed to (e.g., "DELETE MY DATA"). This is a safeguard against accidental deletion. The exact string should be determined and localized by the client.

**Request Example (Conceptual JSON sent by Firebase SDK):**
```json
{
  "confirmation": "DELETE MY DATA"
}
```

**Success Response (`result.data` object received by the client):**

* **Type:** `application/json`
* **Status Code:** `200 OK` (Implicit for successful Callable Function execution)
* **Fields:**
    * `status` (String): A message indicating the outcome. (e.g., `"User data deletion process initiated successfully."`)
    * `message` (String, Optional): A more detailed message for the user, explaining that the process is underway and their Firebase Auth account should be deleted next from the client if applicable.

**Success Response Example (Conceptual JSON received by Firebase SDK):**
```json
{
  "status": "User data deletion process initiated successfully.",
  "message": "Your account data is being deleted. You will be signed out. Please sign in again if you wish to create a new account."
}
```

**Error Responses (Handled by Firebase Functions SDK `HttpsError`):**

* **Common Error Codes (`FunctionsErrorCode`):**
    * `unauthenticated`: Authentication token is missing, invalid, or expired.
    * `invalid-argument`: The `confirmation` string is missing or does not match the required value.
    * `internal`: An internal server error occurred during the deletion process. Data might be in an inconsistent state. This should trigger an alert for manual review.
    * `failed-precondition`: If there's a reason why deletion cannot proceed (e.g., legal hold, though unlikely for this app's MVP context).

**Error Response Example (Conceptual error object):**
Client receives an error where `error.code == .invalidArgument` and `error.message == "Confirmation string is incorrect."`.

**Security Considerations:**

* **Critical Function:** This function performs destructive operations and must be heavily secured.
* **Authentication:** Only the authenticated user whose data is being deleted should be able to trigger this for their own data. The function will operate on the `context.auth.uid` of the caller.
* **Confirmation Step:** The `confirmation` payload field is a deliberate friction point to prevent accidental calls.
* **Irreversible Action:** Data deleted via this function is permanently gone.
* **Firebase Auth Deletion:** This function primarily deletes Firestore data and data from other backend systems (like Vertex AI Search index entries related to the user, if any were directly user-attributable and not covered by general knowledge base updates). The actual Firebase Authentication user record (`Auth.auth().currentUser?.delete()`) is typically deleted from the *client-side* after this function successfully signals that backend data deletion has been completed or initiated. Alternatively, an admin process could delete the Auth record. For MVP (Story 10.2), this function might trigger a manual admin process for backend deletion. The research document's example deletion function implies backend deletion, so we'll assume the function handles its scope of data.
* **Logging:** Log the initiation and successful completion (or failure) of the deletion request (using only the `uid`, no PII).

---
