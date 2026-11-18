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

**Atualização 17/09/2026 — corrigido:** o `kpi-rec-inb` ("Receitas INB"), `kpi-a-receber` ("A Receber INB") e o "Saldo Atual do Ano" no topo do Painel usavam `state.alunos`/`state.gastos_inb` locais, congelados desde 13/08/2026 — por isso uma correção de pagamento no Programa Nego Batera nunca aparecia nesses 3 números (bug real reportado por Leandro, saldo ficou negativo indevidamente). Corrigido: nova função `carregarResumoAnoINB()` busca a RPC `financeiro_resumo_ano(p_ano)` (nova, no repo `programa-nego-batera`) no boot, guarda em `pnbResumoAno`, e `updatePainel()` usa esse valor quando disponível — só cai no cálculo local antigo (`state.alunos`/`state.gastos_inb`) como fallback se a RPC ainda não existir ou a busca falhar. **Depende de Leandro rodar o SQL da `financeiro_resumo_ano` no Supabase do Programa Nego Batera** — até lá, o fallback mantém o comportamento antigo (mesmo bug) sem quebrar nada.

## Convenções

- Commits em português, estilo `fix(agenda): ...`, `feat(pwa): ...`
- PWA com service worker — cuidado com cache ao mudar `index.html` (ver histórico de commits sobre `sw.js`/`updateViaCache`)

## Aba Projeções (desde 29/10/2026)

Substituiu a aba **Lançar** (tudo que ela lançava já existia em Despesas, Shows e Chat; o card da URL do Worker do Chat IA foi pro topo da aba Chat). Funções `calcProjecoes()` / `renderProjecoes()`: Receita, Gastos e Saldo em Mensal/Trimestral/Semestral/Anual, por grupo de categoria (`PROJ_GRUPOS_GASTO`, agrupamento por palavra-chave no padrão Mobills/Organizze/Monarch — o nome original lançado não muda). Realizado = lançado/pago; projetado = fixas e parcelas não pagas, shows confirmados/previstos com data, e média dos últimos 3 meses fechados com lançamento (mesma janela pra todas as categorias de uma fonte). Saldo parte de `SALDO_ANTERIOR_ANO` (constante única, também usada pelo Painel).

## 🔁 Rotina obrigatória ao abrir este projeto

**Toda vez** que uma conversa retomar o Controle LRC (pedido de Leandro, reforçado em 29/10/2026), antes de qualquer outra coisa:

1. **Vasculha de erros**: abrir todas as abas com Playwright efêmero e checar `pageerror`/console; procurar números que ainda leem `state.alunos`/`state.gastos_inb` locais (congelados desde 13/08/2026) em vez do Programa Nego Batera ao vivo.
2. **Melhorias com base no mercado**: comparar com Mobills, Organizze, Monarch, YNAB, Copilot e afins.
3. **Apresentar as sugestões dentro do contexto** num artefato visual (itens A1…/B1…), e **só aplicar o que Leandro aprovar**.
4. Fazer isso **mesmo que as sugestões da vez anterior não tenham sido aprovadas**.

## Vasculha 29/10/2026 aplicada (A2–A5, B1–B9)

