#!/usr/bin/env python3
"""
Script to upload educational resources to Firestore
Story 2.8: Migrate Educational Resources
"""

import json
import sys
import requests
from typing import List, Dict
import subprocess

# Firebase project configuration
PROJECT_ID = "growth-training-app"
COLLECTION = "growth_exercises"

def get_firebase_token():
    """Get Firebase auth token using gcloud"""
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

def get_educational_resources() -> List[Dict]:
    """
    Returns all educational resources with scientific citations
    """
    resources = []

    # 1. ANATOMY EDUCATION GUIDE
    resources.append({
        "id": "anatomy_education_guide",
        "title": "PE Anatomy & Physiology Guide",
        "description": "Comprehensive scientific guide to penile anatomy, blood flow mechanisms, and tissue structure. Understanding these fundamentals is crucial for safe and effective training. MEDICAL DISCLAIMER: This educational content is for informational purposes only and does not replace professional medical advice.",
        "category": "education",
        "difficulty": "beginner",
        "estimatedDuration": 20,
        "equipmentNeeded": [],
        "steps": [
            {
                "stepNumber": 1,
                "title": "Step 1: Understanding the Three Chambers",
                "description": "The penis contains three cylindrical chambers of erectile tissue. Two corpus cavernosum chambers run along the top, while the corpus spongiosum (containing the urethra) runs along the bottom. These chambers fill with blood during erection through a complex vascular process.",
                "tips": [
                    "The corpus cavernosum is the primary target for girth exercises",
                    "The corpus spongiosum expands less during erection to protect the urethra",
                    "Understanding chamber anatomy helps explain why different exercises target different areas",
                    "The septum between the two corpus cavernosum allows some blood flow between chambers"
                ],
                "cautions": [
                    "Excessive pressure on the corpus spongiosum can damage the urethra",
                    "The chambers have limited expansion capacity - respect physiological limits",
                    "Uneven chamber development can occur with improper technique"
                ],
                "warnings": [
                    "MEDICAL WARNING: Trauma to erectile chambers can cause permanent damage",
                    "Consult a urologist before beginning any PE training program",
                    "Stop immediately if you experience pain, numbness, or discoloration"
                ]
            },
            {
                "stepNumber": 2,
                "title": "Step 2: The Tunica Albuginea - The Limiting Factor",
                "description": "The tunica albuginea is a tough, fibrous sheath surrounding the erectile chambers. It's composed of two layers of collagen fibers arranged at 90-degree angles, providing both strength and limited elasticity. This structure is the primary limiting factor in penile expansion and the main target for growth-inducing exercises.",
                "tips": [
                    "The tunica has viscoelastic properties - it can slowly deform under sustained stress",
                    "Collagen remodeling in the tunica is the mechanism behind permanent gains",
                    "The tunica is thicker dorsally (top) than ventrally (bottom)",
                    "Heat application can temporarily increase tunica pliability"
                ],
                "cautions": [
                    "The tunica has a breaking point - excessive force can cause rupture (penile fracture)",
                    "Micro-tears in the tunica need adequate recovery time to heal properly",
                    "Scar tissue formation from overtraining can reduce elasticity"
                ],
                "warnings": [
                    "Tunica rupture is a medical emergency requiring immediate surgery",
                    "Never use excessive force that causes sharp pain",
                    "Reference: Hsu et al. (2013) 'Anatomy and strength of the tunica albuginea' J Urol"
                ]
            },
            {
                "stepNumber": 3,
                "title": "Step 3: Vascular System and Blood Flow",
                "description": "Penile growth and function depend on robust blood flow. The deep penile arteries supply the corpus cavernosum, while the dorsal arteries supply the glans and corpus spongiosum. Understanding vascular anatomy helps explain how exercises promote growth through controlled stress and enhanced circulation.",
                "tips": [
                    "Improved vascular function is often the first benefit users notice",
                    "The helicine arteries within the corpus cavernosum dilate during erection",
                    "Venous occlusion (trapping blood) is essential for maintaining erection",
                    "Regular cardiovascular exercise supports penile vascular health"
                ],
                "cautions": [
                    "Prolonged blood restriction can cause ischemia (tissue death)",
                    "Vascular damage can lead to erectile dysfunction",
                    "Pre-existing cardiovascular conditions increase risk"
                ],
                "warnings": [
                    "Maximum safe occlusion time is 20 minutes",
                    "Never completely cut off blood flow",
                    "Reference: Dean & Lue (2005) 'Physiology of penile erection' Urol Clin North Am"
                ]
            },
            {
                "stepNumber": 4,
                "title": "Step 4: Suspensory Ligament System",
                "description": "The suspensory ligament attaches the penis to the pubic bone, determining the angle of erection and contributing to visible length. The fundiform ligament provides additional support. These structures can be gradually stretched to increase external penile length without affecting actual tissue length.",
                "tips": [
                    "Ligament stretching reveals 'inner penis' - length already present internally",
                    "Downward stretching specifically targets the suspensory ligament",
                    "Ligament gains are often the quickest to achieve (1-3 months)",
                    "Improved erection angle often results from ligament work"
                ],
                "cautions": [
                    "Excessive ligament stretching can lower erection angle permanently",
                    "Ligament tears heal with scar tissue, potentially reducing gains",
                    "Sharp pain indicates potential ligament damage"
                ],
                "warnings": [
                    "Surgical ligament cutting (suspensory ligament release) has significant risks",
                    "Never use excessive force on ligaments",
                    "Reference: Wessells et al. (1996) 'Penile length in the flaccid and erect states' J Urol"
                ]
            },
            {
                "stepNumber": 5,
                "title": "Step 5: Nerve Distribution and Sensitivity",
                "description": "The penis is innervated by the dorsal nerve (sensation), cavernous nerves (erection), and perineal nerve (urethral sensation). Understanding nerve anatomy is crucial for avoiding injury and maintaining sexual function. The glans has the highest concentration of nerve endings.",
                "tips": [
                    "The dorsal nerve runs along the top of the shaft - avoid excessive pressure here",
                    "Nerve function can be temporarily affected by exercises but should quickly recover",
                    "Maintaining sensitivity is as important as gaining size",
                    "The frenulum area is particularly nerve-dense and sensitive"
                ],
                "cautions": [
                    "Numbness lasting over 15 minutes requires immediate cessation of training",
                    "Chronic nerve compression can cause permanent sensitivity loss",
                    "Tingling or 'pins and needles' indicates nerve irritation"
                ],
                "warnings": [
                    "Permanent nerve damage can result from excessive pressure or traction",
                    "Loss of sensation should be evaluated by a medical professional",
                    "Reference: Yang & Bradley (1999) 'Neuroanatomy of the penile portion of human dorsal nerve' BJU Int"
                ]
            },
            {
                "stepNumber": 6,
                "title": "Step 6: Cellular Growth Mechanisms",
                "description": "Penile growth occurs through two primary mechanisms: hypertrophy (cell enlargement) and hyperplasia (cell division). Mechanical stress triggers cellular signaling cascades that promote both processes. Growth factors like IGF-1, VEGF, and FGF play crucial roles in tissue remodeling and angiogenesis (new blood vessel formation).",
                "tips": [
                    "Smooth muscle cells in the corpus cavernosum can undergo both hypertrophy and hyperplasia",
                    "Collagen remodeling in response to stress is key to permanent gains",
                    "The inflammatory response from training triggers growth factor release",
                    "Protein synthesis increases during recovery periods"
                ],
                "cautions": [
                    "Excessive inflammation can lead to fibrosis (scar tissue)",
                    "Growth is a slow process - expect months to years, not weeks",
                    "Overtraining inhibits growth by preventing adequate recovery"
                ],
                "warnings": [
                    "Rapid 'gains' are usually temporary fluid retention, not true growth",
                    "Growth hormone or IGF-1 supplementation has serious health risks",
                    "Reference: Trost et al. (2013) 'Review of penile elongation surgery' Transl Androl Urol"
                ]
            },
            {
                "stepNumber": 7,
                "title": "Step 7: Tissue Adaptation Timeline",
                "description": "Understanding realistic timelines prevents overtraining and disappointment. Initial gains (1-3 months) are primarily from improved blood flow and ligament stretching. True tissue growth (3-12 months) occurs slowly through collagen remodeling. Consolidation (12+ months) involves maintaining and cementing gains.",
                "tips": [
                    "Newbie gains in the first 3 months are typically 0.25-0.5 inches",
                    "Girth gains generally come slower than length gains",
                    "Most users see best results between months 6-18",
                    "Genetic factors significantly influence growth potential"
                ],
                "cautions": [
                    "Claims of gaining inches in weeks are false and dangerous",
                    "Plateau periods are normal and shouldn't prompt overtraining",
                    "Individual variation in growth response is substantial"
                ],
                "warnings": [
                    "Unrealistic expectations lead to dangerous overtraining",
                    "Never increase intensity dramatically to 'break through' plateaus",
                    "Reference: Nikoobakht et al. (2011) 'Effect of penile-extender device' BJU Int"
                ]
            },
            {
                "stepNumber": 8,
                "title": "Step 8: Medical Considerations and Safety",
                "description": "Certain medical conditions contraindicate PE training. Understanding anatomical variations and pre-existing conditions is essential for safety. Regular self-examination and awareness of warning signs prevents serious complications. When in doubt, consult a urologist familiar with PE practices.",
                "tips": [
                    "Perform regular self-examinations for lumps, plaques, or curvature changes",
                    "Keep a training log to track any changes or concerns",
                    "Annual urological checkups are recommended for active practitioners",
                    "Be honest with healthcare providers about PE practices"
                ],
                "cautions": [
                    "Peyronie's disease, varicocele, and STIs are contraindications",
                    "Blood thinners and certain medications increase injury risk",
                    "Pre-existing erectile dysfunction should be evaluated before starting"
                ],
                "warnings": [
                    "MEDICAL EMERGENCY: Priapism (erection lasting >4 hours) requires immediate ER visit",
                    "Any sudden curvature, hard plaques, or severe pain needs medical evaluation",
                    "Reference: Levine et al. (2013) 'Peyronie's disease' J Sex Med"
                ]
            }
        ]
    })

    # 2. GROWTH THEORY GUIDE
    resources.append({
        "id": "growth_theory_guide",
        "title": "Scientific Principles of Penile Growth",
        "description": "Evidence-based exploration of tissue expansion, cellular mechanisms, and growth timelines. Understanding the science helps set realistic expectations and optimize training. MEDICAL DISCLAIMER: This information is educational only and not medical advice.",
        "category": "education",
        "difficulty": "beginner",
        "estimatedDuration": 25,
        "equipmentNeeded": [],
        "steps": [
            {
                "stepNumber": 1,
                "title": "Step 1: Mechanotransduction - How Force Becomes Growth",
                "description": "Mechanotransduction is the process by which cells convert mechanical stimuli into biochemical signals. When tissues experience controlled stress, mechanoreceptors trigger cascades that activate growth pathways. This fundamental principle underlies all PE exercises.",
                "tips": [
                    "Optimal growth occurs at 10-20% above tissue comfort threshold",
                    "Consistent moderate stress is superior to irregular intense stress",
                    "The cytoskeleton transmits force throughout the cell",
                    "Integrins are key mechanoreceptors that initiate signaling"
                ],
                "cautions": [
                    "Excessive force causes inflammatory damage rather than growth",
                    "The mechanotransduction threshold varies between individuals",
                    "Age affects cellular responsiveness to mechanical stimuli"
                ],
                "warnings": [
                    "Pain indicates tissue damage, not effective mechanotransduction",
                    "Never pursue growth through pain or extreme discomfort",
                    "Reference: Ingber (2006) 'Cellular mechanotransduction' FASEB J"
                ]
            },
            {
                "stepNumber": 2,
                "title": "Step 2: Tissue Expansion Principles",
                "description": "Tissue expansion follows Wolff's Law - tissues remodel in response to imposed demands. Similar principles used in reconstructive surgery apply to PE. Gradual, progressive overload induces adaptive changes in connective tissue, smooth muscle, and vascular structures.",
                "tips": [
                    "Tissue expanders in surgery work on identical principles",
                    "Creep (immediate elongation) vs. stress relaxation (adaptation over time)",
                    "Biological creep allows permanent deformation of viscoelastic tissues",
                    "The extracellular matrix remodels to accommodate new tissue architecture"
                ],
                "cautions": [
                    "Rapid expansion causes tearing rather than growth",
                    "Tissue fatigue from overuse reduces expansion capacity",
                    "Individual tissue elasticity varies significantly"
                ],
                "warnings": [
                    "Forced rapid expansion can cause tissue necrosis",
                    "Respect biological limits - tissue has finite expansion capacity",
                    "Reference: De Filippo et al. (2003) 'Tissue engineering a complete vaginal replacement' J Urol"
                ]
            },
            {
                "stepNumber": 3,
                "title": "Step 3: Collagen Remodeling and ECM Adaptation",
                "description": "The extracellular matrix (ECM), primarily composed of collagen, undergoes continuous remodeling. Matrix metalloproteinases (MMPs) break down old collagen while fibroblasts synthesize new fibers. This remodeling process, taking months to years, enables permanent structural changes.",
                "tips": [
                    "Collagen turnover in penile tissue is approximately 60-90 days",
                    "Vitamin C is essential for collagen synthesis",
                    "Heat temporarily denatures collagen bonds, increasing pliability",
                    "Type I and III collagen are primary components of penile connective tissue"
                ],
                "cautions": [
                    "Excessive MMP activity can weaken tissue structure",
                    "Inadequate nutrition impairs collagen synthesis",
                    "Smoking significantly impairs collagen metabolism"
                ],
                "warnings": [
                    "Rapid collagen breakdown without synthesis causes tissue weakness",
                    "Steroid use can impair collagen synthesis and healing",
                    "Reference: Liu et al. (2018) 'Collagen in tendon, ligament, and bone healing' Clin Orthop"
                ]
            },
            {
                "stepNumber": 4,
                "title": "Step 4: Angiogenesis and Vascular Remodeling",
                "description": "New blood vessel formation (angiogenesis) is crucial for supporting enlarged tissue. Hypoxia and mechanical stress trigger VEGF (vascular endothelial growth factor) release, promoting capillary sprouting. Enhanced vascularization supports both growth and improved function.",
                "tips": [
                    "VEGF expression increases within hours of mechanical stress",
                    "L-arginine supplementation may support NO-mediated angiogenesis",
                    "Cardiovascular exercise enhances systemic angiogenic capacity",
                    "Growth requires adequate blood supply for nutrient delivery"
                ],
                "cautions": [
                    "Excessive hypoxia can cause tissue damage rather than angiogenesis",
                    "Diabetes and vascular disease impair angiogenic response",
                    "Nicotine severely inhibits VEGF expression and vessel formation"
                ],
                "warnings": [
                    "Prolonged ischemia causes irreversible tissue death",
                    "Never completely occlude blood flow for extended periods",
                    "Reference: Rogers et al. (2014) 'Intracavernosal VEGF improves erectile function' J Sex Med"
                ]
            },
            {
                "stepNumber": 5,
                "title": "Step 5: Smooth Muscle Hypertrophy vs. Hyperplasia",
                "description": "Penile smooth muscle can undergo both hypertrophy (cell enlargement) and hyperplasia (cell proliferation). Mechanical stress activates satellite cells and growth factor pathways. The balance between these processes determines the nature of gains - girth typically involves more hypertrophy, while length may involve hyperplasia.",
                "tips": [
                    "IGF-1 is a key mediator of smooth muscle growth",
                    "Protein intake directly affects muscle protein synthesis",
                    "Recovery periods are when actual growth occurs",
                    "Smooth muscle comprises 40-50% of penile tissue"
                ],
                "cautions": [
                    "Excessive training prevents protein synthesis and growth",
                    "Hormonal imbalances affect smooth muscle response",
                    "Age-related decline in growth factors affects response"
                ],
                "warnings": [
                    "Exogenous growth hormone has serious health risks",
                    "Anabolic steroids can paradoxically impair penile function",
                    "Reference: Traish et al. (2003) 'Effects of castration on penile tissue' J Androl"
                ]
            },
            {
                "stepNumber": 6,
                "title": "Step 6: Realistic Timeline Expectations",
                "description": "Scientific studies on penile enlargement devices and techniques show modest but real gains over extended periods. Understanding realistic timelines prevents dangerous overtraining and maintains motivation through plateau phases. Most studies show 0.5-1.5 inch length gains over 6-12 months.",
                "tips": [
                    "Month 1-3: Primarily improved EQ and minor ligament gains (0.25-0.5\")",
                    "Month 4-9: Beginning of true tissue growth (0.25-0.75\")",
                    "Month 10-18: Continued slow growth with plateaus (0.25-0.5\")",
                    "Year 2+: Diminishing returns but continued slow progress possible"
                ],
                "cautions": [
                    "Individual genetics greatly affect growth potential",
                    "Claims of multiple inches in months are fabricated",
                    "Photographic 'evidence' is easily manipulated"
                ],
                "warnings": [
                    "Unrealistic expectations lead to dangerous practices",
                    "Never dramatically increase intensity to speed results",
                    "Reference: Gontero et al. (2009) 'Systematic review of penile elongation' BJU Int"
                ]
            },
            {
                "stepNumber": 7,
                "title": "Step 7: Limiting Factors and Genetic Potential",
                "description": "Genetic factors determine growth potential through collagen composition, growth factor expression, and tissue elasticity. The tunica albuginea's structure is the primary limiting factor. Understanding individual limitations prevents injury from pursuing unrealistic goals.",
                "tips": [
                    "Baseline size doesn't predict growth potential",
                    "Younger tissues generally respond better (peak: 18-35 years)",
                    "Genetic elastin/collagen ratios affect expansion capacity",
                    "Family history may indicate growth potential"
                ],
                "cautions": [
                    "Not everyone will achieve the same results despite identical training",
                    "Forcing growth beyond genetic potential causes injury",
                    "Comparison with others' results is counterproductive"
                ],
                "warnings": [
                    "Pursuing unrealistic size goals leads to permanent injury",
                    "Accept genetic limitations to train safely",
                    "Reference: Ponchietti et al. (2001) 'Penile length and circumference study' Eur Urol"
                ]
            },
            {
                "stepNumber": 8,
                "title": "Step 8: Evidence-Based Approach",
                "description": "Scientific literature on PE is limited but growing. Traction devices, vacuum therapy, and jelqing have some research support. Critical evaluation of evidence, understanding study limitations, and distinguishing anecdote from data is essential for safe, effective training.",
                "tips": [
                    "Peer-reviewed studies are more reliable than testimonials",
                    "Look for randomized controlled trials (RCTs) when available",
                    "Consider conflict of interest in manufacturer-funded studies",
                    "Systematic reviews provide the highest level of evidence"
                ],
                "cautions": [
                    "Most online PE claims lack scientific backing",
                    "Forum anecdotes aren't reliable evidence",
                    "Photo 'proof' is easily faked or misleading"
                ],
                "warnings": [
                    "Don't attempt unproven dangerous techniques",
                    "Marketing claims often exaggerate study results",
                    "References: Oderda & Gontero (2011) 'Non-invasive methods of penile lengthening' BJU Int"
                ]
            }
        ]
    })

    # 3. FAQ GUIDE
    resources.append({
        "id": "faq_guide",
        "title": "PE FAQ - Common Questions Answered",
        "description": "Evidence-based answers to frequently asked questions, myth debunking, and troubleshooting guide. Get clear, honest information about PE training. MEDICAL DISCLAIMER: Consult healthcare providers for personal medical advice.",
        "category": "education",
        "difficulty": "beginner",
        "estimatedDuration": 15,
        "equipmentNeeded": [],
        "steps": [
            {
                "stepNumber": 1,
                "title": "Step 1: Does PE Actually Work?",
                "description": "Yes, modest gains are possible through consistent, safe training over extended periods. Scientific studies on traction devices and vacuum therapy show average gains of 0.5-1.5 inches in length over 6-12 months. However, results vary significantly between individuals and require dedication.",
                "tips": [
                    "Realistic expectation: 0.5-1 inch length, 0.25-0.5 inch girth in first year",
                    "Studies show 60-80% of dedicated users see measurable gains",
                    "Improvements in erection quality often occur before size gains",
                    "Consistency matters more than intensity"
                ],
                "cautions": [
                    "Results are NOT guaranteed - individual variation is significant",
                    "Most abandon training before seeing results (3-6 months)",
                    "'Before/after' photos online are often fake or misleading"
                ],
                "warnings": [
                    "Claims of gaining 3+ inches are false and dangerous to pursue",
                    "No 'secret technique' produces rapid gains",
                    "Reference: Nikoobakht et al. (2011) 'Effect of penile-extender device' BJU Int"
                ]
            },
            {
                "stepNumber": 2,
                "title": "Step 2: Common Myths Debunked",
                "description": "Many PE myths persist despite lack of evidence. Pills don't work - no oral supplement can enlarge penis tissue. Ethnicity doesn't determine potential. Size isn't fixed after puberty but growth becomes much slower. Understanding facts versus fiction enables safe, realistic training.",
                "tips": [
                    "MYTH: Pills/creams cause growth - FACT: No evidence supports this",
                    "MYTH: Masturbation affects size - FACT: No correlation exists",
                    "MYTH: Shoe size predicts penis size - FACT: Studies show no correlation",
                    "MYTH: PE is impossible after 40 - FACT: Slower but still possible"
                ],
                "cautions": [
                    "Supplement marketing exploits insecurity with false claims",
                    "Forums perpetuate myths through repetition without evidence",
                    "Confirmation bias makes people believe ineffective methods work"
                ],
                "warnings": [
                    "Never take unregulated 'enhancement' pills - dangerous ingredients common",
                    "Injecting substances for enlargement can cause necrosis",
                    "Reference: Wylie & Eardley (2007) 'Penile size and the small penis syndrome' BJU Int"
                ]
            },
            {
                "stepNumber": 3,
                "title": "Step 3: Is PE Safe?",
                "description": "PE can be relatively safe when practiced conservatively with proper technique. However, risks include temporary dysfunction, numbness, discoloration, and potential permanent injury if done incorrectly. Medical supervision is ideal but rarely sought. Risk increases dramatically with aggressive approaches.",
                "tips": [
                    "Start conservatively and progress gradually over months",
                    "Never train through pain - discomfort maximum",
                    "Rest days are mandatory for tissue recovery",
                    "Keep detailed logs to identify problems early"
                ],
                "cautions": [
                    "Most injuries result from impatience and overtraining",
                    "Combining multiple intense techniques multiplies risk",
                    "Previous injuries increase vulnerability to re-injury"
                ],
                "warnings": [
                    "Permanent erectile dysfunction is possible from severe injury",
                    "Peyronie's disease can develop from repeated trauma",
                    "Reference: Ralph et al. (2010) 'Trauma, surgery and Peyronie's' J Sex Med"
                ]
            },
            {
                "stepNumber": 4,
                "title": "Step 4: How Long Until I See Results?",
                "description": "Initial improvements in erection quality typically occur within 2-4 weeks. Measurable size gains usually require 3-6 months of consistent training. Most significant gains occur between months 6-18. Plateaus are normal and shouldn't prompt aggressive intensity increases.",
                "tips": [
                    "Week 1-4: Improved EQ, minor temporary expansion",
                    "Month 2-3: First measurable gains (0.1-0.25 inches common)",
                    "Month 4-6: Continued slow progress if consistent",
                    "Month 7-12: Best growth period for most users"
                ],
                "cautions": [
                    "Measuring too frequently creates false disappointment",
                    "Monthly measurements are sufficient",
                    "Temporary gains from edema aren't permanent growth"
                ],
                "warnings": [
                    "Don't increase intensity dramatically if gains seem slow",
                    "Patience prevents injury - growth is slow",
                    "Reference: Gontero et al. (2009) 'A pilot phase-II prospective study' BJU Int"
                ]
            },
            {
                "stepNumber": 5,
                "title": "Step 5: What About Pills and Supplements?",
                "description": "No pill or supplement directly causes penile enlargement. Some supplements may support vascular health (L-arginine, L-citrulline) or general health, potentially improving erection quality. However, marketed 'enhancement' pills are scams at best, dangerous at worst.",
                "tips": [
                    "L-arginine may improve nitric oxide production and blood flow",
                    "Vitamin D, zinc support testosterone and general health",
                    "Adequate protein intake supports tissue repair",
                    "Hydration is more important than any supplement"
                ],
                "cautions": [
                    "Gas station/online 'enhancement' pills often contain hidden drugs",
                    "Herbal doesn't mean safe - many herbs have serious side effects",
                    "Supplement industry is poorly regulated"
                ],
                "warnings": [
                    "Hidden PDE5 inhibitors in supplements can cause heart problems",
                    "Never buy prescription drugs without prescription",
                    "Reference: FDA warnings on tainted sexual enhancement products"
                ]
            },
            {
                "stepNumber": 6,
                "title": "Step 6: Troubleshooting Common Problems",
                "description": "Common issues include lack of gains, discoloration, reduced sensitivity, and difficulty maintaining consistency. Most problems result from overtraining or poor technique. Solutions usually involve reducing intensity, improving technique, or taking breaks.",
                "tips": [
                    "No gains after 6 months: Reassess technique, try different exercises",
                    "Discoloration: Reduce intensity, ensure adequate rest",
                    "Lost sensitivity: Take 1-2 week break, reduce pressure",
                    "Can't stay consistent: Set smaller, achievable goals"
                ],
                "cautions": [
                    "Pushing through problems usually worsens them",
                    "Multiple issues simultaneously suggest overtraining",
                    "Ignoring warning signs leads to serious injury"
                ],
                "warnings": [
                    "Persistent numbness requires medical evaluation",
                    "Hard lumps or plaques need immediate assessment",
                    "Reference: Clinical guidelines on penile rehabilitation"
                ]
            },
            {
                "stepNumber": 7,
                "title": "Step 7: What's the Maximum Possible Gains?",
                "description": "Based on available evidence and conservative analysis of community data, maximum realistic gains appear to be 1.5-2 inches length and 0.75-1 inch girth over 2-3 years of dedicated training. Claims exceeding these ranges lack credible evidence and pursuing them is dangerous.",
                "tips": [
                    "Genetics determine individual maximum potential",
                    "Most gains occur in first 18 months",
                    "Diminishing returns after 2 years are typical",
                    "Maintenance becomes focus after reaching potential"
                ],
                "cautions": [
                    "Chasing unrealistic goals causes injury",
                    "Online claims often exaggerate or fabricate results",
                    "Photographic 'proof' is easily manipulated"
                ],
                "warnings": [
                    "Never pursue gains beyond tissue capacity",
                    "Accept biological limitations for safety",
                    "Reference: Lever et al. (2006) 'Does size matter?' Psychology of Men & Masculinity"
                ]
            },
            {
                "stepNumber": 8,
                "title": "Step 8: Should I Tell My Partner/Doctor?",
                "description": "Open communication with partners about PE can reduce relationship stress and unrealistic expectations. Discussing with healthcare providers ensures safety, especially if you have health conditions or experience problems. Shame and secrecy increase risk by preventing proper medical care when needed.",
                "tips": [
                    "Partners often care less about size than practitioners believe",
                    "Honesty prevents misunderstandings about changes",
                    "Urologists are increasingly aware of PE practices",
                    "Medical professionals maintain confidentiality"
                ],
                "cautions": [
                    "Hiding injuries delays necessary treatment",
                    "Partners may notice changes even if not discussed",
                    "Secrecy creates psychological stress"
                ],
                "warnings": [
                    "Never hide PE-related injuries from medical providers",
                    "Delayed treatment of injuries worsens outcomes",
                    "Reference: Veale et al. (2015) 'Am I normal? A systematic review' BJU Int"
                ]
            }
        ]
    })

    # 4. NUTRITION AND SUPPLEMENTATION GUIDE
    resources.append({
        "id": "nutrition_supplementation_guide",
        "title": "Nutrition & Supplementation for PE",
        "description": "Evidence-based nutritional strategies and supplement review for supporting tissue health and growth. Learn what actually helps versus marketing hype. MEDICAL DISCLAIMER: Consult healthcare providers before starting any supplement regimen.",
        "category": "education",
        "difficulty": "beginner",
        "estimatedDuration": 18,
        "equipmentNeeded": [],
        "steps": [
            {
                "stepNumber": 1,
                "title": "Step 1: Protein Requirements for Tissue Growth",
                "description": "Adequate protein intake is essential for tissue repair and growth. Collagen synthesis, smooth muscle hypertrophy, and cellular repair all require amino acids. While PE doesn't require bodybuilder-level protein, insufficient intake impairs recovery and growth.",
                "tips": [
                    "Aim for 0.8-1.2g protein per kg body weight daily",
                    "Complete proteins contain all essential amino acids",
                    "Collagen supplements may specifically support connective tissue",
                    "Spread protein intake throughout the day for optimal synthesis"
                ],
                "cautions": [
                    "Excessive protein doesn't accelerate PE gains",
                    "Plant-based diets require careful planning for complete proteins",
                    "Kidney disease requires protein restriction"
                ],
                "warnings": [
                    "Protein powders are supplements, not magic growth formulas",
                    "Never exceed 2g/kg without medical supervision",
                    "Reference: Phillips & Van Loon (2011) 'Dietary protein for athletes' J Sports Sci"
                ]
            },
            {
                "stepNumber": 2,
                "title": "Step 2: L-Arginine and Nitric Oxide Pathways",
                "description": "L-arginine is a precursor to nitric oxide (NO), a key vasodilator improving blood flow. Some studies suggest L-arginine supplementation may improve erectile function and support vascular health. However, effects on actual growth are unproven.",
                "tips": [
                    "Typical dose: 3-6g daily, divided into multiple doses",
                    "L-citrulline may be more effective (converts to L-arginine)",
                    "Take on empty stomach for better absorption",
                    "Natural sources: nuts, seeds, meat, dairy"
                ],
                "cautions": [
                    "Can cause GI upset, diarrhea at high doses",
                    "May interact with blood pressure medications",
                    "Effects diminish with continuous use"
                ],
                "warnings": [
                    "Avoid if you have herpes - may trigger outbreaks",
                    "Don't combine with ED medications without medical consultation",
                    "Reference: Rhim et al. (2019) 'Effect of L-arginine on erectile function' Sex Med Rev"
                ]
            },
            {
                "stepNumber": 3,
                "title": "Step 3: Vitamin D and Hormonal Health",
                "description": "Vitamin D plays crucial roles in testosterone production, vascular function, and tissue health. Deficiency is common and associated with erectile dysfunction. While not directly causing growth, optimal levels support overall penile health and function.",
                "tips": [
                    "Get tested - optimal levels are 30-50 ng/mL",
                    "Daily requirement: 600-800 IU minimum, more if deficient",
                    "D3 (cholecalciferol) superior to D2",
                    "Sun exposure provides natural vitamin D"
                ],
                "cautions": [
                    "Fat-soluble vitamin - can accumulate to toxic levels",
                    "Requires fat for absorption - take with meals",
                    "Dark skin requires more sun exposure for synthesis"
                ],
                "warnings": [
                    "Don't exceed 4000 IU daily without testing",
                    "Hypercalcemia risk with excessive supplementation",
                    "Reference: Crafa et al. (2020) 'Vitamin D and sexual dysfunction' Int J Mol Sci"
                ]
            },
            {
                "stepNumber": 4,
                "title": "Step 4: Zinc and Testosterone Support",
                "description": "Zinc is essential for testosterone production, immune function, and protein synthesis. Deficiency impairs wound healing and may affect sexual function. While zinc won't directly cause growth, adequate levels support optimal hormonal environment for training response.",
                "tips": [
                    "RDA: 11mg for men, don't exceed 40mg daily",
                    "Best absorbed from animal sources (oysters highest)",
                    "Take separately from iron and calcium supplements",
                    "Zinc picolinate or citrate well absorbed"
                ],
                "cautions": [
                    "Excess zinc interferes with copper absorption",
                    "Can cause nausea on empty stomach",
                    "Long-term high doses suppress immune function"
                ],
                "warnings": [
                    "Never exceed 40mg daily without medical supervision",
                    "Zinc toxicity causes severe GI symptoms",
                    "Reference: Prasad (2013) 'Discovery of zinc in human nutrition' Adv Nutr"
                ]
            },
            {
                "stepNumber": 5,
                "title": "Step 5: Hydration and Blood Flow",
                "description": "Proper hydration is fundamental for blood flow, nutrient transport, and tissue health. Dehydration reduces blood volume, impairs erection quality, and slows recovery. Water is more important than any supplement for PE success.",
                "tips": [
                    "Minimum 2-3 liters water daily, more if active",
                    "Urine should be pale yellow, not dark or clear",
                    "Hydrate before, during, and after PE sessions",
                    "Electrolytes important if sweating significantly"
                ],
                "cautions": [
                    "Overhydration dilutes electrolytes",
                    "Caffeine and alcohol are diuretics",
                    "Thirst is a late indicator of dehydration"
                ],
                "warnings": [
                    "Severe dehydration impairs tissue recovery",
                    "Never restrict water for temporary size appearance",
                    "Reference: Armstrong (2007) 'Assessing hydration status' Curr Sports Med Rep"
                ]
            },
            {
                "stepNumber": 6,
                "title": "Step 6: Anti-Inflammatory Considerations",
                "description": "While some inflammation triggers growth, chronic excessive inflammation impairs healing. Omega-3 fatty acids, found in fish oil, have anti-inflammatory properties that may support recovery. However, completely blocking inflammation may impede adaptation.",
                "tips": [
                    "EPA/DHA 1-3g daily from fish oil may help",
                    "Natural sources: fatty fish, walnuts, flax seeds",
                    "Curcumin (turmeric) has anti-inflammatory properties",
                    "Balance is key - some inflammation needed for growth"
                ],
                "cautions": [
                    "High doses increase bleeding risk",
                    "May interact with blood thinners",
                    "Quality varies - choose third-party tested brands"
                ],
                "warnings": [
                    "Don't take NSAIDs regularly - may impair growth",
                    "Never exceed recommended doses",
                    "Reference: Calder (2013) 'Omega-3 fatty acids and inflammatory processes' Nutrients"
                ]
            },
            {
                "stepNumber": 7,
                "title": "Step 7: What Doesn't Work - Supplement Myths",
                "description": "Many supplements marketed for PE have no evidence of efficacy. Tribulus, horny goat weed, maca, and ginseng may affect libido but don't cause growth. 'Testosterone boosters' rarely significantly increase testosterone. Save money by avoiding unproven supplements.",
                "tips": [
                    "No oral supplement directly causes penile growth",
                    "Herbal doesn't mean effective or safe",
                    "Marketing exploits insecurity with false claims",
                    "Focus on proven basics: protein, vitamins, hydration"
                ],
                "cautions": [
                    "Proprietary blends hide actual ingredients/doses",
                    "Contamination with unlisted drugs is common",
                    "Placebo effect makes people think they work"
                ],
                "warnings": [
                    "Gas station 'enhancement' pills often contain hidden drugs",
                    "Never trust before/after photos in ads",
                    "Reference: FDA database of tainted supplements"
                ]
            },
            {
                "stepNumber": 8,
                "title": "Step 8: Lifestyle Factors More Important Than Supplements",
                "description": "Sleep, exercise, stress management, and avoiding smoking/excess alcohol have greater impact than any supplement. These lifestyle factors affect hormones, blood flow, and recovery capacity. Optimize basics before spending on supplements.",
                "tips": [
                    "7-9 hours quality sleep essential for growth hormone release",
                    "Regular cardio improves penile vascular health",
                    "Stress increases cortisol, impairs testosterone",
                    "Smoking severely impairs blood flow and healing"
                ],
                "cautions": [
                    "Poor lifestyle nullifies any supplement benefits",
                    "Quick fixes don't exist - consistency matters",
                    "Supplements can't compensate for unhealthy habits"
                ],
                "warnings": [
                    "Smoking is the worst thing for penile health",
                    "Excessive alcohol impairs testosterone and recovery",
                    "Reference: Yafi et al. (2016) 'Erectile dysfunction' Nat Rev Dis Primers"
                ]
            }
        ]
    })

    # 5. MEASUREMENT AND TRACKING GUIDE
    resources.append({
        "id": "measurement_tracking_guide",
        "title": "Accurate Measurement & Progress Tracking",
        "description": "Learn proper measurement techniques, understand normal variations, and track progress scientifically. Accurate measurement prevents false disappointment and documents real gains. MEDICAL DISCLAIMER: This is for educational tracking only.",
        "category": "education",
        "difficulty": "beginner",
        "estimatedDuration": 12,
        "equipmentNeeded": [],
        "steps": [
            {
                "stepNumber": 1,
                "title": "Step 1: BPEL - Bone Pressed Erect Length",
                "description": "BPEL is the standard measurement for tracking length gains. Measured from pubic bone to tip, pressing ruler through fat pad for consistency. This eliminates weight fluctuation variables and provides reproducible results. Most studies use BPEL or similar bone-pressed measurements.",
                "tips": [
                    "Use rigid ruler, not tape measure",
                    "Press firmly into pubic bone at penis base",
                    "Measure along top (dorsal) side to tip",
                    "Maintain consistent erection level (80-100%)"
                ],
                "cautions": [
                    "Don't press so hard it hurts - consistent moderate pressure",
                    "Curved penis: measure straight line or use string then measure",
                    "Time of day affects erection quality and measurements"
                ],
                "warnings": [
                    "Never forcefully straighten curved penis for measurement",
                    "Inconsistent technique gives false results",
                    "Reference: Wessells et al. (1996) 'Penile length measurements' J Urol"
                ]
            },
            {
                "stepNumber": 2,
                "title": "Step 2: NBPEL and Other Length Measurements",
                "description": "Non-bone pressed erect length (NBPEL) measures visible length without pressing. Bone pressed flaccid (BPFL) and stretched flaccid (BPFSL) provide additional data points. Multiple measurements give comprehensive picture of changes.",
                "tips": [
                    "NBPEL shows 'usable' length",
                    "BPFSL often correlates with BPEL",
                    "Flaccid varies greatly with temperature, arousal, activity",
                    "Track multiple metrics for complete picture"
                ],
                "cautions": [
                    "Flaccid measurements highly variable",
                    "Don't overstretch when measuring BPFSL",
                    "Weight loss/gain significantly affects NBPEL"
                ],
                "warnings": [
                    "Never stretch to pain when measuring",
                    "Obsessive measuring causes psychological stress",
                    "Reference: Veale et al. (2015) 'Systematic review of penile size' BJU Int"
                ]
            },
            {
                "stepNumber": 3,
                "title": "Step 3: Measuring Girth - EG and Base Girth",
                "description": "Girth typically measured at mid-shaft (EG - erect girth) and base. Use tailors tape or string around circumference, then measure string against ruler. Consistency in measurement location is crucial as girth varies along shaft.",
                "tips": [
                    "Mark measurement points for consistency",
                    "Mid-shaft usually means halfway point",
                    "Don't pull tape too tight - snug but not compressing",
                    "Measure at same arousal level each time"
                ],
                "cautions": [
                    "Girth varies significantly along shaft",
                    "Temporary expansion from edema isn't real gain",
                    "Post-workout measurements are inflated"
                ],
                "warnings": [
                    "Don't measure immediately after PE - temporary swelling",
                    "Tourniquet-like tightness damages tissue",
                    "Reference: Clinical measurement standards in urology"
                ]
            },
            {
                "stepNumber": 4,
                "title": "Step 4: Measurement Frequency and Timing",
                "description": "Monthly measurement is optimal - frequent enough to track progress but not so often that normal variations cause confusion. Measure at consistent time of day, arousal level, and conditions. Document everything for accurate comparison.",
                "tips": [
                    "Measure monthly on same date",
                    "Morning measurements often most consistent",
                    "Wait 48 hours after PE sessions",
                    "Use same room temperature if possible"
                ],
                "cautions": [
                    "Daily measuring shows false variations",
                    "Post-PE measurements are temporarily inflated",
                    "Stress, fatigue, alcohol affect measurements"
                ],
                "warnings": [
                    "Obsessive measuring indicates unhealthy fixation",
                    "Never measure during injury recovery",
                    "Reference: Mondaini et al. (2002) 'Penile length is normal' Eur Urol"
                ]
            },
            {
                "stepNumber": 5,
                "title": "Step 5: Understanding Normal Variations",
                "description": "Erection quality, temperature, arousal, time of day, and recent sexual activity all affect measurements. Variations of ±0.25 inches are normal day-to-day. Understanding variability prevents false disappointment or premature celebration.",
                "tips": [
                    "EQ significantly affects apparent size",
                    "Cold causes significant shrinkage",
                    "Hydration status affects erection fullness",
                    "Recent ejaculation may reduce size temporarily"
                ],
                "cautions": [
                    "Single measurements don't indicate gains/losses",
                    "Look for trends over months, not days",
                    "Psychological state affects erection quality"
                ],
                "warnings": [
                    "Don't change routine based on single measurement",
                    "Temporary losses usually just normal variation",
                    "Reference: Studies on penile hemodynamics and size variation"
                ]
            },
            {
                "stepNumber": 6,
                "title": "Step 6: Photo Documentation Best Practices",
                "description": "Consistent photos provide visual progress tracking. Use same angle, lighting, distance, and arousal level. Include ruler in frame for reference. Never share identifying photos online. Store securely and encrypted.",
                "tips": [
                    "Use timer or tripod for consistency",
                    "Same angle, lighting, distance every time",
                    "Include ruler for scale reference",
                    "Grid background helps show proportions"
                ],
                "cautions": [
                    "Angles dramatically affect apparent size",
                    "Never include face or identifying features",
                    "Lighting can create illusions"
                ],
                "warnings": [
                    "Protect privacy - photos can be compromising",
                    "Never share on public forums",
                    "Reference: Clinical photography standards in medicine"
                ]
            },
            {
                "stepNumber": 7,
                "title": "Step 7: Statistical Significance of Gains",
                "description": "Understanding what constitutes real change versus measurement error is crucial. Generally, length changes ≥0.25 inches and girth changes ≥0.125 inches exceed typical measurement error. Multiple consistent measurements confirm real gains.",
                "tips": [
                    "Changes <0.25\" length may be measurement error",
                    "Girth changes <0.125\" within error margin",
                    "Three consistent measurements confirm change",
                    "Statistical significance ≠ visually noticeable"
                ],
                "cautions": [
                    "Small gains may be real but not visible",
                    "Measurement error can mask or exaggerate gains",
                    "Partner perception doesn't always match measurements"
                ],
                "warnings": [
                    "Don't claim gains within measurement error margin",
                    "Be honest about progress for safety",
                    "Reference: Statistical analysis in clinical measurements"
                ]
            },
            {
                "stepNumber": 8,
                "title": "Step 8: Progress Tracking Tools and Logs",
                "description": "Detailed logs help identify patterns, optimal routines, and potential problems. Track measurements, routine details, rest days, and any issues. Spreadsheets, apps, or notebooks all work. Consistency in documentation is key.",
                "tips": [
                    "Log date, measurements, routine, duration, intensity",
                    "Note any discomfort, discoloration, numbness",
                    "Track EQ changes and sexual function",
                    "Graph progress to visualize trends"
                ],
                "cautions": [
                    "Don't share logs with identifying information",
                    "Obsessive tracking can indicate unhealthy fixation",
                    "Missing data makes pattern recognition difficult"
                ],
                "warnings": [
                    "Never falsify data - honest tracking ensures safety",
                    "Share concerning patterns with healthcare provider",
                    "Reference: Clinical outcome measurement best practices"
                ]
            }
        ]
    })

    # 6. LIFESTYLE FACTORS GUIDE
    resources.append({
        "id": "lifestyle_factors_guide",
        "title": "Lifestyle Optimization for PE Success",
        "description": "Comprehensive guide to sleep, exercise, stress management, and habits that support or hinder PE progress. Lifestyle factors often matter more than specific techniques. MEDICAL DISCLAIMER: General health information only - consult healthcare providers for personal advice.",
        "category": "education",
        "difficulty": "beginner",
        "estimatedDuration": 22,
        "equipmentNeeded": [],
        "steps": [
            {
                "stepNumber": 1,
                "title": "Step 1: Sleep - The Foundation of Recovery",
                "description": "Quality sleep is when tissue repair, growth hormone release, and testosterone production peak. Poor sleep impairs recovery, reduces gains, and increases injury risk. 7-9 hours of quality sleep optimizes growth potential and sexual function.",
                "tips": [
                    "Growth hormone peaks during deep sleep (stages 3-4)",
                    "Testosterone production occurs primarily during REM sleep",
                    "Consistent sleep schedule optimizes hormonal rhythms",
                    "Cool, dark room improves sleep quality"
                ],
                "cautions": [
                    "Sleep deprivation increases cortisol, impairs recovery",
                    "Sleep apnea severely impacts erectile function",
                    "Irregular sleep disrupts hormonal balance"
                ],
                "warnings": [
                    "Chronic sleep deprivation (<6 hours) impairs all aspects of health",
                    "Never sacrifice sleep for extra training",
                    "Reference: Leproult & Van Cauter (2011) 'Effect of sleep restriction on testosterone' JAMA"
                ]
            },
            {
                "stepNumber": 2,
                "title": "Step 2: Cardiovascular Exercise and Penile Health",
                "description": "Cardiovascular fitness directly correlates with erectile function and penile health. Regular cardio improves blood flow, enhances nitric oxide production, and supports angiogenesis. Better cardiovascular health means better PE response and results.",
                "tips": [
                    "150 minutes moderate cardio weekly minimum",
                    "HIIT training boosts growth hormone and testosterone",
                    "Swimming, cycling, running all beneficial",
                    "Improved cardio often improves EQ before size gains"
                ],
                "cautions": [
                    "Excessive endurance training can lower testosterone",
                    "Cycling requires proper saddle to avoid nerve compression",
                    "Start gradually if sedentary"
                ],
                "warnings": [
                    "Sedentary lifestyle major risk factor for ED",
                    "Consult doctor before starting exercise if health conditions",
                    "Reference: Lamina et al. (2009) 'Therapeutic effect of exercise on erectile function' Asian J Androl"
                ]
            },
            {
                "stepNumber": 3,
                "title": "Step 3: Stress Management and Cortisol",
                "description": "Chronic stress elevates cortisol, which suppresses testosterone, impairs recovery, and reduces sexual function. Stress management through meditation, exercise, or therapy optimizes hormonal environment for growth. Mental health directly impacts PE success.",
                "tips": [
                    "Meditation 10-20 minutes daily reduces cortisol",
                    "Regular exercise is powerful stress management",
                    "Deep breathing activates parasympathetic nervous system",
                    "Social connections reduce stress hormones"
                ],
                "cautions": [
                    "PE itself can become source of stress if obsessive",
                    "Relationship stress particularly impacts sexual function",
                    "Financial/work stress affects all health aspects"
                ],
                "warnings": [
                    "Chronic stress is incompatible with optimal PE results",
                    "Depression/anxiety require professional treatment",
                    "Reference: Kruger & Schiffer (2011) 'Sexual dysfunction in depression' Adv Psychosom Med"
                ]
            },
            {
                "stepNumber": 4,
                "title": "Step 4: The Catastrophic Effects of Smoking",
                "description": "Smoking is the single worst lifestyle factor for penile health. It damages blood vessels, reduces nitric oxide, impairs healing, and may cause permanent erectile dysfunction. Nicotine constricts penile arteries within minutes of smoking.",
                "tips": [
                    "Quitting smoking improves EQ within weeks",
                    "Vaping still delivers vessel-damaging nicotine",
                    "Secondhand smoke also impacts vascular health",
                    "Support groups/medications help quitting"
                ],
                "cautions": [
                    "Smoking negates any PE efforts",
                    "Damage accumulates with pack-years",
                    "Young smokers still experience vascular damage"
                ],
                "warnings": [
                    "Smoking can cause permanent ED by age 40",
                    "Penile arterial damage may be irreversible",
                    "Reference: Kovac et al. (2015) 'Effects of cigarette smoking on erectile dysfunction' Andrology"
                ]
            },
            {
                "stepNumber": 5,
                "title": "Step 5: Alcohol and Substance Considerations",
                "description": "Moderate alcohol may have minimal impact, but excessive drinking impairs testosterone production, reduces sleep quality, and causes dehydration. Recreational drugs, particularly stimulants, can severely impact erectile function and recovery.",
                "tips": [
                    "Limit to 1-2 drinks maximum on training days",
                    "Hydrate extra when consuming alcohol",
                    "Red wine in moderation may support vascular health",
                    "Cannabis effects on PE are unstudied but likely minimal"
                ],
                "cautions": [
                    "Binge drinking severely suppresses testosterone",
                    "Chronic alcohol use causes testicular atrophy",
                    "Stimulants (cocaine, amphetamines) damage penile tissue"
                ],
                "warnings": [
                    "Alcohol + PE exercises increases injury risk",
                    "Never train while intoxicated",
                    "Reference: Sarkola & Eriksson (2003) 'Testosterone secretion after alcohol' Alcohol Clin Exp Res"
                ]
            },
            {
                "stepNumber": 6,
                "title": "Step 6: Body Weight and Metabolic Health",
                "description": "Obesity reduces testosterone, impairs blood flow, and creates insulin resistance - all detrimental to PE success. The fat pad also buries penis length. Even modest weight loss improves hormones and reveals hidden length. Metabolic health equals penile health.",
                "tips": [
                    "Every 35-50 lbs lost reveals ~1 inch visual length",
                    "Weight loss improves testosterone and blood flow",
                    "Mediterranean diet supports vascular health",
                    "Intermittent fasting may boost growth hormone"
                ],
                "cautions": [
                    "Crash dieting impairs recovery and hormones",
                    "Very low body fat also reduces testosterone",
                    "Weight fluctuations affect measurements"
                ],
                "warnings": [
                    "Obesity is major ED risk factor",
                    "Diabetes severely impacts penile health",
                    "Reference: Corona et al. (2014) 'Obesity and sexual dysfunction' Nat Rev Urol"
                ]
            },
            {
                "stepNumber": 7,
                "title": "Step 7: Psychological Factors and Realistic Expectations",
                "description": "Mental health profoundly impacts PE journey. Body dysmorphia, unrealistic expectations, and obsessive behavior are common. Healthy mindset viewing PE as general self-improvement rather than fixing inadequacy leads to better outcomes and life satisfaction.",
                "tips": [
                    "Set process goals, not just outcome goals",
                    "Average size is smaller than most believe (5.1-5.5\" BPEL)",
                    "Partner satisfaction poorly correlates with size",
                    "Therapy helps address underlying insecurities"
                ],
                "cautions": [
                    "PE can become compulsive behavior",
                    "Social media/porn creates unrealistic expectations",
                    "Comparison with others breeds dissatisfaction"
                ],
                "warnings": [
                    "Body dysmorphic disorder requires professional help",
                    "Suicidal ideation needs immediate intervention",
                    "Reference: Veale et al. (2015) 'Penile dysmorphic disorder' Body Image"
                ]
            },
            {
                "stepNumber": 8,
                "title": "Step 8: Quick Gain Myths and Patience",
                "description": "The internet proliferates myths about rapid gains through 'one weird trick' or secret techniques. Real growth requires months to years of consistent, moderate effort. Understanding realistic timelines prevents dangerous overtraining and maintains motivation through plateaus.",
                "tips": [
                    "Real growth follows logarithmic curve - fast initially, then slower",
                    "Plateaus are normal and necessary adaptation periods",
                    "Most abandon PE before seeing results (3-6 months)",
                    "Consistency beats intensity for long-term success"
                ],
                "cautions": [
                    "Dramatic intensity increases cause injury, not breakthrough",
                    "Marketing exploits impatience with false promises",
                    "Temporary gains from edema aren't permanent growth"
                ],
                "warnings": [
                    "'Gain 3 inches in 3 weeks' claims are dangerous lies",
                    "Patience prevents permanent injury",
                    "Reference: Gontero et al. (2009) 'Systematic review of penile elongation' BJU Int"
                ]
            }
        ]
    })

    return resources

