import Foundation

private enum AppTextKey: String {
    case appName
    case statusRunnerTitle
    case statusActivityTitle
    case statusNetworkTitle
    case statusModeTitle
    case statusLaunchAtLoginTitle
    case buttonManualStart
    case buttonManualStop
    case buttonAutomaticMode
    case buttonRefresh
    case toggleLaunchAtLogin
    case buttonOpenLoginItemsSettings
    case buttonOpenRunnerDirectory
    case buttonOpenUpdateWindow
    case buttonOpenAboutWindow
    case aboutWindowTitle
    case aboutDescription
    case buttonOpenAuthorGitHub
    case buttonOpenAuthorX
    case buttonOpenRepository
    case updateWindowTitle
    case updateDescription
    case updateInstalledVersionTitle
    case updateLatestVersionTitle
    case updateStatusTitle
    case updateUnknownVersion
    case buttonCheckForUpdates
    case buttonInstallUpdate
    case buttonOpenReleasePage
    case updateIdle
    case updateChecking
    case updateUpToDate
    case updateAvailableFallback
    case updateDownloading
    case updateInstalling
    case updateErrorInvalidResponse
    case updateErrorNoPublishedRelease
    case updateErrorMissingAsset
    case updateErrorDownload
    case updateErrorOpenInstaller
    case updateErrorNoRelease
    case buttonQuit
    case runnerRunning
    case runnerStopped
    case controlModeAutomatic
    case controlModeForceRunning
    case controlModeForceStopped
    case policyAutomaticRun
    case policyAutomaticExpensive
    case policyAutomaticOffline
    case policyAutomaticUnknown
    case policyForceRunning
    case policyForceStopped
    case launchAtLoginEnabled
    case launchAtLoginRequiresApproval
    case launchAtLoginDisabled
    case launchAtLoginUnavailable
    case launchAtLoginUnknown
    case activityWorkingJob
    case activityWaitingForJob
    case activityStopping
    case activityWaitingOrStarting
    case activityRunnerStopped
    case activityUnknown
    case networkChecking
    case networkNoInternet
    case networkMetered
    case networkUnmetered
    case interfaceEthernet
    case interfaceWiFi
    case interfaceCellular
    case interfaceOther
    case interfaceGeneric
    case errorMissingRunnerScript
    case errorLaunchAtLoginUpdate
    case errorRunnerHandling
}

enum AppStrings {
    private typealias Catalog = [AppTextKey: String]

    // Based on Apple's published app localization language and locale identifiers,
    // with Bundle language matching used for macOS-preferred language fallback.
    static let supportedLanguageIdentifiers = [
        "en",
        "en-AU",
        "en-CA",
        "en-GB",
        "en-US",
        "hu",
        "ar",
        "bn",
        "ca",
        "cs",
        "da",
        "de",
        "el",
        "es-ES",
        "es-MX",
        "fi",
        "fr",
        "fr-CA",
        "gu",
        "he",
        "hi",
        "hr",
        "id",
        "it",
        "ja",
        "kn",
        "ko",
        "ml",
        "mr",
        "ms",
        "nb",
        "nn",
        "no",
        "nl",
        "or",
        "pa",
        "pl",
        "pt-BR",
        "pt-PT",
        "ro",
        "ru",
        "sk",
        "sl",
        "sv",
        "ta",
        "te",
        "th",
        "tr",
        "uk",
        "ur",
        "vi",
        "zh-Hans",
        "zh-Hant",
    ]

    private static let fallbackLanguage = "en"

    private static let matchedLanguageIdentifier: String = {
        Bundle.preferredLocalizations(
            from: supportedLanguageIdentifiers,
            forPreferences: Locale.preferredLanguages
        ).first ?? fallbackLanguage
    }()

    private static let activeLanguageFamily = languageFamily(for: matchedLanguageIdentifier)

    private static let english: Catalog = [
        .appName: "github runer mac",
        .statusRunnerTitle: "Runner",
        .statusActivityTitle: "Activity",
        .statusNetworkTitle: "Network",
        .statusModeTitle: "Mode",
        .statusLaunchAtLoginTitle: "Launch at login",
        .buttonManualStart: "Start manually",
        .buttonManualStop: "Stop manually",
        .buttonAutomaticMode: "Automatic mode",
        .buttonRefresh: "Refresh",
        .toggleLaunchAtLogin: "Launch automatically at login",
        .buttonOpenLoginItemsSettings: "Open Login Items settings",
        .buttonOpenRunnerDirectory: "Open runner folder",
        .buttonOpenUpdateWindow: "Check for updates",
        .buttonOpenAboutWindow: "About and links",
        .aboutWindowTitle: "About github runer mac",
        .aboutDescription: "Created by Benedek Koncsik. Open the profile pages or the project repository directly from the menu.",
        .buttonOpenAuthorGitHub: "GitHub profile",
        .buttonOpenAuthorX: "X profile",
        .buttonOpenRepository: "Project repository",
        .updateWindowTitle: "Software update",
        .updateDescription: "Check the latest GitHub release and open the downloaded macOS DMG installer.",
        .updateInstalledVersionTitle: "Installed version",
        .updateLatestVersionTitle: "Latest version",
        .updateStatusTitle: "Status",
        .updateUnknownVersion: "Not checked yet",
        .buttonCheckForUpdates: "Check now",
        .buttonInstallUpdate: "Download installer",
        .buttonOpenReleasePage: "Open release page",
        .updateIdle: "Ready to check for updates.",
        .updateChecking: "Checking GitHub releases...",
        .updateUpToDate: "You already have the latest version.",
        .updateAvailableFallback: "A newer version is available.",
        .updateDownloading: "Downloading the new version...",
        .updateInstalling: "Opening the downloaded installer...",
        .updateErrorInvalidResponse: "The update server returned an unexpected response.",
        .updateErrorNoPublishedRelease: "No published GitHub release is available yet for this repository.",
        .updateErrorMissingAsset: "The latest release does not contain a macOS app download.",
        .updateErrorDownload: "The update package could not be downloaded.",
        .updateErrorOpenInstaller: "The downloaded installer could not be opened.",
        .updateErrorNoRelease: "There is no downloadable release selected.",
        .buttonQuit: "Quit",
        .runnerRunning: "Running",
        .runnerStopped: "Stopped",
        .controlModeAutomatic: "Automatic",
        .controlModeForceRunning: "Forced running",
        .controlModeForceStopped: "Forced stopped",
        .policyAutomaticRun: "In automatic mode the runner may run.",
        .policyAutomaticExpensive: "In automatic mode the runner stops on a metered connection.",
        .policyAutomaticOffline: "In automatic mode the runner stops when there is no internet.",
        .policyAutomaticUnknown: "In automatic mode the app is still checking the network.",
        .policyForceRunning: "Manual override keeps the runner running regardless of network rules.",
        .policyForceStopped: "Manual override keeps the runner stopped.",
        .launchAtLoginEnabled: "Enabled",
        .launchAtLoginRequiresApproval: "Approval required",
        .launchAtLoginDisabled: "Disabled",
        .launchAtLoginUnavailable: "Unavailable in this build",
        .launchAtLoginUnknown: "Unknown",
        .activityWorkingJob: "Working: %@",
        .activityWaitingForJob: "Waiting for jobs",
        .activityStopping: "Stopping",
        .activityWaitingOrStarting: "Waiting or starting",
        .activityRunnerStopped: "The runner is stopped",
        .activityUnknown: "Unknown status",
        .networkChecking: "Checking network...",
        .networkNoInternet: "No internet connection",
        .networkMetered: "%@, metered",
        .networkUnmetered: "%@, unmetered",
        .interfaceEthernet: "Ethernet",
        .interfaceWiFi: "Wi-Fi",
        .interfaceCellular: "Cellular",
        .interfaceOther: "Other connection",
        .interfaceGeneric: "Connection",
        .errorMissingRunnerScript: "Cannot find the runner startup script: %@",
        .errorLaunchAtLoginUpdate: "Failed to update launch at login: %@",
        .errorRunnerHandling: "Failed to manage the runner: %@",
    ]

