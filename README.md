<div align="center">

# 🍏 CleanBar

### *The Native Glassmorphic Menu Bar Janitor for macOS*
**Engineered for video creators and developers living on compact SSDs.**

[![Release](https://img.shields.io/github/v/release/JulioJCLF/CleanBar?style=for-the-badge&color=00c8ff)](https://github.com/JulioJCLF/CleanBar/releases/latest)
[![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue?style=for-the-badge&logo=apple)](https://github.com/JulioJCLF/CleanBar)
[![Architecture](https://img.shields.io/badge/Architecture-Universal%20(Apple%20Silicon%20%2B%20Intel)-purple?style=for-the-badge)](https://github.com/JulioJCLF/CleanBar/releases/latest)
[![Swift](https://img.shields.io/badge/Swift-6.0-F05138?style=for-the-badge&logo=swift)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

<br/>

<img src="assets/cleanbar-dashboard.png" width="440" alt="CleanBar Dashboard Preview" style="border-radius: 18px; box-shadow: 0 16px 40px rgba(0,0,0,0.4);" />

<br/>
<br/>

**[Download Latest Release (Universal DMG/ZIP)](https://github.com/JulioJCLF/CleanBar/releases/latest)**

</div>

---

## 💡 Why CleanBar?

If you create content (YouTube, TikTok, Reels) and write code on a MacBook with a 256 GB or 512 GB SSD, you know the daily struggle:

- **Video editing caches** (`work/` folders, scratch files, ProRes `.mov` exports) silently steal 10 to 30 GB per shoot.
- **Development dependencies** (`node_modules`, Next.js `.next/cache`, Rust `target/`) accumulate tens of gigabytes across forgotten projects.
- **Application caches & AI tool logs** clutter system directories without warning.
- **Runaway background daemons** quietly peg CPU cores, heat up your Mac, and drain your battery.

Most existing cleaners are **bloated Electron apps** (consuming 300+ MB of RAM just sitting in the background) or demand expensive monthly subscriptions.

**CleanBar** is a 100% native **Swift 6 + SwiftUI + AppKit** utility that weighs **< 500 KB**, uses **0.0% CPU when idle**, consumes less than 45 MB of RAM, and sits elegantly in your menu bar with authentic macOS **frosted glass (Glassmorphism)**.

---

## 📸 Screenshots & Feature Walkthrough

<div align="center">

| 📊 1. Overview & Media Pipeline | 🧼 2. Deep System Cleaning | ⚡ 3. CPU Tamer & Process Killer |
|:---:|:---:|:---:|
| <img src="assets/cleanbar-dashboard.png" width="280" alt="Dashboard" /> | <img src="assets/cleanbar-deepclean.png" width="280" alt="Deep Clean" /> | <img src="assets/cleanbar-processes.png" width="280" alt="CPU Tamer" /> |
| Real-time SSD gauge, video scratch purger & node_modules tracker | Granular purge for app caches, build artifacts & stale logs | Real-time top CPU monitor with instant kill switch for runaway loops |

</div>

---

## ✨ Features at a Glance

### 1. 📊 Overview & Media Pipeline (Dashboard)
- **Zero-Lag Storage Gauge**: Real-time disk capacity measured directly via POSIX kernel syscalls (`statfs`) in microseconds—never freezes your WindowServer.
- **Video Pipeline Janitor (`~/video`)**: Automatically detects completed video shoots. With one click, safely purges heavy `.mov` scratch files and `work/` proxy caches while preserving your master video, `.srt` subtitles, chapters, and thumbnails.
- **Dev Workspace Scanner**: On-demand background scanner that locates bloated `node_modules` and lets you reclaim 5+ GB per project in one click.
- **Quick Actions**: Instant triggers for global package pruning (`pnpm store prune`, `npm cache clean`, `brew cleanup`) and emptying the macOS Trash.

### 2. 🧼 Deep System Cleaning
- **Application Caches**: Deep scans `~/Library/Caches` to clean bloated browser data (Dia, Chrome), Spotify cache, and Homebrew bottles.
- **Build & Compiler Caches**: Targets hidden build folders including Next.js (`.next/cache`), Rust (`target/`), and temporary compiler outputs.
- **Package Managers**: Prunes unreferenced global store files from `pnpm`, `npm`, and `brew`.
- **System Logs & Reports**: Cleans old diagnostic dumps, crash reporters, and leftover AI logs.
- **Granular Selection**: Translucent checkboxes let you select exactly what to clean, with real-time estimation of recoverable gigabytes.

### 3. ⚡ Process Sentinel & CPU Tamer (Anti-Freeze)
- **Real-Time CPU Monitoring**: Lightweight background tracker inspecting the top 7 CPU & memory consumers every 6 seconds.
- **Runaway Loop Detection**: If an orphaned daemon or background task consumes >25% CPU for extended periods, a bold red alert card immediately warns you.
- **One-Click Process Termination**: Safely kill runaway background tasks with built-in safety guardrails protecting critical macOS system processes (`WindowServer`, `launchd`).

---

## ⚡ Comparison

| Feature | CleanBar 🍏 | CleanMyMac | Typical Electron Cleaners |
| :--- | :---: | :---: | :---: |
| **Technology** | **Pure Swift 6 + SwiftUI** | Objective-C / Swift | Electron / Chromium |
| **Download Size** | **471 KB** | ~150 MB | 120–250 MB |
| **Idle RAM Usage** | **< 45 MB** | 120–200 MB | 300–600 MB |
| **Idle CPU Usage** | **0.0%** | Background daemon | 1.0–4.0% |
| **Pricing** | **100% Free & Open Source** | $39.95 / year | Freemium / Paid |
| **UI Design** | **Native Frosted Glass Popover** | Proprietary Window | Webview / HTML |
| **Developer & Video Focus** | **Yes (`~/video`, `node_modules`, builds)** | No (Generic) | Limited |

---

## 📥 Installation

### Option 1: Direct Download (Recommended)
1. Head over to the **[Latest Release](https://github.com/JulioJCLF/CleanBar/releases/latest)**.
2. Download `CleanBar-v1.0.0-macOS-Universal.zip` (only 471 KB).
3. Unzip and drag `CleanBar.app` to your **Applications** folder (`/Applications`).
4. Launch `CleanBar`—the sparkles icon (`✨`) will instantly appear in your menu bar!

> [!TIP]
> **First-time macOS Gatekeeper Notice**: Because this is an indie open-source app built without an Apple Developer corporate subscription, on the very first launch: **Right-click** `CleanBar.app` → click **Open** → confirm **Open**.

### Option 2: Start on System Boot (Optional)
1. Open **System Settings** on your Mac.
2. Navigate to **General** > **Login Items**.
3. Under *Open at Login*, click `+` and choose `/Applications/CleanBar.app`.

---

## 🛠️ Building from Source

CleanBar is built using Swift Package Manager with zero third-party dependencies.

### Prerequisites
- macOS 13.0 (Ventura) or newer
- Xcode Command Line Tools (`xcode-select --install`)

### Compilation Commands:
```bash
# 1. Clone the repository
git clone https://github.com/JulioJCLF/CleanBar.git
cd CleanBar

# 2. Build for Apple Silicon (M1/M2/M3/M4)
swift build -c release --arch arm64

# 3. Build for Intel Macs
swift build -c release --arch x86_64

# 4. Create Universal 2 binary with lipo
lipo -create -output CleanBar.app/Contents/MacOS/CleanBar \
  .build/arm64-apple-macosx/release/CleanBar \
  .build/x86_64-apple-macosx/release/CleanBar
```

---

## 🛡️ Architecture & Performance Principles

- **No Continuous Disk Spun**: CleanBar avoids background polling loops. All disk traversal and calculations are strictly asynchronous and on-demand with intelligent debouncing.
- **Sub-Millisecond Kernel Reads**: Storage status queries utilize Darwin POSIX `statfs` directly, bypassing slow APFS purgeable computation daemons.
- **Accessory Runloop**: Configured with `LSUIElement=true` and explicit transparent lifecycle management to prevent macOS Automatic Termination freezes.

---

## 📄 License

Distributed under the **MIT License**. See [LICENSE](LICENSE) for details.

<br/>

<div align="center">
  <sub>Crafted with Swift by <a href="https://github.com/JulioJCLF">Julio Lopes</a>.</sub>
</div>
