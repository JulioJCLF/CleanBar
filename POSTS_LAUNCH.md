# 🚀 CleanBar — Manual Completo de Lançamento Viral (LinkedIn & Reddit)

> **CleanBar v1.1.0** — O utilitário nativo para macOS que substitui limpadores de R$ 200/ano e apps pesados em Electron por engenharia pura em **Swift 6 + SwiftUI + AppKit** (0.0% CPU e ~33 MB RAM).

---

## 🎬 1. Roteiro do Vídeo Viral (15 a 20 Segundos)

Posts no LinkedIn com vídeo nativo curto têm **até 5x mais alcance** que posts com apenas texto ou link externo.

### 🎥 Como Gravar o Vídeo Perfeito:
1. Abra o **Monitor de Atividade (Activity Monitor)** do macOS e filtre por `CleanBar`.
2. Posicione a janela do **CleanBar** no centro e o **Monitor de Atividade** ao lado.
3. Comece a gravação de tela (`Cmd + Shift + 5`):
   - **0s - 4s**: Mostre o Dashboard do CleanBar com os anéis medidores animados em 120Hz (ProMotion) e a pontuação de saúde.
   - **4s - 8s**: Clique em **Otimizar Mac (1-Click)** ou navegue para **Deep Clean** e selecione as categorias.
   - **8s - 12s**: Alterne para a aba **Processos & CPU** com a barra de busca filtrando tarefas em tempo real.
   - **12s - 15s**: Dê zoom ou aponte o cursor no **Monitor de Atividade**: destaque o consumo de **0.0% de CPU** e apenas **~33 MB de memória RAM**.

---

## 💼 2. Post para o LinkedIn (Versão em Português 🇧🇷)

### 📌 Copie e cole:

Cansado de pagar R$ 200/ano por limpadores ou rodar utilitários pesados em Electron que consom 400 MB de RAM em segundo plano, resolvi construir minha própria alternativa nativa para macOS: apresento o **CleanBar** 🍏🧹✨

Quem tem um Mac com SSD de 256 GB ou 512 GB conhece a dor diária:
• Caches de navegadores (Chrome, Safari, Arc), Slack e Spotify devoram dezenas de gigabytes em silêncio;
• Instaladores esquecidos (.dmg e .pkg) lotam a pasta Downloads;
• Relatórios de erro e logs de diagnóstico antigos se acumulam invisíveis no disco;
• E pior: processos em loop infinito pegam núcleos da CPU, esquentam o Mac e drenam a bateria.

Para resolver isso com máxima elegância e performance extrema, desenvolvi o **CleanBar** — agora evoluído para um **aplicativo completo com janela desktop + companheiro na barra de menus**, construído 100% em **Swift 6, SwiftUI e AppKit**.

### 🛠️ Decisões de Engenharia & Performance:
1. **0.0% de CPU em Repouso**: Eliminamos loops de software na main thread. Todas as animações e medidores rodam via **CoreAnimation / Metal diretamente na GPU**, sem acordar o processador.
2. **Pegada Mínima (~33 MB de RAM)**: Sem Electron, sem Chromium embutido. Ao fechar a janela, o app aciona o kernel Darwin (`malloc_zone_pressure_relief`) e devolve páginas de memória livres instantaneamente ao macOS.
3. **Métricas Direto do Kernel Darwin**: Em vez de APIs lentas do sistema de arquivos que travam a interface, as consultas de SSD usam syscalls POSIX (`statfs`) em microssegundos, e a RAM é lida do Mach kernel (`host_statistics64`).
4. **Segurança de Dados**: Diferente de scripts perigosos, o CleanBar move instaladores residuais para a Lixeira nativa do macOS (`FileManager.trashItem`), permitindo que você restaure qualquer arquivo com "Colocar de Volta" a qualquer momento.
5. **Universal 2 & 100% Bilíngue**: Suporte nativo para Apple Silicon (M1 a M4) e Macs Intel, com alternância em 1 clique entre Português e Inglês.

O projeto é **100% gratuito e Open Source (MIT)**.

Se você usa Mac ou quer explorar a arquitetura do código Swift, o repositório e o download direto estão aqui:

🔗 **GitHub & Download**: https://github.com/JulioJCLF/CleanBar

Feedbacks e contribuições são muito bem-vindos! Se curtir a iniciativa, deixe uma ⭐ no repositório para apoiar o projeto! 🚀

