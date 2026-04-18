# GitHub Runner Menu

## English

GitHub Runner Menu is a small macOS menu bar app for controlling a local self-hosted GitHub Actions runner.

It watches the current network state and can automatically start or stop the runner depending on whether the connection is available and non-metered. It also shows whether the runner is running, waiting for jobs, or currently processing a workflow job.

### GitHub Description

Smart macOS menu bar app for managing a local self-hosted GitHub Actions runner with automatic network-aware start and stop control.

### Creator and links

- GitHub: [BenKoncsik](https://github.com/BenKoncsik)
- X: [BenedekKoncsik](https://x.com/BenedekKoncsik)
- Repository: [github-runer-mac](https://github.com/BenKoncsik/github-runer-mac)

### What this app does

- Runs as a menu bar app on macOS
- Monitors the local GitHub Actions runner status
- Detects network availability and whether the connection is metered
- Automatically starts the runner on unmetered internet
- Automatically stops the runner when the machine is offline or on a metered connection
- Lets you manually override the automatic behavior
- Lets you enable launch at login
- Opens the configured runner directory from the menu

### Requirements

- macOS 14 or later
- Swift 6 toolchain / Xcode with Swift Package Manager support
- A local self-hosted GitHub Actions runner already installed

### Default runner location

The app currently expects the runner to be installed here:

`/Users/user/GitHub/actions-runner`

If your runner is stored somewhere else, update the default path in [RunnerMenuStore.swift](/Users/user/GitHub/github_mac/Sources/GitHubRunnerMenu/Stores/RunnerMenuStore.swift).

### How to build and run

Build the project:

```bash
swift build
```

Build and launch the app bundle:

```bash
./script/build_and_run.sh
```

Useful script modes:

```bash
./script/build_and_run.sh --verify
./script/build_and_run.sh --logs
./script/build_and_run.sh --telemetry
./script/build_and_run.sh --debug
```

### How to use

1. Install and configure your self-hosted GitHub Actions runner.
2. Make sure the runner folder contains the usual `run.sh` script.
3. Build and launch the app.
4. Open the menu bar item called `GitHub Runner`.
5. Use `Automatic mode` to let the app manage the runner based on network conditions.
6. Use manual start or manual stop if you want to override the automatic logic.
7. Enable launch at login if you want the app to start with macOS.

### Automatic behavior

- Unmetered connection: the runner may run
- Metered connection: the runner is stopped
- Offline: the runner is stopped
- Unknown network state: the app keeps the current state until it knows more

### License

This project is licensed under the terms described in [LICENSE](LICENSE).

## Magyar

A GitHub Runner Menu egy kis macOS menüsáv alkalmazás, amely egy helyi self-hosted GitHub Actions runner vezérlésére szolgál.

Figyeli az aktuális hálózati állapotot, és automatikusan el tudja indítani vagy le tudja állítani a runnert attól függően, hogy van-e internetkapcsolat, illetve hogy a kapcsolat forgalomkorlátos-e. A menüben azt is megmutatja, hogy a runner fut-e, várakozik-e feladatra, vagy éppen dolgozik-e egy workflow jobon.

### GitHub Leírás

Okos macOS menüsáv alkalmazás helyi self-hosted GitHub Actions runner kezelésére, automatikus hálózatfüggő indítással és leállítással.

### Készítő és linkek

- GitHub: [BenKoncsik](https://github.com/BenKoncsik)
- X: [BenedekKoncsik](https://x.com/BenedekKoncsik)
- Repository: [github-runer-mac](https://github.com/BenKoncsik/github-runer-mac)

### Mire való ez az alkalmazás

- macOS menüsáv alkalmazásként fut
- Figyeli a helyi GitHub Actions runner állapotát
- Észleli, hogy van-e internetkapcsolat, és hogy a kapcsolat forgalomkorlátos-e
- Nem forgalomkorlátos internet esetén automatikusan elindítja a runnert
- Offline vagy forgalomkorlátos kapcsolat esetén automatikusan leállítja a runnert
- Lehetővé teszi a kézi felülbírálást
- Beállítható, hogy automatikusan induljon bejelentkezéskor
- A menüből meg tudja nyitni a beállított runner mappát

### Követelmények

- macOS 14 vagy újabb
- Swift 6 toolchain / Xcode Swift Package Manager támogatással
- Egy előre telepített helyi self-hosted GitHub Actions runner

### Alapértelmezett runner helye

Az alkalmazás jelenleg ezt a mappát várja:

`/Users/user/GitHub/actions-runner`

Ha a runner máshol található, módosítsd az alapértelmezett útvonalat itt: [RunnerMenuStore.swift](/Users/user/GitHub/github_mac/Sources/GitHubRunnerMenu/Stores/RunnerMenuStore.swift).

### Build és indítás

A projekt fordítása:

```bash
swift build
```

Az app bundle elkészítése és indítása:

```bash
./script/build_and_run.sh
```

Hasznos script módok:

```bash
./script/build_and_run.sh --verify
./script/build_and_run.sh --logs
./script/build_and_run.sh --telemetry
./script/build_and_run.sh --debug
```

### Használat

1. Telepítsd és konfiguráld a self-hosted GitHub Actions runnert.
2. Ellenőrizd, hogy a runner mappa tartalmazza a szokásos `run.sh` scriptet.
3. Fordítsd le és indítsd el az alkalmazást.
4. Nyisd meg a `GitHub Runner` menüsáv elemet.
5. Az `Automatic mode` használatával az app a hálózati állapot alapján kezeli a runnert.
6. A kézi indítás és kézi leállítás gombokkal felül tudod bírálni az automatikus működést.
7. Ha szeretnéd, kapcsold be az automatikus indulást bejelentkezéskor.

### Automatikus működés

- Nem forgalomkorlátos kapcsolat: a runner futhat
- Forgalomkorlátos kapcsolat: a runner leáll
- Offline állapot: a runner leáll
- Ismeretlen hálózati állapot: az app megtartja az aktuális állapotot, amíg több információ nem érkezik

### Licenc

Ez a projekt a [LICENSE](LICENSE) fájlban leírt feltételek szerint használható.
