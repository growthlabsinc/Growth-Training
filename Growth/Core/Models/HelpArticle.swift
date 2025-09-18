//
//  HelpArticle.swift
//  Growth
//
//  Created by Claude on 6/25/25.
//

import Foundation
import SwiftUI

// MARK: - Help Article Model
struct HelpArticle: Identifiable, Codable {
    let id: String
    let title: String
    let subtitle: String
    let category: HelpCategory
    let content: String
    let readingTime: Int // in minutes
    let lastUpdated: Date
    let tags: [String]
    let relatedArticles: [String] // IDs of related articles
    let isPremium: Bool
    
    init(
        id: String = UUID().uuidString,
        title: String,
        subtitle: String,
        category: HelpCategory,
        content: String,
        readingTime: Int,
        lastUpdated: Date = Date(),
        tags: [String] = [],
        relatedArticles: [String] = [],
        isPremium: Bool = false
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.category = category
        self.content = content
        self.readingTime = readingTime
        self.lastUpdated = lastUpdated
        self.tags = tags
        self.relatedArticles = relatedArticles
        self.isPremium = isPremium
    }
}

// MARK: - Help Article Section
struct HelpArticleSection: Identifiable {
    let id = UUID()
    let title: String
    let content: String
    let type: SectionType
    
    enum SectionType {
        case text
        case bulletList
        case numberedList
        case tip
        case warning
        case code
        case image(String) // image name
    }
}

// MARK: - Help Article Content Builder
struct HelpArticleContent {
    let sections: [HelpArticleSection]
    
    var fullContent: String {
        sections.map { section in
            switch section.type {
            case .text:
                return section.content
            case .bulletList:
                return "**\(section.title)**\n" + section.content.split(separator: "\n").map { "• \($0)" }.joined(separator: "\n")
            case .numberedList:
                let items = section.content.split(separator: "\n")
                return "**\(section.title)**\n" + items.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")
            case .tip:
                return "💡 **Tip**: \(section.content)"
            case .warning:
                return "⚠️ **Warning**: \(section.content)"
            case .code:
                return "```\n\(section.content)\n```"
            case .image(let imageName):
                return "[Image: \(imageName)]"
            }
        }.joined(separator: "\n\n")
    }
}

// MARK: - Help Article Repository
class HelpArticleRepository: ObservableObject {
    @Published var articles: [HelpArticle] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    static let shared = HelpArticleRepository()
    
    private init() {
        loadDefaultArticles()
    }
    
    func loadDefaultArticles() {
        self.articles = Self.defaultArticles
    }
    
    func getArticles(for category: HelpCategory) -> [HelpArticle] {
        articles.filter { $0.category == category }
    }
    
    func searchArticles(query: String) -> [HelpArticle] {
        guard !query.isEmpty else { return articles }
        
        let lowercasedQuery = query.lowercased()
        return articles.filter { article in
            article.title.lowercased().contains(lowercasedQuery) ||
            article.subtitle.lowercased().contains(lowercasedQuery) ||
            article.content.lowercased().contains(lowercasedQuery) ||
            article.tags.contains { $0.lowercased().contains(lowercasedQuery) }
        }
    }
    
    func getRelatedArticles(for article: HelpArticle) -> [HelpArticle] {
        articles.filter { article.relatedArticles.contains($0.id) }
    }
}

