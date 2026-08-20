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

## Instituto Nego Batera — agora só leitura ao vivo do Programa Nego Batera

**Desde 20/08/2026:** a Aba INB (nav + página) foi **removida de vez** — Leandro confirmou que só alimenta dados do Instituto (financeiro, agenda, etc.) pelo Programa Nego Batera (`C:\Projetos\Programa-Nego-Batera\`), nunca mais editando aqui. Em vez de qualquer aba própria, o Painel principal tem um card (`#card-resumo-inb`) que busca **ao vivo** (toda vez que a página carrega, sem cache/job agendado) um resumo do mês corrente via RPC pública `financeiro_resumo_mes(p_ano, p_mes)` no Supabase do Programa Nego Batera (projeto separado, credenciais hardcoded em `PNB_SUPABASE_URL`/`PNB_SUPABASE_KEY` — é a anon key, segura de expor, mesmo padrão do resto do app). Só números agregados (arrecadado, gasto, saldo, alunos ativos) — nunca aluno por aluno.

Isso fecha a "Etapa 4" do plano de migração original (ver `project-ecossistema-nego-batera` na memória): Programa Nego Batera é a fonte única, Controle LRC só recebe um resumo, sem sincronização linha a linha.

**Nota:** o card `kpi-rec-inb` ("Receitas INB") e o "Saldo Atual do Ano" no topo do Painel **ainda usam `state.alunos` local**, que ficou **congelado desde a migração de 13/08/2026** (nada novo entra ali) — não foram tocados nesta rodada por não terem sido pedidos explicitamente. Considerar migrar/aposentar esses dois também quando Leandro confirmar.

## Convenções

- Commits em português, estilo `fix(agenda): ...`, `feat(pwa): ...`
- PWA com service worker — cuidado com cache ao mudar `index.html` (ver histórico de commits sobre `sw.js`/`updateViaCache`)
