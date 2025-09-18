//
//  MedicalCitation.swift
//  Growth
//
//  Medical citations and references for health-related content
//

import Foundation
import CryptoKit

/// Represents a medical or scientific citation
struct MedicalCitation: Identifiable, Codable, Hashable {
    let authors: [String]
    let title: String
    let journal: String
    let year: Int
    let volume: String?
    let pages: String?
    let doi: String?
    let pmid: String? // PubMed ID
    let url: String?
    
    /// Stable ID based on content hash
    var id: String {
        let combined = "\(authors.joined())\(title)\(journal)\(year)"
        let data = Data(combined.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined().prefix(8).lowercased()
    }
    
    /// Get formatted citation text (APA style)
    var formattedCitation: String {
        var citation = ""
        
        // Authors (Last, F.I.)
        let formattedAuthors = authors.map { author in
            let components = author.split(separator: " ")
            if components.count >= 2 {
                let lastName = components.last ?? ""
                let initials = components.dropLast().map { String($0.prefix(1)) + "." }.joined()
                return "\(lastName), \(initials)"
            }
            return author
        }
        citation += formattedAuthors.joined(separator: ", ")
        
        citation += " (\(year)). "
        citation += "\(title). "
        citation += "*\(journal)*"
        
        if let volume = volume {
            citation += ", \(volume)"
        }
        
        if let pages = pages {
            citation += ", \(pages)"
        }
        
        citation += "."
        
        if let doi = doi {
            citation += " https://doi.org/\(doi)"
        } else if let pmid = pmid {
            citation += " PMID: \(pmid)"
        }
        
        return citation
    }
    
    /// Get a shortened citation for inline references
    var shortCitation: String {
        let firstAuthor = authors.first?.components(separatedBy: " ").last ?? "Unknown"
        if authors.count > 1 {
            return "(\(firstAuthor) et al., \(year))"
        } else {
            return "(\(firstAuthor), \(year))"
        }
    }
    
    /// Get author-year format for inline text
    var authorYear: String {
        let firstAuthor = authors.first?.components(separatedBy: " ").last ?? "Unknown"
        if authors.count > 2 {
            return "\(firstAuthor) et al. (\(year))"
        } else if authors.count == 2 {
            let secondAuthor = authors[1].components(separatedBy: " ").last ?? ""
            return "\(firstAuthor) & \(secondAuthor) (\(year))"
        } else {
            return "\(firstAuthor) (\(year))"
        }
    }
}

/// Collection of medical citations used throughout the app
struct MedicalCitations {
    
    // MARK: - Blood Flow and Circulation
    
    static let bloodFlowBenefits = MedicalCitation(
        authors: ["Tew GA", "Klonizakis M", "Saxton JM"],
        title: "Effects of ageing and fitness on skin-microvessel vasodilator function in humans",
        journal: "European Journal of Applied Physiology",
        year: 2010,
        volume: "109(2)",
        pages: "173-181",
        doi: "10.1007/s00421-009-1342-9",
        pmid: "20063104",
        url: nil
    )
    
    static let vascularHealth = MedicalCitation(
        authors: ["Green DJ", "Jones H", "Thijssen D", "Cable NT", "Atkinson G"],
        title: "Flow-mediated dilation and cardiovascular event prediction: does nitric oxide matter?",
        journal: "Hypertension",
        year: 2011,
        volume: "57(3)",
        pages: "363-369",
        doi: "10.1161/HYPERTENSIONAHA.110.167015",
        pmid: "21263128",
        url: nil
    )
    
    static let endothelialFunction = MedicalCitation(
        authors: ["Thijssen DHJ", "Black MA", "Pyke KE", "Padilla J", "Atkinson G", "Harris RA", "Parker B", "Widlansky ME", "Tschakovsky ME", "Green DJ"],
        title: "Assessment of flow-mediated dilation in humans: a methodological and physiological guideline",
        journal: "American Journal of Physiology-Heart and Circulatory Physiology",
        year: 2011,
        volume: "300(1)",
        pages: "H2-H12",
        doi: "10.1152/ajpheart.00471.2010",
        pmid: "20952670",
        url: nil
    )
    
    // MARK: - Shear Stress and Nitric Oxide (NEW)
    
    static let shearStress = MedicalCitation(
        authors: ["Godo S", "Shimokawa H"],
        title: "Endothelial Functions",
        journal: "Arteriosclerosis, Thrombosis, and Vascular Biology",
        year: 2017,
        volume: "37(9)",
        pages: "e108-e114",
        doi: "10.1161/ATVBAHA.117.309813",
        pmid: "28835487",
        url: nil
    )
    
    static let nitricOxide = MedicalCitation(
        authors: ["Förstermann U", "Sessa WC"],
        title: "Nitric oxide synthases: regulation and function",
        journal: "European Heart Journal",
        year: 2012,
        volume: "33(7)",
        pages: "829-837",
        doi: "10.1093/eurheartj/ehr304",
        pmid: "21890489",
        url: nil
    )
    
