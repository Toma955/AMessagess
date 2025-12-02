import SwiftUI

struct OrientBackgroundView: View {
    var body: some View {
        ZStack {
            // === statična mračna pozadina (još tamnija) ===
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.00, blue: 0.05),
                    Color(red: 0.06, green: 0.00, blue: 0.10)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [
                    Color(red: 0.50, green: 0.10, blue: 0.70).opacity(0.30),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 500
            )

            RadialGradient(
                colors: [
                    Color(red: 0.75, green: 0.10, blue: 0.45).opacity(0.25),
                    .clear
                ],
                center: .bottomLeading,
                startRadius: 0,
                endRadius: 500
            )

            RadialGradient(
                colors: [
                    Color(red: 0.35, green: 0.05, blue: 0.45).opacity(0.40),
                    .clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: 550
            )
            .blur(radius: 50)
            .blendMode(.screen)

            // === vrlo mirni pulsing krugovi ===
            PurplePulseLayer()
        }
        .ignoresSafeArea()
    }
}

// MARK: - Dinamički ljubičasto/rozi pulsing krugovi (sporo & tamno)

struct PurplePulseLayer: View {

    struct Pulse: Identifiable {
        let id = UUID()
        let createdAt: Date
        let duration: TimeInterval
        let x: CGFloat          // 0...1 relativno na širinu
        let y: CGFloat          // 0...1 relativno na visinu
        let offsetX: CGFloat    // mali drift X
        let offsetY: CGFloat    // mali drift Y
        let color: Color
        let maxRadius: CGFloat
    }

    @State private var pulses: [Pulse] = []
    @State private var intensityPhase: Double = 0.3   // 0...1 (mirno -> mrvu življe)

    // rjeđi tick, mirnija animacija
    private let timer = Timer.publish(every: 0.15, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(pulses) { pulse in
                    let now = Date()
                    let t = now.timeIntervalSince(pulse.createdAt)
                    let rawProgress = max(0.0, min(t / pulse.duration, 1.0))

                    let scaleProgress = easeOutCubic(rawProgress)
                    let fadeProgress = easeInQuad(rawProgress)

                    // ukupna svjetlina – niska
                    let baseAlpha = 0.08 + 0.20 * intensityPhase

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    pulse.color.opacity(0.75),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: pulse.maxRadius
                            )
                        )
                        .frame(width: pulse.maxRadius * 2,
                               height: pulse.maxRadius * 2)
                        .position(
                            x: (pulse.x + pulse.offsetX * CGFloat(scaleProgress)) * geo.size.width,
                            y: (pulse.y + pulse.offsetY * CGFloat(scaleProgress)) * geo.size.height
                        )
                        .scaleEffect(0.5 + 1.4 * CGFloat(scaleProgress))
                        .opacity((1.0 - fadeProgress) * baseAlpha)
                        .blur(radius: 45)
                }
            }
            .blendMode(.screen)
            .allowsHitTesting(false)
            .onReceive(timer) { _ in
                tick(size: geo.size)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            startPhaseAnimation()
        }
    }

    // MARK: - Logika za spawn & faze

    private func tick(size: CGSize) {
        let now = Date()

        // makni isteknule pulseve
        pulses.removeAll { now.timeIntervalSince($0.createdAt) > $0.duration }

        // bazna vjerojatnost spawna – niska (mirno)
        let baseSpawnProb = 0.10
        let spawnProb = baseSpawnProb * (0.4 + 0.8 * intensityPhase)

        var spawnCount = 0
        if Double.random(in: 0...1) < spawnProb {
            spawnCount = 1
            // rijetko 2 odjednom, samo kad je malo "življe"
            if intensityPhase > 0.6 && Double.random(in: 0...1) < 0.25 {
                spawnCount += 1
            }
        }

        for _ in 0..<spawnCount {
            spawnPulse(now: now, size: size)
        }

        // hard limit da ostane lagano
        let maxPulses = 25
        if pulses.count > maxPulses {
            pulses.removeFirst(pulses.count - maxPulses)
        }
    }

    private func spawnPulse(now: Date, size: CGSize) {
        // random pozicija, ali blize unutra (manje po rubu)
        let x = CGFloat.random(in: 0.05...0.95)
        let y = CGFloat.random(in: 0.05...0.95)

        // sporo disanje – duža trajanja
        let duration = TimeInterval.random(in: 10.0...22.0)
        let maxRadius = CGFloat.random(in: 200...340)

        // vrlo lagan drift
        let offsetX = CGFloat.random(in: -0.05...0.05)
        let offsetY = CGFloat.random(in: -0.04...0.06)

        // TAMNI ljubičasto/rozi tonovi
        let palette: [Color] = [
            Color(red: 0.45, green: 0.10, blue: 0.60),
            Color(red: 0.38, green: 0.08, blue: 0.55),
            Color(red: 0.52, green: 0.12, blue: 0.68),
            Color(red: 0.40, green: 0.05, blue: 0.45),
            Color(red: 0.48, green: 0.08, blue: 0.52)
        ]

        var base = palette.randomElement() ?? .purple

        // mala varijacija svjetline, ali i dalje tamno
        let brighten = Double.random(in: -0.06...0.08)
        base = base.opacity(1.0) // samo da se ne miješa s ranijim

        let pulse = Pulse(
            createdAt: now,
            duration: duration,
            x: x,
            y: y,
            offsetX: offsetX,
            offsetY: offsetY,
            color: adjustBrightness(base, delta: brighten),
            maxRadius: maxRadius
        )

        pulses.append(pulse)
    }

    private func startPhaseAnimation() {
        // mala, spora promjena intenziteta – da "diše"
        intensityPhase = 0.3
        withAnimation(
            .easeInOut(duration: 26.0)
                .repeatForever(autoreverses: true)
        ) {
            intensityPhase = 0.7
        }
    }
}

// MARK: - Easing helperi

private func easeOutCubic(_ t: Double) -> Double {
    let clamped = max(0.0, min(1.0, t))
    return 1.0 - pow(1.0 - clamped, 3.0)
}

private func easeInQuad(_ t: Double) -> Double {
    let clamped = max(0.0, min(1.0, t))
    return clamped * clamped
}

// MARK: - Tamna prilagodba boje

private func adjustBrightness(_ color: Color, delta: Double) -> Color {
    // vrlo grubo: povuci prema crnoj ili malo prema svjetlijoj
    let d = max(-0.2, min(0.2, delta))
    // koristimo linearnu interpolaciju prema crnoj
    // (da izbjegnemo cgColor i zajebanciju s komponentama)
    let mixToBlack = d < 0
    let factor = abs(d)

    if mixToBlack {
        // tamnije
        return color.opacity(1.0 - factor * 0.3)
    } else {
        // mrvu svjetlije – ali još uvijek tamno
        return color.opacity(1.0) // ne diramo alpha, radije ostavimo bazu
    }
}
