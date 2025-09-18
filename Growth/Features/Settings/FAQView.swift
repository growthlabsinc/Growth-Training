//
//  FAQView.swift
//  Growth
//
//  Created by Developer on 6/4/25.
//

import SwiftUI

struct FAQView: View {
    @State private var searchText = ""
    @State private var expandedQuestions: Set<String> = []
    
    let faqCategories: [FAQCategory] = [
        FAQCategory(
            title: "Getting Started",
            icon: "play.circle.fill",
            color: Color("GrowthGreen"),
            questions: [
                FAQItem(
                    question: "What is Growth and how does it work?",
                    answer: "Growth is a comprehensive training app designed to help you achieve your personal development goals through scientifically-backed methods and routines. The app provides:\n\n• Structured training programs tailored to your experience level\n• 15+ proven methods with detailed instructions\n• AI-powered coaching for personalized guidance\n• Progress tracking with measurements and analytics\n• Live Activity timer for hands-free sessions\n• Educational resources and safety guidelines\n\nOur approach combines traditional techniques with modern technology to ensure safe, effective progress."
                ),
                FAQItem(
                    question: "How do I start my first training session?",
                    answer: "Getting started is easy:\n\n1. Go to the Dashboard and tap 'Start Session'\n2. Select a method from your active routine (or choose 'Quick Practice')\n3. Review the instructions and warm-up guidance\n4. Start the timer when ready\n5. Follow the on-screen prompts and audio cues\n\nFor beginners, we recommend starting with the Basic Stretching or Manual Method 1 for 5-10 minutes. The app will guide you through each step with detailed instructions."
                ),
                FAQItem(
                    question: "What equipment do I need?",
                    answer: "Most methods require minimal equipment:\n\n**Essential items:**\n• Lubricant (water-based recommended)\n• Clean towel\n• Measuring tape (for tracking)\n• Timer (built into the app)\n\n**Optional equipment:**\n• Heating pad for warm-up\n• Specific devices for advanced methods\n• Camera for progress photos (optional)\n\nThe app clearly indicates any equipment needed for each method. Many effective routines require no equipment at all."
                ),
                FAQItem(
                    question: "Is this app suitable for complete beginners?",
                    answer: "Absolutely! Growth is designed for all experience levels:\n\n• **Beginner-friendly content**: Start with foundational methods and gradually progress\n• **Detailed instructions**: Every method includes step-by-step guidance with visual aids\n• **Safety first approach**: Built-in warm-ups, rest periods, and injury prevention tips\n• **AI Coach support**: Get personalized advice and answers to your questions\n• **Progressive routines**: Start with 2-3 sessions per week, 10-15 minutes each\n\nThe app adapts to your pace and never rushes your progression. We prioritize safety and sustainable growth over quick results."
                )
            ]
        ),
        FAQCategory(
            title: "Methods & Routines",
            icon: "list.bullet.rectangle",
            color: .blue,
            questions: [
                FAQItem(
                    question: "What are the different method categories?",
                    answer: "Growth offers 15+ methods across 5 main categories:\n\n**1. Manual Methods (5 variations)**\n• Focus on control and technique\n• No equipment needed\n• Great for beginners\n\n**2. Device Methods (3 types)**\n• Consistent pressure application\n• Requires specific equipment\n• For intermediate/advanced users\n\n**3. Stretching Methods (4 variations)**\n• Improve flexibility and length\n• Gradual, gentle progression\n• Suitable for all levels\n\n**4. AM Methods (2 types)**\n• Focus on vascular health through flow-mediated dilation¹\n• Morning-specific routines\n• Enhance overall function\n\n**5. Specialized Techniques**\n• Advanced combination methods\n• Targeted improvements\n• Requires experience\n\nEach category serves a specific purpose in a balanced routine.\n\n¹Based on research on flow-mediated dilation and vascular health (Green et al., 2011; Thijssen et al., 2011)"
                ),
                FAQItem(
                    question: "How do progression stages work?",
                    answer: "Each method has 3-5 progression stages that gradually increase in intensity:\n\n**Stage Structure:**\n• **Stage 1**: Foundation - Learn proper form and technique\n• **Stage 2**: Development - Increase duration and intensity\n• **Stage 3**: Advancement - Add variations and challenges\n• **Stage 4-5**: Mastery - Maximum effectiveness\n\n**Progression Timeline:**\n• Spend 4-6 weeks minimum per stage\n• Complete 80% of sessions before advancing\n• Pass the stage assessment (form check)\n• Feel comfortable with current intensity\n\n**Important**: Never skip stages! Each builds essential skills and conditioning for the next level. The app tracks your readiness and suggests when to progress."
                ),
                FAQItem(
                    question: "What's the difference between routines?",
                    answer: "Growth offers specialized routines for different goals:\n\n**Beginner's Foundation**\n• 3 sessions/week, 15-20 minutes\n• Focus on basic techniques and safety\n• Gentle progression over 12 weeks\n\n**Length-Focused Program**\n• 4-5 sessions/week, 20-30 minutes\n• Emphasizes stretching methods\n• Includes traction techniques\n\n**Girth Enhancement**\n• 4 sessions/week, 25-35 minutes\n• Focus on expansion methods\n• Incorporates pump techniques\n\n**All-Around Development**\n• 5 sessions/week, 30-40 minutes\n• Balanced approach to all dimensions\n• Most comprehensive results\n\n**Maintenance Mode**\n• 2-3 sessions/week, 15-20 minutes\n• Preserve gains with minimal time\n• Perfect for busy periods\n\nChoose based on your goals, experience, and available time."
                ),
                FAQItem(
                    question: "Can I create custom routines?",
                    answer: "Yes! Growth supports full routine customization:\n\n**Creating Custom Routines:**\n1. Go to Methods tab → 'Create Routine'\n2. Name your routine and set goals\n3. Add methods from the library\n4. Set duration and rest periods\n5. Configure progression rules\n\n**Customization Options:**\n• Mix methods from different categories\n• Adjust timing for each exercise\n• Set custom rest days\n• Add personal notes and reminders\n• Schedule specific days/times\n\n**Best Practices:**\n• Include warm-up and cool-down\n• Balance different method types\n• Allow adequate rest (2-3 days/week)\n• Start conservative and build up\n\nThe AI Coach can help design a routine tailored to your specific goals."
                )
            ]
        ),
        FAQCategory(
            title: "Safety & Health",
            icon: "heart.fill",
            color: .red,
            questions: [
                FAQItem(
                    question: "What are the essential safety guidelines?",
                    answer: "Safety is our top priority. Follow these critical guidelines:\n\n**Before Training:**\n• Always warm up for 5-10 minutes\n• Check for any injuries or soreness\n• Ensure privacy and comfortable environment\n• Have lubricant and towel ready\n• Review method instructions\n\n**During Training:**\n• Never work through pain - discomfort is NOT normal\n• Maintain steady breathing\n• Stop immediately if you feel numbness or tingling\n• Take breaks as needed\n• Stay within recommended time limits\n\n**Warning Signs (Stop Immediately):**\n• Sharp or persistent pain\n• Numbness or loss of sensation\n• Unusual discoloration\n• Excessive swelling\n• Dizziness or lightheadedness\n\n**After Training:**\n• Cool down gradually\n• Check for any unusual symptoms\n• Apply ice if there's any swelling\n• Rest at least 24 hours between sessions"
                ),
                FAQItem(
                    question: "How do I prevent injuries?",
                    answer: "Injury prevention is built into every aspect of Growth:\n\n**App Safety Features:**\n• Mandatory warm-up timers\n• Progressive overload tracking\n• Rest day enforcement\n• Automatic session limits\n• Form check reminders\n\n**Best Prevention Practices:**\n1. **Start Slowly**: Begin with 50% recommended time\n2. **Focus on Form**: Technique over intensity always\n3. **Use Adequate Lubrication**: Reduces friction injuries\n4. **Take Rest Days**: Recovery is when growth happens\n5. **Stay Hydrated**: Improves tissue health\n6. **Monitor Indicators**: Track EQ and sensitivity\n\n**Common Mistakes to Avoid:**\n• Training every day without rest\n• Ignoring pain or discomfort\n• Progressing too quickly\n• Using excessive force or pressure\n• Training when fatigued or stressed\n\nRemember: Slow, consistent progress is safer and more effective than rushing."
                ),
                FAQItem(
                    question: "Are there any medical conditions that prevent training?",
                    answer: "Certain conditions require medical clearance before training:\n\n**Consult a doctor if you have:**\n• Heart disease or blood pressure issues\n• Diabetes or circulation problems\n• Blood clotting disorders\n• Peyronie's disease or penile curvature\n• History of priapism\n• Recent surgery or injury\n• Erectile dysfunction (underlying cause matters)\n• Any penile abnormalities\n\n**Temporary Conditions (Wait to train):**\n• Active infections or STIs\n• Open wounds or skin conditions\n• Recent circumcision (wait 6-8 weeks)\n• Current inflammation or injury\n• Taking blood thinners\n\n**Safe to Train With:**\n• Mild ED (may actually help)\n• Normal anatomical variations\n• Previous successful PE experience\n• General good health\n\n**Important**: This app is not medical advice. When in doubt, consult a healthcare provider. Your safety is more important than any potential gains."
                ),
                FAQItem(
                    question: "What should I do if I experience an injury?",
                    answer: "If you suspect an injury, follow this protocol immediately:\n\n**Immediate Actions:**\n1. **STOP** all training immediately\n2. **Apply ice** wrapped in cloth for 10-15 minutes\n3. **Rest** completely - no training whatsoever\n4. **Monitor** symptoms over next 24-48 hours\n\n**Seek Medical Help If:**\n• Severe pain that doesn't improve\n• Persistent numbness (>30 minutes)\n• Significant swelling or bruising\n• Difficulty with urination\n• Any discharge or bleeding\n• Symptoms worsen after 24 hours\n\n**Recovery Protocol:**\n• Take at least 1-2 weeks off completely\n• Only resume when 100% symptom-free\n• Start at 25% previous intensity\n• Build back slowly over 4 weeks\n• Consider adjusting technique\n\n**Prevention Going Forward:**\n• Review what caused the injury\n• Adjust routine to prevent recurrence\n• Focus more on warm-up and technique\n• Consider lower intensity, longer duration approach"
                )
            ]
        ),
        FAQCategory(
            title: "Progress & Tracking",
            icon: "chart.line.uptrend.xyaxis",
            color: .orange,
            questions: [
                FAQItem(
                    question: "How do I measure accurately?",
                    answer: "Accurate measurement is crucial for tracking real progress:\n\n**Length Measurement:**\n1. Achieve 100% erection level\n2. Stand upright, penis parallel to floor\n3. Place ruler firmly against pubic bone\n4. Measure to tip along the top\n5. Record to nearest 1/8 inch or 0.1cm\n\n**Girth Measurement:**\n1. Use flexible measuring tape\n2. Measure at three points: base, mid, glans\n3. Don't pull tape too tight\n4. Record average of three measurements\n\n**Best Practices:**\n• Measure same time of day (morning recommended)\n• Same arousal level each time\n• Same room temperature\n• Take 3 measurements, use average\n• Measure maximum once per week\n• Photo documentation helps verify\n\n**Common Errors:**\n• Measuring too frequently (daily)\n• Inconsistent erection level\n• Changing measurement angle\n• Not pressing ruler to bone\n• Measuring immediately after training"
                ),
                FAQItem(
                    question: "When will I see results?",
                    answer: "Progress timelines vary significantly between individuals:\n\n**Typical Timeline:**\n\n**Weeks 1-4: Foundation Phase**\n• Improved vascular function and blood flow¹\n• Better stamina and control\n• Enhanced sensitivity\n• Temporary post-session gains\n• No permanent size changes yet\n\n**Months 2-3: Early Gains**\n• First measurable improvements\n• Enhanced vascular appearance²\n• Tissue adaptation begins³\n• Increased confidence\n• Routine becomes habit\n\n**Months 4-6: Steady Progress**\n• Consistent improvements\n• Noticeable visual changes\n• Angiogenesis (new blood vessel formation)⁴\n• Both length and girth improvements\n\n**Months 6-12: Continued Growth**\n• Continued tissue remodeling⁵\n• Results become permanent\n• Optimization of routine needed\n• Plateau periods normal\n\n**Factors Affecting Speed:**\n• Consistency (most important!)⁶\n• Age and health status\n• Starting conditions and goals\n• Routine intensity and variety\n• Individual biological response\n\n¹Green et al., 2011; ²Thijssen et al., 2011; ³Schoenfeld, 2010; ⁴Prior et al., 2004; ⁵Hornberger & Esser, 2004; ⁶Kraemer & Ratamess, 2004"
                ),
                FAQItem(
                    question: "How do I track with the app?",
                    answer: "Growth provides comprehensive tracking tools:\n\n**Progress Tab Features:**\n\n**1. Measurements Section**\n• Quick entry for length/girth\n• Historical charts and trends\n• Goal tracking and projections\n• Comparison photos (private)\n• Export data options\n\n**2. Session Logging**\n• Automatic timer integration\n• Method completion tracking\n• Intensity and quality notes\n• Rest day monitoring\n• Streak tracking\n\n**3. Analytics Dashboard**\n• Weekly/monthly summaries\n• Progress rate calculations\n• Best performing methods\n• Consistency scores\n• Achievement badges\n\n**4. Health Indicators**\n• EQ scores (1-10 scale)\n• Sensitivity tracking\n• Recovery monitoring\n• Injury prevention alerts\n\n**Tips for Best Results:**\n• Log immediately after sessions\n• Take photos in same position/lighting\n• Add notes about what worked well\n• Review trends monthly, not daily\n• Celebrate small victories!"
                ),
                FAQItem(
                    question: "What if I hit a plateau?",
                    answer: "Plateaus are normal and temporary. Here's how to break through:\n\n**Understanding Plateaus:**\n• Typically occur every 2-3 months\n• Last 2-4 weeks on average\n• Body adapting to current routine\n• NOT a sign to train harder\n• Often precede growth spurts\n\n**Breaking Through:**\n\n**1. Deload Week**\n• Reduce intensity by 50%\n• Focus on perfect technique\n• Extra rest days\n• Let tissues recover fully\n\n**2. Routine Variation**\n• Switch method order\n• Try new techniques\n• Adjust timing (shorter/longer)\n• Change session frequency\n\n**3. Shock Techniques**\n• One week complete rest\n• High-intensity week (carefully!)\n• Focus on single dimension\n• Add supplementary methods\n\n**4. Lifestyle Optimization**\n• Improve sleep quality\n• Increase water intake\n• Add cardio exercise\n• Reduce stress levels\n• Check nutrition\n\n**Remember**: Plateaus are proof your body is adapting. Stay consistent, be patient, and growth will resume."
                )
            ]
        ),
        FAQCategory(
            title: "App Features & Settings",
            icon: "gearshape.fill",
            color: .gray,
            questions: [
                FAQItem(
                    question: "How does the AI Coach work?",
                    answer: "The AI Coach is your personal training assistant powered by advanced AI:\n\n**Features:**\n• Answer questions about methods and techniques\n• Provide personalized routine recommendations\n• Troubleshoot issues and plateaus\n• Offer form corrections and tips\n• Motivation and accountability support\n\n**How to Use:**\n1. Tap the Coach tab in navigation\n2. Type or speak your question\n3. Get instant, personalized responses\n4. Follow up for clarification\n5. Save helpful responses for later\n\n**Best Questions to Ask:**\n• \"How can I improve my routine?\"\n• \"Why am I not seeing gains?\"\n• \"Is this sensation normal?\"\n• \"What method should I try next?\"\n• \"Help me break through a plateau\"\n\n**Privacy Note:** All conversations are private and encrypted. The AI never shares or stores personal information."
                ),
                FAQItem(
                    question: "What is Live Activity and Dynamic Island support?",
                    answer: "Live Activity brings your timer to your lock screen and Dynamic Island:\n\n**Features:**\n• See timer without opening app\n• Pause/resume from lock screen\n• Progress bar visualization\n• Method name and stage display\n• Discreet mode option available\n\n**How to Enable:**\n1. Go to Settings → Notifications\n2. Enable 'Live Activities'\n3. Start any timed session\n4. Timer appears automatically\n5. Tap to expand controls\n\n**Dynamic Island (iPhone 14 Pro+):**\n• Compact timer display\n• Tap to see full timer\n• Long press for quick controls\n• Seamless app switching\n\n**Battery Note:** Live Activities use minimal battery. The timer continues even if the app is closed, ensuring accurate session tracking."
                ),
                FAQItem(
                    question: "How do I use biometric lock?",
                    answer: "Protect your privacy with Face ID/Touch ID:\n\n**Setup:**\n1. Go to Settings → Privacy\n2. Toggle 'Require Biometric Unlock'\n3. Authenticate to confirm\n4. Choose lock timing (immediate/after 1 min/5 min)\n\n**How it Works:**\n• App locks when backgrounded\n• Requires Face ID/Touch ID to open\n• No one can access without authentication\n• Passcode fallback available\n• Separate from device lock\n\n**Additional Privacy:**\n• Blur app preview in app switcher\n• Hide notification details\n• Discreet app icon option\n• Private photo storage\n• Encrypted data sync\n\n**Note:** Even with biometric lock disabled, all data remains encrypted. This feature adds an extra layer of access control."
                ),
                FAQItem(
                    question: "Can I export or backup my data?",
                    answer: "Yes! Growth provides multiple data management options:\n\n**Export Options:**\n\n**1. Full Data Export**\n• Settings → Data & Privacy → Export Data\n• Creates downloadable .zip file\n• Includes all measurements, sessions, photos\n• CSV format for measurements\n• JSON format for session data\n\n**2. Progress Reports**\n• Progress tab → Share button\n• Generate PDF summaries\n• Include charts and analytics\n• Customizable date ranges\n• Share via email or save\n\n**3. Automatic Backup**\n• iCloud sync (if enabled)\n• Real-time cloud backup\n• Restore on any device\n• End-to-end encrypted\n\n**Manual Backup:**\n1. Export full data monthly\n2. Save to secure location\n3. Test restore periodically\n4. Keep multiple versions\n\n**Data Portability:**\nAll exports use standard formats (CSV/JSON/PDF) that can be imported into other apps or analyzed in spreadsheet software."
                )
            ]
        ),
        FAQCategory(
            title: "Subscription & Account",
            icon: "person.circle.fill",
            color: .purple,
            questions: [
                FAQItem(
                    question: "What features are free vs premium?",
                    answer: "Growth offers a generous free tier with optional premium upgrades:\n\n**Free Features:**\n• 5 basic methods with full instructions\n• Session timer with basic tracking\n• Weekly measurement logging\n• 1 preset routine (Beginner)\n• Educational articles\n• Basic progress charts\n• Community support access\n\n**Premium Features:**\n• All 15+ methods unlocked\n• Unlimited custom routines\n• AI Coach conversations\n• Advanced analytics\n• Live Activity support\n• Progress photos storage\n• Priority support\n• Exclusive new methods\n• No ads ever\n\n**Premium Pricing:**\n• Monthly: $9.99\n• Yearly: $79.99 (save 33%)\n• Lifetime: $199.99 (one-time)\n\n**Free Trial:**\nNew users get free premium trial periods. No credit card required for trial."
                ),
                FAQItem(
                    question: "How do I manage my subscription?",
                    answer: "Subscription management is handled through your device:\n\n**iOS Subscription Management:**\n1. Open Settings app (device settings)\n2. Tap your Apple ID at top\n3. Select 'Subscriptions'\n4. Find 'Growth Premium'\n5. Make changes as needed\n\n**In-App Management:**\n• Settings → Subscription\n• View current plan status\n• Upgrade or downgrade\n• Restore purchases\n• See renewal date\n\n**Important Notes:**\n• Cancel anytime, keep access until period ends\n• Subscriptions auto-renew unless cancelled\n• Cancel 24hrs before renewal to avoid charge\n• Switching plans takes effect next billing cycle\n• Family Sharing supported\n\n**Refund Policy:**\nRefunds are handled by Apple. Generally available within 14 days if unused. Contact Apple Support directly for refund requests."
                ),
                FAQItem(
                    question: "Is my data private and secure?",
                    answer: "Privacy and security are fundamental to Growth:\n\n**Data Protection:**\n• End-to-end encryption for all personal data\n• No employee can view your information\n• Secure cloud storage (Firebase)\n• Local biometric authentication\n• No third-party data sharing\n• GDPR and CCPA compliant\n\n**What We Don't Do:**\n• Never sell or share personal data\n• No tracking for advertising\n• No required personal information\n• No social features that expose data\n• No analytics on sensitive metrics\n\n**Your Control:**\n• Delete account anytime (removes all data)\n• Export everything before deletion\n• Choose what to sync to cloud\n• Control notification privacy\n• Manage photo storage\n\n**Technical Security:**\n• TLS 1.3 encryption in transit\n• AES-256 encryption at rest\n• Regular security audits\n• Secure authentication (Firebase Auth)\n• No password storage (uses tokens)\n\n**Medical Privacy:**\nWhile not a medical app, we follow healthcare privacy best practices. Your data is yours alone."
                ),
                FAQItem(
                    question: "How do I delete my account?",
                    answer: "You have full control over your account and data:\n\n**Account Deletion Process:**\n1. Go to Settings → Data & Privacy\n2. Scroll to 'Delete Account' (red button)\n3. Confirm you want to proceed\n4. Optionally export data first\n5. Enter confirmation code\n6. Account deleted immediately\n\n**What Gets Deleted:**\n• All personal information\n• Measurement history\n• Session logs\n• Progress photos\n• AI Coach conversations\n• Custom routines\n• App preferences\n\n**What Happens:**\n• Deletion is immediate and permanent\n• Cannot be undone or recovered\n• Subscription auto-cancelled\n• No refunds for unused time\n• Can create new account with same email\n\n**Before Deleting:**\n1. Export your data for records\n2. Save any custom routines\n3. Screenshot important progress\n4. Consider just taking a break instead\n\n**Alternative:** Use 'Pause Account' to temporarily disable without losing data."
                )
            ]
        )
    ]
    
