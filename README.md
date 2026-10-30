<div align="center">

# 🍏 CleanBar

### *The Native Glassmorphic Menu Bar Janitor for macOS*
**Built for video creators & developers living on compact SSDs.**

[![Release](https://img.shields.io/github/v/release/JulioJCLF/CleanBar?style=for-the-badge&color=00c8ff)](https://github.com/JulioJCLF/CleanBar/releases/latest)
[![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue?style=for-the-badge&logo=apple)](https://github.com/JulioJCLF/CleanBar)
[![Architecture](https://img.shields.io/badge/Architecture-Universal%20(Apple%20Silicon%20%2B%20Intel)-purple?style=for-the-badge)](https://github.com/JulioJCLF/CleanBar/releases/latest)
[![Swift](https://img.shields.io/badge/Swift-6.0-F05138?style=for-the-badge&logo=swift)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

<br/>

[English](#-english) • [Português](#-português) • [Download](https://github.com/JulioJCLF/CleanBar/releases/latest)

</div>

---

## 🇧🇷 Português

### 💡 Por que o CleanBar existe?

Se você cria vídeos (YouTube, Reels, TikTok) e desenvolve software em um MacBook com SSD de 256 GB ou 512 GB, você conhece o pesadelo:
- **Pastas `work/` e arquivos `.mov` ProRes** devoram 10 a 20 GB a cada gravação.
- **`node_modules` e caches de build (`.next`, `target`)** acumulam silenciosamente dezenas de gigabytes em projetos inativos.
- **Caches de navegadores e logs de ferramentas de IA** enchem seu disco sem aviso.
- **Processos do sistema e helpers em loop infinito** travam o Mac, esquentam a máquina e drenam a bateria sem você perceber.

A maioria dos utilitários de limpeza existentes é construída em **Electron** (pesados, lentos, consom 300+ MB de RAM) ou custam assinaturas caras. 

O **CleanBar** é 100% nativo em **Swift 6 + SwiftUI + AppKit**, pesa **menos de 500 KB**, consome **0% de CPU em repouso**, menos de 45 MB de RAM e vive discretamente na sua barra de menus com um design translúcido em **vidro fosco (*Glassmorphism*)**.

---

### ✨ Recursos Principais

#### 1. 📊 Visão Geral & Pipeline de Mídia (Dashboard)
- **Medidor de Armazenamento Contínuo**: Leitura em tempo real direto do kernel (`statfs`) com barra em gradiente *Mint → Cyan*.
- **Pipeline de Mídia (`~/video`)**: Detecta automaticamente quando um projeto de vídeo está finalizado ou com caches pendentes. Um botão limpa com segurança arquivos `.mov` e pastas `work/`, preservando seu vídeo master, legendas `.srt`, capítulos e capa.
- **Scanner de `node_modules`**: Varre projetos em segundo plano sob demanda e permite purgar dependências de projetos inativos com 1 clique (reinstale com `pnpm i` quando for usar).
- **Ações Rápidas**: Poda caches de pacotes (`pnpm store prune`, `npm cache clean`, `brew cleanup`) e esvazia a lixeira do macOS.

#### 2. 🧼 Limpeza Profunda (*Deep Clean*)
- **Caches de Aplicativos**: Varre e limpa arquivos temporários em `~/Library/Caches` (navegadores Dia/Chrome, Spotify, Homebrew).
- **Caches de Compilação**: Identifica e purga `.next/cache` de Next.js, caches de Rust e compiladores web.
- **Logs e Relatórios**: Remove relatórios de travamentos antigos e arquivos `.log` acumulados em `~/Library/Logs`.
- **Seleção Granular**: Escolha exatamente o que limpar através de checkboxes de vidro com cálculo antecipado do espaço recuperável.

#### 3. ⚡ Processos & CPU Tamer (*Anti-Travamento*)
- **Monitor de CPU em Tempo Real**: Lista os maiores consumidores de processador atualizados a cada 6 segundos de forma ultraleve.
- **Alerta de Processo em Loop**: Se algum daemon ou aplicativo de fundo passar de **25% de CPU**, um card de aviso vermelho surge no topo para você agir imediatamente.
- **Botão Finalizar (Kill)**: Encerra processos zumbis na hora (com proteção contra encerramento de processos essenciais do sistema como `WindowServer`).

---

### 📥 Download e Instalação

1. Acesse a página de **[Releases](https://github.com/JulioJCLF/CleanBar/releases/latest)** e baixe o arquivo `CleanBar-v1.0.0-macOS-Universal.zip`.
2. Dê dois cliques para descompactar o **CleanBar.app**.
3. Arraste-o para a pasta **Aplicativos** (`/Applications`).
4. Abra o **CleanBar**. O ícone de brilho (`✨`) surgirá instantaneamente na sua barra superior!

> [!NOTE]
> **Primeira abertura no macOS (Gatekeeper)**: Por ser um aplicativo open-source sem assinatura corporativa da Apple, na primeira vez clique com o **botão direito** no `CleanBar.app` e selecione **Abrir**, confirmando a execução.

#### Iniciar automaticamente com o Mac:
1. Vá em **Ajustes do Sistema** > **Geral** > **Itens de Início de Sessão**.
2. Na seção *Abrir no Início da Sessão*, clique em `+` e selecione `/Applications/CleanBar.app`.

---

## 🇺🇸 English

### 💡 Why CleanBar?

If you create content (YouTube, TikTok, Reels) and build code on a MacBook with 256 GB or 512 GB of storage, you know the struggle:
- **`work/` folders and ProRes `.mov` files** easily eat up 10–20 GB per project.
- **`node_modules` and build caches (`.next`, `target`)** silently pile up across inactive repositories.
- **Application caches and logs** eat away at your precious SSD.
- **Runaway background daemons** quietly peg CPU cores, drain battery, and cause system freezes.

Existing cleaners are bloated Electron apps or expensive monthly subscriptions. **CleanBar** is a pure native **Swift 6 + SwiftUI** utility that weighs **< 500 KB**, uses **zero idle CPU**, and delivers a stunning **frosted glass UI** that feels right at home on modern macOS.

---

### ✨ Features at a Glance

* 🍏 **Apple-Like Glassmorphic UI**: Ultra-thin frosted glass material with specular borders and smooth hover interactions.
* 🚀 **Universal 2 Binary**: Native performance on both **Apple Silicon (M1/M2/M3/M4)** and **Intel Macs**.
* 📊 **Zero-Lag Storage Gauge**: Queries filesystem stats in microseconds via POSIX kernel syscalls without locking the WindowServer.
* 🎬 **Creator Media Janitor**: Automatically detects video project folders and safely purges intermediate work caches while keeping YouTube masters, subtitles, chapters, and thumbnails intact.
* 🛠️ **Dev Workspace Cleaner**: On-demand scanner for heavy `node_modules` and Next.js `.next` caches with one-click purge.
* 🧼 **Deep System Cleaning**: Granularly purges application caches (`~/Library/Caches`), obsolete dev packages (`pnpm`, `npm`, `brew`), and old crash logs.
* ⚡ **CPU Tamer & Process Killer**: Real-time top process monitor that highlights runaway CPU hogs with a one-click kill switch.

---

### 🛠️ Building from Source

Requirements: macOS 13.0+ and Xcode Command Line Tools (`xcode-select --install`).

```bash
# Clone the repository
git clone https://github.com/JulioJCLF/CleanBar.git
cd CleanBar

# Build release binary (Apple Silicon + Intel Universal)
swift build -c release --arch arm64
swift build -c release --arch x86_64

# Combine into a Universal Binary using lipo
lipo -create -output CleanBar.app/Contents/MacOS/CleanBar \
  .build/arm64-apple-macosx/release/CleanBar \
  .build/x86_64-apple-macosx/release/CleanBar
```

---

### 🛡️ Architecture Highlights

- **Pure Swift 6**: Built with strict concurrency checks and `@MainActor` safety.
- **No Background Polling**: No heavy periodic disk crawling; scans are strictly asynchronous and on-demand with intelligent debounce.
- **AppKit + SwiftUI Fusion**: Uses `NSStatusItem` with a native `NSPopover` and `.ultraThinMaterial` for authentic macOS ergonomics.

---

### 📄 License

Distributed under the **MIT License**. See `LICENSE` for more information.

<div align="center">
  <sub>Built with ☕ and Swift by <a href="https://github.com/JulioJCLF">Julio Lopes</a>.</sub>
</div>
