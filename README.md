# github runer mac

## English

`github runer mac` is a lightweight macOS menu bar app for managing a local GitHub Actions self-hosted runner. It shows the runner status, current activity, network condition, and launch-at-login state, and lets you start, stop, or switch back to automatic mode directly from the menu.

The app is designed for a local developer workflow where the runner should react to connectivity changes and stay easy to control without opening Terminal or the GitHub runner directory manually.

See the [LICENSE](LICENSE) file for licensing details.

## Release instructions

GitHub Actions builds and publishes a macOS `.dmg` installer for each release.

To build the app bundle locally:

```bash
git clone https://github.com/HunKonTech/github-runer-mac.git
cd github-runer-mac
./script/build_and_run.sh --bundle
```

To create the DMG locally after the bundle exists:

```bash
APP_VERSION=1.0.0 ./script/build_dmg.sh
```

The bundle will be available in `dist/GitHubRunnerMenu.app`, and the installer in `release/`.

## Magyar

A `github runer mac` egy könnyű, macOS menüsorban futó alkalmazás, amely egy helyi GitHub Actions self-hosted runner kezelésére készült. Megjeleníti a runner állapotát, az aktuális aktivitást, a hálózati állapotot és a bejelentkezéskori indítás állapotát, valamint közvetlenül a menüből lehet vele indítani, leállítani vagy visszakapcsolni automatikus módba.

Az alkalmazás helyi fejlesztői használatra készült, ahol fontos, hogy a runner reagáljon a kapcsolat változásaira, és terminálhasználat nélkül is egyszerűen vezérelhető legyen.

A licenc részletei a [LICENSE](LICENSE) fájlban találhatók.

## Release útmutató

A GitHub Actions minden release-hez macOS `.dmg` telepítőt buildel és tesz közzé.

Ha helyben szeretnéd elkészíteni az alkalmazás bundle-t:

```bash
git clone https://github.com/HunKonTech/github-runer-mac.git
cd github-runer-mac
./script/build_and_run.sh --bundle
```

Ha a bundle elkészülte után helyben szeretnél DMG-t készíteni:

```bash
APP_VERSION=1.0.0 ./script/build_dmg.sh
```

Az elkészült bundle itt lesz: `dist/GitHubRunnerMenu.app`, a telepítő pedig a `release/` mappában.