    var filteredCategories: [FAQCategory] {
        if searchText.isEmpty {
            return faqCategories
        }
        
        return faqCategories.compactMap { category in
            let filteredQuestions = category.questions.filter { item in
                item.question.localizedCaseInsensitiveContains(searchText) ||
                item.answer.localizedCaseInsensitiveContains(searchText)
            }
            
            if !filteredQuestions.isEmpty {
                return FAQCategory(
                    title: category.title,
                    icon: category.icon,
                    color: category.color,
                    questions: filteredQuestions
                )
            }
            return nil
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color("TextSecondaryColor"))
                    
                    TextField("Search FAQs...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(AppTheme.Typography.gravityBook(16))
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // FAQ Categories
                ForEach(filteredCategories) { category in
                    VStack(alignment: .leading, spacing: 12) {
                        // Category Header
                        HStack(spacing: 12) {
                            Image(systemName: category.icon)
                                .font(AppTheme.Typography.title2Font())
                                .foregroundColor(category.color)
                            
                            Text(category.title)
                                .font(AppTheme.Typography.gravitySemibold(18))
                                .foregroundColor(Color("TextColor"))
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        // Questions
                        VStack(spacing: 8) {
                            ForEach(category.questions) { item in
                                FAQItemView(
                                    item: item,
                                    isExpanded: expandedQuestions.contains(item.id)
                                ) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        if expandedQuestions.contains(item.id) {
                                            expandedQuestions.remove(item.id)
                                        } else {
                                            expandedQuestions.insert(item.id)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Citations section
                VStack(spacing: 16) {
                    Text("Scientific References")
                        .font(AppTheme.Typography.gravitySemibold(18))
                        .foregroundColor(Color("TextColor"))
                    
                    Text("All health claims are backed by research")
                        .font(AppTheme.Typography.gravityBook(14))
                        .foregroundColor(Color("TextSecondaryColor"))
                    
                    NavigationLink {
                        AllCitationsView()
                    } label: {
                        HStack {
                            Image(systemName: "doc.text.magnifyingglass")
                            Text("View All Citations")
                        }
                        .font(AppTheme.Typography.gravitySemibold(14))
                        .foregroundColor(Color("GrowthGreen"))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(25)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                .padding()
                
                // Still have questions section
                VStack(spacing: 16) {
                    Text("Still have questions?")
                        .font(AppTheme.Typography.gravitySemibold(18))
                        .foregroundColor(Color("TextColor"))
                    
                    Text("Our support team is here to help")
                        .font(AppTheme.Typography.gravityBook(14))
                        .foregroundColor(Color("TextSecondaryColor"))
                    
                    NavigationLink {
                        ContactSupportView()
                    } label: {
                        Text("Contact Support")
                            .font(AppTheme.Typography.gravitySemibold(14))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color("GrowthGreen"))
                            .cornerRadius(25)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                .padding()
            }
            .padding(.vertical)
        }
        .navigationTitle("FAQ")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Models
struct FAQCategory: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let questions: [FAQItem]
}

struct FAQItem: Identifiable {
    let id = UUID().uuidString
    let question: String
    let answer: String
}

// MARK: - FAQ Item View
struct FAQItemView: View {
    let item: FAQItem
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(item.question)
                        .font(AppTheme.Typography.gravitySemibold(15))
                        .foregroundColor(Color("TextColor"))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer(minLength: 12)
                    
                    Image(systemName: "chevron.down")
                        .font(AppTheme.Typography.captionFont())
                        .foregroundColor(Color("TextSecondaryColor"))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                
                if isExpanded {
                    Text(item.answer)
                        .font(AppTheme.Typography.gravityBook(14))
                        .foregroundColor(Color("TextSecondaryColor"))
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding()
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NavigationStack {
        FAQView()
    }
}