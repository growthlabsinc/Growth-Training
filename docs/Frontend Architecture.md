## Frontend Architecture (iOS) (Draft 1)

This section outlines the architectural approach for the "Growth" iOS application.

**1. Overall Architectural Pattern:**

* **MVVM (Model-View-ViewModel) with SwiftUI:** The application will primarily adopt the MVVM pattern, which works natively and effectively with SwiftUI's declarative nature.
    * **Views (SwiftUI):** Responsible for laying out the UI and presenting data to the user. Views will be lightweight and primarily declarative, reacting to state changes in ViewModels. They will delegate user actions to ViewModels.
    * **ViewModels (ObservableObject):** Contain the presentation logic, manage the state for their corresponding Views, and expose data in a way that's easily consumable by SwiftUI Views (e.g., via `@Published` properties). They interact with Services for business logic and data fetching.
    * **Models (Structs/Classes):** Represent the data entities of the application (e.g., `User`, `GrowthMethod`, `SessionLog`, `AICoachMessage`). These are often simple data structures, potentially with some validation logic.

**2. Key Design Principles:**

* **Declarative UI:** Embrace SwiftUI's declarative syntax for building user interfaces.
* **Modularity:** Features will be organized into distinct modules/groups as defined in the Project Structure, each with its own Views, ViewModels, and potentially feature-specific services. This promotes separation of concerns and easier maintenance.
* **State Management:**
    * Local view state: `@State`, `@StateObject`.
    * Shared state / data passed down the hierarchy: `@ObservedObject`, `@EnvironmentObject` (used judiciously for truly global state or dependencies).
    * Data fetched from backend: Managed by ViewModels and published for View consumption.
* **Dependency Management:**
    * Swift Package Manager (SPM) for external libraries.
    * Dependencies (e.g., services) will typically be injected into ViewModels (e.g., via initializers) to facilitate testability and decoupling.
* **Single Source of Truth:** Strive to maintain a single source of truth for data, whether it's from a backend service (via a ViewModel) or local persistence.
* **Immutability:** Prefer immutable data structures (e.g., using `let` and `structs`) where possible to reduce side effects and improve predictability.
* **Asynchronous Operations:** Utilize Swift Concurrency (`async/await`, `Task`) for all asynchronous operations, such as network requests to Firebase Functions or complex data processing. Ensure UI updates are dispatched to the main actor (`@MainActor`).

**3. Navigation:**

* **SwiftUI Navigation:** Leverage SwiftUI's built-in navigation tools (`NavigationView`/`NavigationStack`, `NavigationLink`, `.sheet`, `.fullScreenCover`).
* **Routing:** A centralized routing solution or coordinator pattern might be introduced within the `Core/Routing/` module if navigation becomes highly complex across many features, but for MVP, standard SwiftUI navigation within feature modules will be prioritized.

**4. Data Flow (Client-Side):**

* **User Interaction (View) -> ViewModel Action:** Views capture user input and call methods on their ViewModel.
* **ViewModel -> Service Layer:** ViewModels interact with service classes (e.g., `AICoachService`, `SessionLogService`, `AuthService`) to perform business logic or data operations. These services encapsulate the interaction with the backend (Firebase Functions) or local persistence.
* **Service Layer -> Backend/Local Persistence:** Services make network calls or interact with local data stores.
* **Data Update -> ViewModel State -> View Update:** Services return data (or errors) to ViewModels, which update their `@Published` properties, causing the SwiftUI Views to re-render automatically.

**5. AI Chat Coach UI Specifics (Story 6.1):**

* **ChatView (SwiftUI):** Will display a list of messages and an input field.
* **MessageBubble (SwiftUI):** Reusable component for displaying individual user and AI messages, styled differently.
* **AICoachViewModel:** Manages the conversation state (messages), handles sending new messages to the `AICoachService`, and updates the view upon receiving new messages or errors.
* **AICoachService:** Encapsulates the logic for calling the `processGrowthCoachQuery` Firebase Function.

**6. Error Handling:**

* Service layer methods will typically return `Result` types or throw errors.
* ViewModels will catch these errors, update state variables to reflect error conditions (e.g., to show an alert to the user), and potentially log errors to a client-side logging service or Crashlytics.
* User-facing error messages will be user-friendly and avoid technical jargon.

**7. Offline Support (PRD NFRs - Graceful handling):**

* **Cached Educational Content:** Educational resources (articles) can be cached locally (e.g., using Core Data or simply storing fetched content in files) for offline viewing once fetched.
* **Session Logging with Later Sync:** For MVP, if session logging fails due to network issues, the app should inform the user. A more advanced implementation could queue logs locally and sync when connectivity resumes (this adds complexity and would need to be explicitly planned). For MVP, focusing on clear feedback for online-only actions is acceptable if offline queueing is out of scope.
* **AI Chat Coach:** Will require an active internet connection. The UI should clearly indicate if the coach is unavailable due to network issues.

---