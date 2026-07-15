# CLAUDE.md — Controle LRC

> Se você está lendo isto numa máquina/login novo, **este repositório é a fonte única do projeto**: https://github.com/lramosbatera-create/controle-lrc

## O que é

App de página única (`index.html`, ~525 KB) para gestão financeira e operacional de Leandro Ramos: alunos do Instituto Nego Batera (cadastro, presenças, mensalidades), agenda de aulas, shows da banda Aline Brasil, relatórios e categorias do cotidiano. Também alimenta o dashboard do vault Obsidian (`C:\Users\maste\COFRE-LEANDRO`) via `scripts\sync-apps.ps1`.

## Stack e deploy

- Front-end: HTML/JS puro em um único arquivo (`index.html`)
- Backend: Supabase (config em `sync-config.json` do Obsidian, não neste repo)
- Deploy: **Cloudflare Pages**, via `wrangler pages deploy`
- Site: https://controle-lrc.pages.dev

## ⚠️ Fluxo de edição — importante

**Desde 15/07/2026:** o arquivo é editado direto aqui: `C:\Users\maste\controle-lrc\index.html` — dentro do próprio repositório Git. Não existe mais cópia solta fora do controle de versão.

> Histórico: até 02/07/2026 a edição era feita numa cópia em `C:\Users\maste\OneDrive\Desktop\CF\index.html.html`, fora do repo. Essa pasta sumiu do OneDrive (motivo não identificado) e o fluxo foi simplificado para eliminar esse ponto de falha.

O script `deploy.ps1`:

1. Commita as mudanças em `index.html`
2. Faz `git push`

**Desde 02/07/2026:** o projeto `controle-lrc` na Cloudflare está conectado a este repositório (branch `main`, implantações automáticas habilitadas) — o `git push` já é suficiente para publicar. Não é mais necessário rodar `wrangler pages deploy` manualmente.

**Rode `deploy.ps1` ao final de cada sessão de edição.**

## Convenções

- Commits em português, estilo `fix(agenda): ...`, `feat(pwa): ...`
- PWA com service worker — cuidado com cache ao mudar `index.html` (ver histórico de commits sobre `sw.js`/`updateViaCache`)
