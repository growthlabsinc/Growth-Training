//
//  DisclaimerVersion.swift
//  Growth
//
//  Created by Assistant on current date.
//

import Foundation

struct DisclaimerVersion: Codable {
    let version: String
    let effectiveDate: Date
    let content: String
    let requiresReacceptance: Bool
    
    init(version: String, effectiveDate: Date, content: String, requiresReacceptance: Bool = false) {
        self.version = version
        self.effectiveDate = effectiveDate
        self.content = content
        self.requiresReacceptance = requiresReacceptance
    }
    
    static let current = DisclaimerVersion(
        version: "1.1",
        effectiveDate: Date(),
        content: """
        MEDICAL DISCLAIMER & SCIENTIFIC BASIS
        
        The Growth app provides educational content based on peer-reviewed scientific research¹⁻⁵ related to vascular health and exercise techniques. This information is not medical advice and should not replace professional medical consultation.
        
        Our methods are based on established research including:
        • Flow-mediated dilation and vascular function (Green et al., 2011)¹
        • Endothelial adaptation through exercise (Thijssen et al., 2011)²
        • Tissue remodeling mechanisms (Humphrey et al., 2014)³
        • Exercise-induced angiogenesis (Prior et al., 2004)⁴
        • Heat therapy for vascular health (Brunt et al., 2016)⁵
        
        Before beginning any exercise program:
        • Consult with your healthcare provider
        • Ensure you have no underlying health conditions that would make these exercises unsafe
        • Stop immediately if you experience pain, discomfort, or other adverse symptoms
        • Review the scientific citations in Settings → Support → Scientific References
        
        WARNING: These techniques should not be used as treatment for any medical condition without proper medical supervision.
        
        By using this app, you acknowledge that:
        • You are participating at your own risk
        • You have consulted with a healthcare provider if you have any medical conditions
        • The app provides educational content only, not medical treatment
        """,
        requiresReacceptance: true
    )
}