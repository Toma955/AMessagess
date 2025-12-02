import SwiftUI

// Jedan "čvorić" oblika (lobe)
private struct BlobLobe {
    let angle: CGFloat        // smjer
    let offsetFactor: CGFloat // koliko je daleko od centra (u odnosu na r)
    let radiusFactor: CGFloat // koliki je taj krug (u odnosu na r)
}

// Jedan blob = centar + baza radijus + brzina + boja + fiksni lobeovi
private struct Blob: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var r: CGFloat
    var dx: CGFloat
    var dy: CGFloat
    var color: Color
    var lobes: [BlobLobe]
}

struct BackgroundView: View {
    @State private var blobs: [Blob] = []
    private let timer = Timer.publish(every: 1 / 60, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                let rect = CGRect(origin: .zero, size: size)
                context.fill(Path(rect), with: .color(.black))

                // adaptivni blur – mali view = mali blur, veliki view = veći blur
                let minDim = min(size.width, size.height)
                let blurRadius = max(1, min(minDim / 80, 10))
                context.addFilter(.blur(radius: blurRadius))
                context.blendMode = .normal

                for blob in blobs {
                    var path = Path()

                    // glavni krug
                    path.addEllipse(in: CGRect(
                        x: blob.x - blob.r,
                        y: blob.y - blob.r,
                        width: blob.r * 2,
                        height: blob.r * 2
                    ))

                    // dodatni krugovi koji prošire oblik
                    for lobe in blob.lobes {
                        let offsetR = blob.r * lobe.offsetFactor
                        let offsetX = cos(lobe.angle) * offsetR
                        let offsetY = sin(lobe.angle) * offsetR
                        let nodeRadius = blob.r * lobe.radiusFactor

                        path.addEllipse(in: CGRect(
                            x: blob.x + offsetX - nodeRadius,
                            y: blob.y + offsetY - nodeRadius,
                            width: nodeRadius * 2,
                            height: nodeRadius * 2
                        ))
                    }

                    context.fill(path, with: .color(blob.color.opacity(0.6)))
                }
            }
            .ignoresSafeArea()
            .onAppear {
                // izbjegni 0x0 layout u previewu
                DispatchQueue.main.async {
                    if blobs.isEmpty {
                        setupBlobs(in: geo.size)
                    }
                }
            }
            .onChange(of: geo.size) { newSize in
                setupBlobs(in: newSize)
            }
            .onReceive(timer) { _ in
                updateBlobs(in: geo.size)
            }
        }
    }

    private func setupBlobs(in size: CGSize) {
        let width = size.width
        let height = size.height
        guard width > 0, height > 0 else { return }

        var tmp: [Blob] = []

        // nijanse narančaste / crvene
        let colors: [Color] = [
            Color(red: 1.00, green: 0.40, blue: 0.10),
            Color(red: 0.95, green: 0.20, blue: 0.20),
            Color(red: 1.00, green: 0.55, blue: 0.10),
            Color(red: 0.95, green: 0.30, blue: 0.15)
        ]

        let minDimension = min(width, height)
        let isTiny = minDimension < 140      // npr. 130×80 preview
        let isSmall = minDimension < 260     // još uvijek mali, ali ne ekstremno

        // broj oblika skaliran po površini + mode
        let baseTotal: Int
        if isTiny {
            baseTotal = 40   // više malih blobova
        } else if isSmall {
            baseTotal = 30
        } else {
            baseTotal = 26
        }

        let areaFactor = max((width * height) / (800 * 800), 0.4)
        let total = Int(CGFloat(baseTotal) * areaFactor)

        for _ in 0..<total {
            let baseMaxR: CGFloat
            let minR: CGFloat

            if isTiny {
                // 🔹 JAKO MALI VIEW (preview u postavkama)
                // mali radijusi, ali ih ima više
                baseMaxR = min(minDimension / 3.5, 18) // max ~18
                minR = max(4, baseMaxR * 0.4)          // 4–7
            } else if isSmall {
                // 🔹 Mali view (ali veći od previewa)
                baseMaxR = min(minDimension / 3, 32)   // max ~32
                minR = max(10, baseMaxR * 0.5)        // 10–16
            } else {
                // 🔹 Veliki view (glavna pozadina)
                baseMaxR = min(minDimension / 2.5, 110)
                minR = max(36, baseMaxR * 0.45)       // 36+
            }

            let maxR = max(baseMaxR, minR)
            guard maxR >= minR else { continue }

            let r = CGFloat.random(in: minR...maxR)

            let x: CGFloat = width > 2 * r ? .random(in: r...(width - r)) : width / 2
            let y: CGFloat = height > 2 * r ? .random(in: r...(height - r)) : height / 2

            // 🔹 Brzina – u tiny previewu malo brže
            let speed: CGFloat
            let roll = Double.random(in: 0...1)
            if isTiny {
                if roll < 0.7 {
                    speed = .random(in: 0.10...0.16)
                } else if roll < 0.95 {
                    speed = .random(in: 0.17...0.22)
                } else {
                    speed = .random(in: 0.23...0.30)
                }
            } else {
                if roll < 0.7 {
                    speed = .random(in: 0.07...0.12)
                } else if roll < 0.95 {
                    speed = .random(in: 0.13...0.18)
                } else {
                    speed = .random(in: 0.19...0.26)
                }
            }

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let dx = cos(angle) * speed
            let dy = sin(angle) * speed

            let color = colors.randomElement() ?? colors[0]

            var lobes: [BlobLobe] = []
            let lobeCount = Int.random(in: 3...5)
            for i in 0..<lobeCount {
                let t = CGFloat(i) / CGFloat(lobeCount)
                let a = t * .pi * 2 + CGFloat.random(in: -0.4...0.4)
                let offsetFactor = CGFloat.random(in: 0.3...0.8)
                let radiusFactor = CGFloat.random(in: 0.5...0.9)
                lobes.append(BlobLobe(
                    angle: a,
                    offsetFactor: offsetFactor,
                    radiusFactor: radiusFactor
                ))
            }

            tmp.append(Blob(
                x: x,
                y: y,
                r: r,
                dx: dx,
                dy: dy,
                color: color,
                lobes: lobes
            ))
        }

        blobs = tmp
    }

    private func updateBlobs(in size: CGSize) {
        let width = size.width
        let height = size.height
        guard width > 0, height > 0 else { return }

        let margin: CGFloat = 60

        blobs = blobs.map { blob in
            var b = blob
            b.x += b.dx
            b.y += b.dy

            if b.x < margin || b.x > width - margin {
                b.dx = -b.dx
            }
            if b.y < margin || b.y > height - margin {
                b.dy = -b.dy
            }

            return b
        }
    }
}
