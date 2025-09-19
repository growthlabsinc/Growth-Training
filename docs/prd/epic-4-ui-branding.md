# Epic 4: Visual & UX Rebranding

## Epic Overview
Update visual assets, color scheme, and UI text to align with Growth Training brand

**Priority**: P1 - High
**Estimated Effort**: 3 days
**Dependencies**: Epic 2 (Content)
**Owner**: Design Team & Frontend Team

## Epic Goals
- Update color palette for professional, scientific feel
- Replace all Angion-specific visual assets
- Update UI text and terminology throughout
- Maintain existing UX patterns and flows

## Acceptance Criteria
- [ ] New color scheme implemented
- [ ] 80+ image assets replaced
- [ ] All UI text updated
- [ ] App icon and launch screen updated
- [ ] No Angion branding remains
- [ ] Visual consistency maintained

## User Stories

### Story 4.1: Update Color Palette
**As a** user
**I want to** see professional, scientific branding
**So that** the app feels trustworthy and modern

**Tasks:**
- Update primary color to deep blue (#1E3A8A)
- Update secondary to growth green (#10B981)
- Update accent to energy orange (#F97316)
- Update semantic colors (success, warning, error)
- Create dark mode variations

**Color Updates:**
```swift
enum BrandColors {
    static let primary = Color(hex: "#1E3A8A") // Deep Blue
    static let secondary = Color(hex: "#10B981") // Growth Green
    static let accent = Color(hex: "#F97316") // Energy Orange
    static let background = Color(hex: "#F8FAFC")
    static let surface = Color(hex: "#FFFFFF")
    static let textPrimary = Color(hex: "#1E293B")
    static let textSecondary = Color(hex: "#64748B")
}
```

**Acceptance Criteria:**
- ThemeManager.swift updated
- All screens using new colors
- Dark mode properly configured
- Accessibility contrast verified

---

### Story 4.2: Replace App Icon & Launch Screen
**As a** user
**I want to** see Growth Training branding
**So that** the app identity is clear

**Tasks:**
- Design new app icon (GT monogram)
- Create all icon sizes (1024x1024 source)
- Update launch screen design
- Remove Angion Method branding
- Implement icon alternatives for testing

**Icon Requirements:**
- Professional, scientific aesthetic
- "GT" monogram or growth symbol
- Works at all sizes
- Distinct from competitors
- A/B test variations

**Acceptance Criteria:**
- App icon updated in Assets
- Launch screen replaced
- All sizes generated
- Icon visible in App Store

---

### Story 4.3: Replace Exercise Visual Assets
**As a** designer
**I want to** update exercise images
**So that** they match new training methods

**Tasks:**
- Inventory 80+ Angion image assets
- Create new exercise illustrations
- Design equipment usage diagrams
- Create safety warning graphics
- Develop progression visualizations

**Asset Categories:**
- Exercise demonstrations (30+)
- Equipment guides (15+)
- Safety warnings (10+)
- Progress indicators (10+)
- Educational diagrams (15+)

**Acceptance Criteria:**
- All Angion assets removed
- New assets created and integrated
- Consistent visual style
- High resolution (3x) included

---

### Story 4.4: Update Onboarding Screens
**As a** new user
**I want to** understand Growth Training
**So that** I can start safely

**Tasks:**
- Redesign welcome screens
- Update value propositions
- Create safety disclaimer screen
- Design goal selection interface
- Update tutorial animations

**Onboarding Flow:**
1. Welcome to Growth Training
2. Science-Based Approach
3. Safety First Commitment
4. Select Your Goals
5. Experience Assessment
6. Recommended Starting Point

**Acceptance Criteria:**
- Onboarding fully rebranded
- Safety prominent
- Goals clearly defined
- Smooth user flow

---

### Story 4.5: Update Dashboard & Home Screen
**As a** user
**I want to** see my training progress
**So that** I stay motivated

**Tasks:**
- Redesign dashboard cards
- Update progress visualizations
- Rebrand quick actions
- Update achievement badges
- Refresh statistics displays

**Dashboard Components:**
- Today's Training Card
- Progress Summary
- Streak Counter
- Next Session
- Safety Reminder

**Acceptance Criteria:**
- Dashboard fully updated
- New color scheme applied
- Terminology consistent
- Visual hierarchy clear

---

### Story 4.6: Rebrand Timer Interface
**As a** user
**I want to** track my training time
**So that** I follow protocols correctly

**Tasks:**
- Update timer visual design
- Rebrand session type labels
- Update progress indicators
- Refresh completion animations
- Update Live Activity design

**Timer Updates:**
- "AM Session" → "Training Session"
- "Method" → "Protocol"
- New color scheme
- Updated icons
- Safety reminders

**Acceptance Criteria:**
- Timer fully rebranded
- Live Activity updated
- Dynamic Island styled
- Animations smooth

---

### Story 4.7: Update Settings & Profile
**As a** user
**I want to** manage my preferences
**So that** I can customize my experience

**Tasks:**
- Update settings menu design
- Rebrand subscription tiers
- Update profile statistics
- Redesign achievement system
- Update about section

**Settings Sections:**
- Training Preferences
- Safety Settings
- Notifications
- Subscription (Growth Pro)
- Help & Support

**Acceptance Criteria:**
- Settings rebranded
- New terminology used
- Subscription updated
- About section accurate

---

### Story 4.8: Update Educational Resources UI
**As a** user
**I want to** access learning materials
**So that** I can train effectively

**Tasks:**
- Redesign resource cards
- Update category icons
- Refresh article layouts
- Update video placeholders
- Create new illustrations

**Resource Categories:**
- Getting Started
- Safety Guidelines
- Training Techniques
- Equipment Guides
- Progress Optimization

**Acceptance Criteria:**
- Resources fully styled
- Categories clear
- Navigation intuitive
- Content accessible

---

## Typography & Styling

### Font System
```swift
enum Typography {
    static let largeTitle = Font.system(size: 34, weight: .bold)
    static let title1 = Font.system(size: 28, weight: .semibold)
    static let title2 = Font.system(size: 22, weight: .semibold)
    static let title3 = Font.system(size: 20, weight: .semibold)
    static let headline = Font.system(size: 17, weight: .semibold)
    static let body = Font.system(size: 17, weight: .regular)
    static let callout = Font.system(size: 16, weight: .regular)
    static let subheadline = Font.system(size: 15, weight: .regular)
    static let footnote = Font.system(size: 13, weight: .regular)
    static let caption = Font.system(size: 12, weight: .regular)
}
```

### Component Styling
- Rounded corners (12px standard)
- Subtle shadows for depth
- Consistent padding (16px)
- Clear touch targets (44px min)

## Terminology Updates

| Screen | Old Term | New Term |
|--------|----------|----------|
| Home | Angion Method | Growth Training |
| Timer | AM Session | Training Session |
| Methods | Methods | Training Protocols |
| Progress | Vascular Development | Training Progress |
| Library | Angion Techniques | Training Library |

## Asset Migration Plan

### Phase 1: Critical Assets
- App icon
- Launch screen
- Tab bar icons
- Navigation icons

### Phase 2: Content Assets
- Exercise images
- Equipment diagrams
- Educational illustrations
- Achievement badges

### Phase 3: Decorative Assets
- Background patterns
- Success animations
- Empty states
- Promotional graphics

## Risks & Mitigations
- **Risk**: User confusion from changes
  - **Mitigation**: Maintain UX patterns, update gradually
- **Risk**: Asset quality inconsistency
  - **Mitigation**: Design system, style guide
- **Risk**: Missed branding elements
  - **Mitigation**: Comprehensive audit, QA review

## Definition of Done
- [ ] Color scheme fully implemented
- [ ] All image assets replaced
- [ ] UI text completely updated
- [ ] App icon and launch screen new
- [ ] Design system documented
- [ ] QA visual review complete
- [ ] Screenshots updated for App Store