#macOS #Swift #SwiftUI #Apple #OpenSource #SoftwareEngineering #CleanCode #DeveloperTools #Tech

---

## 🌐 3. Post para o LinkedIn (Versão em Inglês 🇺🇸 - Direto & Atualizações de Hoje)

### 📌 Copy & paste:

Quick update on CleanBar — my open-source macOS system monitor and janitor utility. Just tagged v1.1.0 with a major set of architectural updates today:

🖥️ Desktop App Window: Evolved CleanBar from a menu-bar-only popover into a standalone macOS window application with a dedicated sidebar, interactive telemetry cards, and process management (while keeping the lightweight menu bar companion).

⚡ 0.0% Idle CPU & ~32MB RAM: Replaced software render loops with hardware-accelerated CoreAnimation / Metal compositing on the GPU. When the window is closed or occluded, it calls Darwin’s `malloc_zone_pressure_relief` syscall to return unused heap pages back to the kernel.

🔒 One-Time Permission Setup: Fixed macOS repeatedly asking for folder permissions by codesigning with a persistent designated requirement (`com.jclf.cleanbar`) and adding a 1-click Full Disk Access helper in Settings.

🛡️ Safe Deletions: Cleaning now routes leftover downloads through macOS Native Trash (`FileManager.trashItem`) instead of unrecoverable deletion, so files can always be restored via "Put Back".

🌐 Bilingual: Added instant 1-click runtime switching between English and Portuguese.

Built with 100% native Swift 6, SwiftUI, and AppKit (zero external dependencies).

Source code and Universal 2 binary (Apple Silicon + Intel) are on GitHub:
🔗 https://github.com/JulioJCLF/CleanBar

Would love to hear feedback or thoughts from other Mac / Swift developers!

#macOS #Swift #SwiftUI #OpenSource #SoftwareEngineering #IndieDev

---

## 🤖 4. Post para o Reddit (r/macapps & r/swift)

**Subreddit:** `r/macapps`  
**Flair:** `[Free / Open Source]`

### Title:
> **[Free & Open Source] CleanBar v1.1 – I built a native, zero-bloat macOS cleaner & system monitor in Swift 6 (0.0% CPU, ~33MB RAM, Universal 2)**

### Body:

Hey r/macapps! 👋

Like many of you, I daily-drive a MacBook with a 256GB SSD. Over time, browser caches, abandoned `.dmg` installers in Downloads, Xcode DerivedData, and runaway background daemons silently eat up space and battery.

I was frustrated by the two existing options:
1. **Expensive subscriptions** charging $30–$40/year for basic cache cleaning.
2. **Heavy Electron utilities** running an entire Chromium browser in background consuming 300MB+ of RAM.

So I built **CleanBar** — an ultra-lightweight, native macOS system monitor and janitor built 100% in **Swift 6 + SwiftUI + AppKit**.

### 🌟 What's New in v1.1.0:
- **🖥️ Standalone Desktop Window App**: In addition to the featherlight menu bar companion, CleanBar now has a full-featured desktop window with a modern sidebar layout, live storage gauges, and process management.
- **⚡ 0.0% CPU & ~33 MB RAM**: Completely hardware-accelerated via CoreAnimation/Metal. Zero software rendering timers when idle.
- **🛡️ Safe Trash Routing**: Cleaned installers are moved to macOS Trash (`trashItem`) rather than unrecoverable permanent deletion.
- **📊 Real-time Mach Kernel Vitals**: Microsecond disk reads via POSIX `statfs` and real-time active/wired/compressed RAM breakdown via Mach `host_statistics64`.
- **🚨 CPU Sentinel & Process Killer**: Real-time process monitor with an instant termination switch for runaway tasks (with strict safety guards against killing system PIDs or `launchd`).
- **🛠️ 1-Click Maintenance**: Flush DNS cache (`dscacheutil`), empty trash via Finder AppleEvents, and purge application caches.
- **🌐 100% Bilingual**: Instant switching between English 🇺🇸 and Portuguese 🇧🇷.
- **Universal 2 Binary**: Native Apple Silicon (M1–M4) and Intel x86_64.

It is completely free, 100% offline (zero telemetry, zero analytics), and open-source under the MIT license.

- 🔗 **GitHub**: https://github.com/JulioJCLF/CleanBar
- 📦 **Download (.zip)**: https://github.com/JulioJCLF/CleanBar/releases/latest

I’d love to hear your thoughts, feedback, and feature requests!
