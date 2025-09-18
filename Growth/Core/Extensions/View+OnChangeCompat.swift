//
//  View+OnChangeCompat.swift
//  Growth
//
//  Compatibility extension for onChange modifier
//

import SwiftUI

extension View {
    /// Compatibility wrapper for onChange modifier
    /// Provides consistent behavior across iOS versions
    @ViewBuilder
    func onChangeCompat<T: Equatable>(of value: T, perform action: @escaping (T) -> Void) -> some View {
        if #available(iOS 17.0, *) {
            self.onChange(of: value) { oldValue, newValue in
                action(newValue)
            }
        } else {
            self.onChange(of: value, perform: action)
        }
    }
}