    private static func catalog(_ overrides: Catalog) -> Catalog {
        english.merging(overrides) { _, new in new }
    }

    private static let catalogs: [String: Catalog] = [
        "en": english,
        "hu": [
            .appName: "github runer mac",
            .statusRunnerTitle: "Runner",
            .statusActivityTitle: "Munka",
            .statusNetworkTitle: "Hálózat",
            .statusModeTitle: "Mód",
            .statusLaunchAtLoginTitle: "Induláskor",
            .buttonManualStart: "Indítás kézzel",
            .buttonManualStop: "Leállítás kézzel",
            .buttonAutomaticMode: "Automatikus mód",
            .buttonRefresh: "Frissítés",
            .toggleLaunchAtLogin: "Induljon automatikusan bejelentkezéskor",
            .buttonOpenLoginItemsSettings: "Login Items beállítások megnyitása",
            .buttonOpenRunnerDirectory: "Runner mappa megnyitása",
            .buttonOpenUpdateWindow: "Frissítések keresése",
            .buttonOpenAboutWindow: "Névjegy és linkek",
            .aboutWindowTitle: "github runer mac névjegy",
            .aboutDescription: "Készítette Benedek Koncsik. Innen közvetlenül megnyithatod a profiloldalakat és a projekt repositoryját.",
            .buttonOpenAuthorGitHub: "GitHub profil",
            .buttonOpenAuthorX: "X profil",
            .buttonOpenRepository: "Projekt repository",
            .updateWindowTitle: "Szoftverfrissítés",
            .updateDescription: "Ellenőrzi a legfrissebb GitHub release-t, letölti és megnyitja a macOS DMG telepítőt.",
            .updateInstalledVersionTitle: "Telepített verzió",
            .updateLatestVersionTitle: "Legfrissebb verzió",
            .updateStatusTitle: "Állapot",
            .updateUnknownVersion: "Még nincs ellenőrizve",
            .buttonCheckForUpdates: "Ellenőrzés",
            .buttonInstallUpdate: "Telepítő letöltése",
            .buttonOpenReleasePage: "Release oldal megnyitása",
            .updateIdle: "Készen áll a frissítések ellenőrzésére.",
            .updateChecking: "GitHub release-ek ellenőrzése...",
            .updateUpToDate: "Már a legfrissebb verzió van telepítve.",
            .updateAvailableFallback: "Elérhető egy újabb verzió.",
            .updateDownloading: "Az új verzió letöltése folyamatban...",
            .updateInstalling: "A letöltött telepítő megnyitása...",
            .updateErrorInvalidResponse: "A frissítési kiszolgáló váratlan választ adott.",
            .updateErrorNoPublishedRelease: "Ehhez a repositoryhoz még nincs közzétett GitHub release.",
            .updateErrorMissingAsset: "A legfrissebb release nem tartalmaz letölthető macOS alkalmazást.",
            .updateErrorDownload: "Nem sikerült letölteni a frissítő csomagot.",
            .updateErrorOpenInstaller: "Nem sikerült megnyitni a letöltött telepítőt.",
            .updateErrorNoRelease: "Nincs kiválasztott letölthető release.",
            .buttonQuit: "Kilépés",
            .runnerRunning: "Fut",
            .runnerStopped: "Leállítva",
            .controlModeAutomatic: "Automatikus",
            .controlModeForceRunning: "Kézileg fut",
            .controlModeForceStopped: "Kézileg leállítva",
            .policyAutomaticRun: "Automatikus módban a runner futhat.",
            .policyAutomaticExpensive: "Automatikus módban a runner megáll, mert a kapcsolat korlátos.",
            .policyAutomaticOffline: "Automatikus módban a runner megáll, mert nincs internet.",
            .policyAutomaticUnknown: "Automatikus módban a hálózat vizsgálata folyamatban van.",
            .policyForceRunning: "Kézi felülbírálattal fut, a hálózati szabály most nem állítja le.",
            .policyForceStopped: "Kézi felülbírálattal leállítva marad.",
            .launchAtLoginEnabled: "Engedélyezve",
            .launchAtLoginRequiresApproval: "Jóváhagyás szükséges",
            .launchAtLoginDisabled: "Kikapcsolva",
            .launchAtLoginUnavailable: "Ebben a buildben nem érhető el",
            .launchAtLoginUnknown: "Ismeretlen",
            .activityWorkingJob: "Dolgozik: %@",
            .activityWaitingForJob: "Várakozik feladatra",
            .activityStopping: "Leállás folyamatban",
            .activityWaitingOrStarting: "Várakozik vagy indul",
            .activityRunnerStopped: "A runner le van állítva",
            .activityUnknown: "Állapot ismeretlen",
            .networkChecking: "Hálózat ellenőrzése...",
            .networkNoInternet: "Nincs elérhető internet",
            .networkMetered: "%@, forgalomkorlátos",
            .networkUnmetered: "%@, nem forgalomkorlátos",
            .interfaceEthernet: "Ethernet",
            .interfaceWiFi: "Wi-Fi",
            .interfaceCellular: "Mobilhálózat",
            .interfaceOther: "Másik kapcsolat",
            .interfaceGeneric: "Kapcsolat",
            .errorMissingRunnerScript: "Nem találom a runner indító scriptet: %@",
            .errorLaunchAtLoginUpdate: "Az automatikus indítás beállítása nem sikerült: %@",
            .errorRunnerHandling: "Nem sikerült a runner kezelése: %@",
        ],
        "de": catalog([
            .statusActivityTitle: "Aktivität",
            .statusNetworkTitle: "Netzwerk",
            .statusModeTitle: "Modus",
            .statusLaunchAtLoginTitle: "Beim Login starten",
            .buttonManualStart: "Manuell starten",
            .buttonManualStop: "Manuell stoppen",
            .buttonAutomaticMode: "Automatischer Modus",
            .buttonRefresh: "Aktualisieren",
            .toggleLaunchAtLogin: "Beim Login automatisch starten",
            .buttonOpenLoginItemsSettings: "Login-Objekte öffnen",
            .buttonOpenRunnerDirectory: "Runner-Ordner öffnen",
            .buttonQuit: "Beenden",
            .runnerRunning: "Läuft",
            .runnerStopped: "Gestoppt",
            .controlModeAutomatic: "Automatisch",
            .controlModeForceRunning: "Erzwungen aktiv",
            .controlModeForceStopped: "Erzwungen gestoppt",
            .activityWaitingForJob: "Wartet auf Jobs",
            .activityRunnerStopped: "Der Runner ist gestoppt",
            .networkChecking: "Netzwerk wird geprüft...",
            .networkNoInternet: "Keine Internetverbindung",
        ]),
        "fr": catalog([
            .statusActivityTitle: "Activité",
            .statusNetworkTitle: "Réseau",
            .statusModeTitle: "Mode",
            .statusLaunchAtLoginTitle: "Au démarrage",
            .buttonManualStart: "Démarrer manuellement",
            .buttonManualStop: "Arrêter manuellement",
            .buttonAutomaticMode: "Mode automatique",
            .buttonRefresh: "Actualiser",
            .toggleLaunchAtLogin: "Lancer automatiquement à la connexion",
            .buttonOpenLoginItemsSettings: "Ouvrir Réglages des éléments de connexion",
            .buttonOpenRunnerDirectory: "Ouvrir le dossier du runner",
            .buttonQuit: "Quitter",
            .runnerRunning: "En cours",
            .runnerStopped: "Arrêté",
            .controlModeAutomatic: "Automatique",
            .controlModeForceRunning: "Forcé en marche",
            .controlModeForceStopped: "Forcé à l'arrêt",
            .activityWaitingForJob: "En attente de tâches",
            .activityRunnerStopped: "Le runner est arrêté",
            .networkChecking: "Vérification du réseau...",
            .networkNoInternet: "Aucune connexion internet",
        ]),
        "es": catalog([
            .statusActivityTitle: "Actividad",
            .statusNetworkTitle: "Red",
            .statusModeTitle: "Modo",
            .statusLaunchAtLoginTitle: "Al iniciar sesión",
            .buttonManualStart: "Iniciar manualmente",
            .buttonManualStop: "Detener manualmente",
            .buttonAutomaticMode: "Modo automático",
            .buttonRefresh: "Actualizar",
            .toggleLaunchAtLogin: "Iniciar automáticamente al iniciar sesión",
            .buttonOpenLoginItemsSettings: "Abrir ajustes de ítems de inicio",
            .buttonOpenRunnerDirectory: "Abrir carpeta del runner",
            .buttonQuit: "Salir",
            .runnerRunning: "En ejecución",
            .runnerStopped: "Detenido",
            .controlModeAutomatic: "Automático",
            .controlModeForceRunning: "Forzado en ejecución",
            .controlModeForceStopped: "Forzado detenido",
            .activityWaitingForJob: "Esperando trabajos",
            .activityRunnerStopped: "El runner está detenido",
            .networkChecking: "Comprobando red...",
            .networkNoInternet: "Sin conexión a internet",
        ]),
        "it": catalog([
            .statusActivityTitle: "Attività",
            .statusNetworkTitle: "Rete",
            .statusModeTitle: "Modalità",
            .statusLaunchAtLoginTitle: "All'accesso",
            .buttonManualStart: "Avvia manualmente",
            .buttonManualStop: "Ferma manualmente",
            .buttonAutomaticMode: "Modalità automatica",
            .buttonRefresh: "Aggiorna",
            .toggleLaunchAtLogin: "Avvia automaticamente all'accesso",
            .buttonOpenLoginItemsSettings: "Apri impostazioni elementi login",
            .buttonOpenRunnerDirectory: "Apri cartella runner",
            .buttonQuit: "Esci",
            .runnerRunning: "In esecuzione",
            .runnerStopped: "Fermo",
            .controlModeAutomatic: "Automatica",
            .controlModeForceRunning: "Avvio forzato",
            .controlModeForceStopped: "Arresto forzato",
            .activityWaitingForJob: "In attesa di job",
            .activityRunnerStopped: "Il runner è fermo",
            .networkChecking: "Controllo rete...",
            .networkNoInternet: "Nessuna connessione internet",
        ]),
        "nl": catalog([
            .statusActivityTitle: "Activiteit",
            .statusNetworkTitle: "Netwerk",
            .statusModeTitle: "Modus",
            .statusLaunchAtLoginTitle: "Bij inloggen",
            .buttonManualStart: "Handmatig starten",
            .buttonManualStop: "Handmatig stoppen",
            .buttonAutomaticMode: "Automatische modus",
            .buttonRefresh: "Verversen",
            .toggleLaunchAtLogin: "Automatisch starten bij inloggen",
            .buttonOpenLoginItemsSettings: "Login-items instellingen openen",
            .buttonOpenRunnerDirectory: "Runner-map openen",
            .buttonQuit: "Stoppen",
            .runnerRunning: "Actief",
            .runnerStopped: "Gestopt",
            .controlModeAutomatic: "Automatisch",
            .controlModeForceRunning: "Geforceerd actief",
            .controlModeForceStopped: "Geforceerd gestopt",
            .activityWaitingForJob: "Wacht op taken",
            .activityRunnerStopped: "De runner is gestopt",
            .networkChecking: "Netwerk controleren...",
            .networkNoInternet: "Geen internetverbinding",
        ]),
        "cs": catalog([
            .statusActivityTitle: "Aktivita",
            .statusNetworkTitle: "Síť",
            .statusModeTitle: "Režim",
            .statusLaunchAtLoginTitle: "Při přihlášení",
            .buttonManualStart: "Spustit ručně",
            .buttonManualStop: "Zastavit ručně",
            .buttonAutomaticMode: "Automatický režim",
            .buttonRefresh: "Obnovit",
            .toggleLaunchAtLogin: "Spouštět automaticky po přihlášení",
            .buttonOpenLoginItemsSettings: "Otevřít nastavení položek po přihlášení",
            .buttonOpenRunnerDirectory: "Otevřít složku runneru",
            .buttonQuit: "Ukončit",
            .runnerRunning: "Spuštěno",
            .runnerStopped: "Zastaveno",
            .networkChecking: "Kontrola sítě...",
            .networkNoInternet: "Bez připojení k internetu",
        ]),
        "da": catalog([
            .statusActivityTitle: "Aktivitet",
            .statusNetworkTitle: "Netværk",
            .statusModeTitle: "Tilstand",
            .statusLaunchAtLoginTitle: "Ved login",
            .buttonManualStart: "Start manuelt",
            .buttonManualStop: "Stop manuelt",
            .buttonAutomaticMode: "Automatisk tilstand",
            .buttonRefresh: "Opdater",
            .toggleLaunchAtLogin: "Start automatisk ved login",
            .buttonOpenLoginItemsSettings: "Åbn loginobjekter",
            .buttonOpenRunnerDirectory: "Åbn runner-mappe",
            .buttonQuit: "Afslut",
            .runnerRunning: "Kører",
            .runnerStopped: "Stoppet",
            .networkChecking: "Kontrollerer netværk...",
            .networkNoInternet: "Ingen internetforbindelse",
        ]),
        "fi": catalog([
            .statusActivityTitle: "Toiminta",
            .statusNetworkTitle: "Verkko",
            .statusModeTitle: "Tila",
            .statusLaunchAtLoginTitle: "Kirjautuessa",
            .buttonManualStart: "Käynnistä käsin",
            .buttonManualStop: "Pysäytä käsin",
            .buttonAutomaticMode: "Automaattinen tila",
            .buttonRefresh: "Päivitä",
            .toggleLaunchAtLogin: "Käynnistä automaattisesti kirjautuessa",
            .buttonOpenLoginItemsSettings: "Avaa kirjautumiskohteiden asetukset",
            .buttonOpenRunnerDirectory: "Avaa runner-kansio",
            .buttonQuit: "Lopeta",
            .runnerRunning: "Käynnissä",
            .runnerStopped: "Pysäytetty",
            .networkChecking: "Tarkistetaan verkkoa...",
            .networkNoInternet: "Ei internetyhteyttä",
        ]),
        "no": catalog([
            .statusActivityTitle: "Aktivitet",
            .statusNetworkTitle: "Nettverk",
            .statusModeTitle: "Modus",
            .statusLaunchAtLoginTitle: "Ved innlogging",
            .buttonManualStart: "Start manuelt",
            .buttonManualStop: "Stopp manuelt",
            .buttonAutomaticMode: "Automatisk modus",
            .buttonRefresh: "Oppdater",
            .toggleLaunchAtLogin: "Start automatisk ved innlogging",
            .buttonOpenLoginItemsSettings: "Åpne innstillinger for innloggingselementer",
            .buttonOpenRunnerDirectory: "Åpne runner-mappe",
            .buttonQuit: "Avslutt",
            .runnerRunning: "Kjører",
            .runnerStopped: "Stoppet",
            .networkChecking: "Sjekker nettverk...",
            .networkNoInternet: "Ingen internettforbindelse",
        ]),
        "pl": catalog([
            .statusActivityTitle: "Aktywność",
            .statusNetworkTitle: "Sieć",
            .statusModeTitle: "Tryb",
            .statusLaunchAtLoginTitle: "Przy logowaniu",
            .buttonManualStart: "Uruchom ręcznie",
            .buttonManualStop: "Zatrzymaj ręcznie",
            .buttonAutomaticMode: "Tryb automatyczny",
            .buttonRefresh: "Odśwież",
            .toggleLaunchAtLogin: "Uruchamiaj automatycznie po zalogowaniu",
            .buttonOpenLoginItemsSettings: "Otwórz ustawienia elementów logowania",
            .buttonOpenRunnerDirectory: "Otwórz folder runnera",
            .buttonQuit: "Zakończ",
            .runnerRunning: "Uruchomiony",
            .runnerStopped: "Zatrzymany",
            .networkChecking: "Sprawdzanie sieci...",
            .networkNoInternet: "Brak połączenia z internetem",
        ]),
        "pt-BR": catalog([
            .statusActivityTitle: "Atividade",
            .statusNetworkTitle: "Rede",
            .statusModeTitle: "Modo",
            .statusLaunchAtLoginTitle: "Ao iniciar sessão",
            .buttonManualStart: "Iniciar manualmente",
            .buttonManualStop: "Parar manualmente",
            .buttonAutomaticMode: "Modo automático",
            .buttonRefresh: "Atualizar",
            .toggleLaunchAtLogin: "Iniciar automaticamente ao iniciar sessão",
            .buttonOpenLoginItemsSettings: "Abrir ajustes dos itens de início",
            .buttonOpenRunnerDirectory: "Abrir pasta do runner",
            .buttonQuit: "Sair",
            .runnerRunning: "Em execução",
            .runnerStopped: "Parado",
            .networkChecking: "Verificando rede...",
            .networkNoInternet: "Sem conexão com a internet",
        ]),
        "pt-PT": catalog([
            .statusActivityTitle: "Atividade",
            .statusNetworkTitle: "Rede",
            .statusModeTitle: "Modo",
            .statusLaunchAtLoginTitle: "Ao iniciar sessão",
            .buttonManualStart: "Iniciar manualmente",
            .buttonManualStop: "Parar manualmente",
            .buttonAutomaticMode: "Modo automático",
            .buttonRefresh: "Atualizar",
            .toggleLaunchAtLogin: "Iniciar automaticamente ao iniciar sessão",
            .buttonOpenLoginItemsSettings: "Abrir definições dos itens de início",
            .buttonOpenRunnerDirectory: "Abrir pasta do runner",
            .buttonQuit: "Sair",
            .runnerRunning: "Em execução",
            .runnerStopped: "Parado",
            .networkChecking: "A verificar rede...",
            .networkNoInternet: "Sem ligação à internet",
        ]),
        "ro": catalog([
            .statusActivityTitle: "Activitate",
            .statusNetworkTitle: "Rețea",
            .statusModeTitle: "Mod",
            .statusLaunchAtLoginTitle: "La autentificare",
            .buttonManualStart: "Pornește manual",
            .buttonManualStop: "Oprește manual",
            .buttonAutomaticMode: "Mod automat",
            .buttonRefresh: "Reîmprospătează",
            .toggleLaunchAtLogin: "Pornește automat la autentificare",
            .buttonOpenLoginItemsSettings: "Deschide setările elementelor de autentificare",
            .buttonOpenRunnerDirectory: "Deschide dosarul runnerului",
            .buttonQuit: "Ieșire",
            .runnerRunning: "Rulează",
            .runnerStopped: "Oprit",
            .networkChecking: "Se verifică rețeaua...",
            .networkNoInternet: "Fără conexiune la internet",
        ]),
        "ru": catalog([
            .statusActivityTitle: "Активность",
            .statusNetworkTitle: "Сеть",
            .statusModeTitle: "Режим",
            .statusLaunchAtLoginTitle: "При входе",
            .buttonManualStart: "Запустить вручную",
            .buttonManualStop: "Остановить вручную",
            .buttonAutomaticMode: "Автоматический режим",
            .buttonRefresh: "Обновить",
            .toggleLaunchAtLogin: "Запускать автоматически при входе",
            .buttonOpenLoginItemsSettings: "Открыть настройки объектов входа",
            .buttonOpenRunnerDirectory: "Открыть папку runner",
            .buttonQuit: "Выйти",
            .runnerRunning: "Запущен",
            .runnerStopped: "Остановлен",
            .networkChecking: "Проверка сети...",
            .networkNoInternet: "Нет подключения к интернету",
        ]),
        "sv": catalog([
            .statusActivityTitle: "Aktivitet",
            .statusNetworkTitle: "Nätverk",
            .statusModeTitle: "Läge",
            .statusLaunchAtLoginTitle: "Vid inloggning",
            .buttonManualStart: "Starta manuellt",
            .buttonManualStop: "Stoppa manuellt",
            .buttonAutomaticMode: "Automatiskt läge",
            .buttonRefresh: "Uppdatera",
            .toggleLaunchAtLogin: "Starta automatiskt vid inloggning",
            .buttonOpenLoginItemsSettings: "Öppna inställningar för inloggningsobjekt",
            .buttonOpenRunnerDirectory: "Öppna runner-mapp",
            .buttonQuit: "Avsluta",
            .runnerRunning: "Körs",
            .runnerStopped: "Stoppad",
            .networkChecking: "Kontrollerar nätverk...",
            .networkNoInternet: "Ingen internetanslutning",
        ]),
        "tr": catalog([
            .statusActivityTitle: "Etkinlik",
            .statusNetworkTitle: "Ağ",
            .statusModeTitle: "Mod",
            .statusLaunchAtLoginTitle: "Girişte",
            .buttonManualStart: "Elle başlat",
            .buttonManualStop: "Elle durdur",
            .buttonAutomaticMode: "Otomatik mod",
            .buttonRefresh: "Yenile",
            .toggleLaunchAtLogin: "Girişte otomatik başlat",
            .buttonOpenLoginItemsSettings: "Giriş öğeleri ayarlarını aç",
            .buttonOpenRunnerDirectory: "Runner klasörünü aç",
            .buttonQuit: "Çık",
            .runnerRunning: "Çalışıyor",
            .runnerStopped: "Durduruldu",
            .networkChecking: "Ağ denetleniyor...",
            .networkNoInternet: "İnternet bağlantısı yok",
        ]),
        "uk": catalog([
            .statusActivityTitle: "Активність",
            .statusNetworkTitle: "Мережа",
            .statusModeTitle: "Режим",
            .statusLaunchAtLoginTitle: "Під час входу",
            .buttonManualStart: "Запустити вручну",
            .buttonManualStop: "Зупинити вручну",
            .buttonAutomaticMode: "Автоматичний режим",
            .buttonRefresh: "Оновити",
            .toggleLaunchAtLogin: "Запускати автоматично під час входу",
            .buttonOpenLoginItemsSettings: "Відкрити параметри елементів входу",
            .buttonOpenRunnerDirectory: "Відкрити теку runner",
            .buttonQuit: "Вийти",
            .runnerRunning: "Працює",
            .runnerStopped: "Зупинено",
            .networkChecking: "Перевірка мережі...",
            .networkNoInternet: "Немає підключення до інтернету",
        ]),
        "ar": catalog([
            .statusActivityTitle: "النشاط",
            .statusNetworkTitle: "الشبكة",
            .statusModeTitle: "الوضع",
            .statusLaunchAtLoginTitle: "عند تسجيل الدخول",
            .buttonManualStart: "تشغيل يدوي",
            .buttonManualStop: "إيقاف يدوي",
            .buttonAutomaticMode: "الوضع التلقائي",
            .buttonRefresh: "تحديث",
            .toggleLaunchAtLogin: "التشغيل تلقائيًا عند تسجيل الدخول",
            .buttonOpenLoginItemsSettings: "فتح إعدادات عناصر تسجيل الدخول",
            .buttonOpenRunnerDirectory: "فتح مجلد runner",
            .buttonQuit: "إنهاء",
            .runnerRunning: "قيد التشغيل",
            .runnerStopped: "متوقف",
            .networkChecking: "جار التحقق من الشبكة...",
            .networkNoInternet: "لا يوجد اتصال بالإنترنت",
        ]),
        "he": catalog([
            .statusActivityTitle: "פעילות",
            .statusNetworkTitle: "רשת",
            .statusModeTitle: "מצב",
            .statusLaunchAtLoginTitle: "בעת התחברות",
            .buttonManualStart: "הפעל ידנית",
            .buttonManualStop: "עצור ידנית",
            .buttonAutomaticMode: "מצב אוטומטי",
            .buttonRefresh: "רענן",
            .toggleLaunchAtLogin: "הפעל אוטומטית בעת התחברות",
            .buttonOpenLoginItemsSettings: "פתח הגדרות פריטי התחברות",
            .buttonOpenRunnerDirectory: "פתח תיקיית runner",
            .buttonQuit: "יציאה",
            .runnerRunning: "פועל",
            .runnerStopped: "נעצר",
            .networkChecking: "בודק רשת...",
            .networkNoInternet: "אין חיבור לאינטרנט",
        ]),
        "ja": catalog([
            .statusActivityTitle: "アクティビティ",
            .statusNetworkTitle: "ネットワーク",
            .statusModeTitle: "モード",
            .statusLaunchAtLoginTitle: "ログイン時",
            .buttonManualStart: "手動で開始",
            .buttonManualStop: "手動で停止",
            .buttonAutomaticMode: "自動モード",
            .buttonRefresh: "更新",
            .toggleLaunchAtLogin: "ログイン時に自動起動",
            .buttonOpenLoginItemsSettings: "ログイン項目設定を開く",
            .buttonOpenRunnerDirectory: "runner フォルダを開く",
            .buttonQuit: "終了",
            .runnerRunning: "実行中",
            .runnerStopped: "停止中",
            .networkChecking: "ネットワークを確認中...",
            .networkNoInternet: "インターネット接続がありません",
        ]),
        "ko": catalog([
            .statusActivityTitle: "활동",
            .statusNetworkTitle: "네트워크",
            .statusModeTitle: "모드",
            .statusLaunchAtLoginTitle: "로그인 시",
            .buttonManualStart: "수동 시작",
            .buttonManualStop: "수동 중지",
            .buttonAutomaticMode: "자동 모드",
            .buttonRefresh: "새로 고침",
            .toggleLaunchAtLogin: "로그인 시 자동 실행",
            .buttonOpenLoginItemsSettings: "로그인 항목 설정 열기",
            .buttonOpenRunnerDirectory: "runner 폴더 열기",
            .buttonQuit: "종료",
            .runnerRunning: "실행 중",
            .runnerStopped: "중지됨",
            .networkChecking: "네트워크 확인 중...",
            .networkNoInternet: "인터넷 연결 없음",
        ]),
        "zh-Hans": catalog([
            .statusActivityTitle: "活动",
            .statusNetworkTitle: "网络",
            .statusModeTitle: "模式",
            .statusLaunchAtLoginTitle: "登录时",
            .buttonManualStart: "手动启动",
            .buttonManualStop: "手动停止",
            .buttonAutomaticMode: "自动模式",
            .buttonRefresh: "刷新",
            .toggleLaunchAtLogin: "登录时自动启动",
            .buttonOpenLoginItemsSettings: "打开登录项设置",
            .buttonOpenRunnerDirectory: "打开 runner 文件夹",
            .buttonQuit: "退出",
            .runnerRunning: "运行中",
            .runnerStopped: "已停止",
            .networkChecking: "正在检查网络...",
            .networkNoInternet: "没有互联网连接",
        ]),
        "zh-Hant": catalog([
            .statusActivityTitle: "活動",
            .statusNetworkTitle: "網路",
            .statusModeTitle: "模式",
            .statusLaunchAtLoginTitle: "登入時",
            .buttonManualStart: "手動啟動",
            .buttonManualStop: "手動停止",
            .buttonAutomaticMode: "自動模式",
            .buttonRefresh: "重新整理",
            .toggleLaunchAtLogin: "登入時自動啟動",
            .buttonOpenLoginItemsSettings: "開啟登入項目設定",
            .buttonOpenRunnerDirectory: "開啟 runner 資料夾",
            .buttonQuit: "結束",
            .runnerRunning: "執行中",
            .runnerStopped: "已停止",
            .networkChecking: "正在檢查網路...",
            .networkNoInternet: "沒有網際網路連線",
        ]),
        "id": catalog([
            .statusActivityTitle: "Aktivitas",
            .statusNetworkTitle: "Jaringan",
            .statusModeTitle: "Mode",
            .statusLaunchAtLoginTitle: "Saat masuk",
            .buttonManualStart: "Mulai manual",
            .buttonManualStop: "Hentikan manual",
            .buttonAutomaticMode: "Mode otomatis",
            .buttonRefresh: "Segarkan",
            .toggleLaunchAtLogin: "Jalankan otomatis saat masuk",
            .buttonOpenLoginItemsSettings: "Buka pengaturan item masuk",
            .buttonOpenRunnerDirectory: "Buka folder runner",
            .buttonQuit: "Keluar",
            .runnerRunning: "Berjalan",
            .runnerStopped: "Berhenti",
            .networkChecking: "Memeriksa jaringan...",
            .networkNoInternet: "Tidak ada koneksi internet",
        ]),
        "vi": catalog([
            .statusActivityTitle: "Hoạt động",
            .statusNetworkTitle: "Mạng",
            .statusModeTitle: "Chế độ",
            .statusLaunchAtLoginTitle: "Khi đăng nhập",
            .buttonManualStart: "Khởi động thủ công",
            .buttonManualStop: "Dừng thủ công",
            .buttonAutomaticMode: "Chế độ tự động",
            .buttonRefresh: "Làm mới",
            .toggleLaunchAtLogin: "Tự động chạy khi đăng nhập",
            .buttonOpenLoginItemsSettings: "Mở cài đặt mục đăng nhập",
            .buttonOpenRunnerDirectory: "Mở thư mục runner",
            .buttonQuit: "Thoát",
            .runnerRunning: "Đang chạy",
            .runnerStopped: "Đã dừng",
            .networkChecking: "Đang kiểm tra mạng...",
            .networkNoInternet: "Không có kết nối internet",
        ]),
        "hi": catalog([
            .statusActivityTitle: "गतिविधि",
            .statusNetworkTitle: "नेटवर्क",
            .statusModeTitle: "मोड",
            .statusLaunchAtLoginTitle: "लॉगिन पर",
            .buttonManualStart: "मैन्युअल शुरू करें",
            .buttonManualStop: "मैन्युअल रोकें",
            .buttonAutomaticMode: "स्वचालित मोड",
            .buttonRefresh: "रीफ़्रेश",
            .toggleLaunchAtLogin: "लॉगिन पर अपने आप शुरू करें",
            .buttonOpenLoginItemsSettings: "लॉगिन आइटम सेटिंग्स खोलें",
            .buttonOpenRunnerDirectory: "runner फ़ोल्डर खोलें",
            .buttonQuit: "बंद करें",
            .runnerRunning: "चल रहा है",
            .runnerStopped: "रुका हुआ",
            .networkChecking: "नेटवर्क जाँचा जा रहा है...",
            .networkNoInternet: "इंटरनेट कनेक्शन नहीं है",
        ]),
        "ca": catalog([
            .statusActivityTitle: "Activitat",
            .statusNetworkTitle: "Xarxa",
            .statusModeTitle: "Mode",
            .buttonManualStart: "Inicia manualment",
            .buttonManualStop: "Atura manualment",
            .buttonAutomaticMode: "Mode automàtic",
            .buttonRefresh: "Actualitza",
            .buttonQuit: "Surt",
            .runnerRunning: "En execució",
            .runnerStopped: "Aturat",
        ]),
        "hr": catalog([
            .statusActivityTitle: "Aktivnost",
            .statusNetworkTitle: "Mreža",
            .statusModeTitle: "Način",
            .buttonManualStart: "Pokreni ručno",
            .buttonManualStop: "Zaustavi ručno",
            .buttonAutomaticMode: "Automatski način",
            .buttonRefresh: "Osvježi",
            .buttonQuit: "Zatvori",
            .runnerRunning: "Radi",
            .runnerStopped: "Zaustavljen",
        ]),
        "el": catalog([
            .statusActivityTitle: "Δραστηριότητα",
            .statusNetworkTitle: "Δίκτυο",
            .statusModeTitle: "Λειτουργία",
            .buttonManualStart: "Χειροκίνητη εκκίνηση",
            .buttonManualStop: "Χειροκίνητη διακοπή",
            .buttonAutomaticMode: "Αυτόματη λειτουργία",
            .buttonRefresh: "Ανανέωση",
            .buttonQuit: "Έξοδος",
            .runnerRunning: "Σε εκτέλεση",
            .runnerStopped: "Σταματημένο",
        ]),
        "ms": catalog([
            .statusActivityTitle: "Aktiviti",
            .statusNetworkTitle: "Rangkaian",
            .statusModeTitle: "Mod",
            .buttonManualStart: "Mula secara manual",
            .buttonManualStop: "Henti secara manual",
            .buttonAutomaticMode: "Mod automatik",
            .buttonRefresh: "Segar semula",
            .buttonQuit: "Keluar",
            .runnerRunning: "Sedang berjalan",
            .runnerStopped: "Dihentikan",
        ]),
        "th": catalog([
            .statusActivityTitle: "กิจกรรม",
            .statusNetworkTitle: "เครือข่าย",
            .statusModeTitle: "โหมด",
            .buttonManualStart: "เริ่มด้วยตนเอง",
            .buttonManualStop: "หยุดด้วยตนเอง",
            .buttonAutomaticMode: "โหมดอัตโนมัติ",
            .buttonRefresh: "รีเฟรช",
            .buttonQuit: "ออก",
            .runnerRunning: "กำลังทำงาน",
            .runnerStopped: "หยุดแล้ว",
        ]),
        "sk": catalog([
            .statusActivityTitle: "Aktivita",
            .statusNetworkTitle: "Sieť",
            .statusModeTitle: "Režim",
            .buttonManualStart: "Spustiť ručne",
            .buttonManualStop: "Zastaviť ručne",
            .buttonAutomaticMode: "Automatický režim",
            .buttonRefresh: "Obnoviť",
            .buttonQuit: "Ukončiť",
            .runnerRunning: "Spustené",
            .runnerStopped: "Zastavené",
        ]),
        "sl": catalog([
            .statusActivityTitle: "Dejavnost",
            .statusNetworkTitle: "Omrežje",
            .statusModeTitle: "Način",
            .buttonManualStart: "Zaženi ročno",
            .buttonManualStop: "Ustavi ročno",
            .buttonAutomaticMode: "Samodejni način",
            .buttonRefresh: "Osveži",
            .buttonQuit: "Izhod",
            .runnerRunning: "Teče",
            .runnerStopped: "Ustavljeno",
        ]),
        "bn": catalog([
            .statusActivityTitle: "কার্যকলাপ",
            .statusNetworkTitle: "নেটওয়ার্ক",
            .statusModeTitle: "মোড",
            .buttonManualStart: "হাতে চালু করুন",
            .buttonManualStop: "হাতে বন্ধ করুন",
            .buttonAutomaticMode: "স্বয়ংক্রিয় মোড",
            .buttonRefresh: "রিফ্রেশ",
            .buttonQuit: "বন্ধ করুন",
        ]),
        "gu": catalog([
            .statusActivityTitle: "પ્રવૃત્તિ",
            .statusNetworkTitle: "નેટવર્ક",
            .statusModeTitle: "મોડ",
            .buttonManualStart: "હાથેથી શરૂ કરો",
            .buttonManualStop: "હાથેથી બંધ કરો",
            .buttonAutomaticMode: "સ્વચાલિત મોડ",
            .buttonRefresh: "રીફ્રેશ",
            .buttonQuit: "બંધ કરો",
        ]),
        "kn": catalog([
            .statusActivityTitle: "ಚಟುವಟಿಕೆ",
            .statusNetworkTitle: "ಜಾಲ",
            .statusModeTitle: "ಮೋಡ್",
            .buttonManualStart: "ಕೈಯಾರೆ ಪ್ರಾರಂಭಿಸಿ",
            .buttonManualStop: "ಕೈಯಾರೆ ನಿಲ್ಲಿಸಿ",
            .buttonAutomaticMode: "ಸ್ವಯಂ ಮೋಡ್",
            .buttonRefresh: "ರಿಫ್ರೆಶ್",
            .buttonQuit: "ನಿರ್ಗಮಿಸಿ",
        ]),
        "ml": catalog([
            .statusActivityTitle: "പ്രവർത്തനം",
            .statusNetworkTitle: "നെറ്റ്‌വർക്ക്",
            .statusModeTitle: "മോഡ്",
            .buttonManualStart: "കൈയാൽ ആരംഭിക്കുക",
            .buttonManualStop: "കൈയാൽ നിർത്തുക",
            .buttonAutomaticMode: "ഓട്ടോമാറ്റിക് മോഡ്",
            .buttonRefresh: "റിഫ്രെഷ്",
            .buttonQuit: "പുറത്തുകടക്കുക",
        ]),
        "mr": catalog([
            .statusActivityTitle: "क्रियाकलाप",
            .statusNetworkTitle: "नेटवर्क",
            .statusModeTitle: "मोड",
            .buttonManualStart: "हस्तचालित सुरू करा",
            .buttonManualStop: "हस्तचालित थांबवा",
            .buttonAutomaticMode: "स्वयंचलित मोड",
            .buttonRefresh: "रीफ्रेश",
            .buttonQuit: "बाहेर पडा",
        ]),
        "or": catalog([
            .statusActivityTitle: "କାର୍ଯ୍ୟକଳାପ",
            .statusNetworkTitle: "ନେଟୱର୍କ",
            .statusModeTitle: "ମୋଡ୍",
            .buttonManualStart: "ହାତେ ଆରମ୍ଭ କରନ୍ତୁ",
            .buttonManualStop: "ହାତେ ବନ୍ଦ କରନ୍ତୁ",
            .buttonAutomaticMode: "ସ୍ୱୟଂଚାଳିତ ମୋଡ୍",
            .buttonRefresh: "ରିଫ୍ରେଶ",
            .buttonQuit: "ବନ୍ଦ କରନ୍ତୁ",
        ]),
        "pa": catalog([
            .statusActivityTitle: "ਗਤੀਵਿਧੀ",
            .statusNetworkTitle: "ਨੈੱਟਵਰਕ",
            .statusModeTitle: "ਮੋਡ",
            .buttonManualStart: "ਹੱਥੋਂ ਚਾਲੂ ਕਰੋ",
            .buttonManualStop: "ਹੱਥੋਂ ਰੋਕੋ",
            .buttonAutomaticMode: "ਆਟੋਮੈਟਿਕ ਮੋਡ",
            .buttonRefresh: "ਰੀਫ੍ਰੈਸ਼",
            .buttonQuit: "ਬੰਦ ਕਰੋ",
        ]),
        "ta": catalog([
            .statusActivityTitle: "செயல்பாடு",
            .statusNetworkTitle: "பிணையம்",
            .statusModeTitle: "முறை",
            .buttonManualStart: "கைமுறையாக தொடங்கு",
            .buttonManualStop: "கைமுறையாக நிறுத்து",
            .buttonAutomaticMode: "தானியங்கி முறை",
            .buttonRefresh: "புதுப்பிக்க",
            .buttonQuit: "வெளியேறு",
        ]),
        "te": catalog([
            .statusActivityTitle: "చర్య",
            .statusNetworkTitle: "నెట్‌వర్క్",
            .statusModeTitle: "మోడ్",
            .buttonManualStart: "చేతితో ప్రారంభించు",
            .buttonManualStop: "చేతితో ఆపు",
            .buttonAutomaticMode: "ఆటోమేటిక్ మోడ్",
            .buttonRefresh: "రిఫ్రెష్",
            .buttonQuit: "నిష్క్రమించు",
        ]),
        "ur": catalog([
            .statusActivityTitle: "سرگرمی",
            .statusNetworkTitle: "نیٹ ورک",
            .statusModeTitle: "موڈ",
            .buttonManualStart: "دستی طور پر شروع کریں",
            .buttonManualStop: "دستی طور پر روکیں",
            .buttonAutomaticMode: "خودکار موڈ",
            .buttonRefresh: "ریفریش",
            .buttonQuit: "بند کریں",
        ]),
    ]

