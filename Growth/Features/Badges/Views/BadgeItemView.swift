import SwiftUI

struct BadgeItemView: View {
    let badge: Badge
    let size: CGFloat

    var body: some View {
        VStack(spacing: 8) {
            // Icon
            ZStack {
                if let url = URL(string: badge.iconURL), !badge.iconURL.isEmpty {
                    if #available(iOS 15.0, *) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                            case .failure(_):
                                placeholderIcon
                            case .empty:
                                placeholderIcon
                            @unknown default:
                                placeholderIcon
                            }
                        }
                        .frame(width: size, height: size)
                    } else {
                        // Fallback placeholder for earlier iOS
                        placeholderIcon
                    }
                } else {
                    placeholderIcon
                }
            }
            .frame(width: size, height: size)
            .grayscale(badge.isEarned ? 0 : 1)
            .opacity(badge.isEarned ? 1 : 0.4)
            .overlay(
                Group {
                    if !badge.isEarned {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                            .frame(width: size / 2.5, height: size / 2.5)
                            .offset(x: size / 3, y: -size / 3)
                    }
                }, alignment: .topTrailing
            )

            // Name
            Text(badge.name)
                .font(AppTheme.Typography.captionFont())
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
                .lineLimit(2)
                .frame(maxWidth: size)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var placeholderIcon: some View {
        Image(systemName: "star")
            .resizable()
            .scaledToFit()
            .foregroundColor(.gray)
    }

    private var accessibilityText: String {
        if badge.isEarned {
            if let date = badge.earnedDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return "Earned badge: \(badge.name) on \(formatter.string(from: date))"
            } else {
                return "Earned badge: \(badge.name)"
            }
        } else {
            return "Locked badge: \(badge.name). \(badge.description)"
        }
    }
}

#if DEBUG
struct BadgeItemView_Previews: PreviewProvider {
    static var previews: some View {
        let earnedBadge = Badge(id: "1", name: "First Session", description: "Complete your first session.", criteria: [:], iconURL: "", earnedDate: Date())
        let lockedBadge = Badge(id: "2", name: "7 Day Streak", description: "Maintain a 7-day streak.", criteria: [:], iconURL: "", earnedDate: nil)
        HStack {
            BadgeItemView(badge: earnedBadge, size: 72)
            BadgeItemView(badge: lockedBadge, size: 72)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif 