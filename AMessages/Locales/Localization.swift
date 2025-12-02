import Foundation
import Combine

// MARK: - Jezik aplikacije

enum ApplicationLanguage: String, CaseIterable, Identifiable {
    case hr
    case en
    case de
    case fr

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .hr: return "Hrvatski"
        case .en: return "English"
        case .de: return "Deutsch"
        case .fr: return "Français"
        }
    }
}

// MARK: - Ključevi tekstova

enum LKey {
    // Općenito
    case appName

    // Preloader / unlock
    case unlockTitle
    case unlockSubtitle

    // Messenger
    case messengerTitle
    case inputPlaceholder

    // Settings – sekcije
    case settingsTitle
    case settingsGeneral
    case settingsNetwork
    case settingsSecurity
    case settingsFiles
    case settingsWidgets
    case settingsAbout

    // Network
    case networkServerAddress
    case networkServerDescription
    case networkTestTitle
    case networkTestDescription
    case networkTestButton
    case networkTesting
    case networkOnline
    case networkFailed

    // Settings → General (Općenito)
    case generalSectionTitle

    case generalThemeTitle
    case generalThemeDescription

    case generalLanguageTitle
    case generalLanguageDescription

    case generalSoundTitle
    case generalSoundDescription

    case generalNotificationsTitle
    case generalNotificationsDescription

    case generalControlsTitle

    case generalFocusModeTitle
    case generalFocusModeDescription

    case generalSessionIdTitle
    case generalSessionIdDescription

    case generalLockButtonTitle
    case generalQuitButtonTitle
    case generalHistoryButtonTitle

    case generalWindowsDisplayTitle
    case generalWindowsDisplayDescription

    case generalTipTitle
    case generalTipMessage
}

// MARK: - “Statični” prevodi

enum I18n {

    static func t(_ key: LKey, _ lang: ApplicationLanguage) -> String {
        switch lang {
        case .hr: return hr(key)
        case .en: return en(key)
        case .de: return de(key)
        case .fr: return fr(key)
        }
    }

    // MARK: Hrvatski

    private static func hr(_ key: LKey) -> String {
        switch key {
        case .appName:              return "AMessages"
        case .unlockTitle:          return "Otključaj AMessages"
        case .unlockSubtitle:       return "Unesi svoj PIN ili povuci .secret datoteku."

        case .messengerTitle:       return "Razgovor"
        case .inputPlaceholder:     return "Napiši poruku…"

        case .settingsTitle:        return "Postavke"
        case .settingsGeneral:      return "Općenito"
        case .settingsNetwork:      return "Internet"
        case .settingsSecurity:     return "Sigurnost"
        case .settingsFiles:        return "Datoteke"
        case .settingsWidgets:      return "Widgeti"
        case .settingsAbout:        return "O aplikaciji"

        case .networkServerAddress:     return "Adresa servera"
        case .networkServerDescription: return "Glavni poslužitelj za razmjenu poruka."
        case .networkTestTitle:         return "Test konekcije"
        case .networkTestDescription:   return "Provjeri može li se aplikacija spojiti na zadani server."
        case .networkTestButton:        return "Testiraj konekciju"
        case .networkTesting:           return "Testiram..."
        case .networkOnline:            return "Online"
        case .networkFailed:            return "Neuspješno"

        // General / Općenito
        case .generalSectionTitle:
            return "Općenito"

        case .generalThemeTitle:
            return "Tema aplikacije"
        case .generalThemeDescription:
            return "Odaberi pozadinsku temu koja će se koristiti u svim prozorima aplikacije. Tema utječe na boje pozadine, kontrast i opći dojam sučelja."

        case .generalLanguageTitle:
            return "Jezik sučelja"
        case .generalLanguageDescription:
            return "Ovdje mijenjaš jezik teksta u aplikaciji (nazivi prozora, izbornici, poruke). Neke napredne opcije mogu ostati na engleskom dok ih ne prevedemo."

        case .generalSoundTitle:
            return "Zvučni efekti"
        case .generalSoundDescription:
            return "Uključi ili isključi kratke zvukove za nove poruke i radnje u aplikaciji. Ako radiš u tišini ili dijeliš ekran, možda želiš utišati zvukove."

        case .generalNotificationsTitle:
            return "Sistemske obavijesti"
        case .generalNotificationsDescription:
            return "Ako je omogućeno, macOS može prikazivati obavijesti kada stignu nove poruke, čak i dok je prozor aplikacije u pozadini."

        case .generalControlsTitle:
            return "Kontrole aplikacije"

        case .generalFocusModeTitle:
            return "Focus mode"
        case .generalFocusModeDescription:
            return "Kad je Focus mode uključen, sadržaj prozora se zamagli i potamni čim aplikacija izgubi fokus, tako da poruke i bilješke nisu čitljive sa strane."

        case .generalSessionIdTitle:
            return "Prikaži polje za Session ID"
        case .generalSessionIdDescription:
            return "Uključuje ili skriva polje za ručni unos Session ID-a u statusnoj traci. Korisno ako često ručno upisuješ ID ili ga želiš sakriti radi čišćeg izgleda."

        case .generalLockButtonTitle:
            return "Prikaži gumb za zaključavanje aplikacije"
        case .generalQuitButtonTitle:
            return "Prikaži gumb za izlazak iz aplikacije"
        case .generalHistoryButtonTitle:
            return "Prikaži gumb za arhivu/povijest"

        case .generalWindowsDisplayTitle:
            return "Prikaz prozora"
        case .generalWindowsDisplayDescription:
            return "Odaberi želiš li da se prozori prikazuju klasično kao odvojeni prozori ili kompaktnije kao lista. Ovo je priprema – kasnije ćemo povezati ovu opciju s dockom i rasporedom prozora."

        case .generalTipTitle:
            return "Savjet"
        case .generalTipMessage:
            return "Većinu ovih postavki možeš mijenjati bez ponovnog pokretanja aplikacije. Sigurnosne opcije i automatsko zaključavanje nalaze se u kartici Sigurnost, dok je ovdje naglasak na izgledu i osnovnom ponašanju sučelja."
        }
    }