    private static func languageFamily(for identifier: String) -> String {
        let normalized = identifier.lowercased()

        if normalized.hasPrefix("zh-hant") || normalized.contains("hant") {
            return "zh-Hant"
        }

        if normalized.hasPrefix("zh-hans") || normalized.contains("hans") {
            return "zh-Hans"
        }

        if normalized.hasPrefix("pt-br") {
            return "pt-BR"
        }

        if normalized.hasPrefix("pt") {
            return "pt-PT"
        }

        if normalized.hasPrefix("es") {
            return "es"
        }

        if normalized.hasPrefix("fr") {
            return "fr"
        }

        if normalized.hasPrefix("en") {
            return "en"
        }

        if normalized.hasPrefix("nb") || normalized.hasPrefix("nn") || normalized.hasPrefix("no") {
            return "no"
        }

        let base = normalized
            .split(separator: "-")
            .first
            .map(String.init) ?? fallbackLanguage

        return catalogs[base] == nil ? fallbackLanguage : base
    }

    private static func value(_ key: AppTextKey) -> String {
        catalogs[activeLanguageFamily]?[key] ??
        english[key] ??
        key.rawValue
    }

    private static func format(_ key: AppTextKey, _ arguments: CVarArg...) -> String {
        String(
            format: value(key),
            locale: Locale(identifier: matchedLanguageIdentifier),
            arguments: arguments
        )
    }

