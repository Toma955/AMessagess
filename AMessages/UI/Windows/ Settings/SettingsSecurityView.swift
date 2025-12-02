import SwiftUI
#if os(macOS)
import AppKit
#endif

struct SettingsSecurityView: View {
    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var windowManager: WindowManager

    @Binding var autoLockSelection: Int
    let autoLockOptions: [Int]
    @Binding var panicRequiresPin: Bool

    // Glavno zaključavanje + modovi rada
    @State private var lockEnabled: Bool = true
    @State private var selectedLockMode: LockMode = .standard

    // Datumsko zaključavanje
    @State private var dateLockEnabled: Bool = false
    @State private var dateLockDate: Date = Date()

    // Tjedni raspored – dijeli se između mini widgeta i DayLockScheduleWidget-a
    @State private var dayLockSettings: [DayLockSetting] =
        Weekday.allCases.map { DayLockSetting.defaultFor(day: $0) }

    // Fake account
    @State private var fakeAccountEnabled: Bool = false

    // Obavijesti
    @State private var hideContentInNotifications: Bool = true

    enum LockMode: String, CaseIterable, Identifiable {
        case standard
        case highSecurity
        case privateMode

        var id: String { rawValue }

        var label: String {
            switch self {
            case .standard:     return "Standardni"
            case .highSecurity: return "Visoka sigurnost"
            case .privateMode:  return "Privatni način"
            }
        }
    }

    // Koliko je prozora aktivno (nedokiranih)
    private var activeWindowCount: Int {
        windowManager.windows.filter { !$0.isDocked }.count
    }