    // MARK: English

    private static func en(_ key: LKey) -> String {
        switch key {
        case .appName:              return "AMessages"
        case .unlockTitle:          return "Unlock AMessages"
        case .unlockSubtitle:       return "Enter your PIN or drop a .secret file."

        case .messengerTitle:       return "Conversation"
        case .inputPlaceholder:     return "Type a message…"

        case .settingsTitle:        return "Settings"
        case .settingsGeneral:      return "General"
        case .settingsNetwork:      return "Network"
        case .settingsSecurity:     return "Security"
        case .settingsFiles:        return "Files"
        case .settingsWidgets:      return "Widgets"
        case .settingsAbout:        return "About"

        case .networkServerAddress:     return "Server address"
        case .networkServerDescription: return "Main message relay server."
        case .networkTestTitle:         return "Connection test"
        case .networkTestDescription:   return "Check if the app can reach the configured server."
        case .networkTestButton:        return "Test connection"
        case .networkTesting:           return "Testing..."
        case .networkOnline:            return "Online"
        case .networkFailed:            return "Failed"

        // General / Općenito
        case .generalSectionTitle:
            return "General"

        case .generalThemeTitle:
            return "App theme"
        case .generalThemeDescription:
            return "Choose the background theme that will be used in all app windows. The theme controls background colours, contrast and the overall look of the interface."

        case .generalLanguageTitle:
            return "Interface language"
        case .generalLanguageDescription:
            return "Change the language of the interface (window titles, menus, messages). Some advanced options may remain in English until they are translated."

        case .generalSoundTitle:
            return "Sound effects"
        case .generalSoundDescription:
            return "Enable or disable short sounds for new messages and app actions. If you work in silence or share your screen, you might want to turn them off."

        case .generalNotificationsTitle:
            return "System notifications"
        case .generalNotificationsDescription:
            return "If enabled, macOS can show notifications when new messages arrive, even while the app window is in the background."

        case .generalControlsTitle:
            return "App controls"

        case .generalFocusModeTitle:
            return "Focus mode"
        case .generalFocusModeDescription:
            return "When Focus mode is enabled, the window content is blurred and darkened as soon as the app loses focus, so messages and notes are not readable from the side."

        case .generalSessionIdTitle:
            return "Show Session ID field"
        case .generalSessionIdDescription:
            return "Shows or hides the text field for manually entering a Session ID in the status bar. Useful if you often type IDs by hand, or want a cleaner look."

        case .generalLockButtonTitle:
            return "Show lock button"
        case .generalQuitButtonTitle:
            return "Show quit button"
        case .generalHistoryButtonTitle:
            return "Show history/archive button"

        case .generalWindowsDisplayTitle:
            return "Window display"
        case .generalWindowsDisplayDescription:
            return "Choose whether windows should appear as classic separate windows or in a more compact list-style layout. This is a preparation option – later we will connect it to the dock and window layout."

        case .generalTipTitle:
            return "Tip"
        case .generalTipMessage:
            return "Most of these settings can be changed without restarting the app. Security options and auto-lock live under the Security tab – here the focus is on appearance and basic interface behaviour."
        }
    }