    static var appName: String { value(.appName) }
    static var statusRunnerTitle: String { value(.statusRunnerTitle) }
    static var statusActivityTitle: String { value(.statusActivityTitle) }
    static var statusNetworkTitle: String { value(.statusNetworkTitle) }
    static var statusModeTitle: String { value(.statusModeTitle) }
    static var statusLaunchAtLoginTitle: String { value(.statusLaunchAtLoginTitle) }
    static var buttonManualStart: String { value(.buttonManualStart) }
    static var buttonManualStop: String { value(.buttonManualStop) }
    static var buttonAutomaticMode: String { value(.buttonAutomaticMode) }
    static var buttonRefresh: String { value(.buttonRefresh) }
    static var toggleLaunchAtLogin: String { value(.toggleLaunchAtLogin) }
    static var buttonOpenLoginItemsSettings: String { value(.buttonOpenLoginItemsSettings) }
    static var buttonOpenRunnerDirectory: String { value(.buttonOpenRunnerDirectory) }
    static var buttonOpenUpdateWindow: String { value(.buttonOpenUpdateWindow) }
    static var buttonOpenAboutWindow: String { value(.buttonOpenAboutWindow) }
    static var aboutWindowTitle: String { value(.aboutWindowTitle) }
    static var aboutDescription: String { value(.aboutDescription) }
    static var buttonOpenAuthorGitHub: String { value(.buttonOpenAuthorGitHub) }
    static var buttonOpenAuthorX: String { value(.buttonOpenAuthorX) }
    static var buttonOpenRepository: String { value(.buttonOpenRepository) }
    static var updateWindowTitle: String { value(.updateWindowTitle) }
    static var updateDescription: String { value(.updateDescription) }
    static var updateInstalledVersionTitle: String { value(.updateInstalledVersionTitle) }
    static var updateLatestVersionTitle: String { value(.updateLatestVersionTitle) }
    static var updateStatusTitle: String { value(.updateStatusTitle) }
    static var updateUnknownVersion: String { value(.updateUnknownVersion) }
    static var buttonCheckForUpdates: String { value(.buttonCheckForUpdates) }
    static var buttonInstallUpdate: String { value(.buttonInstallUpdate) }
    static var buttonOpenReleasePage: String { value(.buttonOpenReleasePage) }
    static var updateIdle: String { value(.updateIdle) }
    static var updateChecking: String { value(.updateChecking) }
    static var updateUpToDate: String { value(.updateUpToDate) }
    static var updateAvailableFallback: String { value(.updateAvailableFallback) }
    static var updateDownloading: String { value(.updateDownloading) }
    static var updateInstalling: String { value(.updateInstalling) }
    static var updateErrorInvalidResponse: String { value(.updateErrorInvalidResponse) }
    static var updateErrorNoPublishedRelease: String { value(.updateErrorNoPublishedRelease) }
    static var updateErrorMissingAsset: String { value(.updateErrorMissingAsset) }
    static var updateErrorDownload: String { value(.updateErrorDownload) }
    static var updateErrorOpenInstaller: String { value(.updateErrorOpenInstaller) }
    static var updateErrorNoRelease: String { value(.updateErrorNoRelease) }
    static var buttonQuit: String { value(.buttonQuit) }
    static var runnerRunning: String { value(.runnerRunning) }
    static var runnerStopped: String { value(.runnerStopped) }
    static var controlModeAutomatic: String { value(.controlModeAutomatic) }
    static var controlModeForceRunning: String { value(.controlModeForceRunning) }
    static var controlModeForceStopped: String { value(.controlModeForceStopped) }
    static var policyAutomaticRun: String { value(.policyAutomaticRun) }
    static var policyAutomaticExpensive: String { value(.policyAutomaticExpensive) }
    static var policyAutomaticOffline: String { value(.policyAutomaticOffline) }
    static var policyAutomaticUnknown: String { value(.policyAutomaticUnknown) }
    static var policyForceRunning: String { value(.policyForceRunning) }
    static var policyForceStopped: String { value(.policyForceStopped) }
    static var launchAtLoginEnabled: String { value(.launchAtLoginEnabled) }
    static var launchAtLoginRequiresApproval: String { value(.launchAtLoginRequiresApproval) }
    static var launchAtLoginDisabled: String { value(.launchAtLoginDisabled) }
    static var launchAtLoginUnavailable: String { value(.launchAtLoginUnavailable) }
    static var launchAtLoginUnknown: String { value(.launchAtLoginUnknown) }
    static var activityWaitingForJob: String { value(.activityWaitingForJob) }
    static var activityStopping: String { value(.activityStopping) }
    static var activityWaitingOrStarting: String { value(.activityWaitingOrStarting) }
    static var activityRunnerStopped: String { value(.activityRunnerStopped) }
    static var activityUnknown: String { value(.activityUnknown) }
    static var networkChecking: String { value(.networkChecking) }
    static var networkNoInternet: String { value(.networkNoInternet) }
    static var interfaceEthernet: String { value(.interfaceEthernet) }
    static var interfaceWiFi: String { value(.interfaceWiFi) }
    static var interfaceCellular: String { value(.interfaceCellular) }
    static var interfaceOther: String { value(.interfaceOther) }
    static var interfaceGeneric: String { value(.interfaceGeneric) }

    static func activityWorking(jobName: String) -> String {
        format(.activityWorkingJob, jobName)
    }

    static func networkMetered(interface: String) -> String {
        format(.networkMetered, interface)
    }

    static func networkUnmetered(interface: String) -> String {
        format(.networkUnmetered, interface)
    }

    static func errorMissingRunnerScript(path: String) -> String {
        format(.errorMissingRunnerScript, path)
    }

    static func errorLaunchAtLoginUpdate(reason: String) -> String {
        format(.errorLaunchAtLoginUpdate, reason)
    }

    static func errorRunnerHandling(reason: String) -> String {
        format(.errorRunnerHandling, reason)
    }

    static func updateAvailableVersion(_ version: String) -> String {
        "New version available: \(version)"
    }

    static func updateErrorDetails(_ reason: String) -> String {
        "Update failed: \(reason)"
    }

}
