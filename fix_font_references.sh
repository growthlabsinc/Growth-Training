#!/bin/bash

# Script to fix all font references in the Growth app

echo "Fixing font references throughout the app..."

# Fix gravityRegular -> gravityBook
find . -name "*.swift" -type f -exec sed -i '' 's/gravityRegular/gravityBook/g' {} +

# Fix direct .font(.inter*) usage to use AppTheme.Typography methods
find . -name "*.swift" -type f -exec sed -i '' 's/\.font(\.interLargeTitle)/\.font(AppTheme.Typography.largeTitleFont())/g' {} +
find . -name "*.swift" -type f -exec sed -i '' 's/\.font(\.interTitle1)/\.font(AppTheme.Typography.title1Font())/g' {} +
find . -name "*.swift" -type f -exec sed -i '' 's/\.font(\.interTitle2)/\.font(AppTheme.Typography.title2Font())/g' {} +
find . -name "*.swift" -type f -exec sed -i '' 's/\.font(\.interTitle3)/\.font(AppTheme.Typography.title3Font())/g' {} +
find . -name "*.swift" -type f -exec sed -i '' 's/\.font(\.interHeadline)/\.font(AppTheme.Typography.headlineFont())/g' {} +
find . -name "*.swift" -type f -exec sed -i '' 's/\.font(\.interBody)/\.font(AppTheme.Typography.bodyFont())/g' {} +
find . -name "*.swift" -type f -exec sed -i '' 's/\.font(\.interCallout)/\.font(AppTheme.Typography.calloutFont())/g' {} +
find . -name "*.swift" -type f -exec sed -i '' 's/\.font(\.interSubheadline)/\.font(AppTheme.Typography.subheadlineFont())/g' {} +
find . -name "*.swift" -type f -exec sed -i '' 's/\.font(\.interFootnote)/\.font(AppTheme.Typography.footnoteFont())/g' {} +
find . -name "*.swift" -type f -exec sed -i '' 's/\.font(\.interCaption)/\.font(AppTheme.Typography.captionFont())/g' {} +

# Fix Font+Extension.swift to use AppTheme.Typography
cat > ./Growth/Core/UI/Extensions/Font+Extension.swift << 'EOF'
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
EOF

echo "Font references fixed!"
echo "Summary of changes:"
echo "- gravityRegular -> gravityBook"
echo "- .font(.interBody) -> .font(AppTheme.Typography.bodyFont())"
echo "- Font+Extension.swift updated to use AppTheme.Typography methods"