#!/usr/bin/env python3
"""
Script to upload recovery and safety content to Firebase
Following the exact document structure from Stories 2.2, 2.3, and 2.4
"""

import json
import sys
import requests
from typing import Dict, List
from datetime import datetime

# Firebase project configuration
PROJECT_ID = "growth-training-app"
COLLECTION = "growth_exercises"

def get_firebase_token():
    """Get Firebase auth token using gcloud"""
    import subprocess
    try:
        result = subprocess.run(
            ["gcloud", "auth", "print-access-token"],
            capture_output=True,
            text=True,
            check=True
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError:
        print("❌ Error: Failed to get auth token. Make sure you're logged in with:")
        print("   gcloud auth login")
        sys.exit(1)

def create_recovery_safety_exercises() -> Dict:
    """Create all recovery and safety exercises"""
    return {
        "heat_application_warmup": {
            "title": "Heat Application Warm-up",
            "description": "Essential warm-up protocol using heat application to increase blood flow and prepare tissues for PE exercises. MEDICAL DISCLAIMER: Consult a healthcare provider before beginning any PE routine. Not medical advice.",
            "category": "recovery",
            "difficulty": "beginner",
            "estimatedDuration": 10,
            "equipmentNeeded": ["Warm cloth or heating pad", "Towel", "Timer"],
            "steps": [
                {
                    "order": 1,
                    "instruction": "Medical consultation check. Ensure you've consulted with a healthcare provider before beginning any PE routine. Verify you're 18+ years old and understand the risks involved.",
                    "tips": ["Schedule medical consultation if not done", "Review all contraindications", "Ensure proper understanding of risks"],
                    "cautions": ["Never proceed without medical clearance", "Stop if you have any medical conditions affecting circulation", "Do not continue if you experience any pain"]
                },
                {
                    "order": 2,
                    "instruction": "Prepare warm application method. Use a warm (not hot) damp cloth, heating pad on low, or warm shower. Temperature should feel comfortably warm to touch, never burning.",
                    "tips": ["Test temperature on wrist first", "Use timer to track exposure", "Have cool cloth ready for emergencies"],
                    "cautions": ["Never use excessive heat", "Avoid temperatures above comfortable skin contact", "Do not apply heat for longer than recommended"]
                },
                {
                    "order": 3,
                    "instruction": "Apply gentle heat for 5-10 minutes. Focus on entire genital area to increase blood flow and tissue flexibility. Maintain consistent, comfortable warmth throughout.",
                    "tips": ["Move heat source gently around area", "Maintain relaxed breathing", "Use this time for mental preparation"],
                    "cautions": ["Stop immediately if skin becomes red or irritated", "Never fall asleep with heat applied", "Remove heat if any numbness occurs"]
                },
                {
                    "order": 4,
                    "instruction": "Monitor response and warning signs. Watch for proper tissue warming (increased pliability) and immediately stop if you notice pain, excessive redness, or any adverse reactions.",
                    "tips": ["Tissues should feel more pliable", "Skin should return to normal color quickly", "You should feel relaxed and prepared"],
                    "cautions": ["Stop immediately if pain occurs", "Discontinue if skin stays red after heat removal", "Never continue if you feel faint or dizzy"]
                },
                {
                    "order": 5,
                    "instruction": "Complete warm-up assessment. Ensure tissues feel adequately warmed and flexible before proceeding to PE exercises. This step is crucial for injury prevention.",
                    "tips": ["Tissues should feel noticeably warmer", "Movement should feel more comfortable", "Take time to assess readiness"],
                    "cautions": ["Do not rush this assessment", "Better to over-warm than under-warm", "When in doubt, apply heat for additional 2-3 minutes"]
                },
                {
                    "order": 6,
                    "instruction": "Transition safely to PE exercises. Remove heat source and begin exercises immediately while tissues remain warm. Start with the lightest intensity planned for your session.",
                    "tips": ["Begin with gentle movements", "Maintain the warm environment", "Start conservatively with intensity"],
                    "cautions": ["Do not delay after warm-up", "Never start with maximum intensity", "Stop and re-warm if tissues cool during session"]
                },
                {
                    "order": 7,
                    "instruction": "Document warm-up completion. Note the duration, method used, and tissue response for future reference and progression tracking.",
                    "tips": ["Keep consistent warm-up records", "Note what works best for you", "Track any variations in response"],
                    "cautions": ["Report any negative reactions to healthcare provider", "Note if more or less time needed", "Document any equipment issues"]
                },
                {
                    "order": 8,
                    "instruction": "Emergency procedures awareness. Know the signs requiring immediate cessation: severe pain, persistent redness, numbness, or any concerning changes. Have cool cloth and emergency contacts ready.",
                    "tips": ["Keep emergency supplies accessible", "Know when to seek medical help", "Have healthcare provider contact information available"],
                    "cautions": ["Never ignore warning signs", "When in doubt, stop and seek medical advice", "Emergency symptoms require immediate medical attention"]
                }
            ]
        },
        "preparatory_stretching_protocol": {
            "title": "Preparatory Stretching Protocol",
            "description": "Gentle preparatory stretching routine to prime tissues for PE training. Includes light mobility work and circulation enhancement. MEDICAL DISCLAIMER: Consult healthcare provider before beginning. Not medical advice.",
            "category": "recovery",
            "difficulty": "beginner",
            "estimatedDuration": 8,
            "equipmentNeeded": ["Comfortable space", "Timer", "Lubricant (optional)"],
            "steps": [
                {
                    "order": 1,
                    "instruction": "Medical clearance verification. Confirm healthcare provider consultation is complete and you understand all risks. Verify no contraindications exist for your specific situation.",
                    "tips": ["Review medical consultation notes", "Confirm understanding of personal risk factors", "Ensure emergency contacts are available"],
                    "cautions": ["Never proceed without medical clearance", "Stop if any medical conditions worsen", "Seek immediate medical help for concerning symptoms"]
                },
                {
                    "order": 2,
                    "instruction": "Begin with gentle manual manipulation. Using clean hands, perform very light stretching motions without force. Focus on encouraging natural movement and flexibility.",
                    "tips": ["Wash hands thoroughly first", "Use minimal pressure initially", "Focus on gentle, natural movements"],
                    "cautions": ["Never use excessive force", "Stop if any pain occurs", "Avoid aggressive or sudden movements"]
                },
                {
                    "order": 3,
                    "instruction": "Perform light circular motions. Gently move in small circles to encourage blood flow and tissue mobility. Maintain comfortable pressure throughout.",
                    "tips": ["Start with very small circles", "Gradually increase size if comfortable", "Maintain steady, rhythmic motion"],
                    "cautions": ["Stop if circulation feels restricted", "Avoid pressure that causes discomfort", "Never force range of motion"]
                },
                {
                    "order": 4,
                    "instruction": "Include gentle extension movements. Perform light stretching in different directions, never exceeding comfortable range of motion. Focus on promoting flexibility.",
                    "tips": ["Move slowly and deliberately", "Listen to your body's feedback", "Maintain relaxed breathing pattern"],
                    "cautions": ["Stop immediately if pain occurs", "Never stretch beyond comfortable limits", "Avoid bouncing or jerky movements"]
                },
                {
                    "order": 5,
                    "instruction": "Monitor tissue response continuously. Assess for proper circulation, comfort, and readiness. Look for positive signs like increased pliability and warmth.",
                    "tips": ["Check for improved flexibility", "Note increased warmth from circulation", "Ensure comfort is maintained"],
                    "cautions": ["Stop if tissues become cold or numb", "Discontinue if pain or discomfort develops", "Seek medical help if concerning changes occur"]
                },
                {
                    "order": 6,
                    "instruction": "Complete readiness assessment. Ensure tissues feel adequately prepared for PE exercises. This includes checking flexibility, warmth, and comfort levels.",
                    "tips": ["Take time for thorough assessment", "Tissues should feel more flexible", "Comfort should be maintained or improved"],
                    "cautions": ["Do not proceed if tissues feel unprepared", "Better to extend preparation time", "When in doubt, continue preparation"]
                },
                {
                    "order": 7,
                    "instruction": "Transition to PE exercises safely. Begin with lowest planned intensity immediately while tissues remain prepared. Maintain the prepared state throughout transition.",
                    "tips": ["Start immediately after preparation", "Begin with gentlest planned exercises", "Maintain warm, comfortable environment"],
                    "cautions": ["Do not delay after preparation", "Never start with high intensity", "Stop and re-prepare if readiness is lost"]
                },
                {
                    "order": 8,
                    "instruction": "Document preparation effectiveness. Record the duration, methods used, and tissue response for future reference and routine optimization.",
                    "tips": ["Note what preparation methods work best", "Track time needed for optimal preparation", "Record any variations in response"],
                    "cautions": ["Report negative responses to healthcare provider", "Note if preparation seems inadequate", "Document any concerning observations"]
                }
            ]
        },
        "warning_signs_recognition": {
            "title": "Warning Signs Recognition",
            "description": "Critical safety education on recognizing warning signs during PE exercises. Essential for injury prevention and immediate response protocols. MEDICAL DISCLAIMER: Consult healthcare provider immediately for any concerning symptoms.",
            "category": "recovery",
            "difficulty": "beginner",
            "estimatedDuration": 15,
            "equipmentNeeded": ["Emergency contact information", "Cool compress (optional)", "Timer"],
            "steps": [
                {
                    "order": 1,
                    "instruction": "Learn immediate stop signs. Recognize pain, numbness, sudden color changes (white, blue, purple), or loss of sensation as signals requiring immediate cessation of all activities.",
                    "tips": ["Memorize these critical warning signs", "Practice recognizing normal vs concerning changes", "Keep emergency contacts readily available"],
                    "cautions": ["These signs require immediate action", "Never ignore or 'push through' these symptoms", "Seek immediate medical attention if symptoms persist"]
                },
                {
                    "order": 2,
                    "instruction": "Identify circulation warning signs. Watch for persistent coldness, prolonged color changes, reduced sensitivity, or tingling that doesn't resolve quickly after exercise.",
                    "tips": ["Normal color should return within minutes", "Sensitivity should normalize quickly", "Warmth should return naturally"],
                    "cautions": ["Prolonged circulation changes require medical evaluation", "Never continue if circulation seems impaired", "Ice should only be used in genuine emergencies"]
                },
                {
                    "order": 3,
                    "instruction": "Recognize tissue damage indicators. Look for persistent swelling, bruising that worsens, skin breaks, unusual texture changes, or areas that remain tender.",
                    "tips": ["Some mild temporary marking may be normal", "Healing should progress steadily", "Document changes with photos if needed"],
                    "cautions": ["Persistent or worsening damage requires medical attention", "Never continue exercises with active tissue damage", "Infection signs require immediate medical care"]
                },
                {
                    "order": 4,
                    "instruction": "Monitor for systemic warning signs. Watch for dizziness, nausea, unusual fatigue, difficulty concentrating, or any whole-body symptoms during or after exercises.",
                    "tips": ["PE exercises should not cause systemic symptoms", "Maintain awareness of overall wellbeing", "Trust your body's signals"],
                    "cautions": ["Systemic symptoms may indicate serious problems", "Stop all activities if systemic symptoms occur", "Seek medical evaluation for unexplained systemic symptoms"]
                },
                {
                    "order": 5,
                    "instruction": "Understand progressive warning signs. Recognize when mild symptoms are worsening over time, including increasing discomfort, longer recovery times, or reduced function.",
                    "tips": ["Track symptoms over multiple sessions", "Note trends in recovery time", "Document any progressive changes"],
                    "cautions": ["Progressive worsening requires routine modification", "Increasing symptoms indicate need for medical consultation", "Never ignore patterns of worsening"]
                },
                {
                    "order": 6,
                    "instruction": "Learn proper response protocols. Know the immediate steps for each warning sign category, including when to apply cold, when to seek medical help, and what information to provide healthcare providers.",
                    "tips": ["Practice response protocols mentally", "Know your healthcare provider's emergency procedures", "Keep symptom documentation ready"],
                    "cautions": ["Quick appropriate response can prevent serious injury", "Delayed response may worsen outcomes", "When in doubt, err on the side of caution"]
                },
                {
                    "order": 7,
                    "instruction": "Establish emergency action plan. Have emergency contacts, healthcare provider information, and nearest urgent care facility details readily available before beginning any PE routine.",
                    "tips": ["Keep emergency information easily accessible", "Inform trusted contacts about your PE activities", "Know your insurance coverage for emergencies"],
                    "cautions": ["Emergency situations require immediate action", "Prepare for emergencies before they occur", "Never delay seeking help when needed"]
                },
                {
                    "order": 8,
                    "instruction": "Regular warning sign assessment. Conduct daily and weekly reviews of your condition, comparing to baseline and watching for any developing warning signs.",
                    "tips": ["Perform daily visual and tactile assessments", "Compare to your personal baseline", "Maintain detailed records"],
                    "cautions": ["Changes from baseline require attention", "Regular assessment helps catch problems early", "Report significant changes to healthcare provider"]
                }
            ]
        },
        "when_to_stop_immediately": {
            "title": "When to Stop Immediately Protocol",
            "description": "Emergency stop protocols and immediate response procedures for PE exercises. Critical safety information for preventing serious injury. MEDICAL DISCLAIMER: Seek immediate medical attention for emergency symptoms.",
            "category": "recovery",
            "difficulty": "beginner",
            "estimatedDuration": 12,
            "equipmentNeeded": ["Emergency contact information", "Cold compress", "Clean cloth"],
            "steps": [
                {
                    "order": 1,
                    "instruction": "Immediate pain protocol. Stop all activity instantly if sharp, sudden, or severe pain occurs. Do not attempt to 'work through' pain or reduce intensity - complete cessation is required.",
                    "tips": ["Any pain requires immediate stopping", "Pain indicates potential tissue damage", "Document pain characteristics for medical consultation"],
                    "cautions": ["Pain is always a stop signal", "Never ignore or minimize pain", "Continuing with pain can cause serious injury"]
                },
                {
                    "order": 2,
                    "instruction": "Circulation emergency response. Stop immediately if skin becomes white, blue, purple, or black. Remove all equipment, apply gentle warmth (not heat), and seek immediate medical attention.",
                    "tips": ["Color changes indicate circulation problems", "Remove all restrictive devices immediately", "Gentle massage may help restore circulation"],
                    "cautions": ["Severe color changes are medical emergencies", "Do not delay seeking medical help", "Permanent damage can occur quickly"]
                },
                {
                    "order": 3,
                    "instruction": "Numbness or loss of sensation protocol. Complete immediate cessation if any area becomes numb or loses sensation. Remove equipment, position comfortably, and monitor for sensation return.",
                    "tips": ["Sensation should return within minutes", "Gentle movement may help restore sensation", "Document duration of numbness"],
                    "cautions": ["Prolonged numbness indicates nerve damage risk", "Numbness lasting over 10 minutes requires medical evaluation", "Never continue with reduced sensation"]
                },
                {
                    "order": 4,
                    "instruction": "Tissue damage stop protocol. Cease all activity if skin breaks, unusual swelling develops, or abnormal texture changes occur. Clean area gently and assess for medical care needs.",
                    "tips": ["Clean hands before touching damaged tissue", "Apply clean, dry dressing if needed", "Photograph damage for medical consultation"],
                    "cautions": ["Open wounds require medical evaluation", "Infected tissue damage needs immediate medical care", "Do not resume exercises until fully healed"]
                },
                {
                    "order": 5,
                    "instruction": "Equipment emergency procedures. If equipment becomes stuck, painful, or causes concerning symptoms, stop all attempts to remove forcefully. Seek medical help for safe removal.",
                    "tips": ["Stay calm if equipment becomes stuck", "Do not panic or force removal", "Lubrication may help with gentle removal"],
                    "cautions": ["Forced removal can cause severe injury", "Some equipment emergencies require medical intervention", "Do not attempt dangerous removal techniques"]
                },
                {
                    "order": 6,
                    "instruction": "Systemic emergency response. Stop all PE activities if dizziness, nausea, chest pain, difficulty breathing, or other whole-body symptoms occur. Seek immediate medical attention.",
                    "tips": ["Systemic symptoms are serious warning signs", "Call emergency services if symptoms are severe", "Have someone else present if possible"],
                    "cautions": ["Systemic symptoms may indicate life-threatening conditions", "Do not delay emergency medical care", "These symptoms are never normal during PE"]
                },
                {
                    "order": 7,
                    "instruction": "Post-emergency assessment protocol. After any emergency stop, conduct thorough assessment before considering future PE activities. Medical clearance may be required before resuming.",
                    "tips": ["Document all emergency details", "Schedule medical consultation", "Allow adequate time for complete recovery"],
                    "cautions": ["Emergency stops indicate serious safety concerns", "Medical clearance may be required before resuming", "Multiple emergency stops suggest need for routine modification"]
                },
                {
                    "order": 8,
                    "instruction": "Emergency prevention education. Learn from any emergency stop incidents to prevent recurrence. Modify techniques, equipment, or intensity to eliminate conditions that led to the emergency.",
                    "tips": ["Analyze what factors contributed to the emergency", "Implement preventive measures", "Consider working with healthcare provider to modify approach"],
                    "cautions": ["Emergency patterns suggest fundamental safety issues", "Repeated emergencies may indicate need to discontinue PE", "Professional medical guidance may be necessary"]
                }
            ]
        },
        "pre_exercise_safety_checklist": {
            "title": "Pre-Exercise Safety Checklist",
            "description": "Comprehensive safety checklist to complete before every PE session. Essential for injury prevention and optimal results. MEDICAL DISCLAIMER: Medical consultation required before beginning PE routine.",
            "category": "recovery",
            "difficulty": "beginner",
            "estimatedDuration": 5,
            "equipmentNeeded": ["Timer", "Checklist (written or digital)", "Emergency contacts"],
            "steps": [
                {
                    "order": 1,
                    "instruction": "Medical clearance verification. Confirm current medical clearance is valid and no new health conditions have developed since last medical consultation.",
                    "tips": ["Keep medical clearance documentation accessible", "Note any changes in health status", "Schedule regular medical check-ups"],
                    "cautions": ["Never proceed without valid medical clearance", "New health conditions require medical re-evaluation", "Some medications may affect PE safety"]
                },
                {
                    "order": 2,
                    "instruction": "Current health status assessment. Evaluate today's health including sleep quality, stress levels, hydration, recent illness, and current medications.",
                    "tips": ["Poor sleep or high stress may increase injury risk", "Adequate hydration is essential", "Some medications affect circulation"],
                    "cautions": ["Illness or fatigue increase injury risk", "Dehydration affects tissue health", "Certain medications contraindicate PE exercises"]
                },
                {
                    "order": 3,
                    "instruction": "Equipment safety inspection. Check all equipment for damage, wear, cleanliness, and proper function before each use. Replace damaged equipment immediately.",
                    "tips": ["Clean equipment before each use", "Check for cracks, sharp edges, or wear", "Test equipment function before applying"],
                    "cautions": ["Damaged equipment can cause serious injury", "Unclean equipment risks infection", "Malfunctioning equipment should never be used"]
                },
                {
                    "order": 4,
                    "instruction": "Environment preparation check. Ensure private, comfortable space with appropriate temperature, lighting, and emergency supplies readily available.",
                    "tips": ["Maintain comfortable room temperature", "Ensure adequate lighting for safety", "Keep emergency supplies within reach"],
                    "cautions": ["Cold environments increase injury risk", "Poor lighting can lead to accidents", "Emergency supplies must be immediately accessible"]
                },
                {
                    "order": 5,
                    "instruction": "Mental preparation assessment. Confirm you're in appropriate mental state - focused, calm, and prepared to stop immediately if needed. Avoid PE if distracted or rushed.",
                    "tips": ["Take time to mentally prepare", "Practice relaxation techniques if needed", "Ensure adequate time without rushing"],
                    "cautions": ["Distraction increases accident risk", "Rushing leads to poor judgment", "Emotional stress affects pain perception"]
                },
                {
                    "order": 6,
                    "instruction": "Emergency preparedness verification. Confirm emergency contacts are available, emergency supplies are accessible, and you know proper emergency procedures.",
                    "tips": ["Keep emergency contacts immediately accessible", "Review emergency procedures regularly", "Ensure emergency supplies are fresh"],
                    "cautions": ["Emergency preparedness can prevent serious complications", "Lack of preparation can worsen emergency outcomes", "Practice emergency procedures mentally"]
                },
                {
                    "order": 7,
                    "instruction": "Session planning confirmation. Review planned exercises, intensity levels, duration, and safety modifications based on current condition and recent sessions.",
                    "tips": ["Plan conservative progression", "Consider recent session outcomes", "Have modification options ready"],
                    "cautions": ["Overly aggressive planning increases injury risk", "Ignore recent problems at your peril", "Flexibility in planning is essential for safety"]
                },
                {
                    "order": 8,
                    "instruction": "Final safety commitment. Make conscious commitment to prioritize safety over progress, to stop immediately if warning signs occur, and to seek medical help when needed.",
                    "tips": ["Safety always comes before progress", "Commit to honest self-assessment during session", "Remember that setbacks protect long-term gains"],
                    "cautions": ["Compromising safety for progress leads to injury", "Denial of warning signs causes serious harm", "Long-term success requires consistent safety practices"]
                }
            ]
        },
        "medical_consultation_guidelines": {
            "title": "Medical Consultation Guidelines",
            "description": "Essential guidelines for medical consultation before beginning PE training. Includes what to discuss, how to prepare, and ongoing medical care needs. MEDICAL DISCLAIMER: This is not medical advice - professional consultation required.",
            "category": "recovery",
            "difficulty": "beginner",
            "estimatedDuration": 20,
            "equipmentNeeded": ["Medical consultation notes", "Health history documentation", "Question list"],
            "steps": [
                {
                    "order": 1,
                    "instruction": "Prepare comprehensive health history. Compile complete medical history including current conditions, medications, surgeries, and family history relevant to PE training safety.",
                    "tips": ["Gather all relevant medical records", "List all current medications including supplements", "Include family history of relevant conditions"],
                    "cautions": ["Incomplete health history may miss important contraindications", "Failing to disclose conditions can lead to dangerous recommendations", "Honesty is essential for safe medical guidance"]
                },
                {
                    "order": 2,
                    "instruction": "Identify appropriate healthcare provider. Seek consultation with physician experienced in men's health, urology, or willing to research PE training risks and benefits.",
                    "tips": ["Urologists often have relevant expertise", "Some general practitioners are knowledgeable", "Consider seeking second opinion if needed"],
                    "cautions": ["Not all physicians are familiar with PE training", "Some may dismiss concerns without proper evaluation", "Provider comfort with topic is important for thorough consultation"]
                },
                {
                    "order": 3,
                    "instruction": "Prepare specific PE training questions. Develop list of questions about your personal risk factors, contraindications, monitoring needs, and warning signs specific to your health status.",
                    "tips": ["Ask about your specific risk factors", "Inquire about monitoring recommendations", "Request guidance on warning signs for your situation"],
                    "cautions": ["Generic advice may not address your specific risks", "Your health conditions may create unique considerations", "Standard precautions may be insufficient for your situation"]
                },
                {
                    "order": 4,
                    "instruction": "Discuss cardiovascular considerations. Review how PE training might affect cardiovascular health, especially if you have heart conditions, blood pressure issues, or circulation problems.",
                    "tips": ["PE can affect blood pressure and circulation", "Some cardiovascular conditions may contraindicate PE", "Monitoring needs may be specific to your condition"],
                    "cautions": ["Cardiovascular conditions can make PE dangerous", "Blood pressure changes during PE may be problematic", "Circulation issues increase injury risk significantly"]
                },
                {
                    "order": 5,
                    "instruction": "Address psychological and sexual health aspects. Discuss expectations, psychological motivations, relationship impacts, and existing sexual health concerns with healthcare provider.",
                    "tips": ["Honest discussion about motivations is important", "Consider psychological counseling if needed", "Address relationship impacts thoughtfully"],
                    "cautions": ["Unrealistic expectations can lead to dangerous behavior", "Underlying psychological issues may drive unsafe practices", "Relationship pressures can compromise safety judgment"]
                },
                {
                    "order": 6,
                    "instruction": "Establish ongoing monitoring protocol. Work with healthcare provider to establish regular check-in schedule, monitoring parameters, and criteria for stopping PE training.",
                    "tips": ["Regular medical monitoring is essential", "Establish clear parameters for concern", "Create plan for addressing problems"],
                    "cautions": ["Lack of monitoring can allow problems to progress", "Changes may develop gradually and need professional assessment", "Self-monitoring alone is insufficient for many conditions"]
                },
                {
                    "order": 7,
                    "instruction": "Document medical recommendations thoroughly. Obtain written recommendations, contraindications, monitoring requirements, and emergency procedures from healthcare provider.",
                    "tips": ["Request written documentation of all recommendations", "Clarify any unclear instructions", "Keep medical recommendations easily accessible"],
                    "cautions": ["Verbal instructions may be forgotten or misunderstood", "Written documentation provides important reference", "Medical recommendations should guide all PE decisions"]
                },
                {
                    "order": 8,
                    "instruction": "Plan for emergency medical care. Ensure healthcare provider understands your PE activities and establish procedures for PE-related medical emergencies or concerns.",
                    "tips": ["Make sure provider understands PE training", "Establish clear emergency contact procedures", "Know which urgent care facilities are appropriate"],
                    "cautions": ["Emergency medical providers may not understand PE training", "Delayed emergency care can worsen outcomes", "Some PE emergencies require specialized knowledge"]
                }
            ]
        },
        "post_exercise_recovery_routine": {
            "title": "Post-Exercise Recovery Routine",
            "description": "Comprehensive cool-down and recovery routine for after PE exercises. Essential for healing optimization and injury prevention. MEDICAL DISCLAIMER: Consult healthcare provider for persistent symptoms.",
            "category": "recovery",
            "difficulty": "beginner",
            "estimatedDuration": 15,
            "equipmentNeeded": ["Cool compress", "Warm compress", "Clean towel", "Timer"],
            "steps": [
                {
                    "order": 1,
                    "instruction": "Immediate post-exercise assessment. Conduct thorough visual and tactile assessment of all areas involved in exercises. Look for any signs of excessive stress, damage, or abnormal response.",
                    "tips": ["Check color, temperature, and sensitivity", "Compare to pre-exercise condition", "Document any changes observed"],
                    "cautions": ["Any concerning changes require immediate attention", "Damage may not be immediately apparent", "Early detection allows for prompt intervention"]
                },
                {
                    "order": 2,
                    "instruction": "Gentle circulation restoration. Perform light massage or gentle movements to encourage normal circulation and prevent pooling or congestion in exercised areas.",
                    "tips": ["Use very gentle pressure", "Focus on encouraging normal blood flow", "Maintain movements for 3-5 minutes"],
                    "cautions": ["Avoid excessive pressure on potentially stressed tissues", "Stop if any discomfort occurs", "Circulation problems require medical attention"]
                },
                {
                    "order": 3,
                    "instruction": "Temperature therapy application. Apply appropriate temperature therapy based on exercise intensity and tissue response - cool for inflammation control or warmth for circulation enhancement.",
                    "tips": ["Cool application helps reduce inflammation", "Warm application can maintain circulation", "Alternate temperatures may be beneficial"],
                    "cautions": ["Never apply extreme temperatures", "Limit temperature therapy duration", "Stop if skin becomes irritated"]
                },
                {
                    "order": 4,
                    "instruction": "Gentle stretching and mobility. Perform very light stretching or movement to prevent stiffness and maintain flexibility after exercise session.",
                    "tips": ["Use minimal pressure", "Focus on gentle range of motion", "Stop if any resistance is felt"],
                    "cautions": ["Post-exercise tissues may be vulnerable", "Never force movement after intense sessions", "Pain indicates need to stop immediately"]
                },
                {
                    "order": 5,
                    "instruction": "Hygiene and cleanliness protocol. Clean all areas thoroughly with appropriate gentle cleansers to prevent infection and maintain tissue health.",
                    "tips": ["Use gentle, pH-balanced cleansers", "Rinse thoroughly to remove all cleanser", "Pat dry gently with clean towel"],
                    "cautions": ["Harsh cleansers can irritate stressed tissues", "Poor hygiene can lead to infection", "Excessive scrubbing may cause additional damage"]
                },
                {
                    "order": 6,
                    "instruction": "Rest positioning and support. Position comfortably in supportive position that promotes circulation and prevents additional stress on exercised tissues.",
                    "tips": ["Avoid positions that restrict circulation", "Use supportive clothing or positioning", "Consider elevation if appropriate"],
                    "cautions": ["Restrictive positioning can impede recovery", "Pressure points should be avoided", "Monitor circulation in rest position"]
                },
                {
                    "order": 7,
                    "instruction": "Recovery progress monitoring. Establish monitoring schedule for next 24-48 hours to track healing progress and watch for any delayed reactions or complications.",
                    "tips": ["Check condition every few hours initially", "Note any changes in sensation, color, or comfort", "Document recovery progress"],
                    "cautions": ["Problems may develop hours after exercise", "Delayed reactions can be serious", "Progressive worsening requires medical attention"]
                },
                {
                    "order": 8,
                    "instruction": "Session documentation and planning. Record exercise details, recovery response, and any observations for future session planning and medical consultation needs.",
                    "tips": ["Document exercise type, intensity, and duration", "Note recovery response and any concerns", "Plan modifications for future sessions"],
                    "cautions": ["Poor recovery may indicate need for intensity reduction", "Patterns of poor recovery require medical consultation", "Ignoring recovery signals can lead to injury"]
                }
            ]
        },
        "healing_optimization_protocol": {
            "title": "Healing Optimization Protocol",
            "description": "Advanced recovery techniques for optimizing healing between PE sessions. Includes nutrition, rest, and lifestyle factors for maximum recovery. MEDICAL DISCLAIMER: Not medical advice - consult healthcare provider for concerns.",
            "category": "recovery",
            "difficulty": "intermediate",
            "estimatedDuration": 30,
            "equipmentNeeded": ["Nutrition tracking method", "Sleep tracking", "Stress management tools"],
            "steps": [
                {
                    "order": 1,
                    "instruction": "Optimize nutrition for tissue repair. Focus on adequate protein intake, vitamins C and E, zinc, and proper hydration to support tissue healing and recovery processes.",
                    "tips": ["Aim for 0.8-1.2g protein per kg body weight", "Include vitamin C rich foods", "Maintain consistent hydration"],
                    "cautions": ["Nutritional deficiencies can impair healing", "Excessive supplementation may be harmful", "Consult healthcare provider about supplement needs"]
                },
                {
                    "order": 2,
                    "instruction": "Prioritize quality sleep for recovery. Ensure 7-9 hours of quality sleep nightly as tissue repair occurs primarily during sleep cycles.",
                    "tips": ["Maintain consistent sleep schedule", "Create optimal sleep environment", "Address sleep quality issues"],
                    "cautions": ["Poor sleep significantly impairs healing", "Sleep disorders may require medical treatment", "Sleep medications may affect recovery"]
                },
                {
                    "order": 3,
                    "instruction": "Manage stress levels effectively. Implement stress reduction techniques as chronic stress impairs healing and increases injury risk through elevated cortisol levels.",
                    "tips": ["Practice regular stress reduction techniques", "Consider meditation or relaxation exercises", "Address sources of chronic stress"],
                    "cautions": ["Chronic stress significantly impairs healing", "High stress increases injury risk", "Stress management may require professional help"]
                },
                {
                    "order": 4,
                    "instruction": "Maintain appropriate activity levels. Balance rest with gentle activity to promote circulation without impeding recovery from PE exercises.",
                    "tips": ["Light walking can promote circulation", "Avoid activities that stress exercised areas", "Listen to your body's need for rest"],
                    "cautions": ["Excessive rest can impede circulation", "Too much activity can impair recovery", "Balance is essential for optimal healing"]
                },
                {
                    "order": 5,
                    "instruction": "Monitor inflammatory response. Watch for signs of excessive inflammation and implement appropriate anti-inflammatory measures if needed.",
                    "tips": ["Some inflammation is normal for healing", "Excessive inflammation impedes recovery", "Natural anti-inflammatory foods may help"],
                    "cautions": ["Chronic inflammation prevents healing", "Anti-inflammatory medications may affect healing", "Persistent inflammation requires medical evaluation"]
                },
                {
                    "order": 6,
                    "instruction": "Support circulation enhancement. Use appropriate techniques like light massage, contrast temperature therapy, or gentle movement to optimize circulation for healing.",
                    "tips": ["Gentle massage can improve circulation", "Contrast temperature therapy may help", "Stay adequately hydrated for circulation"],
                    "cautions": ["Excessive massage may impede healing", "Temperature therapy should be moderate", "Circulation problems require medical attention"]
                },
                {
                    "order": 7,
                    "instruction": "Track recovery progress systematically. Monitor healing indicators, energy levels, and readiness for next session to optimize recovery timing.",
                    "tips": ["Keep detailed recovery logs", "Note factors that enhance or impede recovery", "Adjust recovery protocols based on response"],
                    "cautions": ["Poor recovery patterns indicate need for modification", "Ignoring recovery signals increases injury risk", "Consistent poor recovery requires medical consultation"]
                },
                {
                    "order": 8,
                    "instruction": "Integrate recovery with lifestyle. Make recovery optimization a sustainable part of daily routine rather than additional burden or temporary measure.",
                    "tips": ["Build recovery habits into daily routine", "Focus on sustainable lifestyle changes", "Prioritize recovery as essential to success"],
                    "cautions": ["Inconsistent recovery practices limit progress", "Recovery shortcuts often backfire", "Long-term success requires consistent recovery practices"]
                }
            ]
        }
    }

def create_method_document(method_id: str, method_data: Dict) -> Dict:
    """Create Firebase document structure for a method"""

    # Create steps array
    steps_array = []
    for step in method_data["steps"]:
        step_doc = {
            "mapValue": {
                "fields": {
                    "stepNumber": {"integerValue": str(step["order"])},
                    "title": {"stringValue": f"Step {step['order']}"},
                    "description": {"stringValue": step["instruction"]},
                    "tips": {
                        "arrayValue": {
                            "values": [{"stringValue": tip} for tip in step["tips"]]
                        }
                    },
                    "cautions": {
                        "arrayValue": {
                            "values": [{"stringValue": caution} for caution in step["cautions"]]
                        }
                    },
                    "warnings": {
                        "arrayValue": {
                            "values": []
                        }
                    }
                }
            }
        }
        steps_array.append(step_doc)

    # Create equipment array
    equipment_array = [{"stringValue": item} for item in method_data["equipmentNeeded"]]

    # Build the complete document
    doc = {
        "fields": {
            "title": {"stringValue": method_data["title"]},
            "description": {"stringValue": method_data["description"]},
            "category": {"stringValue": method_data["category"]},
            "difficulty": {"stringValue": method_data["difficulty"]},
            "estimatedDuration": {"integerValue": str(method_data["estimatedDuration"])},
            "equipmentNeeded": {
                "arrayValue": {
                    "values": equipment_array
                }
            },
            "steps": {
                "arrayValue": {
                    "values": steps_array
                }
            },
            "createdAt": {"timestampValue": datetime.utcnow().isoformat() + "Z"},
            "updatedAt": {"timestampValue": datetime.utcnow().isoformat() + "Z"}
        }
    }

    return doc

def upload_method(token: str, method_id: str, method_doc: Dict) -> bool:
    """Upload a method to Firebase"""
    url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents/{COLLECTION}/{method_id}"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }

    response = requests.patch(url, headers=headers, json=method_doc)
    return response.status_code == 200

def main():
    print("🚀 Recovery & Safety Content Upload Script")
    print("=" * 50)
    print()

    # Get auth token
    print("🔐 Getting authentication token...")
    token = get_firebase_token()
    print("✅ Authenticated")
    print()

    # Create methods
    print("📝 Creating recovery and safety exercises...")
    methods = create_recovery_safety_exercises()
    print(f"✅ Created {len(methods)} recovery exercises")
    print()

    # Upload methods
    print("📤 Uploading to Firebase...")
    successful_uploads = 0

    for method_id, method_data in methods.items():
        method_doc = create_method_document(method_id, method_data)

        if upload_method(token, method_id, method_doc):
            print(f"  ✅ Uploaded: {method_data['title']}")
            successful_uploads += 1
        else:
            print(f"  ❌ Failed: {method_data['title']}")

    print()
    print("=" * 50)
    print(f"✅ Successfully uploaded {successful_uploads}/{len(methods)} exercises")
    if successful_uploads == len(methods):
        print("🎉 All recovery and safety exercises uploaded successfully!")
    else:
        print(f"⚠️ {len(methods) - successful_uploads} uploads failed - check errors above")

if __name__ == "__main__":
    main()