- **Projeções** ganhou: cenários Conservador/Realista/Otimista, "Próximos 12 meses" (cálculo cobre 24 meses, `PROJ_N`), 🎯 Limites por categoria (`state.limites`, aviso a partir de 80%), 📏 Previsto × Real (`state.previsoes` = foto da projeção realista tirada antes de cada mês; sem foto, usa média dos 3 meses anteriores), 🏷️ Categorias editáveis (`state.regrasCategoria`, nome → grupo) e card de Reserva de emergência (meta 6 meses).
- **Importar Extrato** (Despesas): CSV da fatura Nubank (`date,title,amount`, compra positiva), CSV de conta (saída negativa) e OFX (Itaú). Vira Cotidiano com `grupo` e `origem:'extrato'`; pode tirar o "Saídas <banco>" resumido do mês (vai pra Lixeira).
- **Lixeira** (`state.lixeira`, 30 dias) + barra "Desfazer" 10 s em todos os remover do financeiro, agenda, shows e alunos especiais (`paraLixeira`/`restaurarLixeira`). O `confirm()` continua.
- **Salvamento automático na nuvem**: `saveState()` → `agendarAutoSaveNuvem()` → `dbPushAll(true)` 5 s depois, só `full_state`. Trava: o blob leva `atualizadoEm` e o aparelho guarda `lrc-nuvem-versao`. Nuvem mais nova → pausa e pede ↓ Importar. Aparelho sem versão → só liga depois de um Enviar/Importar manual. No boot, `verificarNuvemNoBoot()` avisa se a nuvem não responde.
- Chat IA: mensalidade/aluno/gasto INB → avisa que é no Programa Nego Batera; "paguei a luz" marca a fixa existente como paga (não cria fixa nova); sem fixa parecida → Cotidiano com o nome.
- Painel: gráfico mensal usa `calcProjecoes()` (INB ao vivo + fixas + parcelas). `wppTipo` declarado. Funções mortas da aba Lançar removidas.
- Novos campos do estado entram em `saveState`, no blob do `dbPushAll` e nas duas cargas (`dbLoad`, `dbPullAll`).

## Ajustes do Raio-X 29/10/2026 (D1, D3, D4, D5)

- Grupos pela natureza do gasto: novos 🧾 Impostos & Contador (`pontual:true`, não entra na média; Contador, DARF, Receita Federal, Dívida Ativa) e 👪 Família & Ajuda (Márcia). Cartão ML e Infinit Pay → 🛍️ Compras & Vestuário (são compras, confirmado por Leandro); Cartão Nubank/Itaú são fixos de verdade (assinaturas). A palavra-chave mais longa vence (`projGrupoPorPalavra`).
- Limites: `state.limites[id]` = número ou `{valor, acumula}`; com acumula, a sobra desde o 1º mês com gasto no ano fica disponível (`projLimiteDisponivel`). Nos meses futuros a projeção usa no máximo o limite (menos no Conservador). Padrão aplicado uma vez (`_migLimites2910`, sincronizado na nuvem): Alimentação 1200, Igreja 300 acumulativo.

## Meta Janeiro (desde 29/10/2026)

Card `#proj-meta-janeiro` na aba Projeções, visível de setembro a janeiro (`renderMetaJaneiro`). Meta automática = gastos − receita de janeiro na projeção realista (ou a meta que Leandro digitar); depósitos em `state.metas['jan<ano>'].depositos` (sincronizado na nuvem). Guardar não é gasto, não mexe no saldo. Junto entrou a sazonalidade do INB: nos meses do ano que vem, usa o mesmo mês deste ano quando ele já aconteceu (janeiro de férias entra baixo).

## Tabela antiga `shows` (limpa em 29/10/2026)

Os shows vivem só no `full_state` (app, Projeções e `sync-apps.ps1` leem de lá). A tabela `shows` do Supabase estava desatualizada: as 19 linhas foram apagadas e o app não grava mais nela (commit 643098f). Backup em `C:\Users\maste\Documents\Projetos\LRC\Backups\controle-lrc-tabela-shows-antiga-2026-10-29.json`. Em 29/10 Leandro rodou no SQL Editor o `drop table` de `shows`, `despesas_fixas`, `gastos_inb` e `gastos_nb` (conferido: 404 PGRST205). Mesmo tratamento, também em 29/10, para `despesas_fixas` (30 linhas), `gastos_inb` (24) e `gastos_nb` (18): apagadas, com backup na mesma pasta, e o app não grava mais nelas (commit f3ce15a). **O Supabase do Controle LRC agora tem só `app_meta` (full_state).** A tabela `alunos` (cópia do INB congelada desde 13/08/2026) saiu em 08/11/2026: o app não lê nem grava mais nela (boot, ↓ Importar, Enviar e `dbSave` ignoram), o Chat recusa também "marcar presença" do INB, e o vault Obsidian lê o INB do Programa Nego Batera. Backup em `Documents\Projetos\LRC\Backups\controle-lrc-tabela-alunos-antiga-2026-11-08.json`; o `drop table alunos` é o arquivo `supabase-drop-alunos-2026-11-08.sql` (Leandro roda no SQL Editor). A tabela `avulsos` nunca existeu neste Supabase (404 PGRST205): as duas gravações nela falhavam em silêncio e foram removidas. Os avulsos vivem só no `full_state`.