def upload_resource(resource: Dict, token: str) -> bool:
    """Upload a single educational resource to Firebase"""
    url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents/{COLLECTION}/{resource['id']}"

    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }

    # Convert to Firestore format
    firestore_doc = {
        "fields": {
            "id": {"stringValue": resource["id"]},
            "title": {"stringValue": resource["title"]},
            "description": {"stringValue": resource["description"]},
            "category": {"stringValue": resource["category"]},
            "difficulty": {"stringValue": resource["difficulty"]},
            "estimatedDuration": {"integerValue": str(resource["estimatedDuration"])},
            "equipmentNeeded": {
                "arrayValue": {
                    "values": [{"stringValue": item} for item in resource["equipmentNeeded"]]
                }
            },
            "steps": {
                "arrayValue": {
                    "values": [
                        {
                            "mapValue": {
                                "fields": {
                                    "stepNumber": {"integerValue": str(step["stepNumber"])},
                                    "title": {"stringValue": step["title"]},
                                    "description": {"stringValue": step["description"]},
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
                                            "values": [{"stringValue": warning} for warning in step["warnings"]]
                                        }
                                    }
                                }
                            }
                        }
                        for step in resource["steps"]
                    ]
                }
            }
        }
    }

    # Try PATCH first (update), then POST if doesn't exist
    response = requests.patch(url, json=firestore_doc, headers=headers)

    if response.status_code == 404:
        # Document doesn't exist, create it
        parent_url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents/{COLLECTION}"
        response = requests.post(
            parent_url,
            json=firestore_doc,
            headers=headers,
            params={"documentId": resource["id"]}
        )

    return response.status_code in [200, 201]

