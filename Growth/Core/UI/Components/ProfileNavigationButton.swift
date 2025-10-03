//
//  ProfileNavigationButton.swift
//  Growth
//
//  Created by Developer on 6/2/25.
//

import SwiftUI

struct ProfileNavigationButton: View {
    @State private var showProfile = false
    
    var body: some View {
        Button(action: {
            showProfile = true
        }) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(Color("GrowthGreen"))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .sheet(isPresented: $showProfile) {
            ProfileView()
        }
    }
}

// Alternative sheet-based navigation
struct ProfileNavigationSheetButton: View {
    @State private var showProfile = false
    
    var body: some View {
        Button(action: {
            showProfile = true
        }) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(Color("GrowthGreen"))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .sheet(isPresented: $showProfile) {
            NavigationStack {
                ProfileView()
                    .navigationBarItems(trailing: Button("Done") {
                        showProfile = false
                    })
            }
        }
    }
}

#Preview {
    NavigationStack {
        VStack {
            ProfileNavigationButton()
            ProfileNavigationSheetButton()
        }
    }
}