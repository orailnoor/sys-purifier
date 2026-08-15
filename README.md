# System Purifier

A desktop utility for auditing and managing Android system packages over ADB. Built for users who want precise control over what runs on their device, with safeguards that prevent irreversible damage to the operating system.

Available for **macOS** (Apple Silicon and Intel) and **Windows** (64-bit).

---

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Manual Approach (Without This Tool)](#manual-approach-without-this-tool)
- [Recommended FOSS Alternatives](#recommended-foss-alternatives)
- [Disclaimer](#disclaimer)
- [Privacy](#privacy)
- [Contributing](#contributing)
- [License](#license)

---

## Features

**Risk-Aware Package Management**
System components are classified against an internal risk database. Packages tied to core telephony, networking, or OS stability require explicit typed confirmation before removal. Accidental deletion of essential services is structurally prevented.

**Pre-Removal Backup**
Every uninstall operation is preceded by an automated extraction of the target package — including split APK structures — to local storage. If the backup fails, the removal is not executed. This guarantees a recovery path for every action taken.

**Package Restoration**
Previously removed applications can be reinstalled directly from the local backup archive. The restoration engine handles both single-APK and split-APK packages via sequential ADB streaming.

**Bundled Platform Tools**
Both macOS and Windows builds ship with a copy of Android platform-tools. No prior ADB installation, Android SDK, or PATH configuration is required. The application works out of the box.

**Operation Journal**
All actions — backups, removals, restorations — are recorded in a structured session log, providing a clear audit trail of every modification made to a device.

**Multi-Device Support**
Multiple connected Android devices are detected and managed independently within a single session.

**Zero Telemetry**
The application makes no outbound network requests. No analytics, crash reports, or usage data is collected. All operations are performed entirely on the local machine and the connected device.

---

## Installation

### macOS

1. Download `System-Purifier-v1.0.0-macOS.zip` from the [latest release](https://github.com/orailnoor/sys-purifier/releases/latest).
2. Extract the archive and move `System Purifier.app` to `/Applications`.
3. On first launch, macOS may require approval under **System Settings > Privacy and Security**.

### Windows

1. Download `SystemPurifier-v1.0.0-Windows-Setup.exe` from the [latest release](https://github.com/orailnoor/sys-purifier/releases/latest).
2. Run the installer and follow the on-screen prompts.
3. Launch System Purifier from the Start Menu or Desktop shortcut.

### Device Preparation

Before connecting your Android device:

1. Navigate to **Settings > About Phone** and tap **Build Number** seven times to enable Developer Options.
2. Navigate to **Settings > Developer Options** and enable **USB Debugging**.
3. Connect the device via USB. When prompted on the device, authorize the debugging connection.

---

## Manual Approach (Without This Tool)

If you prefer to manage packages directly from the command line without any third-party application, the process is straightforward. This section documents the exact ADB commands that System Purifier executes under the hood.

### 1. Install Android Platform Tools

**macOS (Homebrew):**
```bash
brew install android-platform-tools
```

**macOS (Manual):**
```bash
curl -sL https://dl.google.com/android/repository/platform-tools-latest-darwin.zip -o platform-tools.zip
unzip platform-tools.zip
export PATH="$PWD/platform-tools:$PATH"
```

**Windows:**

Download [platform-tools-latest-windows.zip](https://dl.google.com/android/repository/platform-tools-latest-windows.zip), extract it, and add the extracted directory to your system PATH.

### 2. Verify Device Connection

```bash
adb devices
```

You should see your device listed with the status `device`. If the status reads `unauthorized`, check the device screen and approve the debugging prompt.

### 3. List Installed Packages

```bash
# All packages
adb shell pm list packages

# Filter for a specific vendor
adb shell pm list packages | grep google
```

### 4. Back Up a Package Before Removal

```bash
# Find the APK path on-device
adb shell pm path com.example.package

# Pull it to local storage
adb pull /data/app/.../base.apk ./backups/com.example.package/
```

### 5. Remove a Package (Current User Only)

This disables the package for the current user without deleting the system image. A factory reset will restore it.

```bash
adb shell pm uninstall -k --user 0 com.example.package
```

The `-k` flag preserves the application's data and cache in case you need to reinstall later.

### 6. Restore a Previously Removed Package

```bash
# Single APK
adb install -r -d ./backups/com.example.package/base.apk

# Split APKs (multiple files)
adb install-multiple -r -d ./backups/com.example.package/*.apk
```

### 7. Common Google Packages Reference

| Package | Description |
|---|---|
| `com.android.chrome` | Google Chrome |
| `com.google.android.gm` | Gmail |
| `com.google.android.apps.maps` | Google Maps |
| `com.google.android.apps.photos` | Google Photos |
| `com.google.android.apps.docs` | Google Drive |
| `com.google.android.apps.nbu.files` | Files by Google |
| `com.google.android.googlequicksearchbox` | Google Search / Assistant |
| `com.google.android.inputmethod.latin` | Gboard |
| `com.google.android.calendar` | Google Calendar |
| `com.google.android.dialer` | Google Phone |
| `com.google.android.contacts` | Google Contacts |
| `com.google.android.apps.messaging` | Google Messages |
| `com.google.android.videos` | Google TV |
| `com.google.android.deskclock` | Google Clock |
| `com.google.android.calculator` | Google Calculator |

---

## Recommended FOSS Alternatives

After removing proprietary applications, the following Free and Open Source Software can serve as replacements. All are available through [F-Droid](https://f-droid.org/), a repository of verified open-source Android applications.

For a comprehensive and actively maintained catalogue, refer to the [Android FOSS](https://github.com/offa/android-foss) project.

| Replaces | Recommended Alternative | Source |
|---|---|---|
| Google Play Store | [F-Droid](https://f-droid.org/) + [Aurora Store](https://gitlab.com/AuroraOSS/AuroraStore) | F-Droid for FOSS apps; Aurora Store for anonymous Play Store access |
| Google Chrome | [Fennec F-Droid](https://f-droid.org/packages/org.mozilla.fennec_fdroid/) or [Cromite](https://github.com/nicemicro/nicemicrocromite) | Firefox-based and Chromium-based options, both tracker-free |
| Gmail | [K-9 Mail](https://k9mail.app/) or [FairEmail](https://email.faircode.eu/) | Standards-compliant IMAP/SMTP clients with no tracking |
| Google Maps | [Organic Maps](https://organicmaps.app/) or [OsmAnd](https://osmand.net/) | Offline-capable navigation built on OpenStreetMap |
| Google Photos | [Fossify Gallery](https://github.com/FossifyOrg/Gallery) | Local gallery with no cloud dependency |
| Gboard | [FlorisBoard](https://github.com/florisboard/florisboard) or [AnySoftKeyboard](https://anysoftkeyboard.github.io/) | Privacy-respecting keyboards with no network access |
| Google Phone | [Fossify Phone](https://github.com/FossifyOrg/Phone) | Lightweight dialer with no telemetry |
| Google Contacts | [Fossify Contacts](https://github.com/FossifyOrg/Contacts) | Offline contact management |
| Google Messages | [Fossify SMS Messenger](https://github.com/FossifyOrg/Messages) | Simple, private SMS/MMS client |
| Google Calendar | [Fossify Calendar](https://github.com/FossifyOrg/Calendar) | Offline calendar with widget support |
| Google Calculator | [Fossify Calculator](https://github.com/FossifyOrg/Calculator) | Basic and scientific calculator |
| Files by Google | [Material Files](https://github.com/zhanghai/MaterialFiles) | Full-featured file manager |
| Google Clock | [Fossify Clock](https://github.com/FossifyOrg/Clock) | Alarm, timer, and stopwatch |

---

## Disclaimer

This software removes system packages from Android devices using ADB. While the application enforces safeguards — including mandatory backups, risk classification, and typed confirmation for critical operations — the authors assume no responsibility for any damage, data loss, or device malfunction resulting from its use.

Removing core system components can result in:

- Loss of push notification delivery (if Google Play Services is removed)
- Disabled functionality in applications that depend on Google frameworks
- System instability or boot failure (if protected components are force-removed outside of this tool)

**Users are solely responsible for understanding the implications of removing any package from their device.** This tool performs per-user uninstalls (`--user 0`), which do not modify the system partition. A factory reset will restore all removed packages to their original state.

This project is not affiliated with, endorsed by, or associated with Google LLC or any device manufacturer.

---

## Privacy

System Purifier collects zero telemetry. It makes no outbound network requests, transmits no data, and operates entirely offline. See [PRIVACY.md](PRIVACY.md) for the full policy.

---

## Contributing

Contributions are welcome. Please open an issue to discuss proposed changes before submitting a pull request. For security-related reports, refer to [SECURITY.md](SECURITY.md).

---

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
