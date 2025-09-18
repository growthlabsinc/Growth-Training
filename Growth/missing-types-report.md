# Missing Types Report

Based on my search through the Growth codebase, here are the missing type definitions:

## 1. ProgressOverviewData
- **Referenced in:** 
  - `/Features/Progress/ViewModels/ProgressViewModel.swift`
  - `/Core/Services/InsightGenerationService.swift`
- **Status:** Not defined anywhere in the codebase
- **Usage:** Used to store aggregated progress overview information

## 2. ProgressInsight
- **Referenced in:**
  - `/Features/Progress/Views/ProgressOverviewView.swift`
  - `/Features/Progress/Components/InsightCardView.swift`
  - `/Core/Services/InsightGenerationService.swift`
- **Status:** Not defined anywhere in the codebase
- **Usage:** Used to represent insights about user progress

## 3. TimeRange
- **Referenced in:** Multiple files (9 files found)
- **Status:** Defined as local enums in multiple files with different implementations:
  - `/Features/Gains/Views/GainsProgressView.swift` - enum with week/month/quarter/year/all cases
  - `/Features/Routines/Views/RoutineHistoryView.swift` - enum with week/month/all cases
- **Issue:** No shared definition, each file has its own version

## 4. ProgressTimelineData
- **Referenced in:**
  - `/Features/Progress/ViewModels/ProgressViewModel.swift`
  - `/Features/Progress/Views/DetailedProgressStatsView.swift`
  - `/Core/UI/Components/ProgressTimelineView.swift`
- **Status:** Not defined anywhere in the codebase
- **Usage:** Used to store timeline data for progress visualization

## 5. MarkdownStyle
- **Referenced in:** `/Core/UI/Theme/AppTheme.swift`
- **Status:** Referenced but not defined in the codebase
- **Usage:** Used for markdown styling in the app theme

## 6. GrowthMethodsViewModel
- **Referenced in:**
  - `/Features/GrowthMethods/Views/MethodsOverviewView.swift`
  - `/Features/GrowthMethods/Views/GrowthMethodsListView.swift`
  - `/Features/GrowthMethods/Views/FixedGrowthMethodsListView.swift`
- **Status:** Not defined anywhere in the codebase
- **Usage:** ViewModel for growth methods functionality

## 7. GrowthMethodDetailViewModel
- **Referenced in:** `/Features/GrowthMethods/Views/GrowthMethodDetailView.swift`
- **Status:** Not defined anywhere in the codebase
- **Usage:** ViewModel for growth method detail view

## 8. AchievementHighlight
- **Referenced in:**
  - `/Features/Progress/ViewModels/ProgressViewModel.swift`
  - `/Features/Progress/Components/AchievementHighlightView.swift`
- **Status:** Not defined anywhere in the codebase
- **Usage:** Used to represent achievement highlights in progress view

## 9. StatisticHighlight
- **Referenced in:**
  - `/Features/Progress/ViewModels/ProgressViewModel.swift`
  - `/Features/Progress/Components/StatsHighlightView.swift`
- **Status:** Not defined anywhere in the codebase
- **Usage:** Used to represent statistical highlights

## 10. TrendInfo
- **Referenced in:**
  - `/Features/Progress/ViewModels/ProgressViewModel.swift`
  - `/Features/Progress/Views/DetailedProgressStatsView.swift`
  - `/Features/Progress/Components/StatsTrendCard.swift`
  - `/Features/Progress/Components/StatsHighlightView.swift`
- **Status:** Not defined anywhere in the codebase
- **Usage:** Used to store trend information for statistics

## 11. DrillDownDate
- **Referenced in:** `/Features/Progress/Views/ProgressView.swift`
- **Status:** Not defined anywhere in the codebase
- **Usage:** Likely used for date selection in progress view

## 12. RoutineAdherenceData
- **Referenced in:**
  - `/Features/Progress/ViewModels/ProgressViewModel.swift`
  - `/Core/Services/InsightGenerationService.swift`
  - `/Features/Routines/Components/RoutineAdherenceView.swift`
- **Status:** Not defined anywhere in the codebase
- **Usage:** Used to store routine adherence calculations

## Summary

All 12 types are missing their definitions in the codebase. This suggests either:
1. These types were removed during refactoring but references weren't cleaned up
2. A models file containing these definitions is missing
3. These are placeholders for future implementation

The most critical missing types appear to be:
- Progress-related models (ProgressOverviewData, ProgressInsight, etc.)
- ViewModels for GrowthMethods feature
- Shared types like TimeRange that have multiple local implementations