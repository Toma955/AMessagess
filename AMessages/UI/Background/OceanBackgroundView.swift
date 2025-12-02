import SwiftUI

/// Jednostavan sinusni val kao Shape
struct OceanWaveShape: Shape {
    var phase: CGFloat      // pomak vala (animira se)
    var amplitude: CGFloat  // relativna visina vala (0–1 u odnosu na visinu)
    var wavelength: CGFloat // relativna širina vala (0–1 u odnosu na širinu)
    var baseline: CGFloat   // na kojoj visini je sredina vala (0–1, 0 = vrh, 1 = dno)

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height

        let midY = baseline * height
        let amp = amplitude * height
        let waveLen = max(wavelength * width, 1) // zaštita od 0

        path.move(to: CGPoint(x: 0, y: midY))

        let step: CGFloat = 4.0
        var x: CGFloat = 0
        while x <= width {
            let progress = x / waveLen
            let angle = (progress + phase) * 2 * .pi
            let y = midY + sin(angle) * amp
            path.addLine(to: CGPoint(x: x, y: y))
            x += step
        }

        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()

        return path
    }

    // animiramo preko phase
    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }
}

struct OceanBackgroundView: View {
    @State private var phase1: CGFloat = 0.0
    @State private var phase2: CGFloat = 0.0

    var body: some View {
        ZStack {
            // GORNJI DIO – svjetlije nebo/more
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.18, blue: 0.35),
                    Color(red: 0.01, green: 0.06, blue: 0.15)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // PRVI VAL – bliže površini, svjetliji
            OceanWaveShape(
                phase: phase1,
                amplitude: 0.05,     // 5% visine
                wavelength: 0.35,    // kraći valovi
                baseline: 0.45       // oko sredine
            )
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.15, green: 0.60, blue: 0.90),
                        Color(red: 0.05, green: 0.35, blue: 0.70)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .opacity(0.85)
            .blur(radius: 6)

            // DRUGI VAL – dublje, tamniji, malo drugačiji ritam
            OceanWaveShape(
                phase: phase2,
                amplitude: 0.07,
                wavelength: 0.50,
                baseline: 0.55
            )
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.02, green: 0.30, blue: 0.55),
                        Color(red: 0.01, green: 0.10, blue: 0.25)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .opacity(0.9)
            .blur(radius: 8)

            // DONJI TAMNI DIO – duboko more
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.65)
                ],
                startPoint: .center,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
        .onAppear {
            // kontinuirani pomak valova
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                phase1 = 1.0
            }
            withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
                phase2 = -1.0
            }
        }
    }
}