// MARK: - Default Help Articles
extension HelpArticleRepository {
    static let defaultArticles: [HelpArticle] = [
        // Getting Started Articles
        HelpArticle(
            id: "welcome-to-growth",
            title: "Welcome to Growth",
            subtitle: "Everything you need to know to get started with the app",
            category: .gettingStarted,
            content: """
            Welcome to Growth, your comprehensive training companion for safe and effective personal development. This guide will walk you through everything you need to know to get started on your journey.

            ## What is Growth?

            Growth is a scientifically-designed training app that helps you achieve your personal development goals through structured routines, proven methods, and intelligent progress tracking. Whether you're a complete beginner or experienced practitioner, Growth adapts to your level and helps you progress safely.

            ## Key Features

            **Structured Training Programs**
            • 15+ proven methods with detailed instructions
            • Progressive difficulty stages for each method
            • Customizable routines tailored to your goals
            • Built-in rest day scheduling

            **Smart Progress Tracking**
            • Accurate measurement logging
            • Visual progress charts and analytics
            • Photo comparison tools (private and secure)
            • Performance indicators and health metrics

            **AI-Powered Coaching**
            • Personalized guidance and recommendations
            • Form corrections and technique tips
            • Plateau-breaking strategies
            • 24/7 availability for questions

            **Safety First Approach**
            • Mandatory warm-up protocols
            • Injury prevention guidelines
            • Rest day enforcement
            • Warning system for overtraining

            ## Getting Started Checklist

            1. **Complete Your Profile**
               • Set your experience level
               • Define your goals
               • Configure privacy settings

            2. **Choose Your First Routine**
               • Browse pre-made routines
               • Start with Beginner's Foundation
               • Review the schedule and methods

            3. **Prepare Your Space**
               • Ensure privacy
               • Gather necessary supplies
               • Set up comfortable environment

            4. **Take Initial Measurements**
               • Follow the measurement guide
               • Record baseline metrics
               • Take reference photos (optional)

            5. **Start Your First Session**
               • Read method instructions carefully
               • Complete the warm-up
               • Follow timer prompts
               • Log your session

            ## Important First-Time Tips

            💡 **Start Conservative**: Begin with 50% of recommended time and intensity. It's better to build up slowly than risk injury.

            💡 **Focus on Form**: Proper technique is more important than duration or intensity. Master the basics before advancing.

            💡 **Track Everything**: The more data you log, the better the app can help you optimize your training.

            💡 **Be Patient**: Real, lasting results take time. Focus on consistency rather than quick gains.

            ## Next Steps

            After completing your first week, explore these features:
            • Custom routine creation
            • Advanced tracking options
            • AI Coach conversations
            • Educational resources
            • Community guidelines

            Remember, Growth is a marathon, not a sprint. Take your time, follow the safety guidelines, and enjoy the journey to becoming your best self.
            """,
            readingTime: 5,
            tags: ["beginner", "getting started", "introduction", "welcome", "first time"],
            relatedArticles: ["first-routine-guide", "safety-fundamentals", "measurement-guide"]
        ),
        
        HelpArticle(
            id: "first-routine-guide",
            title: "Creating Your First Routine",
            subtitle: "Step-by-step guide to setting up your initial training program",
            category: .gettingStarted,
            content: """
            Creating your first routine is an important step in your Growth journey. This guide will help you set up a program that matches your experience level and goals.

            ## Understanding Routines

            A routine is a structured collection of methods performed on specific days. Good routines balance different method types, include adequate rest, and progress gradually over time.

            ## Choosing a Pre-Made Routine

            For beginners, we strongly recommend starting with a pre-made routine:

            **1. Beginner's Foundation**
            • Duration: 12 weeks
            • Frequency: 3 days/week
            • Session length: 15-20 minutes
            • Focus: Basic techniques and safety

            **2. Gentle Start Program**
            • Duration: 8 weeks
            • Frequency: 3-4 days/week
            • Session length: 10-15 minutes
            • Focus: Ultra-conservative approach

            ## How to Select a Routine

            1. **Navigate to Routines Tab**
               • Tap the Routines icon in navigation
               • Select "Browse Routines"

            2. **Filter by Experience Level**
               • Use the filter button
               • Select "Beginner"
               • Sort by popularity

            3. **Review Routine Details**
               • Tap on a routine to see details
               • Check included methods
               • Review time commitment
               • Read user reviews

            4. **Start the Routine**
               • Tap "Start This Routine"
               • Confirm your choice
               • Schedule your first session

            ## Anatomy of a Good Beginner Routine

            **Warm-Up Phase (5 minutes)**
            • General circulation exercises
            • Gentle stretching
            • Mental preparation

            **Main Training (10-15 minutes)**
            • 2-3 complementary methods
            • Focus on form over intensity
            • Built-in rest periods

            **Cool-Down (5 minutes)**
            • Gradual intensity reduction
            • Recovery techniques
            • Session notes

            ## Weekly Schedule Example

            **Monday**: Full routine (20 min)
            **Tuesday**: Rest
            **Wednesday**: Full routine (20 min)
            **Thursday**: Rest
            **Friday**: Full routine (20 min)
            **Weekend**: Rest and recovery

            ## Customizing Your Routine

            After 2-4 weeks, you can start customizing:

            1. **Adjust Timing**
               • Add 2-3 minutes if comfortable
               • Extend specific methods
               • Add extra rest if needed

            2. **Swap Methods**
               • Try variations of current methods
               • Explore new categories
               • Maintain balance

            3. **Change Frequency**
               • Add one session per week
               • Adjust rest days
               • Listen to your body

            ## Common Beginner Mistakes

            ⚠️ **Too Much Too Soon**: Starting with advanced routines or training daily

            ⚠️ **Skipping Warm-Up**: Always complete the full warm-up sequence

            ⚠️ **Ignoring Rest Days**: Recovery is when growth happens

            ⚠️ **Changing Too Often**: Stick with a routine for at least 4 weeks

            ## When to Progress

            You're ready for a new routine when:
            • Completed 80% of scheduled sessions
            • Comfortable with all methods
            • No soreness or discomfort
            • Measurements show progress
            • Been on routine 6-12 weeks

            ## Next Steps

            Once comfortable with your first routine:
            • Explore intermediate programs
            • Create custom combinations
            • Add specialized methods
            • Increase frequency gradually

            Remember: The best routine is one you'll stick with consistently. Start simple and build from there.
            """,
            readingTime: 4,
            tags: ["routine", "beginner", "program", "schedule", "first time"],
            relatedArticles: ["welcome-to-growth", "method-overview", "progression-guide"]
        ),
        
        HelpArticle(
            id: "safety-fundamentals",
            title: "Safety Fundamentals",
            subtitle: "Essential safety guidelines for injury-free training",
            category: .gettingStarted,
            content: """
            Safety is the foundation of effective training. This comprehensive guide covers everything you need to know to train safely and avoid injuries.

            ## The Golden Rules of Safe Training

            1. **Never Train Through Pain**
               • Discomfort is NOT normal
               • Stop immediately if you feel pain
               • Distinguish soreness from injury

            2. **Always Warm Up**
               • Minimum 5-10 minutes
               • Increases blood flow
               • Prepares tissues for training

            3. **Respect Rest Days**
               • Recovery is essential
               • Growth happens during rest
               • Prevents overtraining

            4. **Start Conservative**
               • Begin at 50% intensity
               • Build up gradually
               • Form over force always

            ## Pre-Training Safety Checklist

            ✓ **Health Check**
            • No current injuries
            • Well-rested
            • Hydrated
            • No medications affecting circulation

            ✓ **Environment Setup**
            • Private, comfortable space
            • Appropriate temperature
            • Clean hands and equipment
            • Timer and supplies ready

            ✓ **Mental Readiness**
            • Focused and relaxed
            • Not rushed or stressed
            • Reviewed method instructions
            • Clear training goals

            ## Warning Signs During Training

            **Stop Immediately If You Experience:**
            
            🚨 **Sharp or Sudden Pain**
            • Any acute discomfort
            • Stabbing sensations
            • Burning feelings

            🚨 **Numbness or Tingling**
            • Loss of sensation
            • "Pins and needles"
            • Cold feelings

            🚨 **Unusual Appearance**
            • Dark discoloration
            • Excessive swelling
            • Skin changes

            🚨 **Systemic Symptoms**
            • Dizziness
            • Nausea
            • Rapid heart rate
            • Shortness of breath

            ## Proper Warm-Up Protocol

            **Phase 1: General Warm-Up (3-5 min)**
            • Light cardio activity
            • Full body movement
            • Increase heart rate gradually

            **Phase 2: Specific Warm-Up (3-5 min)**
            • Gentle massage
            • Light stretching
            • Gradual tissue preparation

            **Phase 3: Mental Preparation (2 min)**
            • Review session plan
            • Set intentions
            • Focus on safety

            ## Safe Training Techniques

            **Pressure Application**
            • Start light, increase gradually
            • Never use excessive force
            • Maintain consistent pressure
            • Release immediately if uncomfortable

            **Duration Management**
            • Follow recommended times
            • Use timer always
            • Take breaks as needed
            • Never extend beyond comfort

            **Lubrication Use**
            • Essential for most methods
            • Reduces friction injuries
            • Reapply as needed
            • Use quality products

            ## Post-Training Safety

            **Cool-Down (5 minutes)**
            • Gradual intensity reduction
            • Gentle massage
            • Return to baseline

            **Health Check**
            • Inspect for any issues
            • Note any unusual sensations
            • Check circulation

            **Recovery Protocol**
            • Stay hydrated
            • Avoid intense activities
            • Monitor for delayed symptoms

            ## Injury Prevention Strategies

            **1. Progressive Overload**
            • Increase intensity by 10% weekly max
            • Master current level first
            • Track all changes

            **2. Method Rotation**
            • Vary techniques
            • Prevent repetitive stress
            • Balance training focus

            **3. Listen to Your Body**
            • Respect fatigue signals
            • Take extra rest when needed
            • Never train when sick

            ## Emergency Response Plan

            If injury occurs:

            1. **Stop All Activity**
            2. **Apply Ice** (wrapped, 10-15 min)
            3. **Rest Completely**
            4. **Monitor Symptoms**
            5. **Seek Medical Help** if severe or persistent

            ## Long-Term Safety Habits

            • Regular health check-ups
            • Consistent measurement tracking
            • Periodic routine evaluation
            • Ongoing education
            • Community support

            Remember: No goal is worth risking your health. Train smart, stay safe, and enjoy sustainable progress.
            """,
            readingTime: 6,
            tags: ["safety", "injury prevention", "warm-up", "health", "guidelines"],
            relatedArticles: ["injury-recovery-guide", "warm-up-techniques", "common-mistakes"]
        ),
        
        // Methods & Techniques Articles
        HelpArticle(
            id: "method-overview",
            title: "Understanding Training Methods",
            subtitle: "Complete guide to all available methods and their benefits",
            category: .methodsTechniques,
            content: """
            Growth offers 15+ scientifically-designed methods across multiple categories. Understanding each method's purpose and proper execution is key to achieving your goals safely and effectively.

            ## Method Categories Overview

            ### 1. Manual Methods
            
            Manual methods form the foundation of most training programs. They require no equipment and allow precise control over pressure and technique.

            **Benefits:**
            • Complete control over intensity
            • No equipment needed
            • Excellent for beginners
            • Develops mind-muscle connection
            • Highly customizable

            **Types Available:**
            • Basic Manual (Levels 1-3)
            • Advanced Manual Techniques
            • Combination Movements
            • Targeted Approaches

            ### 2. Stretching Methods

            Stretching methods focus on gradual, controlled elongation through various techniques.

            **Benefits:**
            • Gentle progression
            • Improved flexibility
            • Enhanced circulation
            • Low injury risk
            • Suitable for all levels

            **Types Available:**
            • Basic Stretching
            • Multi-Directional Stretches
            • Progressive Tension
            • Advanced Flexibility Work

            ### 3. Device-Assisted Methods

            These methods use specialized equipment to provide consistent, measured application of techniques.

            **Benefits:**
            • Consistent pressure
            • Hands-free options
            • Precise measurement
            • Extended duration capability
            • Advanced progression

            **Types Available:**
            • Vacuum-Based Devices
            • Traction Systems
            • Compression Tools
            • Combination Devices

            ### 4. AM Methods

            Specifically designed for morning sessions when natural physiological conditions are optimal.

            **Benefits:**
            • Utilizes natural state
            • Improves vascular health
            • Gentle approach
            • Quick sessions
            • Minimal equipment

            **Types Available:**
            • AM Stretch Protocol
            • Morning Massage
            • Circulation Enhancement

            ### 5. Specialized Techniques

            Advanced methods combining multiple approaches for targeted results.

            **Benefits:**
            • Accelerated progress
            • Specific goal targeting
            • Advanced practitioners
            • Maximum efficiency
            • Breakthrough plateaus

            ## Choosing the Right Methods

            **For Beginners:**
            • Start with Manual Method 1
            • Add Basic Stretching
            • Master form before progressing
            • 2-3 methods maximum

            **For Length Goals:**
            • Prioritize stretching methods
            • Add traction techniques
            • Include AM protocols
            • Progressive tension focus

            **For Girth Goals:**
            • Focus on expansion methods
            • Include compression techniques
            • Add vascular work
            • Combination approaches

            **For Overall Development:**
            • Balance all categories
            • Rotate method focus
            • Include recovery techniques
            • Comprehensive approach

            ## Method Progression System

            Each method has 3-5 progression stages:

            **Stage 1: Foundation**
            • Learn proper form
            • Minimal intensity
            • Short duration
            • Focus on technique

            **Stage 2: Development**
            • Increase duration
            • Moderate intensity
            • Refine technique
            • Build endurance

            **Stage 3: Advancement**
            • Full duration
            • Optimal intensity
            • Add variations
            • Consistent results

            **Stage 4-5: Mastery**
            • Maximum effectiveness
            • Advanced variations
            • Combination work
            • Personal optimization

            ## Progression Timeline

            • **Weeks 1-4**: Master Stage 1
            • **Weeks 5-8**: Progress to Stage 2
            • **Weeks 9-16**: Advance to Stage 3
            • **Months 4+**: Consider Stage 4-5

            ## Method Combination Strategies

            **Complementary Pairing:**
            • Manual + Stretching
            • AM Method + Evening Routine
            • Device + Manual finishing

            **Sequential Training:**
            • Warm-up → Primary → Secondary → Cool-down
            • Light → Moderate → Intense → Recovery

            **Weekly Rotation:**
            • Monday: Manual focus
            • Wednesday: Stretching emphasis
            • Friday: Combination work

            ## Common Questions

            **Q: How many methods should I use?**
            A: Beginners: 2-3 methods. Intermediate: 3-5. Advanced: 5+

            **Q: Can I do multiple methods in one session?**
            A: Yes, but limit to 2-3 complementary methods per session.

            **Q: How long before switching methods?**
            A: Master current methods for 4-6 weeks before adding new ones.

            **Q: Which method is most effective?**
            A: Effectiveness depends on consistency and proper execution, not the method itself.

            ## Safety Considerations

            ⚠️ Always warm up before any method
            ⚠️ Never rush progression stages
            ⚠️ Stop if you experience pain
            ⚠️ Maintain proper form throughout
            ⚠️ Use adequate lubrication

            ## Next Steps

            1. Choose 2-3 methods matching your goals
            2. Read detailed instructions for each
            3. Practice at Stage 1 for 2 weeks
            4. Track your progress
            5. Gradually increase as comfortable

            Remember: Consistency with proper form beats intensity every time.
            """,
            readingTime: 7,
            tags: ["methods", "techniques", "overview", "categories", "progression"],
            relatedArticles: ["manual-method-guide", "stretching-techniques", "device-guide"]
        ),
        
        HelpArticle(
            id: "progression-guide",
            title: "Progression Strategy Guide",
            subtitle: "How to advance safely through method stages and increase intensity",
            category: .methodsTechniques,
            content: """
            Proper progression is the key to safe, sustainable results. This guide explains how to advance through method stages and increase training intensity effectively.

            ## Understanding Progression

            Progression in Growth follows the principle of progressive overload - gradually increasing demands on your body to stimulate adaptation and growth.

            ## The Three Pillars of Progression

            ### 1. Time Progression
            
            Increasing session duration is often the first progression step.

            **Guidelines:**
            • Increase by 2-3 minutes per week maximum
            • Only after completing current duration comfortably
            • Maintain quality throughout extended time
            • Track endurance improvements

            **Example Timeline:**
            • Week 1-2: 10 minutes
            • Week 3-4: 12-13 minutes
            • Week 5-6: 15 minutes
            • Week 7-8: 17-18 minutes

            ### 2. Intensity Progression

            Adjusting pressure, speed, or resistance within methods.

            **Guidelines:**
            • Increase intensity by 10% weekly max
            • Master current intensity first
            • Never sacrifice form for intensity
            • Monitor body response carefully

            **Intensity Levels:**
            • Light (30-40%): Learning phase
            • Moderate (50-60%): Development phase
            • Firm (70-80%): Advanced phase
            • Maximum (90-100%): Mastery only

            ### 3. Complexity Progression

            Adding variations or combining techniques.

            **Guidelines:**
            • Only after mastering basics
            • One new element at a time
            • Practice new elements separately first
            • Integrate gradually

            ## Stage Advancement Criteria

            ### Ready to Progress When:

            ✅ **Consistency Achieved**
            • Completed 80% of scheduled sessions
            • No missed sessions for 2 weeks
            • Routine feels automatic

            ✅ **Comfort Established**
            • No soreness or discomfort
            • Can complete full duration easily
            • Recovery is quick and complete

            ✅ **Form Mastered**
            • Technique is automatic
            • Can maintain form when tired
            • No bad habits developed

            ✅ **Results Appearing**
            • Measurements improving
            • Visual changes noted
            • Performance indicators positive

            ### NOT Ready If:

            ❌ **Inconsistent Training**
            • Missing sessions regularly
            • Varying intensity randomly
            • No established routine

            ❌ **Discomfort Present**
            • Any pain or soreness
            • Slow recovery
            • Fatigue accumulating

            ❌ **Form Breaking Down**
            • Rushing through methods
            • Compensating with bad habits
            • Unable to maintain technique

            ## Method-Specific Progression

            ### Manual Methods
            
            **Stage 1 → 2:**
            • Master basic grip
            • Increase from 5 to 10 minutes
            • Add rhythm variations

            **Stage 2 → 3:**
            • Extend to 15 minutes
            • Add pressure variations
            • Include direction changes

            **Stage 3 → 4:**
            • Full 20-minute sessions
            • Complex combinations
            • Advanced techniques

            ### Stretching Methods

            **Stage 1 → 2:**
            • Hold stretches longer
            • Add gentle tension
            • Include more directions

            **Stage 2 → 3:**
            • Progressive tension work
            • Multi-angle stretching
            • Increased duration

            **Stage 3 → 4:**
            • Maximum safe tension
            • Complex positions
            • Extended holds

            ## Weekly Progression Examples

            ### Conservative Approach (Recommended)
            
            **Week 1-2:** Establish baseline
            **Week 3-4:** Add 2 minutes OR 10% intensity
            **Week 5-6:** Solidify gains
            **Week 7-8:** Add another increment
            
            ### Standard Approach
            
            **Week 1:** Learn technique
            **Week 2:** Increase time 20%
            **Week 3:** Increase intensity 10%
            **Week 4:** Consolidation week
            
            ### Aggressive Approach (Advanced Only)
            
            **Week 1:** Baseline + 10%
            **Week 2:** Add time and intensity
            **Week 3:** Peak week
            **Week 4:** Deload 50%

            ## Plateau Management

            When progress stalls:

            1. **Deload Week**
               • Reduce volume 50%
               • Focus on perfect form
               • Extra rest days

            2. **Method Rotation**
               • Switch primary methods
               • Try new combinations
               • Change session timing

            3. **Intensity Cycling**
               • High/Low/Medium days
               • Wave loading
               • Periodic testing

            ## Tracking Progression

            **Daily Logs:**
            • Session duration
            • Intensity level (1-10)
            • Method completion
            • Recovery status

            **Weekly Reviews:**
            • Average intensity
            • Total volume
            • Progress indicators
            • Body feedback

            **Monthly Analysis:**
            • Measurement changes
            • Photo comparisons
            • Performance improvements
            • Routine adjustments

            ## Common Progression Mistakes

            ⚠️ **Too Fast:** Jumping stages or adding too much too soon
            ⚠️ **Impatience:** Changing before mastering current level
            ⚠️ **Ignoring Signals:** Pushing through fatigue or discomfort
            ⚠️ **Poor Tracking:** Not monitoring progression accurately
            ⚠️ **Comparison:** Trying to match others' progression

            ## Advanced Progression Strategies

            **Periodization:**
            • 4-week progression cycles
            • Built-in deload weeks
            • Planned peak phases

            **Auto-Regulation:**
            • Daily readiness assessment
            • Adjust based on recovery
            • Flexible progression

            **Specialization Phases:**
            • Focus on one dimension
            • Maintain others minimally
            • Rotate focus monthly

            Remember: Slow, steady progression leads to permanent results. Rush the process, and you risk injury and setbacks.
            """,
            readingTime: 8,
            tags: ["progression", "advancement", "stages", "intensity", "overload"],
            relatedArticles: ["method-overview", "plateau-breaking", "tracking-guide"]
        ),
        
        // Tracking & Progress Articles
        HelpArticle(
            id: "measurement-guide",
            title: "Accurate Measurement Guide",
            subtitle: "Step-by-step instructions for consistent, reliable measurements",
            category: .trackingProgress,
            content: """
            Accurate measurements are crucial for tracking real progress. This comprehensive guide ensures you're measuring correctly and consistently every time.

            ## Why Accurate Measurements Matter

            • Track real vs. perceived progress
            • Identify what's working
            • Adjust routines based on data
            • Stay motivated with objective results
            • Ensure safe progression rates

            ## Essential Equipment

            **Required:**
            • Flexible measuring tape (cloth or vinyl)
            • Rigid ruler (for length)
            • Smartphone for photos
            • Measurement log (in-app)

            **Optional but Helpful:**
            • Marker for consistent points
            • Mirror for positioning
            • Good lighting setup
            • Backup measuring tools

            ## Length Measurement Protocol

            ### Step-by-Step Instructions

            1. **Preparation**
               • Ensure 100% erection level
               • Stand upright, relaxed posture
               • Room temperature environment
               • Same time of day (morning best)

            2. **Positioning**
               • Penis parallel to floor
               • No pushing down or pulling up
               • Natural angle maintained
               • Relaxed state (no flexing)

            3. **Ruler Placement**
               • Press firmly against pubic bone
               • Don't press into fat pad
               • Ruler along top side
               • Perpendicular to body

            4. **Reading Measurement**
               • Eye level with ruler
               • Read at exact tip
               • Record to nearest 1/8" or 0.1cm
               • Take 3 readings, use average

            ### Common Length Errors

            ❌ Not pressing to pubic bone
            ❌ Measuring from side or bottom
            ❌ Inconsistent erection level
            ❌ Changing body position
            ❌ Measuring at different times

            ## Girth Measurement Protocol

            ### Three-Point Method

            1. **Base Girth**
               • Measure at absolute base
               • Against body but not compressed
               • Keep tape level
               • Not too tight or loose

            2. **Mid-Shaft Girth**
               • Exact halfway point
               • Mark if needed for consistency
               • Same tape tension
               • Perpendicular to shaft

            3. **Below Glans**
               • Just behind glans ridge
               • Consistent location
               • Gentle tape placement
               • Record all three

            ### Girth Best Practices

            • Use same measuring tape always
            • Check tape isn't stretched out
            • Measure at same arousal level
            • Keep tape perpendicular
            • Record average of 3 points

            ## Measurement Frequency

            **Recommended Schedule:**
            • Full measurements: Weekly (same day/time)
            • Quick checks: After each routine cycle
            • Progress photos: Bi-weekly
            • Avoid daily measuring

            **Why Not Daily?**
            • Natural size fluctuations
            • Measurement fatigue
            • Obsessive behavior risk
            • No meaningful daily changes

            ## Environmental Factors

            ### Factors Affecting Size

            **Temperature:**
            • Cold causes contraction
            • Heat causes relaxation
            • Measure at room temp
            • Same conditions each time

            **Arousal Level:**
            • Always measure at 100%
            • Use same stimulation method
            • Allow time to reach maximum
            • Be consistent

            **Time of Day:**
            • Morning: Most consistent
            • Evening: May be larger
            • Post-workout: Temporarily enhanced
            • Choose one time, stick to it

            **Hydration Status:**
            • Dehydration reduces size
            • Overhydration affects readings
            • Normal hydration best
            • Consistent water intake

            ## Photo Documentation

            ### Setup for Consistency

            **Camera Position:**
            • Same distance every time
            • Mark floor position
            • Use tripod if possible
            • Same height/angle

            **Lighting:**
            • Consistent light source
            • Avoid shadows
            • Natural light best
            • Same time of day

            **Background:**
            • Plain, consistent background
            • Reference object for scale
            • Grid or ruler visible
            • Same location

            ### Photo Guidelines

            • Front, side, and top views
            • Same poses each time
            • Include measurement tools
            • Date stamp photos
            • Store securely

            ## Recording and Tracking

            ### In-App Logging

            1. Go to Progress tab
            2. Select "Add Measurement"
            3. Enter all data points
            4. Add notes about conditions
            5. Save and review trends

            ### What to Track

            **Primary Metrics:**
            • Length (bone-pressed)
            • Base girth
            • Mid-shaft girth
            • Below glans girth

            **Secondary Metrics:**
            • Flaccid length
            • Flaccid girth
            • Erection quality (1-10)
            • Session performance

            **Conditions:**
            • Time of measurement
            • Days since last session
            • General health status
            • Any relevant notes

            ## Analyzing Your Data

            ### What's Normal?

            **Measurement Variations:**
            • ±0.125" (3mm) daily normal
            • ±0.25" (6mm) weekly possible
            • Look for monthly trends
            • Focus on averages

            **Progress Expectations:**
            • First gains: 4-8 weeks
            • Visible changes: 2-3 months
            • 0.25-0.5" first 6 months typical
            • Slower progress after year 1

            ### When to Adjust

            **No Progress After:**
            • 6-8 weeks: Review technique
            • 3 months: Change routine
            • 6 months: Full reassessment

            ## Troubleshooting

            **Inconsistent Measurements:**
            • Review technique
            • Check equipment
            • Ensure same conditions
            • Take more readings

            **Decreasing Measurements:**
            • Normal fluctuation?
            • Overtraining possible
            • Need rest period
            • Check health factors

            Remember: Consistency in measurement technique is more important than the absolute numbers. Track trends, not individual readings.
            """,
            readingTime: 9,
            tags: ["measurement", "tracking", "progress", "accuracy", "documentation"],
            relatedArticles: ["progress-analysis", "photo-guide", "tracking-tools"]
        ),
        
        // AI Coach Articles
        HelpArticle(
            id: "ai-coach-guide",
            title: "Making the Most of AI Coach",
            subtitle: "How to use the AI Coach feature for personalized guidance",
            category: .aiCoach,
            content: """
            The AI Coach is your 24/7 personal training assistant, powered by advanced artificial intelligence. Learn how to get the most value from your conversations and improve your results.

            ## What Can the AI Coach Do?

            ### Personalized Guidance
            • Analyze your progress data
            • Recommend routine adjustments
            • Suggest methods for your goals
            • Create custom programs
            • Troubleshoot plateaus

            ### Technical Support
            • Explain proper form
            • Clarify method instructions
            • Answer safety questions
            • Provide alternative techniques
            • Debug common issues

            ### Motivation & Accountability
            • Daily check-ins
            • Progress celebrations
            • Plateau encouragement
            • Goal setting help
            • Consistency reminders

            ### Educational Resources
            • Scientific explanations
            • Anatomy education
            • Best practices
            • Research summaries
            • Myth busting

            ## Getting Started with AI Coach

            ### First Conversation

            1. **Introduce Yourself**
               "Hi, I'm new to Growth. I'm a beginner looking to start safely."

            2. **Share Your Goals**
               "My goal is to gain 0.5 inches in length over 6 months."

            3. **Describe Your Experience**
               "I've never done PE before but I'm committed to being consistent."

            4. **Ask for Recommendations**
               "What routine would you recommend for someone like me?"

            ### Best Practices for Questions

            **Be Specific:**
            ❌ "Help me get bigger"
            ✅ "I've been doing Manual Method 1 for 4 weeks. Should I progress to stage 2?"

            **Provide Context:**
            ❌ "Is this normal?"
            ✅ "I'm experiencing mild soreness after sessions. Is this normal for week 2?"

            **Share Data:**
            ❌ "I'm not seeing results"
            ✅ "My measurements haven't changed in 3 weeks. Length: 6.0", Girth: 4.5". Current routine: [details]"

            ## Types of Questions to Ask

            ### Routine Optimization
            • "Review my current routine and suggest improvements"
            • "How can I balance length and girth training?"
            • "Should I add a 4th training day?"
            • "What methods complement each other?"

            ### Technique Clarification
            • "Can you explain the proper grip for Manual Method 2?"
            • "How much pressure should I use for stretching?"
            • "What's the difference between Stage 2 and 3?"
            • "How do I know if my form is correct?"

            ### Progress Analysis
            • "I've gained 0.25\" in 3 months. Is this good progress?"
            • "Why did my gains slow down after month 2?"
            • "Should I take a deload week?"
            • "How can I break through this plateau?"

            ### Safety Concerns
            • "I felt a slight discomfort during stretching. Should I be concerned?"
            • "How do I differentiate between good and bad sensations?"
            • "What are signs I'm overtraining?"
            • "When should I take extra rest?"

            ### Goal Setting
            • "Is gaining 1 inch in a year realistic?"
            • "Should I focus on length or girth first?"
            • "How do I set monthly targets?"
            • "What's a good long-term plan?"

            ## Advanced AI Coach Features

            ### Progress Review Sessions

            Ask for comprehensive analysis:
            "Can you review my last month's progress and provide a detailed assessment?"

            The AI will analyze:
            • Measurement trends
            • Session consistency
            • Method effectiveness
            • Areas for improvement
            • Next month's focus

            ### Custom Routine Creation

            Request personalized programs:
            "Create a 12-week routine focused on length, intermediate level, 4 days per week"

            The AI will provide:
            • Weekly schedule
            • Method selection
            • Progression timeline
            • Rest day placement
            • Adjustment guidelines

            ### Troubleshooting Sessions

            Get help with specific issues:
            "I've been stuck at 6.5\" length for 6 weeks despite consistent training. Help me troubleshoot."

            The AI will explore:
            • Current routine analysis
            • Potential limiting factors
            • Technique assessment
            • Recovery evaluation
            • Solution strategies

            ## Making Conversations Productive

            ### Before Starting a Chat

            1. **Review Recent Progress**
               Check your measurements and logs

            2. **Identify Specific Questions**
               Write down what you need help with

            3. **Gather Relevant Data**
               Have your stats and routine ready

            4. **Set Clear Objectives**
               Know what you want from the conversation

            ### During the Conversation

            • Answer follow-up questions thoroughly
            • Be honest about compliance and issues
            • Ask for clarification if needed
            • Take notes on recommendations
            • Request specific action items

            ### After the Chat

            • Review and save important advice
            • Implement recommendations
            • Track results of changes
            • Follow up on progress
            • Share outcomes in next chat

            ## Privacy and Data

            **What the AI Coach Knows:**
            • Your measurement history
            • Session logs and consistency
            • Methods you've used
            • Previous conversations
            • General app usage patterns

            **Privacy Guarantees:**
            • Conversations are encrypted
            • No human reviews your chats
            • Data never shared externally
            • You can delete chat history
            • Anonymous usage statistics only

            ## Common AI Coach Conversations

            ### Weekly Check-In Template
            "Weekly update: Completed 3/3 sessions. Measurements: L: 6.25\" (+0.05\"), G: 4.6\" (same). Feeling good, no issues. Should I change anything?"

            ### Plateau Breaking Template
            "Hit plateau: No gains for 4 weeks. Current: [stats]. Routine: [details]. Training 4x/week, good consistency. Need new strategy."

            ### Method Question Template
            "Question about [Method Name]: Currently at Stage [X]. Experiencing [specific issue/question]. How should I adjust?"

            ## Tips for Best Results

            💡 **Be Consistent:** Regular check-ins help the AI understand your patterns

            💡 **Be Detailed:** More information leads to better recommendations

            💡 **Be Patient:** Implement advice for 2-4 weeks before judging effectiveness

            💡 **Be Open:** Try suggested modifications even if different from your plan

            💡 **Be Honest:** Accurate information ensures appropriate guidance

            Remember: The AI Coach is a tool to enhance your training, not replace your judgment. Always prioritize safety and listen to your body.
            """,
            readingTime: 10,
            tags: ["ai coach", "chat", "guidance", "personalized", "assistant"],
            relatedArticles: ["conversation-examples", "ai-privacy", "coaching-benefits"]
        ),
        
        // Settings & Features Articles
        HelpArticle(
            id: "live-activity-guide",
            title: "Live Activity & Dynamic Island",
            subtitle: "Using timer features on your lock screen and Dynamic Island",
            category: .settingsFeatures,
            content: """
            Live Activity brings your training timer to your iPhone's lock screen and Dynamic Island (iPhone 14 Pro and later), allowing you to monitor sessions without keeping the app open.

            ## What is Live Activity?

            Live Activity is an iOS feature that displays real-time information from Growth on your lock screen and in the Dynamic Island. When you start a timed session, you can:

            • See remaining time at a glance
            • Pause/resume without opening the app
            • Track progress with visual indicators
            • Maintain privacy with discreet mode
            • Switch apps while timer continues

            ## Setting Up Live Activity

            ### Enable the Feature

            1. **In Growth App:**
               • Go to Settings → Notifications
               • Toggle ON "Live Activities"
               • Toggle ON "Timer Notifications"

            2. **In iPhone Settings:**
               • Settings → Growth
               • Ensure "Live Activities" is enabled
               • Check notification permissions

            ### First Time Use

            1. Start any timed session
            2. Swipe up to go home
            3. Timer appears on lock screen
            4. Tap to see controls

            ## Using Live Activity

            ### Lock Screen Display

            **Standard View Shows:**
            • Method name
            • Current stage
            • Time remaining
            • Progress bar
            • Pause/Resume button

            **Expanded View (Long Press):**
            • Full session details
            • Skip stage option
            • End session button
            • Notes field

            ### Dynamic Island (iPhone 14 Pro+)

            **Compact View:**
            • Small timer bubble
            • Tap to expand
            • Glanceable progress

            **Expanded View:**
            • Full timer display
            • Quick controls
            • Method details
            • Visual progress

            ## Privacy Features

            ### Discreet Mode

            Enable for privacy:
            1. Settings → Privacy
            2. Toggle "Discreet Live Activity"
            3. Shows generic "Timer" label
            4. No method details visible

            ### Notification Privacy

            • Blur sensitive information
            • Generic app icon option
            • Hide notification preview
            • Require authentication

            ## Advanced Features

            ### Background Updates

            The timer continues accurately even when:
            • App is closed
            • Phone is locked
            • Using other apps
            • Low Power Mode active

            ### Smart Alerts

            • 1-minute warning
            • Stage completion
            • Session finished
            • Rest reminders

            ### Multi-Stage Support

            • Automatic stage progression
            • Visual stage indicators
            • Manual stage control
            • Custom stage timing

            ## Troubleshooting

            ### Live Activity Not Appearing

            1. **Check Permissions:**
               • iOS Settings → Growth → Live Activities ON
               • Notification permissions enabled

            2. **Restart Process:**
               • Force quit Growth app
               • Restart iPhone
               • Try starting new session

            3. **iOS Version:**
               • Requires iOS 16.1 or later
               • Update iOS if needed

            ### Timer Not Updating

            • Check battery settings
            • Disable Low Power Mode
            • Ensure background refresh on
            • Reinstall app if persistent

            ### Dynamic Island Issues

            • Only iPhone 14 Pro and later
            • Check for iOS updates
            • Reset all settings
            • Contact support

            ## Battery Impact

            **Minimal Usage:**
            • Uses iOS system features
            • No significant drain
            • Efficient background updates
            • Automatic optimization

            **Best Practices:**
            • Keep iOS updated
            • Close unused apps
            • Normal battery management
            • No special settings needed

            ## Tips for Best Experience

            💡 **Quick Access:** Add timer widget to Today View for faster starts

            💡 **Haptic Feedback:** Enable for stage changes and completion

            💡 **Auto-Lock:** Set longer auto-lock time during sessions

            💡 **Focus Mode:** Create training Focus to minimize distractions

            ## Comparison with Standard Timer

            **Live Activity Advantages:**
            • Always visible
            • Quick controls
            • App switching friendly
            • Battery efficient
            • System integrated

            **When to Use Standard Timer:**
            • Detailed method instructions needed
            • Complex multi-method sessions
            • Note-taking during session
            • First time with method

            ## Future Enhancements

            Coming soon:
            • Apple Watch support
            • Custom complications
            • Siri integration
            • Shortcut automation
            • Widget improvements

            Remember: Live Activity is designed to enhance your training experience while maintaining privacy and convenience.
            """,
            readingTime: 7,
            tags: ["live activity", "dynamic island", "timer", "ios", "features"],
            relatedArticles: ["timer-guide", "privacy-settings", "ios-features"]
        ),
        
        // Troubleshooting Articles
        HelpArticle(
            id: "common-issues",
            title: "Troubleshooting Common Issues",
            subtitle: "Solutions for frequent problems and error messages",
            category: .troubleshooting,
            content: """
            This guide helps you resolve common issues quickly. If your problem isn't listed here, contact support for personalized help.

            ## App Performance Issues

            ### App Running Slowly

            **Symptoms:**
            • Laggy interface
            • Slow screen transitions
            • Delayed button responses
            • Timer stuttering

            **Solutions:**
            1. **Clear Cache**
               • Settings → Storage → Clear Cache
               • Restart app

            2. **Free Up Space**
               • Delete old progress photos
               • Export and remove old data
               • Check iPhone storage

            3. **Update App**
               • Check App Store for updates
               • Install latest version

            4. **Restart iPhone**
               • Full power cycle
               • Clear system memory

            ### App Crashing

            **Immediate Steps:**
            1. Force quit app (swipe up and remove)
            2. Restart iPhone
            3. Update to latest app version
            4. Check iOS compatibility

            **If Persists:**
            • Delete and reinstall app
            • Check for iOS updates
            • Reset network settings
            • Contact support with crash logs

            ## Sync and Data Issues

            ### Data Not Syncing

            **Check These First:**
            • Internet connection active
            • Logged into correct account
            • iCloud Drive enabled
            • Sufficient iCloud storage

            **Fix Steps:**
            1. Pull down to refresh
            2. Log out and back in
            3. Toggle iCloud sync off/on
            4. Check date/time settings

            ### Missing Measurements

            **Possible Causes:**
            • Not saved properly
            • Sync delay
            • Account mix-up
            • Local storage only

            **Recovery Steps:**
            1. Check "Local Only" data
            2. Force sync (Settings → Sync Now)
            3. Check other devices
            4. Restore from backup

            ## Timer Problems

            ### Timer Stopping Unexpectedly

            **Common Causes:**
            • iOS battery optimization
            • Background app refresh off
            • Low Power Mode active
            • Memory pressure

            **Solutions:**
            1. **Settings → Battery**
               • Disable Low Power Mode
               • Turn off battery optimization for Growth

            2. **Background App Refresh**
               • Settings → General → Background App Refresh
               • Enable for Growth

            3. **Use Live Activity**
               • More reliable for long sessions
               • Continues when app closes

            ### Timer Not Starting

            • Check method selection
            • Ensure stage is chosen
            • Verify no active session
            • Restart app if frozen

            ## Measurement Tracking Issues

            ### Can't Add Measurements

            **Troubleshooting:**
            1. Check data format (decimals)
            2. Ensure reasonable values
            3. Verify date not future
            4. Check edit permissions

            ### Wrong Measurement Units

            **To Change Units:**
            1. Settings → Units & Display
            2. Choose Imperial or Metric
            3. Existing data converts automatically
            4. Restart app to ensure change

            ## AI Coach Problems

            ### AI Coach Not Responding

            **Check:**
            • Internet connection
            • Subscription status
            • Server status page
            • App permissions

            **Fix:**
            1. Close and reopen chat
            2. Clear conversation cache
            3. Check subscription active
            4. Try again in few minutes

            ### Generic AI Responses

            **Improve Responses:**
            • Provide more context
            • Share specific data
            • Ask detailed questions
            • Reference your history

            ## Account and Login Issues

            ### Can't Log In

            **Step-by-Step:**
            1. Verify email spelling
            2. Check caps lock
            3. Try password reset
            4. Check spam folder
            5. Try different network

            ### Account Locked

            **Reasons:**
            • Too many login attempts
            • Suspicious activity
            • Payment issue
            • Terms violation

            **Resolution:**
            • Wait 30 minutes
            • Reset password
            • Contact support
            • Verify payment method

            ## Subscription Problems

            ### Subscription Not Recognized

            1. **Restore Purchase**
               • Settings → Subscription
               • Tap "Restore Purchases"
               • Sign in if prompted

            2. **Verify Status**
               • Check iOS Settings → Apple ID → Subscriptions
               • Confirm active status
               • Check correct Apple ID

            ### Can't Cancel Subscription

            **Correct Method:**
            • iOS Settings (not Growth app)
            • Apple ID → Subscriptions
            • Select Growth
            • Cancel Subscription

            ## Photo Storage Issues

            ### Photos Not Saving

            **Permissions Check:**
            1. iOS Settings → Growth
            2. Photos permission enabled
            3. Storage space available
            4. iCloud Photos settings

            ### Can't View Old Photos

            • Check filter settings
            • Verify date range
            • Ensure sync complete
            • Try different sort order

            ## General Fixes

            ### Nuclear Option (Last Resort)

            If nothing else works:

            1. **Export All Data**
               • Settings → Export Data
               • Save to safe location

            2. **Delete App**
               • Hold app icon
               • Delete app
               • Restart iPhone

            3. **Fresh Install**
               • Download from App Store
               • Log in with same account
               • Restore purchases
               • Import backed-up data

            ### When to Contact Support

            Contact support if:
            • Problem persists after troubleshooting
            • Data loss occurred
            • Payment issues
            • Security concerns
            • Bug affecting usage

            **Include in Support Request:**
            • Device model and iOS version
            • App version number
            • Description of issue
            • Steps to reproduce
            • Screenshots if applicable

            Remember: Most issues have simple solutions. Work through troubleshooting steps methodically before assuming the worst.
            """,
            readingTime: 8,
            tags: ["troubleshooting", "problems", "issues", "fixes", "support"],
            relatedArticles: ["contact-support", "data-recovery", "app-settings"]
        ),
        
        // Additional Getting Started Articles
        HelpArticle(
            id: "app-navigation-guide",
            title: "Navigating the App",
            subtitle: "Understanding the main sections and features",
            category: .gettingStarted,
            content: """
            Growth is organized into six main sections, each designed to support different aspects of your training journey. This guide helps you understand what each section offers and how to use them effectively.

            ## Main Navigation Tabs

            ### 1. Dashboard Tab

            Your training command center providing:
            • Quick session start button
            • Today's scheduled activities
            • Recent progress summary
            • Streak counter
            • Quick stats overview

            **Key Actions:**
            • Tap "Start Session" for quick practice
            • View upcoming routine sessions
            • Check daily goals
            • Monitor consistency streak

            ### 2. Methods Tab

            Your complete method library containing:
            • All available training methods
            • Detailed instructions and videos
            • Progression stages for each method
            • Equipment requirements
            • Safety guidelines

            **How to Use:**
            • Browse by category
            • Filter by experience level
            • Save favorites for quick access
            • View stage progressions
            • Access video tutorials

            ### 3. Progress Tab

            Comprehensive tracking center featuring:
            • Measurement logging
            • Progress charts
            • Photo comparisons
            • Analytics dashboard
            • Export options

            **Features:**
            • Add new measurements
            • View historical trends
            • Compare progress photos
            • Analyze performance metrics
            • Share progress reports

            ### 4. Coach Tab

            AI-powered assistance providing:
            • 24/7 chat support
            • Personalized recommendations
            • Technique guidance
            • Progress analysis
            • Motivation support

            **Best Uses:**
            • Ask specific questions
            • Get routine recommendations
            • Troubleshoot issues
            • Review progress
            • Plan adjustments

            ### 5. Resources Tab

            Educational content including:
            • Scientific articles
            • Safety guidelines
            • Anatomy education
            • Best practices
            • Video tutorials

            **Content Types:**
            • Beginner guides
            • Advanced techniques
            • Research summaries
            • Safety protocols
            • Success stories

            ### 6. Settings Tab

            App customization and account management:
            • Profile settings
            • Privacy controls
            • Notification preferences
            • Data management
            • Subscription status

            ## Quick Tips for New Users

            💡 **Start Here**: Dashboard → Start Session → Choose a beginner method

            💡 **Learn First**: Resources → Beginner Guides → Safety Fundamentals

            💡 **Track Early**: Progress → Add Measurement → Set baseline

            💡 **Get Help**: Coach → Start Chat → "I'm new, help me begin"

            ## Hidden Features

            **Long Press Actions:**
            • Dashboard cards for quick edits
            • Method tiles for favorites
            • Progress entries for notes

            **Swipe Gestures:**
            • Left on sessions to delete
            • Right on methods to save
            • Down on charts to refresh

            **3D Touch/Haptic Touch:**
            • App icon for quick session
            • Timer for controls
            • Charts for data points

            ## Customization Options

            **Dashboard Layout:**
            • Rearrange card order
            • Hide/show widgets
            • Choose metric display

            **Method Organization:**
            • Create custom folders
            • Sort preferences
            • Filter settings

            **Progress Display:**
            • Chart types
            • Date ranges
            • Metric preferences

            Remember: Take time to explore each section. The app is designed to grow with you as you progress.
            """,
            readingTime: 4,
            tags: ["navigation", "app guide", "features", "tabs", "interface"],
            relatedArticles: ["welcome-to-growth", "first-routine-guide", "app-settings-guide"]
        ),
        
        // Additional Methods Articles
        HelpArticle(
            id: "manual-method-guide",
            title: "Mastering Manual Methods",
            subtitle: "Complete guide to manual training techniques",
            category: .methodsTechniques,
            content: """
            Manual methods are the foundation of effective training. This comprehensive guide covers proper technique, progression, and optimization for all manual methods.

            ## Understanding Manual Methods

            Manual methods involve direct hand techniques without equipment. They offer:
            • Complete control over pressure and speed
            • No equipment costs
            • Immediate feedback
            • Versatile application
            • Safe progression

            ## Basic Manual Method 1

            **Purpose:** Foundation technique for beginners

            **Technique:**
            1. Proper grip formation
            2. Consistent pressure application
            3. Controlled movement patterns
            4. Regular rhythm maintenance
            5. Focus on form over speed

            **Key Points:**
            • Start with light pressure
            • Maintain relaxed grip
            • Use adequate lubrication
            • Focus on consistency
            • Never rush movements

            **Progression Timeline:**
            • Week 1-2: Learn basic form
            • Week 3-4: Increase duration
            • Week 5-6: Add variations
            • Week 7-8: Advance to Stage 2

            ## Manual Method 2: Advanced Techniques

            **Prerequisites:**
            • Mastered Method 1
            • 4+ weeks experience
            • No discomfort with basics

            **New Elements:**
            • Variable pressure zones
            • Direction changes
            • Speed variations
            • Combined movements
            • Advanced grips

            **Safety Focus:**
            • Gradual intensity increase
            • Monitor tissue response
            • Extra warm-up time
            • Careful pressure control

            ## Manual Method 3: Specialized Approaches

            **Target Areas:**
            • Base enhancement
            • Mid-shaft development
            • Head expansion
            • Overall balance

            **Technique Variations:**
            • Focused pressure points
            • Rotational movements
            • Stretching integration
            • Pulse techniques

            ## Common Manual Method Mistakes

            ❌ **Excessive Pressure**
            • Causes: Impatience, poor form
            • Fix: Reset to 50% intensity

            ❌ **Inconsistent Rhythm**
            • Causes: Fatigue, distraction
            • Fix: Use timer, count reps

            ❌ **Neglecting Lubrication**
            • Causes: Forgetfulness, rushing
            • Fix: Pre-session checklist

            ❌ **Skipping Warm-Up**
            • Causes: Time pressure
            • Fix: Build into routine

            ## Optimizing Your Manual Training

            ### Session Structure
            
            **Warm-Up (5 min):**
            • Light massage
            • Gradual blood flow increase
            • Mental preparation

            **Main Work (10-20 min):**
            • Primary method focus
            • Consistent technique
            • Progress monitoring

            **Cool-Down (5 min):**
            • Pressure reduction
            • Recovery massage
            • Session notes

            ### Weekly Programming

            **Beginner (3x/week):**
            • Monday: Method 1 basic
            • Wednesday: Method 1 variation
            • Friday: Combined session

            **Intermediate (4x/week):**
            • Add Method 2 elements
            • Increase duration
            • Include specialization

            **Advanced (5x/week):**
            • Multiple methods
            • Extended sessions
            • Targeted protocols

            ## Tracking Manual Progress

            **Session Metrics:**
            • Duration completed
            • Intensity level (1-10)
            • Technique quality
            • Recovery status

            **Weekly Review:**
            • Total volume
            • Intensity average
            • Technique improvements
            • Any issues noted

            ## Troubleshooting Manual Methods

            **"Not Feeling Anything"**
            • Check grip pressure
            • Verify technique
            • Ensure proper arousal
            • Consider progression

            **"Getting Fatigued Quickly"**
            • Reduce intensity
            • Take micro-breaks
            • Check grip tension
            • Build endurance slowly

            **"Losing Focus"**
            • Use timer alerts
            • Set mini-goals
            • Try audio guidance
            • Minimize distractions

            Remember: Manual methods are skill-based. Perfect practice makes perfect progress.
            """,
            readingTime: 6,
            tags: ["manual methods", "technique", "training", "progression", "guide"],
            relatedArticles: ["method-overview", "stretching-techniques", "progression-guide"]
        ),
        
        HelpArticle(
            id: "stretching-techniques",
            title: "Stretching Methods Explained",
            subtitle: "Safe and effective stretching protocols",
            category: .methodsTechniques,
            content: """
            Stretching methods focus on gradual tissue elongation through controlled tension. This guide covers proper technique, safety considerations, and progression strategies.

            ## Fundamentals of Stretching

            Stretching methods work by:
            • Applying controlled tension
            • Promoting tissue adaptation
            • Improving flexibility
            • Enhancing circulation
            • Supporting other methods

            ## Basic Stretching Protocol

            ### Preparation
            
            **Essential Steps:**
            1. Complete full warm-up
            2. Achieve optimal state
            3. Apply lubrication
            4. Find comfortable position
            5. Prepare timer

            ### Basic Technique

            **Grip Formation:**
            • Behind glans placement
            • Firm but gentle hold
            • Even pressure distribution
            • No circulation restriction
            • Comfortable hand position

            **Direction Sequence:**
            1. Straight out (baseline)
            2. Upward angle
            3. Downward angle
            4. Left side
            5. Right side
            6. Rotational (advanced)

            **Hold Times:**
            • Beginner: 30-60 seconds
            • Intermediate: 1-2 minutes
            • Advanced: 2-3 minutes
            • Between directions: 30s rest

            ## Progressive Stretching Methods

            ### Method 1: Static Holds
            
            **Technique:**
            • Apply steady tension
            • Hold without movement
            • Focus on time under tension
            • Gradual intensity increase

            **Best For:**
            • Beginners
            • Length focus
            • Recovery days
            • Technique learning

            ### Method 2: Dynamic Stretching

            **Technique:**
            • Gentle tension changes
            • Slow, controlled movement
            • Varied angles
            • Rhythm focus

            **Best For:**
            • Intermediate users
            • Flexibility improvement
            • Warm-up integration
            • Variety needs

            ### Method 3: Progressive Tension

            **Technique:**
            • Start at 50% tension
            • Increase gradually
            • Peak at 80% max
            • Controlled release

            **Best For:**
            • Advanced users
            • Plateau breaking
            • Intensive sessions
            • Maximum gains

            ## Safety Guidelines

            ### Critical Rules

            ⚠️ **Never Stretch Cold**
            • Always warm up first
            • Check tissue readiness
            • Start very gentle

            ⚠️ **Stop at Discomfort**
            • Tension yes, pain no
            • Listen to your body
            • When in doubt, reduce

            ⚠️ **Avoid Overstretching**
            • No bouncing motions
            • No sudden increases
            • No extreme angles

            ### Warning Signs

            **Stop Immediately If:**
            • Sharp pain
            • Numbness/tingling
            • Color changes
            • Loss of sensation
            • Unusual marks

            ## Optimization Strategies

            ### Session Design

            **Structure:**
            1. Warm-up (5-10 min)
            2. Light stretches (5 min)
            3. Main stretching (10-15 min)
            4. Recovery (5 min)

            **Frequency:**
            • Beginner: 3x weekly
            • Intermediate: 4-5x weekly
            • Advanced: Daily possible
            • Rest days important

            ### Combining with Other Methods

            **Effective Combinations:**
            • Stretching → Manual
            • AM stretching routine
            • Post-device stretching
            • Recovery stretching

            **Timing:**
            • Morning: Gentle only
            • Afternoon: Full intensity
            • Evening: Moderate
            • Post-workout: Light

            ## Progress Tracking

            ### Measurements

            **What to Track:**
            • Maximum stretch length
            • Comfortable hold time
            • Angle achievements
            • Recovery time
            • Flexibility improvements

            **How to Measure:**
            • Use consistent markers
            • Same time of day
            • Same conditions
            • Regular intervals
            • Photo documentation

            ### Expected Progress

            **Timeline:**
            • Week 1-2: Technique learning
            • Week 3-4: Comfort building
            • Week 5-8: First gains
            • Month 3+: Steady progress

            **Realistic Expectations:**
            • 0.25" in 3 months
            • 0.5" in 6 months
            • Individual variation
            • Consistency crucial

            ## Advanced Techniques

            ### Fulcrum Stretching

            **Method:**
            • Use cylindrical object
            • Create leverage point
            • Enhanced stretch angle
            • Advanced users only

            ### Bundle Stretching

            **Method:**
            • Combine with rotation
            • Multi-directional tension
            • Complex movement patterns
            • Maximum effectiveness

            ### Assisted Stretching

            **Method:**
            • Device integration
            • Hands-free options
            • Extended duration
            • Consistent tension

            ## Troubleshooting

            **"Not Seeing Length Gains"**
            • Increase hold times
            • Check tension level
            • Verify measurement method
            • Consider deload week

            **"Losing Grip"**
            • Adjust hand position
            • Use grip aids
            • Check lubrication
            • Try different angles

            **"Getting Sore"**
            • Reduce intensity
            • Extra rest days
            • Check technique
            • Warm up more

            Remember: Stretching is a marathon, not a sprint. Patience and consistency yield the best results.
            """,
            readingTime: 7,
            tags: ["stretching", "methods", "technique", "length", "flexibility"],
            relatedArticles: ["manual-method-guide", "safety-fundamentals", "progression-guide"]
        ),
        
        // Additional Progress Tracking Articles
        HelpArticle(
            id: "progress-analysis",
            title: "Analyzing Your Progress Data",
            subtitle: "Understanding trends and making data-driven decisions",
            category: .trackingProgress,
            content: """
            Your progress data tells a story. Learning to read and interpret this data helps you make informed decisions about your training. This guide teaches you how to analyze your measurements, identify trends, and optimize your approach.

            ## Understanding Progress Metrics

            ### Primary Measurements

            **Length Metrics:**
            • Bone-pressed erect length (BPEL)
            • Non-bone-pressed length (NBPEL)
            • Stretched flaccid length (SFL)
            • Morning vs. evening variations

            **Girth Metrics:**
            • Base girth (BG)
            • Mid-shaft girth (MSG)
            • Below glans girth (BGG)
            • Average girth calculation

            **Performance Indicators:**
            • Erection quality (EQ) score
            • Recovery time
            • Session endurance
            • Technique consistency

            ## Reading Progress Charts

            ### Trend Identification

            **Upward Trends:**
            • Consistent gains over time
            • May include plateaus
            • Generally linear or stepped
            • Indicates effective routine

            **Plateau Patterns:**
            • Flat line for 2-4 weeks
            • Normal part of progress
            • Often precedes growth spurt
            • Not cause for concern

            **Fluctuation Patterns:**
            • Daily variations normal
            • Weekly averages matter more
            • Consider measurement conditions
            • Look for overall direction

            ### Statistical Analysis

            **Moving Averages:**
            • 7-day average smooths daily variation
            • 30-day average shows true trend
            • Compare current to historical
            • Identifies real vs. temporary changes

            **Growth Rate Calculation:**
            • Monthly gain = (End - Start) / Days × 30
            • Typical rates: 0.05-0.15" per month
            • Varies by individual
            • Slows over time

            ## Identifying Success Patterns

            ### What Works

            **Positive Indicators:**
            • Consistent upward trend
            • Improved EQ scores
            • Quick recovery
            • No discomfort
            • Motivation high

            **Routine Elements:**
            • Which methods show results?
            • What intensity works best?
            • Optimal session duration?
            • Best weekly frequency?

            ### Red Flags

            **Warning Signs:**
            • Decreasing measurements
            • Poor EQ scores
            • Slow recovery
            • Frequent soreness
            • Lost motivation

            **Immediate Actions:**
            • Take rest week
            • Reduce intensity
            • Review technique
            • Check health factors

            ## Data-Driven Decisions

            ### When to Progress

            **Clear Indicators:**
            • 4+ weeks at current level
            • Consistent gains
            • Easy recovery
            • Technique mastered
            • No issues present

            **How to Progress:**
            • Increase one variable
            • Monitor for 2 weeks
            • Adjust if needed
            • Document changes

            ### When to Deload

            **Deload Triggers:**
            • 3+ weeks no progress
            • Decreased performance
            • Accumulated fatigue
            • Life stress high
            • Motivation dropping

            **Deload Protocol:**
            • 50% volume week
            • Focus on technique
            • Extra rest days
            • Recovery activities

            ## Advanced Analytics

            ### Correlation Analysis

            **Factors to Compare:**
            • Sleep vs. gains
            • Stress vs. performance
            • Diet vs. recovery
            • Hydration vs. EQ
            • Exercise vs. results

            **Finding Patterns:**
            • Track multiple variables
            • Look for relationships
            • Test hypotheses
            • Adjust based on findings

            ### Periodization Tracking

            **Cycle Analysis:**
            • 4-week mesocycles
            • Progress within cycles
            • Fatigue accumulation
            • Peak performances
            • Recovery needs

            ## Using Analytics Tools

            ### In-App Features

            **Progress Dashboard:**
            • Visual trend lines
            • Growth rate calculator
            • Comparison tools
            • Export options
            • Custom date ranges

            **Reports Generation:**
            • Monthly summaries
            • Method effectiveness
            • Time analysis
            • Goal tracking
            • Share options

            ### External Analysis

            **Spreadsheet Tips:**
            • Export CSV data
            • Create custom charts
            • Advanced formulas
            • Trend analysis
            • Prediction models

            ## Making Adjustments

            ### Based on Length Data

            **Slow Length Gains:**
            • Increase stretching
            • Add AM sessions
            • Extend hold times
            • Check technique

            **Good Length Progress:**
            • Maintain protocol
            • Document what works
            • Gradual progression
            • Don't change much

            ### Based on Girth Data

            **Slow Girth Gains:**
            • Add expansion work
            • Increase intensity
            • Try new methods
            • Check pressure

            **Good Girth Progress:**
            • Continue approach
            • Monitor carefully
            • Avoid overtraining
            • Balance with length

            ## Long-Term Perspective

            ### Realistic Timelines

            **First Year:**
            • 0.5-1.0" length typical
            • 0.25-0.5" girth possible
            • Highly individual
            • Consistency key

            **Beyond Year One:**
            • Slower progress
            • Refinement focus
            • Maintenance important
            • Advanced techniques

            ### Success Metrics

            **Beyond Size:**
            • Improved confidence
            • Better EQ
            • Enhanced stamina
            • Partner satisfaction
            • Overall wellness

            Remember: Data guides decisions, but listening to your body remains paramount. Use analytics as a tool, not a master.
            """,
            readingTime: 8,
            tags: ["analytics", "progress", "data", "tracking", "analysis"],
            relatedArticles: ["measurement-guide", "progress-photos", "plateau-breaking"]
        ),
        
        HelpArticle(
            id: "progress-photos",
            title: "Progress Photo Best Practices",
            subtitle: "How to take consistent photos for accurate comparisons",
            category: .trackingProgress,
            content: """
            Progress photos provide visual confirmation of your gains and help identify changes that measurements might miss. This guide ensures you take consistent, comparable photos throughout your journey.

            ## Why Progress Photos Matter

            • Visual proof of progress
            • Catch subtle changes
            • Motivation booster
            • Technique verification
            • Historical record

            ## Camera Setup

            ### Equipment Needed

            **Basic Requirements:**
            • Smartphone camera
            • Tripod or stable surface
            • Consistent lighting
            • Plain background
            • Timer function

            **Optional Upgrades:**
            • Ring light
            • Grid backdrop
            • Remote shutter
            • Measurement tape in frame
            • Multiple angles setup

            ### Positioning

            **Camera Placement:**
            • Hip height level
            • 3-4 feet distance
            • Perpendicular angle
            • Centered framing
            • Landscape orientation

            **Mark Your Spot:**
            • Tape floor position
            • Note camera height
            • Save setup details
            • Use same location
            • Consistent distance

            ## Lighting Guidelines

            ### Best Lighting

            **Natural Light:**
            • Morning light ideal
            • Avoid direct sun
            • Diffused daylight
            • Consistent time
            • North-facing window

            **Artificial Light:**
            • Soft white bulbs
            • Multiple sources
            • No harsh shadows
            • Even distribution
            • Same setup always

            ### Avoid These

            ❌ Overhead lighting only
            ❌ Strong shadows
            ❌ Colored lights
            ❌ Changing conditions
            ❌ Flash photography

            ## Photo Angles

            ### Standard Set

            **1. Front View:**
            • Straight on
            • Relaxed posture
            • Arms at sides
            • Level angle
            • Full visibility

            **2. Side Profile:**
            • 90-degree turn
            • Natural stance
            • Shows curve
            • Same height
            • Clear outline

            **3. Top Down:**
            • Camera above
            • Shows girth
            • Difficult alone
            • Use timer
            • Keep consistent

            **4. Measurement Shot:**
            • Ruler visible
            • Clear markings
            • Proper placement
            • Good focus
            • Reference point

            ## Consistency Tips

            ### Same Conditions

            **Every Photo:**
            • Same time of day
            • Same arousal level
            • Same room temperature
            • Same hydration
            • Same stance

            **Document Settings:**
            • Camera settings
            • Distance measurement
            • Lighting setup
            • Time of day
            • Any variations

            ### Posing Guidelines

            **Body Position:**
            • Relaxed stance
            • Weight centered
            • No flexing
            • Natural posture
            • Consistent angle

            **Hand Placement:**
            • Same position
            • Not covering
            • Natural hold
            • Consistent grip
            • Clear visibility

            ## Privacy & Storage

            ### Security First

            **In-App Storage:**
            • Encrypted vault
            • Passcode protected
            • No cloud sync
            • Local only option
            • Secure deletion

            **Best Practices:**
            • Never include face
            • Remove identifiers
            • Secure device
            • Regular backups
            • Private folder

            ### Organization

            **File Naming:**
            • Date format: YYYY-MM-DD
            • Angle identifier
            • Measurement note
            • Consistent system
            • Easy sorting

            **Folder Structure:**
            • Monthly folders
            • Angle subfolders
            • Measurement records
            • Notes file
            • Backup copies

            ## Comparison Techniques

            ### Side-by-Side

            **Creating Comparisons:**
            • Use same scale
            • Align properly
            • Match lighting
            • Label dates
            • Note changes

            **What to Look For:**
            • Overall size changes
            • Shape improvements
            • Vascular changes
            • Proportional growth
            • Angle differences

            ### Progress Collages

            **Monthly Reviews:**
            • 4-photo grid
            • Same angle set
            • Chronological order
            • Clear labels
            • Share safely

            ## Common Mistakes

            ### Photography Errors

            ❌ **Inconsistent Angles**
            Fix: Use tripod marks

            ❌ **Different Lighting**
            Fix: Same time/place

            ❌ **Varying Distance**
            Fix: Mark floor spot

            ❌ **Different States**
            Fix: Consistent protocol

            ### Comparison Errors

            ❌ **Daily Comparisons**
            Fix: Weekly minimum

            ❌ **Different Conditions**
            Fix: Match everything

            ❌ **Poor Quality**
            Fix: Check focus first

            ❌ **Lost Photos**
            Fix: Backup system

            ## Advanced Tips

            ### Video Progress

            **Benefits:**
            • Shows all angles
            • Natural movement
            • Easy comparison
            • Single take
            • Time efficient

            **How To:**
            • 360-degree turn
            • Steady rotation
            • Good lighting
            • Clear quality
            • Extract stills

            ### Measurement Integration

            **In-Frame References:**
            • Ruler placement
            • Grid background
            • Known objects
            • Clear markers
            • Consistent items

            ## Using Photos Effectively

            ### Motivation Tool

            **Regular Reviews:**
            • Monthly comparisons
            • Celebrate progress
            • Identify changes
            • Stay motivated
            • Track consistency

            ### Technique Check

            **Training Verification:**
            • Check form
            • Identify issues
            • Verify methods
            • Document problems
            • Share with coach

            Remember: Consistency is key. Perfect photos aren't necessary - consistent photos are. Focus on maintaining identical conditions for accurate comparisons.
            """,
            readingTime: 7,
            tags: ["photos", "progress", "documentation", "privacy", "comparison"],
            relatedArticles: ["measurement-guide", "progress-analysis", "privacy-settings"]
        ),
        
        // Additional AI Coach Articles
        HelpArticle(
            id: "conversation-examples",
            title: "AI Coach Conversation Examples",
            subtitle: "Real examples of effective AI Coach interactions",
            category: .aiCoach,
            content: """
            Learning how to communicate effectively with the AI Coach maximizes the value you get from each conversation. Here are real examples of productive interactions.

            ## Beginner Conversations

            ### First Time User

            **You:** "Hi, I just downloaded Growth and I'm completely new to PE. Where do I start?"

            **AI Coach:** "Welcome to Growth! I'm here to help you start safely and effectively. First, let me ask a few questions:
            1. What's your primary goal? (length, girth, or both?)
            2. Do you have any previous experience with PE?
            3. How much time can you dedicate per session?
            4. Are you aware of any health conditions I should know about?

            Based on your answers, I'll recommend a perfect starting routine."

            **You:** "I want both length and girth, no experience, can do 20-30 minutes, and I'm healthy."

            **AI Coach:** "Perfect! I recommend starting with the 'Beginner's Foundation' routine. Here's your first week plan:
            - 3 sessions (Mon/Wed/Fri)
            - 20 minutes each
            - Focus on Manual Method 1 and Basic Stretching
            - Take initial measurements this weekend
            - Read the safety guide before starting

            Would you like me to walk you through your first session?"

            ### Safety Concern

            **You:** "I felt a slight pinch during stretching today. Should I be worried?"

            **AI Coach:** "Let's assess this carefully. Please tell me:
            1. Where exactly did you feel the pinch?
            2. How long did it last?
            3. On a scale of 1-10, what was the discomfort level?
            4. Is there any visible marking or swelling?
            5. Does it still hurt now?"

            **You:** "Base area, lasted 2 seconds, maybe a 3/10, no marks, no pain now."

            **AI Coach:** "This sounds like a minor issue, likely from stretching at a slightly wrong angle. Here's what to do:
            1. Take tomorrow off as a precaution
            2. Apply ice for 10 minutes if any discomfort returns
            3. Next session, reduce stretching intensity by 30%
            4. Focus on perfect form over intensity
            5. If it happens again, take a full week off

            The fact that it was brief, mild, and left no marks is reassuring. This is your body telling you to adjust technique."

            ## Intermediate Conversations

            ### Plateau Breaking

            **You:** "I've been stuck at 6.5" length for 6 weeks. Current routine: Manual 1&2, Stretching, 4x/week, 25 min sessions. Started at 6.0" four months ago. What should I change?"

            **AI Coach:** "Good detail! A 0.5" gain in 4 months is actually solid progress. Plateaus at this stage are normal. Let's strategize:

            **Analysis:**
            - Your gains = 0.125"/month (above average)
            - 6-week plateau suggests adaptation
            - Need strategic variation

            **Recommendations:**
            1. **Next 2 weeks - Deload:**
               - Reduce to 3x/week
               - 15-minute sessions
               - 70% intensity
               - Perfect form focus

            2. **Following 4 weeks - Shock cycle:**
               - Add AM stretching (5 min)
               - Introduce Manual Method 3
               - One longer session (35 min)
               - New angle emphasis

            3. **Measurement protocol:**
               - Only measure biweekly
               - Same exact conditions
               - Track EQ daily instead

            Would you like the detailed weekly schedule?"

            ### Routine Optimization

            **You:** "Review my routine: Mon/Wed/Fri: 10min Manual, 10min Stretch, 5min cooldown. Tues/Thurs: 15min device work. Seeing steady gains but wondering if I can optimize."

            **AI Coach:** "Your routine structure is solid! The alternating focus is smart. Let me analyze and suggest refinements:

            **Current Strengths:**
            - Good frequency (5x/week)
            - Method variety
            - Built-in recovery
            - Consistent timing

            **Optimization Suggestions:**

            1. **Exercise Order:**
               - Start with stretching when tissues are cool
               - Manual work second
               - This may enhance both

            2. **Tuesday/Thursday Enhancement:**
               - Add 5-min manual finishing
               - Helps cement device work
               - Total time: 20 min

            3. **Progressive Overload:**
               - Week 1-2: Current
               - Week 3-4: Add 2 min to each method
               - Week 5-6: Add intensity, not time
               - Week 7-8: Deload

            4. **Weekend Addition:**
               - Saturday: 10-min AM stretch (optional)
               - Sunday: Complete rest

            Your steady gains suggest this is working. These tweaks might accelerate progress without overtraining risks."

            ## Advanced Conversations

            ### Custom Program Design

            **You:** "I've been doing PE for 18 months. Gained 1.1" length, 0.4" girth. Goal: Focus on girth for next 6 months. Can train 6x/week, 45 min/session. Create an advanced girth program."

            **AI Coach:** "Excellent progress so far! Here's a specialized advanced girth program:

            **6-Week Girth Specialization Cycle**

            **Weekly Structure:**
            - Mon: Heavy Girth (45 min)
            - Tue: Moderate Mixed (35 min)
            - Wed: Light Recovery (25 min)
            - Thu: Heavy Girth (45 min)
            - Fri: Moderate Mixed (35 min)
            - Sat: Technique Work (30 min)
            - Sun: Rest

            **Monday/Thursday (Heavy):**
            1. Warm-up: 5 min
            2. Compression work: 10 min
            3. Expansion method: 15 min
            4. Advanced pumping: 10 min
            5. Manual finishing: 5 min

            **Tuesday/Friday (Mixed):**
            1. Length maintenance: 10 min
            2. Girth method 2: 15 min
            3. Combined work: 10 min

            **Wednesday (Recovery):**
            1. Light stretching: 10 min
            2. Massage: 10 min
            3. EQ work: 5 min

            **Saturday (Technique):**
            - Perfect form practice
            - New variation testing
            - Video review

            **Progression:**
            - Week 1-2: Establish baseline
            - Week 3-4: Increase intensity 10%
            - Week 5-6: Peak volume
            - Week 7: Deload 50%

            Want specific exercise descriptions?"

            ### Data Analysis Request

            **You:** "Here's my last 3 months data: Starting: L=6.8, G=5.1. Month 1: L=6.85, G=5.15. Month 2: L=6.9, G=5.2. Month 3: L=6.92, G=5.22. EQ improved from 7 to 9. Sessions completed: 47/52. Analyze and advise."

            **AI Coach:** "Excellent data tracking! Here's my comprehensive analysis:

            **Progress Breakdown:**
            - Length gain: 0.12" (0.04"/month)
            - Girth gain: 0.12" (0.04"/month)
            - Consistency: 90.4% (excellent)
            - EQ improvement: +2 points (significant)

            **Key Insights:**
            1. Balanced growth (equal L/G gains)
            2. Slowing length progression
            3. Steady girth increases
            4. Excellent tissue health (EQ)
            5. Near-perfect consistency

            **Interpretations:**
            - You're approaching intermediate plateau
            - Body responding well (EQ increase)
            - Current routine still effective
            - May need variation soon

            **Recommendations:**
            1. **Next month:** Continue current approach
            2. **Month 5:** Introduce periodization
            3. **Focus area:** Length techniques
            4. **Monitor:** Weekly EQ scores
            5. **Consider:** Deload week soon

            Your 90% consistency is the real victory here. Most guys achieving your gains have 95%+ consistency, so you're efficient. 

            Questions about implementing changes?"

            ## Special Situation Conversations

            ### Injury Recovery

            **You:** "I overdid it 5 days ago. Had soreness for 2 days, now feels fine. When and how should I return to training?"

            **AI Coach:** "Good job taking time off! Let's create a safe return protocol:

            **Return-to-Training Protocol:**

            **Day 1-2 (Test Phase):**
            - 50% normal duration
            - 30% normal intensity
            - Manual methods only
            - Stop at ANY discomfort

            **Day 3-4 (if no issues):**
            - 70% duration
            - 50% intensity
            - Add gentle stretching
            - Monitor recovery

            **Week 2:**
            - 85% duration
            - 70% intensity
            - Normal variety
            - Extra rest day

            **Week 3:**
            - Return to full program
            - Keep monitoring
            - Don't rush progression

            **Red Flags to Stop:**
            - Any pain return
            - Numbness/tingling
            - Unusual fatigue
            - Poor EQ

            The 5-day rest was smart. This conservative return prevents re-injury while maintaining progress."

            Remember: The more specific your questions and detailed your information, the better guidance the AI Coach can provide. Don't hesitate to ask follow-up questions or request clarification.
            """,
            readingTime: 10,
            tags: ["ai coach", "examples", "conversations", "chat", "guidance"],
            relatedArticles: ["ai-coach-guide", "effective-questions", "chat-privacy"]
        ),
        
        // Additional Settings & Features Articles
        HelpArticle(
            id: "privacy-settings",
            title: "Privacy & Security Settings",
            subtitle: "Protecting your data and maintaining privacy",
            category: .settingsFeatures,
            content: """
            Your privacy is paramount. Growth provides comprehensive privacy controls to ensure your sensitive data remains secure and private. This guide covers all privacy features and best practices.

            ## Privacy Overview

            Growth's privacy features include:
            • Biometric app lock
            • Encrypted data storage
            • Private photo vault
            • Discreet notifications
            • Secure cloud sync
            • Data export/deletion

            ## Biometric Lock Setup

            ### Enabling Face ID/Touch ID

            1. **Navigate to Settings**
               • Open Growth app
               • Tap Settings tab
               • Select "Privacy"

            2. **Enable Biometric Lock**
               • Toggle "Require Biometric Unlock"
               • Authenticate to confirm
               • Choose lock timing

            3. **Lock Timing Options**
               • Immediately
               • After 1 minute
               • After 5 minutes
               • After 15 minutes

            ### How It Works

            **App Locking:**
            • Triggers when app backgrounds
            • Requires authentication to open
            • Passcode fallback available
            • Separate from device lock

            **What's Protected:**
            • All app content
            • Measurements data
            • Progress photos
            • Chat history
            • Personal settings

            ## Photo Privacy

            ### Secure Photo Storage

            **In-App Vault:**
            • Encrypted storage
            • Not visible in Photos app
            • Requires authentication
            • No iCloud photo sync
            • Secure deletion

            **Taking Private Photos:**
            1. Use in-app camera
            2. Photos save to vault
            3. Never touch Photos app
            4. Encrypted immediately
            5. Deletion is permanent

            ### Photo Management

            **Organization:**
            • Private folders
            • Date sorting
            • Tag system
            • Search disabled
            • Bulk operations

            **Sharing Controls:**
            • Export requires auth
            • No accidental sharing
            • Watermark options
            • Temporary links
            • Share history

            ## Notification Privacy

            ### Discreet Notifications

            **Settings Options:**
            • Hide notification content
            • Generic app name
            • No preview text
            • Silent delivery
            • Custom sounds

            **Configuration:**
            1. Settings → Notifications
            2. Toggle "Private Notifications"
            3. Choose display options
            4. Set quiet hours
            5. Test settings

            ### Live Activity Privacy

            **Discreet Mode:**
            • Shows "Timer" only
            • No method details
            • Generic progress bar
            • Hidden controls
            • Privacy first

            ## Data Security

            ### Encryption Standards

            **At Rest:**
            • AES-256 encryption
            • Secure enclave storage
            • Key derivation
            • No plain text
            • Military grade

            **In Transit:**
            • TLS 1.3 protocol
            • Certificate pinning
            • No data interception
            • Secure endpoints
            • Regular audits

            ### Cloud Sync Security

            **What Syncs:**
            • Encrypted data only
            • No photos by default
            • Measurements encrypted
            • Settings preserved
            • Secure backup

            **Sync Controls:**
            • Toggle sync on/off
            • Choose data types
            • Wi-Fi only option
            • Manual sync
            • Delete cloud data

            ## Account Privacy

            ### Anonymous Usage

            **What We Don't Require:**
            • Real name
            • Phone number
            • Address
            • Birth date
            • Any identifiers

            **Account Creation:**
            • Email only
            • Username optional
            • No verification
            • Instant deletion
            • No questions asked

            ### Data Minimization

            **We Never Collect:**
            • Personal details
            • Location data
            • Device contacts
            • Browsing history
            • Other app data

            **Analytics:**
            • Fully anonymous
            • Opt-out available
            • No sensitive data
            • Crash reports only
            • Privacy focused

            ## Privacy Best Practices

            ### Device Security

            **Recommendations:**
            • Use device passcode
            • Enable auto-lock
            • Avoid public Wi-Fi
            • Regular iOS updates
            • Secure backups

            ### App Usage

            **Privacy Tips:**
            • Use biometric lock
            • Clear recent apps
            • Private browsing
            • Secure environment
            • Regular data review

            ### Photo Guidelines

            **Safety First:**
            • Never include face
            • Remove identifiers
            • Check backgrounds
            • Use in-app camera
            • Regular cleanup

            ## Data Control

            ### Export Your Data

            **How to Export:**
            1. Settings → Data & Privacy
            2. Tap "Export My Data"
            3. Choose format (CSV/JSON)
            4. Select date range
            5. Save securely

            **What's Included:**
            • All measurements
            • Session history
            • Settings backup
            • Text data only
            • Photos separate

            ### Delete Your Data

            **Partial Deletion:**
            • Delete photos only
            • Clear measurements
            • Reset progress
            • Remove sessions
            • Keep account

            **Full Deletion:**
            • Complete removal
            • Immediate effect
            • Not recoverable
            • Cancels subscription
            • Privacy guaranteed

            ## Advanced Privacy

            ### App Disguise

            **Stealth Options:**
            • Alternative icon
            • Generic name
            • Hidden from search
            • Requires setup
            • Extra privacy

            ### Network Privacy

            **VPN Compatible:**
            • Full VPN support
            • No restrictions
            • Enhanced privacy
            • Works globally
            • No speed impact

            ### Backup Security

            **iCloud Backup:**
            • Encrypted in backup
            • Keychain protected
            • Selective backup
            • Exclude options
            • Restore security

            ## Privacy FAQ

            **Q: Can anyone at Growth see my data?**
            A: No. All data is encrypted end-to-end. We cannot access your personal information.

            **Q: What happens to photos if I delete the app?**
            A: Photos stored in the app are deleted. Always export important data first.

            **Q: Is chat history private?**
            A: Yes. AI conversations are encrypted and never used for training or sharing.

            **Q: Can I use a fake email?**
            A: Yes, as long as you can access it for password resets.

            Remember: Your privacy is not just a feature—it's fundamental to Growth. We're committed to protecting your sensitive data with the highest security standards.
            """,
            readingTime: 9,
            tags: ["privacy", "security", "settings", "data", "protection"],
            relatedArticles: ["biometric-setup", "data-management", "photo-security"]
        ),
        
        HelpArticle(
            id: "notification-customization",
            title: "Customizing Notifications",
            subtitle: "Set up reminders and alerts that work for your schedule",
            category: .settingsFeatures,
            content: """
            Smart notifications help you stay consistent without being intrusive. This guide shows you how to customize alerts for optimal training reminders while maintaining privacy.

            ## Notification Types

            ### Training Reminders

            **Session Reminders:**
            • Scheduled routine alerts
            • Custom timing
            • Gentle nudges
            • Skip options
            • Smart scheduling

            **Rest Day Alerts:**
            • Recovery reminders
            • Prevent overtraining
            • Customizable
            • Health focused
            • Optional feature

            ### Progress Notifications

            **Measurement Reminders:**
            • Weekly prompts
            • Consistent timing
            • Data accuracy
            • Optional photos
            • Quick entry

            **Milestone Alerts:**
            • Goal achievements
            • Streak celebrations
            • Progress summaries
            • Motivation boosts
            • Share options

            ### System Notifications

            **Timer Alerts:**
            • Stage completion
            • Session ending
            • Rest periods
            • Background support
            • Haptic options

            **App Updates:**
            • New features
            • Important changes
            • Safety updates
            • Optional tips
            • Release notes

            ## Setting Up Notifications

            ### Initial Configuration

            1. **Allow Notifications**
               • iOS permission prompt
               • Enable all types
               • Can change later

            2. **Choose Categories**
               • Training reminders
               • Progress alerts
               • System messages
               • Marketing (optional)

            3. **Set Schedule**
               • Preferred times
               • Quiet hours
               • Weekend differences
               • Time zones

            ### Customization Options

            **Notification Style:**
            • Banners
            • Alerts
            • Lock screen
            • Notification center
            • Sound options

            **Content Display:**
            • Full preview
            • Private mode
            • Title only
            • Hidden content
            • Custom text

            ## Privacy-First Setup

            ### Discreet Notifications

            **Enable Private Mode:**
            1. Settings → Notifications
            2. Toggle "Private Notifications"
            3. Choose display level
            4. Test appearance

            **What Changes:**
            • Generic titles
            • No sensitive data
            • Coded messages
            • Privacy protected
            • Still functional

            ### Examples

            **Normal Mode:**
            "Time for your Manual Method session"

            **Private Mode:**
            "Your scheduled activity is ready"

            **Ultra-Private:**
            "Reminder: 3:00 PM"

            ## Smart Scheduling

            ### Routine Integration

            **Automatic Scheduling:**
            • Based on routine
            • Adapts to changes
            • Respects rest days
            • Holiday awareness
            • Travel adjustments

            **Custom Rules:**
            • If/then conditions
            • Day preferences
            • Time windows
            • Flexibility options
            • Override ability

            ### Quiet Hours

            **Setting Quiet Hours:**
            1. Define sleep schedule
            2. Set work hours
            3. Weekend differences
            4. Vacation mode
            5. Emergency overrides

            **During Quiet Hours:**
            • Notifications delayed
            • Critical only option
            • Silent delivery
            • Morning summary
            • Respects DND

            ## Advanced Features

            ### Smart Reminders

            **Adaptive Timing:**
            • Learns your patterns
            • Suggests best times
            • Avoids conflicts
            • Weather aware
            • Context sensitive

            **Behavioral Nudges:**
            • Gentle progression
            • Motivation timing
            • Habit building
            • Psychology based
            • Personalized

            ### Integration Options

            **Calendar Sync:**
            • Add to calendar
            • Block time
            • Private events
            • Recurring setup
            • iCal support

            **Apple Watch:**
            • Wrist taps
            • Quick responses
            • Private display
            • Timer control
            • Progress rings

            ## Troubleshooting

            ### Not Receiving Notifications

            **Check These:**
            1. iOS Settings → Notifications → Growth
            2. Ensure enabled
            3. Check Do Not Disturb
            4. Battery settings
            5. Background refresh

            **In-App Settings:**
            • Notification toggles
            • Schedule active
            • Time zones correct
            • Categories enabled

            ### Too Many Notifications

            **Reduce Frequency:**
            • Adjust schedules
            • Disable categories
            • Set quiet hours
            • Batch notifications
            • Weekly summary only

            ### Wrong Timing

            **Fix Scheduling:**
            • Check time zone
            • Verify routine
            • Update preferences
            • Clear cache
            • Reset schedule

            ## Best Practices

            ### For Consistency

            **Optimal Setup:**
            • 2-3 reminders max
            • Same time daily
            • Gentle nudges
            • Easy dismissal
            • Positive framing

            ### For Privacy

            **Recommended:**
            • Private mode on
            • Generic text
            • No lock screen
            • Silent delivery
            • Coded language

            ### For Motivation

            **Engagement Tips:**
            • Milestone alerts on
            • Progress summaries
            • Streak tracking
            • Achievement badges
            • Positive reinforcement

            ## Notification Templates

            ### Customizable Messages

            **Training Reminders:**
            • "Ready to grow?"
            • "Training time!"
            • "Your session awaits"
            • "Let's make progress"
            • Custom message

            **Rest Day Messages:**
            • "Recovery day - rest up!"
            • "No training today"
            • "Rest and grow"
            • "Take it easy"
            • Custom message

            **Progress Alerts:**
            • "New milestone reached!"
            • "Check your progress"
            • "Great consistency!"
            • "Keep it up!"
            • Custom message

            Remember: Notifications should support your journey, not annoy you. Start with minimal settings and add more as needed. Privacy always comes first.
            """,
            readingTime: 7,
            tags: ["notifications", "reminders", "alerts", "privacy", "scheduling"],
            relatedArticles: ["privacy-settings", "routine-scheduling", "consistency-tips"]
        ),
        
        // Additional Troubleshooting Articles
        HelpArticle(
            id: "data-recovery",
            title: "Data Backup and Recovery",
            subtitle: "How to protect and restore your progress data",
            category: .troubleshooting,
            content: """
            Your progress data represents months or years of dedicated effort. This guide ensures you never lose your valuable tracking information and can recover from any data loss scenario.

            ## Automatic Backups

            ### iCloud Sync

            **What's Backed Up:**
            • All measurements
            • Session history
            • Routine configurations
            • App settings
            • AI chat history

            **What's NOT Synced:**
            • Progress photos (privacy)
            • Cached data
            • Temporary files
            • Local-only settings

            **Enabling iCloud Sync:**
            1. Settings → Data & Privacy
            2. Toggle "iCloud Sync"
            3. Verify Apple ID
            4. Check storage space
            5. Initial sync begins

            ### Backup Frequency

            **Automatic Schedule:**
            • Real-time sync when online
            • Changes uploaded immediately
            • Conflict resolution built-in
            • Version history kept
            • 30-day retention

            ## Manual Backup Options

            ### Export Your Data

            **Full Export Process:**
            1. Settings → Data & Privacy
            2. Tap "Export All Data"
            3. Choose format:
               - CSV (spreadsheets)
               - JSON (technical)
               - PDF (reports)
            4. Select date range
            5. Save to Files/Drive

            **Export Contents:**
            • Measurements table
            • Session logs
            • Progress calculations
            • Method history
            • Settings backup

            ### Photo Backup

            **Separate Process:**
            1. Progress → Photos
            2. Select photos
            3. Tap share icon
            4. Save to Photos/Files
            5. Organize externally

            **Privacy Note:**
            Photos require manual backup for security

            ## Recovery Procedures

            ### From iCloud

            **Restore Process:**
            1. Fresh install Growth
            2. Sign in with Apple ID
            3. Enable iCloud Sync
            4. Wait for download
            5. Verify data integrity

            **Troubleshooting Sync:**
            • Check internet connection
            • Verify Apple ID
            • Sufficient iCloud storage
            • Latest iOS version
            • Contact support if fails

            ### From Manual Backup

            **Import Process:**
            1. Settings → Data & Privacy
            2. Tap "Import Data"
            3. Select backup file
            4. Choose merge/replace
            5. Confirm import

            **Supported Formats:**
            • Growth backup (.gbk)
            • CSV measurements
            • JSON exports
            • Legacy formats

            ## Preventing Data Loss

            ### Best Practices

            **Regular Routine:**
            • Weekly manual export
            • Monthly photo backup
            • Verify iCloud active
            • Test restore process
            • Multiple locations

            **Storage Strategy:**
            • iCloud (automatic)
            • Local device export
            • Computer backup
            • Cloud drive copy
            • External storage

            ### Warning Signs

            **Data Risk Indicators:**
            • Sync errors appearing
            • Storage warnings
            • App crashes frequent
            • Slow performance
            • Missing entries

            **Immediate Actions:**
            1. Export everything NOW
            2. Screenshot important data
            3. Note recent entries
            4. Contact support
            5. Don't delete app

            ## Recovery Scenarios

            ### Lost Phone

            **Steps to Recover:**
            1. Get new device
            2. Install Growth
            3. Sign in same Apple ID
            4. Enable iCloud Sync
            5. Data downloads automatically

            **If No iCloud:**
            • Check email exports
            • Computer backups
            • Cloud storage
            • Contact support
            • Manual re-entry

            ### App Deletion

            **Accidental Deletion:**
            • Reinstall immediately
            • Sign in same account
            • iCloud restores data
            • Photos need manual restore
            • Settings preserved

            **Before Deleting:**
            • Export everything
            • Save photos
            • Note configurations
            • Document routines
            • Backup complete

            ### Corrupted Data

            **Signs of Corruption:**
            • Impossible values
            • Missing dates
            • Duplicate entries
            • Graph errors
            • Crash on access

            **Recovery Steps:**
            1. Don't panic
            2. Export what you can
            3. Contact support
            4. Provide error details
            5. Use last backup

            ## Advanced Backup

            ### Automation

            **Scheduled Exports:**
            • Weekly reminders
            • Auto-export option
            • Email delivery
            • Cloud upload
            • Version control

            **Shortcuts Integration:**
            • iOS Shortcuts app
            • Automated workflow
            • Regular schedule
            • Multiple destinations
            • Notification confirm

            ### Data Verification

            **Integrity Checks:**
            • Export regularly
            • Open in spreadsheet
            • Verify completeness
            • Check calculations
            • Compare versions

            **What to Verify:**
            • Date continuity
            • Value ranges
            • Entry count
            • Latest entries
            • Photo references

            ## Emergency Recovery

            ### Support Assistance

            **When to Contact:**
            • Complete data loss
            • Restore failures
            • Corruption issues
            • Account problems
            • Technical errors

            **Information Needed:**
            • Account email
            • Last backup date
            • iOS version
            • Error messages
            • Steps attempted

            ### Data Reconstruction

            **If All Else Fails:**
            • Note remembered data
            • Check photo metadata
            • Review messages
            • Estimate from memory
            • Start fresh baseline

            **Moving Forward:**
            • Implement backup routine
            • Multiple redundancy
            • Regular verification
            • Learn from loss
            • Stay positive

            ## Backup Checklist

            ### Weekly Tasks
            ☐ Manual export
            ☐ Verify iCloud sync
            ☐ Check storage space
            ☐ Test one import

            ### Monthly Tasks
            ☐ Full photo backup
            ☐ Clean old exports
            ☐ Verify all data
            ☐ Update backup location

            ### Quarterly Tasks
            ☐ Full restore test
            ☐ Archive old data
            ☐ Review backup strategy
            ☐ Update procedures

            Remember: Your data is irreplaceable. Invest time in proper backup procedures—you'll thank yourself later. The best backup is the one you never need, but have anyway.
            """,
            readingTime: 8,
            tags: ["backup", "recovery", "data", "icloud", "export"],
            relatedArticles: ["data-management", "troubleshooting", "export-guide"]
        )
    ]
}