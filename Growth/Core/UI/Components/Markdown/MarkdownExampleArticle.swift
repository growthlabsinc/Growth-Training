//
//  MarkdownExampleArticle.swift
//  Growth
//
//  Example article showcasing all enhanced markdown features
//

import Foundation

struct MarkdownExampleArticle {
    static let content = """
    ![hero](growth_hero, Master Your Growth Journey, A comprehensive guide to all features)
    
    # Master Your Growth Journey: Complete Feature Guide
    
    ![dropcap]
    Welcome to the ultimate guide for mastering your personal growth journey with our app. This comprehensive article will walk you through every feature, technique, and best practice to help you achieve your goals safely and effectively.
    
    ![banner](rocket.fill, Quick Start Guide, Get up and running in minutes, blue)
    
    ## Table of Contents
    
    This guide covers everything you need to know:
    
    ---
    
    ## Getting Started
    
    ![step](1, 4, Account Setup)
    
    Before diving into your training, let's ensure your account is properly configured for optimal results.
    
    ![expandable](Essential First Steps)
    1. **Complete Your Profile** - Add your personal details and goals
    2. **Take Initial Measurements** - Establish your baseline metrics
    3. **Set Privacy Preferences** - Control your data sharing settings
    4. **Enable Notifications** - Stay on track with reminders
    
    ### Profile Completion Checklist
    
    - [ ] Add profile photo
    - [ ] Enter birthdate and location
    - [ ] Set your experience level
    - [ ] Define your primary goals
    - [ ] Configure privacy settings
    - [x] Accept terms and conditions
    
    ![progress](Profile Setup, 83, Almost there! Just one more step)
    
    ## Understanding Growth Methods
    
    ![quote](Success is not final, failure is not fatal: it is the courage to continue that counts., Winston Churchill)
    
    Our app features various growth methods, each designed for specific outcomes:
    
    ![feature](figure.flexibility, Flexibility Training, Improve your range of motion and prevent injuries)
    
    ![feature](heart.fill, Cardiovascular Health, Boost endurance and overall fitness)
    
    ![feature](brain.head.profile, Mental Wellness, Develop mindfulness and stress management)
    
    ### Method Categories
    
    ![highlight](Premium Methods, Access to advanced techniques requires a premium subscription, yellow)
    
    **Basic Methods** (Free)
    - Foundation exercises
    - Beginner routines
    - Safety guidelines
    
    **Premium Methods** 👑
    - Advanced techniques
    - Personalized programs
    - AI coaching support
    
    ## Safety First
    
    ⚠️ **Warning**: Always consult with a healthcare professional before beginning any new training program.
    
    ### Essential Safety Guidelines
    
    1. **Start Slowly** - Begin at 50% intensity
    2. **Listen to Your Body** - Pain is not gain
    3. **Stay Hydrated** - Drink water before, during, and after
    4. **Rest Days Matter** - Recovery is when growth happens
    
    💡 **Tip**: Use our built-in timer with automatic rest periods to maintain safe training intervals.
    
    ## Video Tutorials
    
    ![video](https://example.com/intro-video.mp4, Introduction to Growth Training, 1.778)
    
    ### Featured Tutorial Series
    
    ![video-thumbnail](https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg, https://youtube.com/watch?v=dQw4w9WgXcQ, Beginner's Complete Guide, 15:42)
    
    ## Advanced Features
    
    ![step](2, 4, Routine Creation)
    
    ### Creating Custom Routines
    
    Our routine builder offers unprecedented flexibility:
    
    ```swift
    // Example routine structure
    let customRoutine = Routine(
        name: "Morning Power Session",
        duration: 20, // minutes
        difficulty: .intermediate,
        methods: [
            Method(name: "Warm Up", duration: 5),
            Method(name: "Core Work", duration: 10),
            Method(name: "Cool Down", duration: 5)
        ]
    )
    ```
    
    ### AI Coach Integration
    
    ![expandable](How AI Coach Works)
    Our AI Coach uses advanced machine learning to:
    - Analyze your progress patterns
    - Suggest routine adjustments
    - Provide form corrections
    - Offer motivational support
    - Track injury prevention metrics
    
    ## Progress Tracking
    
    ![step](3, 4, Analytics Dashboard)
    
    Track your journey with comprehensive analytics:
    
    | Metric | Description | Update Frequency |
    |--------|-------------|------------------|
    | Daily Streak | Consecutive training days | Real-time |
    | Total Sessions | All completed workouts | After each session |
    | Progress Score | Overall improvement rating | Weekly |
    | Recovery Time | Average rest between sessions | Daily |
    
    ### Understanding Your Data
    
    ![highlight](Pro Tip, Export your data anytime for personal analysis or sharing with trainers, green)
    
    ## Community Features
    
    ![banner](person.3.fill, Join Our Community, Connect with thousands of members, purple)
    
    ### Community Guidelines
    
    ✅ **Success**: Our community thrives on mutual support and respect.
    
    **Do's:**
    - Share your progress and victories
    - Offer encouragement to others
    - Ask questions freely
    - Report concerning content
    
    **Don'ts:**
    - Share medical advice
    - Promote unsafe practices
    - Spam or advertise
    - Violate privacy
    
    ## Premium Benefits
    
    ![step](4, 4, Upgrade Your Experience)
    
    ### What's Included
    
    ![expandable](Premium Feature Comparison)
    | Feature | Free | Premium |
    |---------|------|---------|
    | Basic Methods | ✓ | ✓ |
    | Custom Routines | 3 max | Unlimited |
    | AI Coach | - | ✓ |
    | Video Library | Limited | Full Access |
    | Priority Support | - | ✓ |
    | Advanced Analytics | - | ✓ |
    
    ![progress](Premium Features Unlocked, 100, You have access to all features!)
    
    ## Troubleshooting
    
    ### Common Issues
    
    ℹ️ **Info**: Most issues can be resolved by updating to the latest app version.
    
    ![expandable](Timer Not Working?)
    1. Check notification permissions
    2. Ensure background app refresh is enabled
    3. Restart the app
    4. Contact support if issue persists
    
    ![expandable](Sync Problems?)
    - Verify internet connection
    - Log out and back in
    - Check iCloud settings
    - Clear app cache in settings
    
    ## Best Practices
    
    ![quote](The secret of getting ahead is getting started., Mark Twain)
    
    ### Daily Routine Tips
    
    **Morning Sessions** ☀️
    - Best for energy and focus
    - Easier to maintain consistency
    - Sets positive tone for the day
    
    **Evening Sessions** 🌙
    - Great for stress relief
    - Helps with sleep quality
    - Allows for longer recovery
    
    ### Nutrition Guidelines
    
    ![highlight](Fuel Your Growth, Proper nutrition enhances your results by up to 40%, green)
    
    - **Pre-workout**: Light carbs 30-60 minutes before
    - **Post-workout**: Protein within 30 minutes
    - **Hydration**: 8-10 glasses of water daily
    - **Rest days**: Maintain regular eating schedule
    
    ***
    
    ## Final Thoughts
    
    Your growth journey is unique. This guide provides the foundation, but your dedication and consistency will determine your success. Remember:
    
    - Progress over perfection
    - Consistency over intensity
    - Safety over speed
    - Community over competition
    
    ![banner](star.fill, You're Ready!, Start your journey today, green)
    
    ### Next Steps
    
    - [ ] Review this guide thoroughly
    - [ ] Set up your first routine
    - [ ] Join our community forum
    - [ ] Schedule your first session
    - [ ] Share with a friend
    
    ---
    
    *Last updated: \(Date().formatted(date: .abbreviated, time: .omitted))*
    
    **Need more help?** Contact our support team or browse additional articles in our help center.
    """
    
    static let shortExample = """
    # Quick Feature Demo
    
    ![banner](sparkles, Enhanced Markdown, Beautiful help articles, blue)
    
    ## Visual Elements
    
    ![dropcap]
    This article demonstrates our enhanced markdown rendering with beautiful typography and interactive elements.
    
    ### Code Examples
    
    ```swift
    // Interactive code blocks with syntax highlighting
    func greet(name: String) -> String {
        return "Hello, \\(name)!"
    }
    ```
    
    ### Progress Tracking
    
    ![progress](Learning Progress, 75, You're doing great!)
    
    ### Interactive Checklist
    
    Complete these steps:
    - [x] Read the introduction
    - [ ] Try the code example
    - [ ] Watch the video tutorial
    - [ ] Complete the exercise
    
    ### Video Content
    
    ![video-thumbnail](https://picsum.photos/640/360, https://example.com/video, Learn the Basics, 5:23)
    
    💡 **Tip**: All these features are designed to make learning easier and more engaging!
    """
}