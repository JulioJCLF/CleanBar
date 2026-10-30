# 🚀 CleanBar — Kit de Divulgação (Reddit & LinkedIn)

> Este documento contém os textos formatados e prontos para publicação no **Reddit (r/macapps)** e no **LinkedIn** (versão em Português e Inglês).
> 
> 💡 **Dica visual**: Ao publicar, anexe a screenshot principal localizada em [`assets/cleanbar-dashboard.png`](assets/cleanbar-dashboard.png) ou monte um carrossel com as 3 abas.

---

## 1. 🤖 Post para o Reddit (r/macapps)

**Subreddit:** `r/macapps`  
**Flair recomendada:** `[Self-Promotion]` ou `[Free / Open Source]`

### Title:
> **[Self-Promotion] CleanBar – I got tired of 200MB Electron cleaners and subscriptions, so I built a native 470KB frosted-glass menu bar janitor in Swift 6 (Free & Open Source)**

### Body:

Hey r/macapps! 👋

Like many of you, I daily-drive a Mac with a 256GB SSD. Between video caches, browser cruft, temporary project dependencies, and stray background daemons, storage fills up fast.

When looking for a solution, I noticed two frustrating extremes:
1. **Expensive subscriptions** charging $30–$40/year just to clean cache files.
2. **Bloated Electron utilities** that idle at 300MB+ of RAM and run continuous disk-crawling loops that actually cause WindowServer stutters.

So I decided to build my own: **CleanBar** — an ultra-lightweight, zero-bloat menu bar utility built 100% in native **Swift 6 + SwiftUI + AppKit**.

### ✨ Highlights:
- **🪶 471 KB Total Size**: Zero dependencies. Consumes **0.0% CPU** at idle and **< 45MB RAM**.
- **🍏 Native Glassmorphism**: Floating frosted glass popover (`.ultraThinMaterial`) that feels like an authentic macOS system feature.
- **⚡ Sub-Millisecond Telemetry**: Queries filesystem metrics directly via Darwin POSIX `statfs`—zero lag, no slow APFS daemon freezes.
- **🎬 Heavy Media & Scratch Cleaner**: Intelligently identifies media and scratch folders (`~/video`), purging multi-gigabyte `.mov` proxies and render caches with 1 click while preserving finished master videos and subtitles.
- **🧼 Deep System Cleaning**: Granularly purges app caches (`~/Library/Caches` like Dia, Spotify, Chrome), build outputs (`.next`, `target`), package stores (`pnpm`, `npm`, `brew`), and old crash logs.
- **🚨 CPU Sentinel & Process Killer**: Real-time monitor of top CPU consumers with an instant kill switch for runaway background loops (with built-in safeguards for system-critical processes like WindowServer).
- **Universal 2 Binary**: Runs natively on both **Apple Silicon (M1/M2/M3/M4)** and **Intel Macs**.
- **🔒 100% Private & Offline**: No analytics, no accounts, no tracking.

It's completely free and open source under the MIT License.

- 🔗 **GitHub Repository**: https://github.com/JulioJCLF/CleanBar
- 📦 **Direct Download (.zip)**: https://github.com/JulioJCLF/CleanBar/releases/latest

I'd love to hear your feedback, feature requests, or bugs! If you find it helpful, a star on GitHub means a lot! ⭐

---

## 2. 💼 Post para o LinkedIn (Versão em Português)

### Texto sugerido:

Cansado de limpadores de 200 MB e assinaturas anuais de R$ 200, resolvi construir o meu próprio utilitário nativo para macOS: apresento o **CleanBar** 🍏🧹

Quem usa MacBooks com SSDs de 256 GB ou 512 GB conhece bem a dor:
- Arquivos temporários de vídeo e renders devoram gigabytes silenciosamente;
- Pastas de build e dependências de projetos antigos acumulam dezenas de GBs;
- Caches de navegadores e logs de ferramentas enchem o disco sem aviso;
- E pior: processos em segundo plano entram em loop infinito (como daemons órfãos), drenando bateria e esquentando a máquina.

