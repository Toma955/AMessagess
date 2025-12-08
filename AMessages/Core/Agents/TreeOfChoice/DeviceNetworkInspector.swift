import Foundation

/// Jedan "snapshot" mrežnog okruženja – koristi ga Agent / Watchman / UI.
struct NetworkEnvironmentSnapshot {
    /// Privatna (LAN) adresa našeg uređaja, npr. 192.168.1.23
    let localIPAddress: String?

    /// Default gateway (router na LAN strani), npr. 192.168.1.1
    let gatewayIPAddress: String?

    /// MAC adresa gatewaya (dobivena iz ARP tablice), npr. "00:11:22:33:44:55"
    let gatewayMACAddress: String?

    /// Javna (WAN) IP adresa koju vidi internet – dobiveno preko HTTP upita
    let publicIPAddress: String?

    /// Naziv aktivnog sučelja (en0, en1, bridge0...)
    let interfaceName: String?

    /// Trenutna "uloga" sučelja – samo informativno za dijagnostiku
    let interfaceKindDescription: String?

    /// Port na kojem tvoja app sluša (P2P / relay) – ovo znaš ti, pa ga samo proslijediš
    let listeningPort: UInt16?

    /// Tekstualni opis za debug (možeš prikazati u dijagnostici)
    let debugSummary: String
}

/// Agent koji na macOS-u pokušava dohvatiti osnovne mrežne podatke.
/// Koristi `route`, `arp` i HTTP poziv za javnu IP.
/// Ovo je namjerno izdvojeno iz ostatka sustava da ga možeš zvati od kud god.
final class DeviceNetworkInspector {

    // MARK: - Public API

    /// Glavna funkcija – prikupi snapshot i vrati ga kroz completion.
    ///
    /// - parameter listeningPort:
    ///     Port na kojem tvoj P2P / relay listener radi (ako imaš tu informaciju).
    /// - parameter completion:
    ///     Callback na main queueu s popunjenim snapshotom.
    func collectSnapshot(listeningPort: UInt16? = nil,
                         completion: @escaping (NetworkEnvironmentSnapshot) -> Void) {

        // Radimo u background queueu da ne blokiramo UI.
        DispatchQueue.global(qos: .utility).async {
            let interfaceName = Self.detectDefaultInterfaceName()
            let localIP = interfaceName.flatMap { Self.getLocalIPAddress(for: $0) }
            let gatewayIP = Self.getDefaultGatewayIP()
            let gatewayMAC = gatewayIP.flatMap { Self.getMACAddress(forHost: $0) }

            // Javnu IP dobijamo preko HTTP upita – ovo je blokirajuće u ovom primjeru.
            let publicIP = Self.fetchPublicIPAddress()

            let kindDesc = interfaceName.map { Self.describeInterface(name: $0) }

            let summary = """
            local=\(localIP ?? "nil"), gateway=\(gatewayIP ?? "nil"), \
            gwMAC=\(gatewayMAC ?? "nil"), public=\(publicIP ?? "nil"), \
            iface=\(interfaceName ?? "nil"), port=\(listeningPort.map(String.init) ?? "nil")
            """

            let snapshot = NetworkEnvironmentSnapshot(
                localIPAddress: localIP,
                gatewayIPAddress: gatewayIP,
                gatewayMACAddress: gatewayMAC,
                publicIPAddress: publicIP,
                interfaceName: interfaceName,
                interfaceKindDescription: kindDesc,
                listeningPort: listeningPort,
                debugSummary: summary
            )

            DispatchQueue.main.async {
                completion(snapshot)
            }
        }
    }

    // MARK: - Local helpers (shell)

