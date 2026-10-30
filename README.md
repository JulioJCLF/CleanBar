# 🍏 CleanBar (Glassmorphism Edition)

**CleanBar** é um aplicativo nativo e ultraleve para a barra de menus do macOS (*Menu Bar Popover*), desenvolvido sob medida para criadores de conteúdo e desenvolvedores em máquinas com SSD compacto.

Ele reside discretamente no canto superior direito do macOS (ao lado do relógio), abrindo um elegante painel translúcido em **vidro fosco (Frosted Glass / Ultra Thin Material)** com 3 abas essenciais:

---

## ✨ Funcionalidades Principais

### 1. 📊 Visão Geral (Dashboard)
- **Indicador de SSD com Gradiente Fluido**: Medição instantânea via kernel (`statfs`) com barra de progresso e espaço livre em tempo real.
- **Pipeline de Vídeos (`~/video`)**: Status da pasta, atalho para o Finder e purga de caches (`work/` e `.mov` pesados).
- **Projetos Dev**: Rastreamento sob demanda de dependências pesadas (`node_modules`) com botão de exclusão rápida.
- **Ações Rápidas**: Limpeza de caches de pacotes (`pnpm`, `npm`, `brew`) e esvaziamento da lixeira com um clique.

### 2. 🧼 Limpeza Profunda (Deep Clean)
- Varredura de múltiplos silos de lixo oculto no macOS:
  - **Caches de Aplicativos**: Arquivos temporários acumulados em `~/Library/Caches` (Dia, Spotify, Homebrew, etc.).
  - **Caches de Build**: Pastas `.next/cache` de Next.js, `target/` de Rust e `.turbo`.
  - **Gerenciadores de Pacote**: Poda automática de pacotes não referenciados do pnpm, npm e Homebrew.
  - **Logs e Relatórios**: Limpeza de logs obsoletos e diagnósticos antigos em `~/Library/Logs`.
- Seleção granular por caixas de seleção em vidro.
- Botão vibrante: **`✨ Executar Limpeza Profunda`** com feedback em tempo real de gigabytes recuperados.

### 3. ⚡ Processos & CPU Tamer (Anti-Travamento)
- **Monitor de CPU em Tempo Real**: Monitora os 7 maiores consumidores de CPU do sistema a cada 6 segundos.
- **Alerta de Processo em Loop Infinito**: Se algum processo em segundo plano travar consumindo >25% de CPU (como daemons órfãos), um card de alerta em vermelho aparece com destaque.
- **Finalização com 1 Clique (Kill Button)**: Botão vermelho para encerrar processos travados instantaneamente, com proteção nativa contra encerramento de processos vitais do sistema (`WindowServer`, `launchd`).

---

## 🚀 Instalação e Execução

O aplicativo já está instalado no seu usuário:
```bash
/Users/jclf/Applications/CleanBar.app
```

Para abrir manualmente ou via terminal:
```bash
open /Users/jclf/Applications/CleanBar.app
```

### Iniciar com o Mac:
1. Vá em **Ajustes do Sistema** > **Geral** > **Itens de Início de Sessão**.
2. Em *Abrir no Início da Sessão*, clique em `+` e selecione `/Users/jclf/Applications/CleanBar.app`.
