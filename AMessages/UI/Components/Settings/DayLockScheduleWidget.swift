import SwiftUI

// MARK: - Model dana u tjednu

enum Weekday: Int, CaseIterable, Identifiable {
    case monday = 1
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
    case sunday

    var id: Int { rawValue }

    /// Jedno slovo za mali krug (HR)
    var shortSymbol: String {
        switch self {
        case .monday:    return "P"   // Ponedjeljak
        case .tuesday:   return "U"   // Utorak
        case .wednesday: return "S"   // Srijeda
        case .thursday:  return "Č"   // Četvrtak
        case .friday:    return "P"   // Petak
        case .saturday:  return "S"   // Subota
        case .sunday:    return "N"   // Nedjelja
        }
    }

    var fullName: String {
        switch self {
        case .monday:    return "Ponedjeljak"
        case .tuesday:   return "Utorak"
        case .wednesday: return "Srijeda"
        case .thursday:  return "Četvrtak"
        case .friday:    return "Petak"
        case .saturday:  return "Subota"
        case .sunday:    return "Nedjelja"
        }
    }
}

// MARK: - Konfiguracija jednog dana

struct DayLockSetting: Identifiable, Equatable {
    let day: Weekday
    /// Početak blokade (0–24)
    var startHour: Double
    /// Kraj blokade (0–24)
    var endHour: Double

    var id: Weekday { day }

    /// Nema blokade (0 min) → start == end
    var isUnrestricted: Bool {
        abs(startHour - endHour) < 0.0001
    }

    /// Za prikaz & spremanje (npr. "0 min" ili "00:00 – 06:00")
    var summaryText: String {
        if isUnrestricted {
            return "0 min"
        } else {
            return "\(Self.formatHour(startHour)) – \(Self.formatHour(endHour))"
        }
    }

    static func defaultFor(day: Weekday) -> DayLockSetting {
        // Default: nema blokade → 0 min
        DayLockSetting(day: day, startHour: 0.0, endHour: 0.0)
    }

    static func formatHour(_ value: Double) -> String {
        let totalMinutes = Int((value * 60.0).rounded())
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return String(format: "%02d:%02d", hours, minutes)
    }
}

// MARK: - Glavni widget (7 dana)

struct DayLockScheduleWidget: View {
    /// Ovdje držiš postavke za sve dane (možeš kasnije spremiti u SessionManager)
    @Binding var settings: [DayLockSetting]

    @State private var selectedDay: Weekday = .monday

    public init(settings: Binding<[DayLockSetting]>) {
        self._settings = settings
        if let first = settings.wrappedValue.first?.day {
            _selectedDay = State(initialValue: first)
        }
    }

    // Koliko je dana trenutno zaključano (ima interval ≠ 0 min)
    private var lockedDayCount: Int {
        settings.filter { !$0.isUnrestricted }.count
    }

    private func binding(for day: Weekday) -> Binding<DayLockSetting> {
        Binding<DayLockSetting>(
            get: {
                if let index = settings.firstIndex(where: { $0.day == day }) {
                    return settings[index]
                } else {
                    let def = DayLockSetting.defaultFor(day: day)
                    settings.append(def)
                    return def
                }
            },
            set: { newValue in
                var fixed = newValue

                // koliko je drugih dana već zaključano
                let otherLocked = settings.filter {
                    $0.day != day && !$0.isUnrestricted
                }.count

                // ako bi ovaj postao zaključan, a već je 6 zaključanih → zabrani (vrati na 0 min)
                if !newValue.isUnrestricted && otherLocked >= 6 {
                    fixed = DayLockSetting.defaultFor(day: day)
                }

                if let index = settings.firstIndex(where: { $0.day == day }) {
                    settings[index] = fixed
                } else {
                    settings.append(fixed)
                }
            }
        )
    }

    private func summary(for day: Weekday) -> String {
        if let s = settings.first(where: { $0.day == day }) {
            return s.summaryText
        } else {
            return DayLockSetting.defaultFor(day: day).summaryText
        }
    }

    private func isLocked(day: Weekday) -> Bool {
        if let s = settings.first(where: { $0.day == day }) {
            return !s.isUnrestricted
        } else {
            return false
        }
    }