Para resolver isso de forma elegante e sem sobrecarregar o Mac, desenvolvi o **CleanBar** — um aplicativo para a barra de menus 100% nativo construído com **Swift 6, SwiftUI e AppKit**.

### 🛠️ Decisões Técnicas de Engenharia:
1. **Zero Bloatware (< 500 KB)**: Em vez de usar Electron ou webviews que gastam 300+ MB de RAM, o binário final tem apenas **471 KB** e roda consumindo menos de 45 MB de memória e **0.0% de CPU em repouso**.
2. **Leituras do Kernel em Microssegundos**: As consultas de capacidade do SSD usam chamadas POSIX puras (`statfs`), sem acionar serviços lentos do APFS que causam aquela temida "bolinha de praia" do macOS.
3. **Design Glassmorphism Fluido**: Interface translúcida em vidro fosco (`.ultraThinMaterial`) com três módulos práticos:
   - 📊 **Visão Geral**: Monitor de SSD com barra em degradê e purga de caches pesados;
   - 🧼 **Limpeza Profunda**: Scanner granular de caches de apps, compilação e logs;
   - ⚡ **CPU Tamer**: Monitor em tempo real dos maiores consumidores de processador com encerramento de processos travados em 1 clique.
4. **Universal 2 Binary**: Compilado nativamente tanto para Apple Silicon (M1 a M4) quanto para Macs Intel.

O projeto é **100% gratuito e Open Source (MIT)**.

Se você usa Mac ou quer dar uma olhada na arquitetura do código Swift, o link para o código e para download está aqui:

🔗 **GitHub & Download**: https://github.com/JulioJCLF/CleanBar

Feedbacks e sugestões são super bem-vindos! Se curtir, deixa uma ⭐ no repositório para apoiar o projeto!

#macOS #Swift #SwiftUI #Apple #OpenSource #SoftwareEngineering #DeveloperTools #Tech

---

## 3. 🌐 Post para o LinkedIn (Versão em Inglês - Alcance Internacional)

### Texto sugerido:

Tired of 200MB bloated cleaners and $40/year subscriptions, I decided to build my own native macOS menu bar janitor: meet **CleanBar** 🍏✨

Anyone using a Mac with a 256GB or 512GB SSD knows the daily battle:
- Video scratch files and render caches quietly gobble up 10–20 GB;
- Inactive project dependencies (`node_modules`, build caches) pile up;
- Browser cruft and tool logs silently eat away at storage;
- Runaway background daemons peg CPU cores, drain battery, and cause system stutters.

Instead of installing an Electron-based app that eats 300MB+ of RAM just idling, I built **CleanBar** from the ground up using **Swift 6, SwiftUI, and AppKit**.

### 🛠️ Key Technical Highlights:
- **🪶 Ultra-lightweight (471 KB)**: Consumes **0.0% idle CPU** and under 45 MB of RAM.
- **⚡ Zero-Lag Telemetry**: Storage stats are read via Darwin POSIX `statfs` syscalls in microseconds—no WindowServer freezes or slow daemon crawling.
- **🍏 Native Glassmorphism**: Crafted with Apple’s `.ultraThinMaterial` for an authentic macOS aesthetic.
- **🧼 3 Power Modules**: Real-time SSD gauge & media janitor, deep system cleaner (app caches & builds), and a live CPU monitor with a one-click process termination switch.
- **Universal 2 Binary**: Compiled for Apple Silicon (M1–M4) and Intel Macs with zero external dependencies.

CleanBar is **100% Free and Open Source** under the MIT license.

Check out the code or download the pre-built app below:
🔗 **GitHub Repository**: https://github.com/JulioJCLF/CleanBar

Feedback and PRs are welcome! If you find it useful, don't forget to star the repo on GitHub! ⭐

#macOS #Swift #SwiftUI #OpenSource #Programming #IndieHacker #DeveloperExperience
