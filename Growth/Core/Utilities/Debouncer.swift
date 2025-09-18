//
//  Debouncer.swift
//  Growth
//
//  A utility class for debouncing function calls
//

import Foundation

/// A utility class that delays the execution of a closure until a specified time has passed without additional calls
final class Debouncer {
    private let delay: TimeInterval
    private var workItem: DispatchWorkItem?
    
    init(delay: TimeInterval) {
        self.delay = delay
    }
    
    /// Debounces the execution of the provided closure
    /// - Parameter action: The closure to execute after the delay
    func debounce(action: @escaping () -> Void) {
        // Cancel any existing work item
        workItem?.cancel()
        
        // Create a new work item
        let newWorkItem = DispatchWorkItem(block: action)
        workItem = newWorkItem
        
        // Schedule the work item after the delay
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: newWorkItem)
    }
    
    /// Cancels any pending execution
    func cancel() {
        workItem?.cancel()
        workItem = nil
    }
}