## Chat só no celular · WhatsApp no Programa Nego Batera (29/10/2026)

- **Aba WhatsApp removida** (página, funções `*Wpp*` e botões `abrirWppRapido` do cadastro antigo). Ela lia `state.alunos` congelado desde 13/08. Mensagens a alunos e responsáveis ficam só no Programa Nego Batera → 💬 Comunicados.
- **Chat só no celular**: classe `.so-celular` some com `@media (hover: hover) and (pointer: fine)`; `showPage('chat')` no notebook (`ehNotebook()`) cai no Painel.
- **Atalho do ícone** "🎤 Voz": `shortcuts` no manifest dinâmico → `/#voz`; `abrirVozSePedido()` abre o Chat e liga o microfone. Se o atalho não aparecer, remover e reinstalar o app na tela inicial.
- **Conferir antes de lançar**: `enviarChat` → `confirmarAcaoChat` mostra o cartão (`resumoAcaoChat`) com ✓ Lançar / ✏️ Corrigir; só o ✓ chama `executarAcao`. Consulta, erro e assuntos do Instituto seguem direto (não gravam nada). Texto da IA passa por `escChat`.
- Também ficam registrados aqui as migrações únicas de 29/10: `_migChatOutrosMai` (6 lançamentos de maio do Chat saíram de "Outros") e `_migIdsCotidiano` (ids repetidos 145–151 renumerados).

## Vasculha 30/10/2026 (A1–A4, B1–B6) — sw lrc-v19

- **A1 Relatórios**: Mensal, Anual e WhatsApp usam o realizado de `calcProjecoes('realista')` (`relResumoMes`, `relBloco`, `relSaldoFinal`). Antes somavam as fixas uma vez só, sem INB nem parcelas, com saldo anterior 2.688,66 fixo. Anual mostra também o previsto até dezembro. **A2** `rel-mes-sel` abre no mês atual.
- **A3** `sincronizarContadores()` depois de ↓ Importar (origem dos ids repetidos 145–151); `migrarIdsCotidiano` roda sempre e só mexe se houver repetido.
- **A4** Sem resposta do Programa Nego Batera (`pnbResumoAno` nulo): Receitas INB, A Receber e o Saldo mostram "—" com aviso (`pnbAnoCarregando`), em vez dos alunos locais congelados.
- **B1** `renderContasMes()` no Painel: fixas e parcelas do mês (atrasada / vence em X dias / paga) com ✓ (`pagarFixaPainel`, `pagarParcelaPainel`). **B2** Fechamento do mês anterior: aba Relatórios → 🗓️ Fechamento, aviso no Painel nos dias 1–7, imagem PNG (`imagemFechamento`). **B3** `buscarDespesas()` no topo de Despesas. **B4** Cotidiano monta só o mês aberto (`abrirCotMes`), de ~900 para ~300 botões.
- **B5** Cópia diária `app_meta` key `backup_AAAA-MM-DD` (7 mais recentes) em `dbPushAll`; menu da nuvem → 🛟 Cópias de segurança → "Voltar para esta" (guarda a atual em `restaurar_antes`).
- **B6** `state.conferencias` (no saveState, blob e nas duas cargas): saldo real das contas × `window._saldoApp`; só mostra a diferença, não lança nem mexe em Outros.

## Correção 30/10/2026 — celular sem nuvem (sw lrc-v20)
- Sintoma: celular com saldo diferente do notebook após "↓ Importar"; ponto da nuvem amarelo. Causa: quando a nuvem falha (chave/URL antiga no aparelho ou rede), `dbPullAll` dizia "✓ Dados importados" sem mudar nada.
- Agora `dbPullAll` lança erro se `full_state` não vier, mostra o motivo e não marca versão; `window._nuvemErro` aparece no menu da nuvem (`nuvemStatusTexto`).
- `ligarOutroAparelho()` (menu da nuvem → 📲): QR (qrcode-generator 1.4.4 do cdnjs, carregado sob demanda) com link `#nuvem=<base64 {u,k}>`. No boot, o hash grava `lrc-sb-url`/`lrc-sb-key`, limpa a URL e, ao conectar, chama `dbPullAll()` (flag `lrc-nuvem-ligada`).

