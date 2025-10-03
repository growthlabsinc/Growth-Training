//
//  TimerDisplayView.swift
//  Growth
//
//  Created by Developer on <CURRENT_DATE>.
//

import SwiftUI

struct TimerDisplayView: View {
    let time: String

    var body: some View {
        Text(time)
            .font(.system(size: 80, weight: .light, design: .monospaced))
            .foregroundColor(AppTheme.Colors.text)
            .padding()
    }
}

#if DEBUG
struct TimerDisplayView_Previews: PreviewProvider {
    static var previews: some View {
        TimerDisplayView(time: "01:23")
            .background(AppTheme.Colors.background)
            .previewLayout(.sizeThatFits)
    }
}
#endif 