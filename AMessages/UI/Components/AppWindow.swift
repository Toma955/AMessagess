import SwiftUI

struct AppWindow<Content: View>: View {
    let isSettings: Bool      // za budućnost, sada ga ne koristimo
    let content: Content

    init(
        isSettings: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.isSettings = isSettings
        self.content = content()
    }

    var body: some View {
        ZStack {
            // ista “glass” podloga kao dock / list view
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )

            // sadržaj prozora – bez paddinga, ide od ruba do ruba unutar prozora
            content
                .clipShape(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                )
        }
        .shadow(color: Color.black.opacity(0.35),
                radius: 18,
                x: 0,
                y: 10)
    }
}