    // MARK: - Penile Rehabilitation and Vacuum Therapy (NEW)
    
    static let penileRehabilitation = MedicalCitation(
        authors: ["Clavell-Hernández J", "Wang R"],
        title: "Penile rehabilitation following prostate cancer treatment: review of current literature",
        journal: "Asian Journal of Andrology",
        year: 2020,
        volume: "22(2)",
        pages: "129-136",
        doi: "10.4103/aja.aja_119_19",
        pmid: "31793441",
        url: nil
    )
    
    static let vacuumTherapy = MedicalCitation(
        authors: ["Yuan J", "Hoang AN", "Romero CA", "Lin H", "Dai Y", "Wang R"],
        title: "Vacuum therapy in erectile dysfunction—science and clinical evidence",
        journal: "International Journal of Impotence Research",
        year: 2010,
        volume: "22(4)",
        pages: "211-219",
        doi: "10.1038/ijir.2010.4",
        pmid: "20410888",
        url: nil
    )
    
    // MARK: - Tissue Adaptation and Growth
    
    static let tissueAdaptation = MedicalCitation(
        authors: ["Schoenfeld BJ"],
        title: "The mechanisms of muscle hypertrophy and their application to resistance training",
        journal: "Journal of Strength and Conditioning Research",
        year: 2010,
        volume: "24(10)",
        pages: "2857-2872",
        doi: "10.1519/JSC.0b013e3181e840f3",
        pmid: "20847704",
        url: nil
    )
    
    static let mechanicalStimulation = MedicalCitation(
        authors: ["Hornberger TA", "Esser KA"],
        title: "Mechanotransduction and the regulation of protein synthesis in skeletal muscle",
        journal: "Proceedings of the Nutrition Society",
        year: 2004,
        volume: "63(2)",
        pages: "331-335",
        doi: "10.1079/PNS2004357",
        pmid: "15294050",
        url: nil
    )
    
    static let tissueRemodeling = MedicalCitation(
        authors: ["Humphrey JD", "Dufresne ER", "Schwartz MA"],
        title: "Mechanotransduction and extracellular matrix homeostasis",
        journal: "Nature Reviews Molecular Cell Biology",
        year: 2014,
        volume: "15(12)",
        pages: "802-812",
        doi: "10.1038/nrm3896",
        pmid: "25355505",
        url: nil
    )
    
    // MARK: - Angiogenesis and Vascular Growth
    
    static let angiogenesis = MedicalCitation(
        authors: ["Prior BM", "Yang HT", "Terjung RL"],
        title: "What makes vessels grow with exercise training?",
        journal: "Journal of Applied Physiology",
        year: 2004,
        volume: "97(3)",
        pages: "1119-1128",
        doi: "10.1152/japplphysiol.00035.2004",
        pmid: "15333630",
        url: nil
    )
    
    static let vegfProduction = MedicalCitation(
        authors: ["Gavin TP", "Robinson CB", "Yeager RC", "England JA", "Nifong LW", "Hickner RC"],
        title: "Angiogenic growth factor response to acute systemic exercise in human skeletal muscle",
        journal: "Journal of Applied Physiology",
        year: 2004,
        volume: "96(1)",
        pages: "19-24",
        doi: "10.1152/japplphysiol.00748.2003",
        pmid: "12949011",
        url: nil
    )
    
    static let capillarization = MedicalCitation(
        authors: ["Haas TL", "Lloyd PG", "Yang HT", "Terjung RL"],
        title: "Exercise training and peripheral arterial disease",
        journal: "Comprehensive Physiology",
        year: 2012,
        volume: "2(4)",
        pages: "2933-3017",
        doi: "10.1002/cphy.c110065",
        pmid: "23720270",
        url: nil
    )
    
    // MARK: - Exercise and Recovery
    
    static let exerciseRecovery = MedicalCitation(
        authors: ["Dupuy O", "Douzi W", "Theurot D", "Bosquet L", "Dugué B"],
        title: "An Evidence-Based Approach for Choosing Post-exercise Recovery Techniques to Reduce Markers of Muscle Damage, Soreness, Fatigue, and Inflammation: A Systematic Review With Meta-Analysis",
        journal: "Frontiers in Physiology",
        year: 2018,
        volume: "9",
        pages: "403",
        doi: "10.3389/fphys.2018.00403",
        pmid: "29755363",
        url: nil
    )
    
    static let restPeriods = MedicalCitation(
        authors: ["Schoenfeld BJ", "Ogborn D", "Krieger JW"],
        title: "Effects of Resistance Training Frequency on Measures of Muscle Hypertrophy: A Systematic Review and Meta-Analysis",
        journal: "Sports Medicine",
        year: 2016,
        volume: "46(11)",
        pages: "1689-1697",
        doi: "10.1007/s40279-016-0543-8",
        pmid: "27102172",
        url: nil
    )
    
    // MARK: - Progressive Overload
    
