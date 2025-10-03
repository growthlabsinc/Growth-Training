//
//  Logger.swift
//  Growth
//
//  Production-safe logging utility using Apple's unified logging system
//

import Foundation
import os.log
import FirebaseCrashlytics

/// Log levels for categorizing log messages
enum LogLevel: String {
    case verbose = "VERBOSE"
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    
    var emoji: String {
        switch self {
        case .verbose: return "🔍"
        case .debug: return "🐛"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        }
    }
    
    var osLogType: OSLogType {
        switch self {
        case .verbose, .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        }
    }
}

/// Module-specific logger instances using Apple's unified logging system
struct AppLoggers {
    static let general = os.Logger(subsystem: "com.growthlabs.growth", category: "General")
    static let timer = os.Logger(subsystem: "com.growthlabs.growth", category: "Timer")
    static let liveActivity = os.Logger(subsystem: "com.growthlabs.growth", category: "LiveActivity")
    static let aiCoach = os.Logger(subsystem: "com.growthlabs.growth", category: "AICoach")
    static let storeKit = os.Logger(subsystem: "com.growthlabs.growth", category: "StoreKit")
    static let ui = os.Logger(subsystem: "com.growthlabs.growth", category: "UI")
    static let network = os.Logger(subsystem: "com.growthlabs.growth", category: "Network")
    static let data = os.Logger(subsystem: "com.growthlabs.growth", category: "Data")
    static let auth = os.Logger(subsystem: "com.growthlabs.growth", category: "Auth")
}

/// Production-safe logger that uses Apple's unified logging system
struct Logger {
    
    /// Log a message with the specified level using os.log
    /// - Parameters:
    ///   - message: The message to log
    ///   - level: The severity level
    ///   - logger: The os.Logger instance to use (defaults to general)
    ///   - file: The file where the log was called
    ///   - function: The function where the log was called
    ///   - line: The line number where the log was called
    static func log(
        _ message: String,
        level: LogLevel = .info,
        logger: os.Logger = AppLoggers.general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let filename = (file as NSString).lastPathComponent
        
        // Use os.log for unified logging
        logger.log(level: level.osLogType, "\(level.emoji) [\(filename):\(line)] \(function) - \(message)")
        
        #if !DEBUG
        // In release builds, also log errors and warnings to Crashlytics for TestFlight debugging
        if level == .error || level == .warning {
            let logMessage = "\(level.rawValue) [\(filename):\(line)] \(function) - \(message)"
            Crashlytics.crashlytics().log(logMessage)
            
            // For errors, also record them as non-fatal issues
            if level == .error {
                let userInfo = [
                    NSLocalizedDescriptionKey: message,
                    "file": file,
                    "function": function,
                    "line": "\(line)"
                ]
                let error = NSError(domain: "com.growthlabs.growthmethod.logger", code: 0, userInfo: userInfo)
                Crashlytics.crashlytics().record(error: error)
            }
        }
        #endif
    }
    
    /// Log verbose message (only in debug)
    static func verbose(_ message: String, logger: os.Logger = AppLoggers.general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .verbose, logger: logger, file: file, function: function, line: line)
    }
    
    /// Log debug message (only in debug)
    static func debug(_ message: String, logger: os.Logger = AppLoggers.general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, logger: logger, file: file, function: function, line: line)
    }
    
    /// Log info message
    static func info(_ message: String, logger: os.Logger = AppLoggers.general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, logger: logger, file: file, function: function, line: line)
    }
    
    /// Log warning message
    static func warning(_ message: String, logger: os.Logger = AppLoggers.general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, logger: logger, file: file, function: function, line: line)
    }
    
    /// Log error message (always logged to Crashlytics in release)
    static func error(_ message: String, logger: os.Logger = AppLoggers.general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, logger: logger, file: file, function: function, line: line)
    }
    
    /// Log an error with additional context
    static func error(_ message: String, error: Error?, file: String = #file, function: String = #function, line: Int = #line) {
        let errorDescription = error?.localizedDescription ?? "No error details"
        let fullMessage = "\(message) - Error: \(errorDescription)"
        log(fullMessage, level: .error, file: file, function: function, line: line)
        
        #if !DEBUG
        // Record error to Crashlytics in release builds
        if let error = error {
            Crashlytics.crashlytics().record(error: error)
        }
        #endif
    }
}

// MARK: - Date Formatter Extension
private extension DateFormatter {
    static let logDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        return formatter
    }()
}