def main():
    print("🎓 Educational Resources Upload Script")
    print("=" * 50)
    print()

    # Get auth token
    print("🔐 Getting authentication token...")
    token = get_firebase_token()
    print("✅ Authenticated")
    print()

    # Get all educational resources
    print("📚 Loading educational resources...")
    resources = get_educational_resources()
    print(f"✅ Loaded {len(resources)} educational resources")
    print()

    # List resources to be uploaded
    print("📋 Resources to upload:")
    for i, resource in enumerate(resources, 1):
        print(f"  {i}. {resource['title']} ({resource['estimatedDuration']} min)")
    print()

    # Upload resources
    print("📤 Uploading to Firebase...")
    print("-" * 50)

    success_count = 0
    for resource in resources:
        print(f"Uploading: {resource['title']}...")
        if upload_resource(resource, token):
            print(f"  ✅ Success: {resource['id']}")
            success_count += 1
        else:
            print(f"  ❌ Failed: {resource['id']}")

    print()
    print("=" * 50)
    print(f"📊 Upload Summary:")
    print(f"  ✅ Successful: {success_count}/{len(resources)}")
    print(f"  ❌ Failed: {len(resources) - success_count}/{len(resources)}")

    if success_count == len(resources):
        print()
        print("🎉 All educational resources successfully uploaded!")
        print("✅ Story 2.8 content implementation complete")
    else:
        print()
        print("⚠️  Some uploads failed. Please review and retry.")
        sys.exit(1)

if __name__ == "__main__":
    main()