## Encerrar conta fixa 30/10/2026 (sw lrc-v22)
- Campo opcional `encerradaEm` (chave de mês) em `despesas_fixas`; helper `fixaAtiva(d, k)` (k = mês absoluto, 12+ = ano que vem). Botão ⏹ `encerrarFixa(i)` na lista de fixas (vazio = reativar).
- Encerrada e não paga: some de Contas do mês, não entra no projetado (`calcProjecoes`) e vira "·" na tabela. O que já foi pago continua somando (totais usam `pagFixas` pelo nome — por isso NUNCA apagar uma fixa com histórico).
- Uso: Spotify foi para a fatura do Nubank em out/2026.

## ⭐ Regra "Sempre o melhor!" (vitalícia, 12/11/2026 — roteiro mestre, aplicar SEMPRE sem o Leandro pedir)

Toda verificação segue ANTES → DURANTE → DEPOIS → PUBLICAR, com **atenção maior aos cruzamentos deste app com os outros** (mapa das pontes: `Documents/Projetos/Geral/Mapa dos Cruzamentos.md`).
- **Antes:** estado real (git, data do deploy x commit, pastas, Obsidian) · marcar no mapa as pontes tocadas · mercado · retrato dos números e lint de base.
- **Durante:** correção pedida pelo Leandro = aplica e publica direto · erro que eu acho = mostro e aplico com o ok dele · melhoria = só com aprovação · perguntas sim/não.
- **Depois:** telas no celular e no notebook (Playwright) · **pior caso em cada ponte** (sem internet, lista vazia, SQL não rodado, nome diferente, dois aparelhos, um lado desatualizado) · teste de ponte no build · simplificação · artefato A/B com a seção "Cruzamentos entre apps".
- **Publicar:** Novidades no app + cartão PNG · Manual · memória e Obsidian · cartão **"Falta você"** (SQL, deploy, chave) — o pacote só fecha com ele vazio.
## Vasculha 18/11/2026 (A1–A4, B1–B4) — sw lrc-v26
- **A1** `saveState({semNuvem:true})` grava só no aparelho. Usado em `dbPullAll` (depois de ↓ Importar) e em `projGuardarPrevisoes` (foto do Previsto × Real é conta de tela). Antes, importar no celular reenviava o full_state com `atualizadoEm` novo e o notebook pausava o autosave ("⏸️ Não salvei na nuvem"); um Importar depois apagava o que foi lançado no notebook. Teste: Playwright com `dbPullAll()` + confirm aceito + todo POST bloqueado → 0 gravações depois de importar.
- **A2** `realizadoAteHoje()` (realizado de `calcProjecoes('realista')` até o mês atual, só do ano) é o saldo único: Painel (`saldo-total`, `saldo-sub`), Reserva de emergência e conferência com o banco. `despParc` do Painel só conta parcela paga deste ano dentro do período (`parcAtivaNaMes`). `SALDO_ANTERIOR_ANO` 1361 → **297** (só a mudança de fórmula: −675 parcelas de 2025, −549 Receita Federal). Banco em 18/11: R$ 1.763 (Itaú 1.404 + Nubank 4 + espécie 355) × app R$ 2.201 → R$ 438 de diferença deixados à mostra na conferência (Leandro lança em "Outros").
- **A3** celular: título numa linha, ano escondido, abas com máscara à direita; ponto da nuvem (`#sync-dot`) dentro do cabeçalho com área de toque de 26 px (antes fixo, caía sobre o Novidades). **A4** `.toast` com opacity/visibility (antes ficava a caixinha vazia).
- **B1** `renderConferir`: 7 dias sem conferir → abre sozinho com "⏰ hora de conferir". **B2** `contaFixaDoExtrato` + `APELIDOS_FIXA` (±35% do valor, só conta não paga no mês; cartão = "fatura" + banco): na prévia do extrato vira "Marcar X como paga" e não entra no cotidiano. **B3** `metaJanResumo(calc)` (conta única) + `renderMetaJanPainel()` (#painel-meta-jan). **B4** Painel de saúde confere a ponte 1 via `vault_shows_lrc` (SQL `2026-11-18-vault-shows-lrc.sql` no Programa NB, a rodar pelo Leandro).
- Cuidado ao editar com Python: `\b` dentro de string comum vira o caractere de controle 0x08 (a regex para de funcionar sem erro). Conferir caracteres < 32 depois de cada edição.

## 🔎 Cotidiano por item (18/11/2026, pedido do Leandro, Modo Êxito) — sw lrc-v27
- Aba "🔎 Por Item" em Despesas › Gastos do Cotidiano (`#cot-item`, `renderCotidianoItem`). Item = `cat` agrupado por `cotChaveItem` (minúscula, sem acento, trim). Mostra total, nº, média por pagamento, média por mês, maior; pagamentos por ano › mês (mais recente aberto), barra por mês. Extrato entra junto (marca "extrato"). Nome na aba Por Categoria abre o item (`abrirCotItem`).
- "✏️ Escrito parecido" por `cotChaveParecida` (sem da/de/do/das/dos/e e sem plural): botão **Juntar** (`juntarCotItem`) renomeia só o `cat` dos lançamentos do outro nome, com confirmação e "Desfazer" (15 s, `desfazerJuncaoCot`). Nunca junta sozinho. Links e botões usam `data-*` (apóstrofo seguro) e `cotEsc`.
- Testado com os dados reais (57 itens; Encontros da Igreja 6× + Encontro de Igreja 3× → 9× e desfeito) e piores casos (apóstrofo, sem data, dois anos, HTML no texto).

## Vasculha pós-pacote 18/11/2026 (A1–A3, B1–B4) — sw lrc-v28
- **A1** `contaFixaDoExtrato` devolve `jaPaga` quando a conta já está paga no mês com o mesmo valor (± R$ 1): o mesmo extrato importado de novo não vira gasto do cotidiano (antes a Luz contava em dobro).
- **A2** `dbPushAll` grava `state.resumoSaldo = {saldo, receitas, despesas, quando}` (de `realizadoAteHoje()`, só com o Instituto carregado) no full_state; `sync-apps.ps1` (Financeiro Pessoal) mostra esse saldo em vez do antigo "Saldo estimado" (receitas − fixas).
- **A3** a confirmação do Juntar avisa quando o grupo muda (o grupo do cotidiano sai do nome; nenhum lançamento tem `grupo` próprio).
- **B1** `lancarDiferencaOutros()`: banco menor que o app → botão lança a diferença em Outros (uma vez por conferência, `ult.lancado`). **B2** `state.regrasNome[chaveAntiga] = {de, para, antes:[{id,cat}], quando}`; `cotNomeComRegra` no lançamento à mão, no Chat e no extrato; lista "🔗 Nomes juntados" em Por Item com ✕ (`apagarRegraNome` devolve os nomes). **B3** `state.limitesItem[chave]` + aviso em Projeções a partir de 80%. **B4** topo do item: mês atual × média dos outros meses com seta.
- `resumoSaldo`, `regrasNome` e `limitesItem` entram no saveState, no blob e nos dois carregamentos da nuvem.

## Vasculha pós-pacote 3 18/11/2026 (A1–A4, B1–B4) — sw lrc-v29
- **A1** `juntarCotItem` leva o limite (`state.limitesItem`) para o nome que fica; se os dois têm, fica o do destino (a confirmação avisa). **A2** ao juntar, apaga a regra cuja chave é o nome que fica e qualquer regra que aponte para ela mesma (antes: "B → B"). O Desfazer devolve regras e limites como eram (`regrasAntes`/`limitesAntes` em `_ultimaJuncao`).
- **A3** `parcPagasNoAno(ano)`: conta única das parcelas pagas no ano (Painel e aba Despesas); `#desp-kpi-parc-sub` = "pagas em 2026 · + R$ X fora de 2026". **A4** caixa do Por Item: "Escolha um item (57)".
- **B1** `realizadoAteHoje().mes` → `resumoSaldo.mes = {ano, mes (0–11), receitas, despesas, saldo}`; `sync-apps.ps1` mostra "Saldo do mes (o mesmo do Painel do LRC)" quando o mês bate, senão a conta simples antiga. **B2** `saude-das-pontes.ps1`: item "Controle LRC enviando para a nuvem" (resumoSaldo.quando com mais de 7 dias = ⚠️).
- **B3** Chat: `chatPerguntaDeItem` ("quanto gastei com X", "média de X") responde local com `respostaGastoItem` (mês, ano, média por mês com lançamento, último); a IA também tem a ação `gasto_item` (não inventa valor). Resposta `consulta` agora passa por `escChat`.
- **B4** `historicoConferencias()` no cartão do banco (linhas compactas, seta ↓ menor/↑ maior); `conferirSaldo` guarda uma conferência por dia (a do mesmo dia substitui e mantém `lancado`).
- **lrc-v30 (18/11, tarde)**: `difConferencia(c)`: conferência de HOJE compara com `window._saldoApp` de agora (antes ficava o número da hora e o botão "Lançar em Outros" lançaria a diferença velha, contando de novo o que já foi lançado). De outro dia, fica o número daquele dia. `renderConferir` deixa uma conferência por dia.
- **lrc-v31 (18/11)**: "Google Pay" (compras na Play Store, confirmado pelo Leandro) + "google play"/"play store" entram no grupo 🎉 Lazer (`PROJ_GRUPOS_GASTO`). Google One continua em Assinaturas.

## Vasculha pós-pacote 4 18/11/2026 (A1–A4, B1–B4) — sw lrc-v32
- **A1** `hojeISO(d)` (data local): trocou os 19 `toISOString().slice(0,10)`/`split('T')[0]` (depois das 21h davam o dia seguinte). Chat: mês falado ≠ mês atual → data dia 01 daquele mês, `mes` sempre sai da data.
- **A2** conferência guarda `cotIdAte` (= `cotNextId` na hora). `atrasadosDaConferencia(c)`: lançamentos com id ≥ cotIdAte e data ANTERIOR ao dia (ou o "Outros" da conferência). `difConferencia` = c.app − atrasados (não usa mais `_saldoApp`: receita nova e gasto do mesmo dia não viram diferença). Conferência de 18/11 recebeu cotIdAte 595 em `migrarVasculha1811`.
- **A3** Chat: `respostaFixaParcelaGrupo` (conta fixa por `pagFixas`, parcela, grupo de `PROJ_GRUPOS_GASTO` via `calcProjecoes`); regex aceita "da/do/das/dos".
- **A4** Receita Federal: 04/08/2026, 12 parcelas → fim jul/2027; marca "jul/2026" removida (`migrarVasculha1811`, idempotente, roda no boot, no dbLoad e no ↓ Importar). KPI: "+ R$ 675 pagos antes de 2026".
- **A5 NÃO aplicado**: 6 lançamentos de 14/06 com mes 'mai' (ids 550–555) — a migração de 29/10 (`migrarChatOutrosMai`) diz que são gastos de MAIO lançados pelo Chat em 14/06. Confirmar com o Leandro antes.
- **B1** `renderDiasVazios` (#painel-dias-vazios): 14 dias sem lançamento; `abrirDiaCotidiano(dia)` abre o mês com a data; `marcarSemGasto` → `state.diasSemGasto` (saveState, blob e as duas cargas).
- **B2** prévia do extrato concilia: `noApp(it)` casa Cotidiano (mesmo valor, ±2 dias), parcela paga no mês e Gasto NB do mês, cada um uma vez só; linha "🔎 Conciliação" + "mostrar só as que faltam"; botão "📄 Comparar com o extrato" no cartão do banco (`abrirConciliacao`).
- **B3** campo `criado` nos lançamentos novos (form, Chat, Outros); `esquecidosPorMes()` no histórico das conferências.
- **B4** `resumoSaldo.conf = {data, banco, dif}`; `sync-apps.ps1` mostra a última conferência; `saude-das-pontes.ps1` avisa conferência com mais de 14 dias.
- Achado para a próxima: no celular de 360 px o formulário do mês do Cotidiano corta o campo Valor (≈188 px a mais), anterior a este pacote.
