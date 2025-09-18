//
//  Font+Extension.swift
//  Growth
//
//  Created by Claude on current date.
//

import SwiftUI

extension Font {
    // Redirect to AppTheme.Typography methods for consistency
    static var interLargeTitle: Font {
        AppTheme.Typography.largeTitleFont()
    }
    
    static var interTitle1: Font {
        AppTheme.Typography.title1Font()
    }
    
    static var interTitle2: Font {
        AppTheme.Typography.title2Font()
    }
    
    static var interTitle3: Font {
        AppTheme.Typography.title3Font()
    }
    
    static var interHeadline: Font {
        AppTheme.Typography.headlineFont()
    }
    
    static var interSubheadline: Font {
        AppTheme.Typography.subheadlineFont()
    }
    
    static var interBody: Font {
        AppTheme.Typography.bodyFont()
    }
    
    static var interCallout: Font {
        AppTheme.Typography.calloutFont()
    }
    
    static var interFootnote: Font {
        AppTheme.Typography.footnoteFont()
    }
    
    static var interCaption: Font {
        AppTheme.Typography.captionFont()
    }
}