    // 3+ prozora → veliki 7-dnevni widget, inače mini red
    private var useRadialWidget: Bool {
        activeWindowCount >= 3
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {

                // Naslov sekcije
                Text(Localization.shared.text(.settingsSecurity))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.bottom, 4)

                // MARK: - Zaključavanje + modovi rada
                lockModesSection

                Divider().background(Color.white.opacity(0.15))

                // MARK: - Automatsko zaključavanje
                autoLockSection

                Divider().background(Color.white.opacity(0.15))

                // MARK: - Datumsko zaključavanje
                dateLockSection

                Divider().background(Color.white.opacity(0.15))

                // MARK: - Zaključavanje po danima
                if useRadialWidget {
                    DayLockScheduleWidget(settings: $dayLockSettings)
                } else {
                    dayMiniCircleRow
                }

                Divider().background(Color.white.opacity(0.15))

                // MARK: - Panic lock
                panicLockSection

                Divider().background(Color.white.opacity(0.15))

                // MARK: - Lokacija spremanja
                storageSection

                Divider().background(Color.white.opacity(0.15))

                // MARK: - Lažni račun
                fakeAccountSection

                Divider().background(Color.white.opacity(0.15))

                // MARK: - Obavijesti / sadržaj
                notificationsSection
            }
            .padding(18)
        }
    }

    // MARK: - Sekcije

    private var lockModesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: $lockEnabled) {
                Text("Zaključavanje sesije")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
            }
            .toggleStyle(SwitchToggleStyle(tint: .red))

            Text("Ako je uključeno, aplikacija može automatski zaključati sesiju i primijeniti dodatne sigurnosne modove.")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.6))

            VStack(alignment: .leading, spacing: 6) {
                Text("Modovi rada")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(lockEnabled ? 0.9 : 0.4))

                Picker("", selection: $selectedLockMode) {
                    ForEach(LockMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(!lockEnabled)

                Text(hintForSelectedMode)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.top, 4)
        }
    }

    private var autoLockSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Automatsko zaključavanje")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))

            Text("Nakon koliko vremena neaktivnosti se sesija zaključava.")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.6))

            Picker("", selection: $autoLockSelection) {
                ForEach(autoLockOptions, id: \.self) { minutes in
                    Text(labelForAutoLock(minutes: minutes)).tag(minutes)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var dateLockSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: $dateLockEnabled) {
                Text("Zaključaj na određeni datum")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
            }
            .toggleStyle(SwitchToggleStyle(tint: .red))

            Text("Odaberi datum i vrijeme kada želiš da se aplikacija automatski zaključa, bez obzira na aktivnost.")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.6))

            DatePicker(
                "",
                selection: $dateLockDate,
                displayedComponents: [.date, .hourAndMinute]
            )
            .labelsHidden()
            .disabled(!dateLockEnabled)
            .colorMultiply(.white)
        }
    }

    private var panicLockSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Panic lock")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))

            Toggle(isOn: $panicRequiresPin) {
                Text("Za panic lock traži PIN prije brisanja ključeva")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            }
            .toggleStyle(SwitchToggleStyle(tint: .red))

            Text("Panic lock zatvara sve prozore i briše ključeve iz memorije. Ova opcija dodaje dodatnu potvrdu prije takve akcije.")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.6))
        }
    }

    private var storageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Lokacija spremanja podataka")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))

            Text("Sigurnosni podaci se lokalno spremaju u privatan direktorij na disku.")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.6))

            HStack(spacing: 8) {
                Text(defaultStoragePath)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()

                #if os(macOS)
                Button {
                    openStorageFolder()
                } label: {
                    Image(systemName: "folder")
                        .font(.system(size: 12, weight: .bold))
                    Text("Otvori")
                        .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.white.opacity(0.12))
                )
                #endif
            }
        }
    }

    private var fakeAccountSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Lažni račun")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))

            Toggle(isOn: $fakeAccountEnabled) {
                Text("Omogući ulaz u lažni profil")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            }
            .toggleStyle(SwitchToggleStyle(tint: .red))

            Text("Lažni račun omogućuje brz ulaz u \"čistu\" verziju aplikacije s minimalnim podacima, ako korisnika netko prisiljava da otvori aplikaciju.")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.6))
        }
    }

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Obavijesti")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))

            Toggle(isOn: $hideContentInNotifications) {
                Text("Sakrij sadržaj poruka u obavijestima")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            }
            .toggleStyle(SwitchToggleStyle(tint: .red))

            Text("Kada je uključeno, obavijesti prikazuju samo da je stigla nova poruka, bez teksta.")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.6))
        }
    }

    // MARK: - Dnevni lock helperi & mini widget

    private func summary(for day: Weekday) -> String {
        if let s = dayLockSettings.first(where: { $0.day == day }) {
            return s.summaryText
        } else {
            return DayLockSetting.defaultFor(day: day).summaryText
        }
    }

    private func isLocked(day: Weekday) -> Bool {
        if let s = dayLockSettings.first(where: { $0.day == day }) {
            return !s.isUnrestricted
        } else {
            return false
        }
    }

    private func resetDay(_ day: Weekday) {
        let def = DayLockSetting.defaultFor(day: day)
        if let idx = dayLockSettings.firstIndex(where: { $0.day == day }) {
            dayLockSettings[idx] = def
        } else {
            dayLockSettings.append(def)
        }
    }

    private var dayMiniCircleRow: some View {
        HStack(spacing: 8) {
            ForEach(Weekday.allCases) { day in
                let locked = isLocked(day: day)

                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(
                                locked
                                ? Color.red.opacity(0.85)
                                : Color.black.opacity(0.35)
                            )
                            .frame(width: 22, height: 22)

                        Text(day.shortSymbol)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    Text(summary(for: day))
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .frame(maxWidth: .infinity)
                .onTapGesture(count: 2) {
                    resetDay(day)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.35))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }

    // MARK: - Helperi

    private var hintForSelectedMode: String {
        switch selectedLockMode {
        case .standard:
            return "Standardni mod zaključava sesiju nakon isteka vremena i skriva osjetljive podatke."
        case .highSecurity:
            return "Visoka sigurnost pooštrava automatsko zaključavanje i zahtijeva dodatne provjere."
        case .privateMode:
            return "Privatni način minimizira tragove korištenja aplikacije na ovom uređaju."
        }
    }

    private func labelForAutoLock(minutes: Int) -> String {
        if minutes == 0 {
            return "Isključeno"
        } else if minutes == 1 {
            return "1 min"
        } else {
            return "\(minutes) min"
        }
    }

    private var defaultStoragePath: String {
        #if os(macOS)
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        if let appSupport = paths.first {
            return appSupport.appendingPathComponent("AMessages").path
        } else {
            return "~/Library/Application Support/AMessages"
        }
        #else
        return "Lokalna pohrana na uređaju"
        #endif
    }

    #if os(macOS)
    private func openStorageFolder() {
        let path = (defaultStoragePath as NSString).expandingTildeInPath
        let url = URL(fileURLWithPath: path)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
    #endif
}
