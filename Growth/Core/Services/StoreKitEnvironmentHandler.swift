import Foundation

@available(iOS 15.0, *)
class StoreKitEnvironmentHandler {
    static let shared = StoreKitEnvironmentHandler()
    
    enum Environment {
        case sandbox
        case production
        case xcode
        
        var displayName: String {
            switch self {
            case .sandbox:
                return "Sandbox"
            case .production:
                return "Production"
            case .xcode:
                return "Xcode Testing"
            }
        }
    }
    
    var currentEnvironment: Environment {
        #if DEBUG
        return .xcode
        #else
        if let receiptURL = Bundle.main.appStoreReceiptURL {
            let receiptString = receiptURL.path
            if receiptString.contains("sandboxReceipt") {
                return .sandbox
            } else {
                return .production
            }
        }
        return .production
        #endif
    }
    
    var isEnvironmentDetected: Bool {
        return true // Always detected
    }
    
    private init() {}
}