    /// Pokreće sistemski binarni file i vraća njegov output kao string.
    @discardableResult
    private static func runShell(_ launchPath: String,
                                 _ arguments: [String]) -> String? {
        let task = Process()
        task.launchPath = launchPath
        task.arguments = arguments

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        do {
            try task.run()
        } catch {
            print("[DeviceNetworkInspector] runShell error: \(error)")
            return nil
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard !data.isEmpty else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - Default interface & lokalni IP

    /// Pokuša otkriti koji je "default" interface (en0, en1, itd.) preko `route -n get default`.
    private static func detectDefaultInterfaceName() -> String? {
        guard let output = runShell("/usr/sbin/route", ["-n", "get", "default"]) else {
            return nil
        }

        // tražimo liniju "interface: en0"
        for line in output.split(separator: "\n") {
            if line.contains("interface:") {
                let parts = line.split(separator: " ")
                if let iface = parts.last {
                    return String(iface)
                }
            }
        }
        return nil
    }

    /// Pokušava dobiti IPv4 adresu za zadani interface preko `ipconfig getifaddr`.
    private static func getLocalIPAddress(for interface: String) -> String? {
        guard let output = runShell("/usr/sbin/ipconfig", ["getifaddr", interface]) else {
            return nil
        }
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    // MARK: - Gateway IP

    /// Čita default gateway iz `route -n get default` outputa.
    private static func getDefaultGatewayIP() -> String? {
        guard let output = runShell("/usr/sbin/route", ["-n", "get", "default"]) else {
            return nil
        }

        // tražimo liniju "gateway: 192.168.1.1"
        for line in output.split(separator: "\n") {
            if line.contains("gateway:") {
                let parts = line.split(separator: " ").map { String($0) }
                if let idx = parts.firstIndex(of: "gateway:"),
                   idx + 1 < parts.count {
                    return parts[idx + 1]
                }
            }
        }
        return nil
    }

    // MARK: - MAC adresa gatewaya (ARP tablica)

    /// Pokušava dohvatiti MAC adresu za zadani host preko `arp -n host`.
    private static func getMACAddress(forHost host: String) -> String? {
        guard let output = runShell("/usr/sbin/arp", ["-n", host]) else {
            return nil
        }

        // Tipičan output:
        // ? (192.168.1.1) at 0:11:22:33:44:55 on en0 ifscope [ethernet]
        for line in output.split(separator: "\n") {
            let parts = line.split(separator: " ")
            // tražimo token poslije "at"
            if let atIndex = parts.firstIndex(of: Substring("at")),
               atIndex + 1 < parts.count {
                let macCandidate = String(parts[atIndex + 1])
                if macCandidate.contains(":") {
                    return macCandidate
                }
            }
        }
        return nil
    }

    // MARK: - Javna IP (preko HTTP upita)

    /// Vrlo jednostavno: zovemo servis koji vrati našu javnu IP.
    /// U produkciji bi ovo radilo na tvom serveru (signal server).
    private static func fetchPublicIPAddress() -> String? {
        guard let url = URL(string: "https://api.ipify.org?format=text") else {
            return nil
        }
        var result: String?

        let semaphore = DispatchSemaphore(value: 0)

        let task = URLSession.shared.dataTask(with: url) { data, _, _ in
            defer { semaphore.signal() }
            guard let data = data,
                  let text = String(data: data, encoding: .utf8) else {
                return
            }
            result = text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        task.resume()
        _ = semaphore.wait(timeout: .now() + 5) // max 5s

        return result
    }

    // MARK: - Interface description (Wi-Fi / Ethernet / ostalo)

    /// Mali helper da lakše čitaš logove – nije 100% točno, ali dovoljan hint.
    private static func describeInterface(name: String) -> String {
        if name.hasPrefix("en") {
            // en0 je obično Wi-Fi na MacBooku, ali može biti i Ethernet – ovo je samo hint.
            return "Ethernet/Wi-Fi (\(name))"
        } else if name.hasPrefix("pdp_ip") {
            return "Cellular (\(name))"
        } else if name.hasPrefix("bridge") {
            return "Bridge (\(name))"
        } else {
            return "Interface \(name)"
        }
    }
}
