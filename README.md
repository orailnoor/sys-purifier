# System Purifier

A desktop utility for auditing and managing Android system packages over ADB. Built for users who want precise control over what runs on their device, with safeguards that prevent irreversible damage to the operating system.

Available for **macOS** (Apple Silicon and Intel) and **Windows** (64-bit).

---

## <span style="color:red">Disclaimer</span>

> **This software removes system packages from Android devices. Use it at your own risk.**

While System Purifier enforces safeguards — including mandatory backups, risk classification, and typed confirmation for critical operations — the authors assume **no responsibility** for any damage, data loss, or device malfunction resulting from its use.

Removing core system components can result in:

- Loss of push notification delivery (if Google Play Services is removed)
- Disabled functionality in applications that depend on Google frameworks
- System instability or boot failure (if protected components are force-removed outside of this tool)

This tool performs per-user uninstalls (`--user 0`), which do not modify the system partition. **A factory reset will restore all removed packages to their original state.**

This project is not affiliated with, endorsed by, or associated with Google LLC or any device manufacturer.

### Recovery Plan

If your device becomes unstable or unresponsive after removing packages:

1. **Reboot into Recovery Mode.** Power off the device, then hold **Power + Volume Down** simultaneously (the exact combination varies by manufacturer — consult your device documentation).
2. **Select "Wipe data / factory reset"** from the recovery menu using the volume keys to navigate and the power button to confirm.
3. The device will erase all user data and restore the system partition to its factory state. Every package removed via this tool will be reinstated.

A factory reset is a complete recovery path. Since System Purifier only performs per-user uninstalls and does not touch the system partition, no package removal made through this tool is permanent.

---

## Features

**Risk-Aware Package Management** — System components are classified against an internal risk database. Packages tied to core telephony, networking, or OS stability require explicit typed confirmation before removal.

**Pre-Removal Backup** — Every uninstall is preceded by an automated extraction of the target package, including split APKs, to local storage. If the backup fails, the removal is not executed.

**Package Restoration** — Previously removed applications can be reinstalled directly from the local backup archive.

**Bundled Platform Tools** — Both macOS and Windows builds ship with Android platform-tools. No prior ADB installation or SDK is required.

**Operation Journal** — All actions are recorded in a structured session log for auditability.

**Multi-Device Support** — Multiple connected devices are detected and managed independently.

**Zero Telemetry** — No outbound network requests. No analytics. Fully offline.

---

## Installation

### macOS

1. Download `SystemPurifier-v1.0.0-macOS.zip` from the [latest release](https://github.com/orailnoor/sys-purifier/releases/latest).
2. Extract the archive and move `System Purifier.app` to `/Applications`.
3. On first launch, macOS may require approval under **System Settings > Privacy and Security**.

### Windows

1. Download `SystemPurifier-v1.0.0-Windows-Setup.exe` from the [latest release](https://github.com/orailnoor/sys-purifier/releases/latest).
2. Run the installer and follow the on-screen prompts.

### Device Preparation

1. Navigate to **Settings > About Phone** and tap **Build Number** seven times to enable Developer Options.
2. Navigate to **Settings > Developer Options** and enable **USB Debugging**.
3. Connect the device via USB and authorize the debugging connection when prompted.

---

## Manual Approach (Without This Tool)

If you prefer to work directly from the command line, the following documents the exact ADB commands that System Purifier executes under the hood.

### Install Android Platform Tools

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

**Windows:** Download [platform-tools-latest-windows.zip](https://dl.google.com/android/repository/platform-tools-latest-windows.zip), extract it, and add the directory to your system PATH.

### Common Commands

```bash
# Verify device connection
adb devices

# List all installed packages
adb shell pm list packages

# Filter for Google packages
adb shell pm list packages | grep google

# Back up a package before removal
adb shell pm path com.example.package
adb pull /data/app/.../base.apk ./backups/

# Remove a package (current user only — factory reset restores it)
adb shell pm uninstall -k --user 0 com.example.package

# Restore from backup
adb install -r -d ./backups/base.apk
```

### Common Google Packages

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

---

## FOSS Alternatives

After removing proprietary applications, you will need open-source replacements. The **[Android FOSS](https://github.com/offa/android-foss)** project maintains a comprehensive, actively updated catalogue of Free and Open Source Android applications — covering app stores, browsers, keyboards, maps, messaging, and everything in between.

All listed applications are available through [F-Droid](https://f-droid.org/).

---

## Privacy

System Purifier collects zero telemetry. It makes no outbound network requests, transmits no data, and operates entirely offline. See [PRIVACY.md](PRIVACY.md) for the full policy.

---

## Contributing

Contributions are welcome. Please open an issue to discuss proposed changes before submitting a pull request. For security-related reports, refer to [SECURITY.md](SECURITY.md).

---

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