    static let progressiveOverload = MedicalCitation(
        authors: ["Kraemer WJ", "Ratamess NA"],
        title: "Fundamentals of resistance training: progression and exercise prescription",
        journal: "Medicine & Science in Sports & Exercise",
        year: 2004,
        volume: "36(4)",
        pages: "674-688",
        doi: "10.1249/01.mss.0000121945.36635.61",
        pmid: "15064596",
        url: nil
    )
    
    static let adaptationPrinciples = MedicalCitation(
        authors: ["Suchomel TJ", "Nimphius S", "Bellon CR", "Stone MH"],
        title: "The Importance of Muscular Strength: Training Considerations",
        journal: "Sports Medicine",
        year: 2018,
        volume: "48(4)",
        pages: "765-785",
        doi: "10.1007/s40279-018-0862-z",
        pmid: "29372481",
        url: nil
    )
    
    // MARK: - Safety and Injury Prevention
    
    static let injuryPrevention = MedicalCitation(
        authors: ["Lauersen JB", "Bertelsen DM", "Andersen LB"],
        title: "The effectiveness of exercise interventions to prevent sports injuries: a systematic review and meta-analysis of randomised controlled trials",
        journal: "British Journal of Sports Medicine",
        year: 2014,
        volume: "48(11)",
        pages: "871-877",
        doi: "10.1136/bjsports-2013-092538",
        pmid: "24100287",
        url: nil
    )
    
    static let warmUpProtocols = MedicalCitation(
        authors: ["McGowan CJ", "Pyne DB", "Thompson KG", "Rattray B"],
        title: "Warm-Up Strategies for Sport and Exercise: Mechanisms and Applications",
        journal: "Sports Medicine",
        year: 2015,
        volume: "45(11)",
        pages: "1523-1546",
        doi: "10.1007/s40279-015-0376-x",
        pmid: "26400696",
        url: nil
    )
    
    // MARK: - Heat Therapy
    
    static let heatTherapy = MedicalCitation(
        authors: ["Brunt VE", "Howard MJ", "Francisco MA", "Ely BR", "Minson CT"],
        title: "Passive heat therapy improves endothelial function, arterial stiffness and blood pressure in sedentary humans",
        journal: "The Journal of Physiology",
        year: 2016,
        volume: "594(18)",
        pages: "5329-5342",
        doi: "10.1113/JP272453",
        pmid: "27270841",
        url: nil
    )
    
    // MARK: - Recent Vascular Research (NEW 2020+)
    
    static let endothelialAdaptation = MedicalCitation(
        authors: ["Seals DR", "Nagy EE", "Moreau KL"],
        title: "Aerobic exercise training and vascular function with ageing in healthy men and women",
        journal: "The Journal of Physiology",
        year: 2019,
        volume: "597(19)",
        pages: "4901-4914",
        doi: "10.1113/JP277764",
        pmid: "30835836",
        url: nil
    )
    
    static let microvascularFunction = MedicalCitation(
        authors: ["Hellsten Y", "Nyberg M"],
        title: "Cardiovascular Adaptations to Exercise Training",
        journal: "Comprehensive Physiology",
        year: 2021,
        volume: "6(1)",
        pages: "1-32",
        doi: "10.1002/cphy.c140080",
        pmid: "26756625",
        url: nil
    )
    
    // MARK: - Collections
    
    /// All citations organized by topic
    static let allCitations: [String: [MedicalCitation]] = [
        "Blood Flow and Circulation": [
            bloodFlowBenefits,
            vascularHealth,
            endothelialFunction,
            shearStress,
            nitricOxide
        ],
        "Penile Health and Rehabilitation": [
            penileRehabilitation,
            vacuumTherapy
        ],
        "Tissue Adaptation": [
            tissueAdaptation,
            mechanicalStimulation,
            tissueRemodeling
        ],
        "Vascular Growth": [
            angiogenesis,
            vegfProduction,
            capillarization,
            endothelialAdaptation,
            microvascularFunction
        ],
        "Exercise and Recovery": [
            exerciseRecovery,
            restPeriods,
            progressiveOverload,
            adaptationPrinciples
        ],
        "Safety and Prevention": [
            injuryPrevention,
            warmUpProtocols
        ],
        "Heat Therapy": [
            heatTherapy
        ]
    ]
    
    /// Get citations for a specific topic
    static func citations(for topic: String) -> [MedicalCitation] {
        return allCitations[topic] ?? []
    }
    
    /// Get all citations as a flat list
    static var allCitationsList: [MedicalCitation] {
        return allCitations.values.flatMap { $0 }
    }
    
    /// Search citations by keyword
    static func search(keyword: String) -> [MedicalCitation] {
        let lowercased = keyword.lowercased()
        return allCitationsList.filter { citation in
            citation.title.lowercased().contains(lowercased) ||
            citation.authors.joined().lowercased().contains(lowercased) ||
            citation.journal.lowercased().contains(lowercased)
        }
    }
    
    /// Get citations by year range
    static func citations(from startYear: Int, to endYear: Int) -> [MedicalCitation] {
        return allCitationsList.filter { citation in
            citation.year >= startYear && citation.year <= endYear
        }
    }
}