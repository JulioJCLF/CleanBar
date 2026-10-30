<div align="center">

# 🍏 CleanBar

### *The Native, Zero-Bloat Menu Bar Cleaner & System Monitor for macOS*
**Reclaim gigabytes of hidden storage, eliminate runaway CPU hogs, and keep your Mac running at peak speed.**

[![Release](https://img.shields.io/github/v/release/JulioJCLF/CleanBar?style=for-the-badge&color=00c8ff)](https://github.com/JulioJCLF/CleanBar/releases/latest)
[![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue?style=for-the-badge&logo=apple)](https://github.com/JulioJCLF/CleanBar)
[![Architecture](https://img.shields.io/badge/Architecture-Universal-purple?style=for-the-badge)](https://github.com/JulioJCLF/CleanBar/releases/latest)
[![Swift](https://img.shields.io/badge/Swift-6.0-F05138?style=for-the-badge&logo=swift)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

<br/>

![Views](https://komarev.com/ghpvc/?username=JulioJCLF-CleanBar&label=Repo%20Views&color=00c8ff&style=for-the-badge)
[![Downloads](https://img.shields.io/github/downloads/JulioJCLF/CleanBar/total?style=for-the-badge&color=blue&logo=apple)](https://github.com/JulioJCLF/CleanBar/releases/latest)
[![Stars](https://img.shields.io/github/stars/JulioJCLF/CleanBar?style=for-the-badge&color=gold&logo=github)](https://github.com/JulioJCLF/CleanBar/stargazers)

<br/>

<img src="assets/cleanbar-demo.gif" width="480" alt="CleanBar Demo in Action" style="border-radius: 14px; box-shadow: 0 16px 40px rgba(0,0,0,0.4);" />

<br/>
<br/>

**[Download Latest Release (macOS Universal)](https://github.com/JulioJCLF/CleanBar/releases/latest)**

</div>

---

## 💡 The Problem with Modern Mac Cleaners

Over time, everyday macOS usage silently clutters your storage:
- **Application & Browser Caches** (`~/Library/Caches`) quietly swell into tens of gigabytes.
- **Media Scratch Files & Exports** leave behind massive temporary caches.
- **Developer & Workspace Dependencies** (`node_modules`, Next.js `.next`, Rust `target/`) take up storage across inactive folders.
- **Orphaned Daemons & Runaway Background Tasks** peg CPU cores, causing system heat and draining battery life.

Most utilities designed to solve this are either **heavy Electron applications** (running an entire Chromium browser in background consuming 300+ MB of RAM) or lock basic features behind **expensive annual subscriptions**.

### 🌟 The CleanBar Philosophy: Pure, Native & Featherlight
**CleanBar** is built 100% in **Swift 6 + SwiftUI + AppKit**:
- **Tiny footprint**: Less than **500 KB** total download size.
- **Zero background overhead**: **0.0% CPU** at idle and **< 45 MB of RAM**.
- **Authentic macOS Design**: Beautiful, responsive **Glassmorphism** popover using Apple's `.ultraThinMaterial`.
- **100% Private & Offline**: Zero analytics, zero tracking, zero internet calls.

---

## 📸 Core Modules

<div align="center">

| 📊 1. Overview & Heavy Files | 🧼 2. Deep System Cleaning | ⚡ 3. CPU Sentinel & Process Killer |
|:---:|:---:|:---:|
| <img src="assets/cleanbar-dashboard.png" width="280" alt="Dashboard" /> | <img src="assets/cleanbar-deepclean.png" width="280" alt="Deep Clean" /> | <img src="assets/cleanbar-processes.png" width="280" alt="Deep Clean" /> |
| Real-time SSD gauge, media cache purger & heavy directory tracker | Granular purge for app caches, build artifacts & old logs | Real-time CPU monitor with instant kill switch for runaway loops |

</div>

---

## ✨ Features at a Glance

### 1. 📊 Real-Time Storage & Heavy File Manager
- **Zero-Lag SSD Gauge**: Reads disk metrics directly from Darwin POSIX syscalls (`statfs`) in microseconds—never freezes your menu bar or waits on slow APFS background daemons.
- **Media & Scratch Purger**: Quickly detects video and media caches (`~/video`), purging multi-gigabyte work files and `.mov` proxies while keeping your final exports and subtitles untouched.
- **Heavy Folder & Project Scanner**: On-demand scanner identifying heavy directory trees (like `node_modules` or local workspaces) with one-click purge.
- **Quick Maintenance**: One-tap shortcut for package manager stores (`pnpm`, `npm`, `brew`) and macOS Trash.

### 2. 🧼 Deep System Cleaning
- **Application Caches**: Deep-scans `~/Library/Caches` to safely remove cached data from web browsers, Spotify, Homebrew, and daily apps.
- **Build & Compiler Artifacts**: Reclaims storage locked by build caches (`.next/cache`, `target/`, compiler scratch directories).
- **Package Stores**: Prunes unreferenced global cache packages without touching your active tools.
- **System Logs & Diagnostic Reports**: Removes old crash logs and stale telemetry dumps from `~/Library/Logs`.
- **Granular Control**: Every category can be reviewed and toggled before cleaning, with a live counter of recoverable space.

### 3. ⚡ Process Sentinel & CPU Tamer (Anti-Freeze)
- **Top 7 CPU Consumers**: Real-time telemetry refreshed every 6 seconds with negligible system impact.
- **Runaway Loop Warning**: Automatically highlights background daemons or unresponsive apps consuming >25% CPU with a prominent red alert card.
- **One-Click Process Killer**: Terminate frozen or rogue tasks instantly, backed by safety guardrails that protect critical macOS system processes (`WindowServer`, `launchd`).

---

## ⚡ Comparison

| Feature | CleanBar 🍏 | CleanMyMac | Electron Cleaners |
| :--- | :---: | :---: | :---: |
| **Engine** | **Native Swift 6 + SwiftUI** | Objective-C / Swift | Electron / Web Technologies |
| **App Size** | **471 KB** | ~150 MB | 120–250 MB |
| **Idle Memory (RAM)** | **< 45 MB** | 120–200 MB | 300–600 MB |
| **Idle CPU Usage** | **0.0%** | Background Daemon | 1.0–4.0% |
| **Price** | **100% Free & Open Source** | $39.95 / year | Subscription / Freemium |
| **Design** | **Native Frosted Glass Popover** | Custom Window | Web HTML/CSS |
| **Telemetry / Tracking** | **None (100% Offline)** | Extensive | Analytics Trackers |

---

## 📥 Installation

### Option 1: Direct Download (Pre-built Universal Binary)
1. Download `CleanBar-v1.0.0-macOS-Universal.zip` from the **[Latest Release](https://github.com/JulioJCLF/CleanBar/releases/latest)**.
2. Unzip and drag `CleanBar.app` into your **Applications** folder (`/Applications`).
3. Launch `CleanBar`—the sparkles icon (`✨`) will appear in your top menu bar!

> [!TIP]
> **First Launch on macOS**: As an open-source project without a paid Apple Developer certificate, on the first launch: **Right-click** `CleanBar.app` → select **Open** → click **Open** to confirm.

### Option 2: Launch on Startup (Recommended)
1. Open **System Settings** on your Mac.
2. Go to **General** > **Login Items**.
3. Under *Open at Login*, click `+` and add `/Applications/CleanBar.app`.

---

## 🛠️ Building from Source

CleanBar compiles with zero third-party package dependencies.

### Requirements
- macOS 13.0 (Ventura) or newer
- Xcode Command Line Tools (`xcode-select --install`)

```bash
# Clone the repository
git clone https://github.com/JulioJCLF/CleanBar.git
cd CleanBar

# Build Universal 2 binary (Apple Silicon + Intel)
swift build -c release --arch arm64
swift build -c release --arch x86_64

# Package into Universal App
lipo -create -output CleanBar.app/Contents/MacOS/CleanBar \
  .build/arm64-apple-macosx/release/CleanBar \
  .build/x86_64-apple-macosx/release/CleanBar
```

---

## 📄 License

Distributed under the **MIT License**. See [LICENSE](LICENSE) for details.

<br/>

<div align="center">
  <sub>Crafted with Swift by <a href="https://github.com/JulioJCLF">Julio Lopes</a>.</sub>
</div>