    // MARK: Deutsch

    private static func de(_ key: LKey) -> String {
        switch key {
        case .appName:              return "AMessages"
        case .unlockTitle:          return "AMessages entsperren"
        case .unlockSubtitle:       return "PIN eingeben oder .secret-Datei ziehen."

        case .messengerTitle:       return "Gespräch"
        case .inputPlaceholder:     return "Nachricht schreiben…"

        case .settingsTitle:        return "Einstellungen"
        case .settingsGeneral:      return "Allgemein"
        case .settingsNetwork:      return "Netzwerk"
        case .settingsSecurity:     return "Sicherheit"
        case .settingsFiles:        return "Dateien"
        case .settingsWidgets:      return "Widgets"
        case .settingsAbout:        return "Über die App"

        case .networkServerAddress:     return "Serveradresse"
        case .networkServerDescription: return "Hauptserver für Nachrichten."
        case .networkTestTitle:         return "Verbindungstest"
        case .networkTestDescription:   return "Prüfen, ob die App den Server erreicht."
        case .networkTestButton:        return "Verbindung testen"
        case .networkTesting:           return "Teste..."
        case .networkOnline:            return "Online"
        case .networkFailed:            return "Fehlgeschlagen"

        // General / Općenito
        case .generalSectionTitle:
            return "Allgemein"

        case .generalThemeTitle:
            return "App-Design"
        case .generalThemeDescription:
            return "Wähle das Hintergrund-Design, das in allen Fenstern verwendet wird. Das Design steuert die Hintergrundfarben, den Kontrast und den Gesamteindruck der Oberfläche."

        case .generalLanguageTitle:
            return "Sprache der Oberfläche"
        case .generalLanguageDescription:
            return "Hier änderst du die Sprache der Oberfläche (Fenstertitel, Menüs, Meldungen). Einige erweiterte Optionen bleiben möglicherweise vorübergehend auf Englisch."

        case .generalSoundTitle:
            return "Soundeffekte"
        case .generalSoundDescription:
            return "Aktiviere oder deaktiviere kurze Sounds für neue Nachrichten und Aktionen. Wenn du in Ruhe arbeitest oder den Bildschirm teilst, kannst du die Sounds ausschalten."

        case .generalNotificationsTitle:
            return "System-Benachrichtigungen"
        case .generalNotificationsDescription:
            return "Wenn aktiviert, kann macOS Benachrichtigungen anzeigen, wenn neue Nachrichten ankommen – auch wenn das Fenster im Hintergrund ist."

        case .generalControlsTitle:
            return "App-Steuerung"

        case .generalFocusModeTitle:
            return "Fokus-Modus"
        case .generalFocusModeDescription:
            return "Wenn der Fokus-Modus aktiv ist, wird der Fensterinhalt unscharf und abgedunkelt, sobald die App den Fokus verliert. So sind Nachrichten nicht von der Seite lesbar."

        case .generalSessionIdTitle:
            return "Session-ID-Feld anzeigen"
        case .generalSessionIdDescription:
            return "Blendet das Textfeld für die manuelle Eingabe einer Session-ID in der Statusleiste ein oder aus. Praktisch, wenn du IDs oft von Hand eingibst oder die Leiste aufräumen willst."

        case .generalLockButtonTitle:
            return "Sperr-Taste anzeigen"
        case .generalQuitButtonTitle:
            return "Beenden-Taste anzeigen"
        case .generalHistoryButtonTitle:
            return "Verlauf/Archiv-Taste anzeigen"

        case .generalWindowsDisplayTitle:
            return "Fensterdarstellung"
        case .generalWindowsDisplayDescription:
            return "Lege fest, ob Fenster klassisch getrennt oder kompakter als Liste dargestellt werden sollen. Diese Option ist eine Vorbereitung – später wird sie mit Dock und Layout verknüpft."

        case .generalTipTitle:
            return "Hinweis"
        case .generalTipMessage:
            return "Die meisten dieser Einstellungen können ohne Neustart der App geändert werden. Sicherheitsoptionen und Auto-Sperre findest du im Tab „Sicherheit“ – hier geht es hauptsächlich um Aussehen und Basis-Verhalten der Oberfläche."
        }
    }

    // MARK: Français

