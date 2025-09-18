//
//  TimerAction.swift
//  GrowthTimerWidget
//
//  Simple timer action enum with AppIntents support
//

import Foundation
import AppIntents

@available(iOS 16.1, *)
public enum TimerAction: String, Codable, Sendable, CaseIterable, AppEnum {
    case pause = "pause"
    case resume = "resume"
    case stop = "stop"
    
    public static var typeDisplayRepresentation: TypeDisplayRepresentation = "Timer Action"
    
    public static var caseDisplayRepresentations: [TimerAction : DisplayRepresentation] = [
        .pause: "Pause",
        .resume: "Resume",
        .stop: "Stop"
    ]
}