    private func resetDay(_ day: Weekday) {
        let unrestricted = DayLockSetting.defaultFor(day: day)
        if let index = settings.firstIndex(where: { $0.day == day }) {
            settings[index] = unrestricted
        } else {
            settings.append(unrestricted)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Vremensko zaključavanje")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))

            Text("Za svaki dan odaberi u kojem vremenskom rasponu aplikacija nije dostupna (24-satni format). Dvostruki klik resetira dan na 0 min.")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.6))

            // 7 malih krugova + tekst "0 min" ili "HH:MM – HH:MM"
            HStack(spacing: 10) {
                ForEach(Weekday.allCases) { day in
                    let locked = isLocked(day: day)

                    VStack(spacing: 4) {
                        DayCircleButton(
                            day: day,
                            isSelected: day == selectedDay,
                            isLocked: locked
                        )
                        .onTapGesture(count: 2) {
                            // dvostruki klik → reset na 0 min
                            resetDay(day)
                        }
                        .onTapGesture {
                            // jednostruki klik → odaberi dan za namještanje
                            withAnimation(.spring(response: 0.30, dampingFraction: 0.8)) {
                                selectedDay = day
                            }
                        }

                        Text(summary(for: day))
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            // Veliki kružni slider za odabrani dan
            let settingBinding = binding(for: selectedDay)
            DayLockCircleView(
                setting: settingBinding,
                centerLabel: settingBinding.wrappedValue.summaryText
            )
            .frame(height: 190)
            .padding(.top, 10)

            let activeSetting = binding(for: selectedDay).wrappedValue
            Text("\(selectedDay.fullName): \(activeSetting.summaryText)")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.7))
                .padding(.top, 4)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.35))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }
}

// MARK: - Mali krug za dan

struct DayCircleButton: View {
    let day: Weekday
    let isSelected: Bool
    let isLocked: Bool

    var body: some View {
        ZStack {
            // Pozadina – zelena ako je dan zaključan
            Circle()
                .fill(
                    isLocked
                    ? Color.green.opacity(isSelected ? 0.85 : 0.65)
                    : Color.black.opacity(isSelected ? 0.45 : 0.25)
                )

            // Vanjski rub
            Circle()
                .strokeBorder(
                    isSelected ? Color.white.opacity(0.95) : Color.white.opacity(0.45),
                    lineWidth: isSelected ? 3 : 2
                )

            // Unutarnji rub
            Circle()
                .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                .scaleEffect(0.7)

            Text(day.shortSymbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.95))
        }
        .frame(width: 32, height: 32)
    }
}

// MARK: - Veliki kružni slider (24h)

struct DayLockCircleView: View {
    @Binding var setting: DayLockSetting
    let centerLabel: String

    @State private var activeHandle: Handle? = nil

    private enum Handle {
        case start
        case end
    }

    /// smjernice – sati na kojima crtamo tickove
    private let tickHours: [Double] = [0, 3, 6, 9, 12, 15, 18, 21]

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = (size / 2) - 16

