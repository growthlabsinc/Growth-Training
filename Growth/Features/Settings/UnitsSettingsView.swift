//
//  UnitsSettingsView.swift
//  Growth
//
//  Created by Developer on 6/4/25.
//

import SwiftUI

struct UnitsSettingsView: View {
    @StateObject private var gainsService = GainsService.shared
    @EnvironmentObject var themeManager: ThemeManager
    @AppStorage("temperatureUnit") private var temperatureUnit: String = "fahrenheit"
    @AppStorage("timeFormat") private var timeFormat: String = "12hour"
    
    var body: some View {
        Form {
            // Measurement Units Section
            Section(header: Text("Measurements").font(AppTheme.Typography.gravitySemibold(13))) {
                Picker("Unit System", selection: .init(
                    get: { gainsService.preferredUnit },
                    set: { gainsService.preferredUnit = $0 }
                )) {
                    ForEach(MeasurementUnit.allCases, id: \.self) { unit in
                        Text(unit.displayName).tag(unit)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "ruler")
                            .foregroundColor(Color("GrowthGreen"))
                            .frame(width: 20)
                        Text("Length: \(gainsService.preferredUnit == .imperial ? "inches" : "centimeters")")
                            .font(AppTheme.Typography.gravityBook(13))
                    }
                    
                    HStack {
                        Image(systemName: "circle")
                            .foregroundColor(Color("BrightTeal"))
                            .frame(width: 20)
                        Text("Girth: \(gainsService.preferredUnit == .imperial ? "inches" : "centimeters")")
                            .font(AppTheme.Typography.gravityBook(13))
                    }
                    
                    HStack {
                        Image(systemName: "cube")
                            .foregroundColor(Color("MintGreen"))
                            .frame(width: 20)
                        Text("Volume: \(gainsService.preferredUnit == .imperial ? "cubic inches" : "cubic cm")")
                            .font(AppTheme.Typography.gravityBook(13))
                    }
                }
                .foregroundColor(Color("TextSecondaryColor"))
                .padding(.vertical, 4)
            }
            
            // Temperature Section
            Section(header: Text("Temperature").font(AppTheme.Typography.gravitySemibold(13))) {
                Picker("Temperature Unit", selection: $temperatureUnit) {
                    Text("Fahrenheit (°F)").tag("fahrenheit")
                    Text("Celsius (°C)").tag("celsius")
                }
                
                Text("Used for wellness tracking and environmental conditions")
                    .font(AppTheme.Typography.gravityBook(12))
                    .foregroundColor(Color("TextSecondaryColor"))
            }
            
            // Time & Date Section
            Section(header: Text("Time & Date").font(AppTheme.Typography.gravitySemibold(13))) {
                Picker("Time Format", selection: $timeFormat) {
                    Text("12-hour (AM/PM)").tag("12hour")
                    Text("24-hour").tag("24hour")
                }
                
                Picker("First Day of Week", selection: $themeManager.firstDayOfWeek) {
                    Text("Sunday").tag(1)
                    Text("Monday").tag(2)
                }
                
                Text("Affects how calendars and weekly views are displayed")
                    .font(AppTheme.Typography.gravityBook(12))
                    .foregroundColor(Color("TextSecondaryColor"))
            }
            
            // Conversion Helper Section
            Section(header: Text("Quick Conversions").font(AppTheme.Typography.gravitySemibold(13))) {
                ConversionRow(
                    title: "Length",
                    imperial: "1 inch",
                    metric: "2.54 cm",
                    icon: "ruler",
                    color: Color("GrowthGreen")
                )
                
                ConversionRow(
                    title: "Temperature",
                    imperial: "98.6°F",
                    metric: "37°C",
                    icon: "thermometer",
                    color: Color("ErrorColor")
                )
                
                ConversionRow(
                    title: "Volume",
                    imperial: "1 in³",
                    metric: "16.39 cm³",
                    icon: "cube",
                    color: Color("MintGreen")
                )
            }
        }
        .navigationTitle("Units & Measurements")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            // Preferences are automatically saved via @AppStorage and didSet
        }
    }
}

// MARK: - Conversion Row Component
struct ConversionRow: View {
    let title: String
    let imperial: String
    let metric: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 25)
            
            Text(title)
                .font(AppTheme.Typography.gravitySemibold(14))
                .frame(width: 80, alignment: .leading)
            
            Spacer()
            
            Text("\(imperial) = \(metric)")
                .font(AppTheme.Typography.gravityBook(13))
                .foregroundColor(Color("TextSecondaryColor"))
        }
    }
}

#Preview {
    NavigationStack {
        UnitsSettingsView()
            .environmentObject(ThemeManager.shared)
    }
}