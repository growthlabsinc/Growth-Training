//
//  ScaleButtonStyle.swift
//  Growth
//
//  Created by Developer on 6/5/25.
//

import SwiftUI

/// A button style that scales down when pressed
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}