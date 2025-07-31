//
//  ContactMeView.swift
//  Andare
//
//  Created by neg2sode on 2025/7/23.
//

import SwiftUI
import StoreKit

struct ContactMeView: View {
    @Environment(\.requestReview) var requestReview
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Contact Me")
                .font(.title)
                .fontWeight(.bold)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 0) {
                // --- Row 1: Rate the App ---
                Button(action: { requestReview() }) {
                    ContactRow(
                        title: "Rate the app",
                        icon: .symbol("heart.circle.fill"),
                        iconRenderingMode: .multicolor
                    )
                }
                .buttonStyle(.plain)
                
                Divider().padding(.horizontal)
                
                // --- Row 2: Send Feedback ---
                Button(action: sendFeedbackMail) {
                    ContactRow(
                        title: "Send Feedback",
                        icon: .symbol("paperplane.circle.fill"),
                        iconRenderingMode: .multicolor
                    )
                }
                .buttonStyle(.plain)
                
                Divider().padding(.horizontal)

                // --- Row 3: Follow on Bilibili ---
                Link(destination: URL(string: "https://space.bilibili.com/1442295892")!) {
                    ContactRow(
                        title: "Follow on Bilibili",
                        icon: .image("thumbnail_bilibili")
                    )
                }
                .foregroundStyle(.primary)
            }
        }
    }
    
    /// Constructs a mailto URL and attempts to open the Mail app.
    private func sendFeedbackMail() {
        let subject = "Andare App Feedback"
        let body = "Feel free to reach out with any questions or ideas — I'll respond as soon as I can."
        
        MailUtilities.send(subject: subject, body: body)
    }
}

struct ContactRow: View {
    let title: String
    let icon: IconType
    var iconRenderingMode: SymbolRenderingMode = .hierarchical

    enum IconType {
        case symbol(String)
        case image(String)
    }
    
    var body: some View {
        HStack {
            Label {
                Text(title)
                    .font(.body)
            } icon: {
                switch icon {
                case .symbol(let name):
                    Image(systemName: name)
                        .symbolRenderingMode(iconRenderingMode)
                        .frame(width: 28, height: 28)
                        .font(.title3)
                case .image(let name):
                    Image(name)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 28, height: 28)
                        .clipShape(Circle())
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .foregroundStyle(.primary)
        .padding(.vertical, 12)
        .padding(.horizontal)
        .contentShape(Rectangle())
    }
}

struct ContactMeView_Previews: PreviewProvider {
    static var previews: some View {
        ContactMeView()
    }
}