            ZStack {
                // Vanjski krug
                Circle()
                    .stroke(Color.white.opacity(0.25), lineWidth: 8)

                // Tick smjernice (0,3,6,9,12,15,18,21)
                ForEach(tickHours, id: \.self) { hour in
                    let pOuter = point(on: center, radius: radius, forHour: hour)
                    let pInner = point(on: center, radius: radius - 10, forHour: hour)

                    Path { path in
                        path.move(to: pInner)
                        path.addLine(to: pOuter)
                    }
                    .stroke(Color.white.opacity(0.25), lineWidth: hour.truncatingRemainder(dividingBy: 6) == 0 ? 2 : 1)
                }

                // Zaključani luk (samo ako postoji interval)
                if !setting.isUnrestricted {
                    LockedArcShape(startHour: normalizedStart, endHour: normalizedEnd)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    Color.red.opacity(0.8),
                                    Color.orange.opacity(0.9),
                                    Color.red.opacity(0.8)
                                ]),
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                }

                // Unutarnji krug
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 2)
                    .scaleEffect(0.65)

                // U sredini piše "0 min" ili "HH:MM – HH:MM"
                Text(centerLabel)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))

                // Ručke samo ako postoji interval
                if !setting.isUnrestricted {
                    HandleDot(
                        center: point(on: center, radius: radius, forHour: normalizedStart),
                        isStart: true
                    )

                    HandleDot(
                        center: point(on: center, radius: radius, forHour: normalizedEnd),
                        isStart: false
                    )
                }
            }
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        handleDragChange(location: value.location,
                                         center: center,
                                         radius: radius)
                    }
                    .onEnded { _ in
                        activeHandle = nil
                    }
            )
        }
    }

    // Normalizacija – 0...24
    private var normalizedStart: Double {
        min(max(setting.startHour, 0), 24)
    }

    private var normalizedEnd: Double {
        min(max(setting.endHour, 0), 24)
    }

    // MARK: - Drag logika

    private func handleDragChange(location: CGPoint, center: CGPoint, radius: CGFloat) {
        let dx = location.x - center.x
        let dy = location.y - center.y
        let distance = sqrt(dx*dx + dy*dy)

        // ignoriraj drag unutar sredine
        guard distance > radius - 24, distance < radius + 24 else {
            return
        }

        let angle = atan2(dy, dx)
        let degrees = angle * 180 / .pi
        let hour = hour(forAngleDegrees: Double(degrees))

        // ako je do sada bilo 0 min → napravi mali interval od 1h
        if setting.isUnrestricted {
            var start = hour
            var end = hour + 1.0
            if end > 24 { end = 24 }
            setting.startHour = start
            setting.endHour = end
            return
        }

        if activeHandle == nil {
            let startPoint = point(on: center, radius: radius, forHour: normalizedStart)
            let endPoint = point(on: center, radius: radius, forHour: normalizedEnd)

            let distToStart = hypot(location.x - startPoint.x, location.y - startPoint.y)
            let distToEnd = hypot(location.x - endPoint.x, location.y - endPoint.y)

            activeHandle = distToStart < distToEnd ? .start : .end
        }

        var newStart = normalizedStart
        var newEnd = normalizedEnd

        switch activeHandle {
        case .start:
            newStart = hour
            if newStart > newEnd {
                newEnd = newStart
            }
        case .end:
            newEnd = hour
            if newEnd < newStart {
                newStart = newEnd
            }
        case .none:
            break
        }

        setting.startHour = newStart
        setting.endHour = newEnd
    }

    // MARK: - Kut ↔ sat

    private func angleDegrees(forHour hour: Double) -> Double {
        (hour / 24.0) * 360.0 - 90.0
    }

    private func hour(forAngleDegrees degrees: Double) -> Double {
        var normalized = degrees + 90.0
        while normalized < 0 { normalized += 360 }
        while normalized >= 360 { normalized -= 360 }
        let hour = (normalized / 360.0) * 24.0
        return min(max(hour, 0), 24)
    }

    private func point(on center: CGPoint, radius: CGFloat, forHour hour: Double) -> CGPoint {
        let angle = angleDegrees(forHour: hour) * .pi / 180.0
        let x = center.x + cos(angle) * radius
        let y = center.y + sin(angle) * radius
        return CGPoint(x: x, y: y)
    }

    // MARK: - Ručka

    @ViewBuilder
    private func HandleDot(center: CGPoint, isStart: Bool) -> some View {
        Circle()
            .fill(isStart ? Color.white : Color.white.opacity(0.9))
            .frame(width: 14, height: 14)
            .overlay(
                Circle()
                    .stroke(Color.black.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.6), radius: 3, x: 0, y: 2)
            .position(center)
    }
}

// MARK: - Luk za zaključani interval

struct LockedArcShape: Shape {
    var startHour: Double
    var endHour: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 - 16

        let startAngle = Angle.degrees((startHour / 24.0) * 360.0 - 90.0)
        let endAngle = Angle.degrees((endHour / 24.0) * 360.0 - 90.0)

        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )

        return path
    }

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(startHour, endHour) }
        set {
            startHour = newValue.first
            endHour = newValue.second
        }
    }
}
