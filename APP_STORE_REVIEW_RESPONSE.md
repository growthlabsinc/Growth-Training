# App Store Review Response

## 1.4.1 - Medical Citations
**Resolved**: Added 20+ peer-reviewed citations from journals including European Journal of Applied Physiology, Hypertension (AHA), American Journal of Physiology, and others.

**Implementation**:
- Created `MedicalCitation.swift` with proper academic formatting
- Added `CitationView.swift` for displaying citations
- Updated FAQ and Medical Disclaimer with numbered citations
- New "Scientific References" section in Settings

**Key Citations**: Blood flow (Tew 2010, Green 2011), Tissue adaptation (Schoenfeld 2010), Angiogenesis (Prior 2004), Exercise recovery (Dupuy 2018), Progressive training (Kraemer 2004), Injury prevention (Lauersen 2014).

**Testing**: Settings → Support → Scientific References to view all citations with DOI/PMID links.

## 2.1 - iPad Performance
**Resolved**: Fixed "Start Free Trial" button not responding on iPad.

**Fix**: Updated `SubscriptionPurchaseViewModel` for iPad modal presentation using `.formSheet`, added loading states and error handling.

**Testing**: Launch on iPad → Settings → Subscription → Tap "Start Free Trial" → Verify loading spinner and modal presentation.

## 3.1.2 - Terms of Use
**Resolved**: Fixed Terms of Use link and content display.

**Fix**: Updated `LegalDocumentService.swift`, ensured proper URL loading with fallback, added all required subscription disclosures.

**Content Includes**: User agreement, auto-renewal terms, payment policies, cancellation/refund, user responsibilities, IP rights, privacy link, liability, contact info.

**Testing**: Settings → Legal → Terms of Use (also accessible from subscription screen and onboarding).

## Summary
All violations resolved:
- 1.4.1: Added 20+ medical citations
- 2.1: Fixed iPad subscription button
- 3.1.2: Fixed Terms of Use display

Test Account: apple@growthlabs.coach / Growthreview!01
Contact: jon@growthlabs.coach