    private static func fr(_ key: LKey) -> String {
        switch key {
        case .appName:              return "AMessages"
        case .unlockTitle:          return "Déverrouiller AMessages"
        case .unlockSubtitle:       return "Saisissez votre PIN ou déposez un fichier .secret."

        case .messengerTitle:       return "Conversation"
        case .inputPlaceholder:     return "Écrire un message…"

        case .settingsTitle:        return "Réglages"
        case .settingsGeneral:      return "Général"
        case .settingsNetwork:      return "Internet"
        case .settingsSecurity:     return "Sécurité"
        case .settingsFiles:        return "Fichiers"
        case .settingsWidgets:      return "Widgets"
        case .settingsAbout:        return "À propos"

        case .networkServerAddress:     return "Adresse du serveur"
        case .networkServerDescription: return "Serveur principal de messagerie."
        case .networkTestTitle:         return "Test de connexion"
        case .networkTestDescription:   return "Vérifiez si l'app peut joindre le serveur."
        case .networkTestButton:        return "Tester la connexion"
        case .networkTesting:           return "Test en cours..."
        case .networkOnline:            return "En ligne"
        case .networkFailed:            return "Échec"

        // General / Općenito
        case .generalSectionTitle:
            return "Général"

        case .generalThemeTitle:
            return "Thème de l’application"
        case .generalThemeDescription:
            return "Choisissez le thème d’arrière-plan utilisé dans toutes les fenêtres. Le thème définit les couleurs de fond, le contraste et l’apparence générale de l’interface."

        case .generalLanguageTitle:
            return "Langue de l’interface"
        case .generalLanguageDescription:
            return "Modifiez ici la langue de l’interface (titres de fenêtres, menus, messages). Certaines options avancées peuvent rester en anglais en attendant leur traduction."

        case .generalSoundTitle:
            return "Effets sonores"
        case .generalSoundDescription:
            return "Activez ou désactivez les sons courts pour les nouveaux messages et les actions de l’app. Si vous travaillez en silence ou partagez votre écran, vous pouvez les couper."

        case .generalNotificationsTitle:
            return "Notifications système"
        case .generalNotificationsDescription:
            return "Si activé, macOS peut afficher des notifications lorsque de nouveaux messages arrivent, même si la fenêtre de l’app est en arrière-plan."

        case .generalControlsTitle:
            return "Contrôles de l’application"

        case .generalFocusModeTitle:
            return "Mode focus"
        case .generalFocusModeDescription:
            return "Lorsque le mode focus est activé, le contenu de la fenêtre est flouté et assombri dès que l’app perd le focus, afin que les messages restent illisibles de côté."

        case .generalSessionIdTitle:
            return "Afficher le champ ID de session"
        case .generalSessionIdDescription:
            return "Affiche ou masque le champ de saisie de l’ID de session dans la barre d’état. Pratique si vous saisissez souvent des ID à la main ou si vous préférez une barre épurée."

        case .generalLockButtonTitle:
            return "Afficher le bouton de verrouillage"
        case .generalQuitButtonTitle:
            return "Afficher le bouton Quitter"
        case .generalHistoryButtonTitle:
            return "Afficher le bouton historique/archives"

        case .generalWindowsDisplayTitle:
            return "Affichage des fenêtres"
        case .generalWindowsDisplayDescription:
            return "Choisissez si les fenêtres doivent apparaître comme des fenêtres classiques séparées ou sous forme de liste plus compacte. Cette option prépare un futur comportement lié au dock et à la disposition des fenêtres."

        case .generalTipTitle:
            return "Astuce"
        case .generalTipMessage:
            return "La plupart de ces réglages peuvent être modifiés sans redémarrer l’app. Les options de sécurité et le verrouillage automatique se trouvent dans l’onglet Sécurité – ici, on se concentre sur l’apparence et le comportement général de l’interface."
        }
    }
}

// MARK: - ObservableObject za cijelu app

final class Localization: ObservableObject {
    static let shared = Localization()

    @Published var currentLanguage: ApplicationLanguage

    private init() {
        if let raw = UserDefaults.standard.string(forKey: "app_language"),
           let lang = ApplicationLanguage(rawValue: raw) {
            currentLanguage = lang
        } else {
            currentLanguage = .hr
        }
    }

    func setLanguage(_ lang: ApplicationLanguage) {
        guard lang != currentLanguage else { return }
        currentLanguage = lang
        UserDefaults.standard.set(lang.rawValue, forKey: "app_language")
    }

    /// Kratki helper: lokalizirani tekst za trenutni jezik
    func text(_ key: LKey) -> String {
        I18n.t(key, currentLanguage)
    }
}
