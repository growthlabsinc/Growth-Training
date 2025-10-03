//
//  NavigationHeaderView.swift
//  Growth
//
//  Created by Developer on 6/2/25.
//

import SwiftUI

struct NavigationHeaderView: View {
    let title: String
    
    var body: some View {
        HStack(alignment: .center) {
            Text(title)
                .font(AppTheme.Typography.gravityBoldFont(34))
                .foregroundColor(Color("TextColor"))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Profile button matching dashboard style
            ProfileNavigationButton()
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }
}

// MARK: - View Modifier for consistent navigation styling
struct CustomNavigationHeader: ViewModifier {
    let title: String
    
    func body(content: Content) -> some View {
        content
            .navigationBarHidden(true)
            .safeAreaInset(edge: .top) {
                NavigationHeaderView(title: title)
                    .background(Color(UIColor.systemBackground))
            }
    }
}

extension View {
    func customNavigationHeader(title: String) -> some View {
        modifier(CustomNavigationHeader(title: title))
    }
}