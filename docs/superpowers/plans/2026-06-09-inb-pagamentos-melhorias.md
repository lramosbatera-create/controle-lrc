# INB Pagamentos — Janeiro, Avulsos e Mês de Início — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar três melhorias na aba INB: regra de Janeiro (matrícula-only), campo mês de início por aluno com marcação automática de matrícula, e alunos avulsos com linha separada no balancete.

**Architecture:** Single-file HTML app. Todas as mudanças são em `C:\Users\maste\OneDrive\Desktop\index.html.html`. O deploy é feito via `deploy.ps1` que copia para o repo e publica no Cloudflare Pages. Não há testes automatizados — verificação é manual no browser após cada tarefa.

**Tech Stack:** HTML/CSS/JS puro, localStorage, Supabase (sync opcional)

---

## Arquivo Modificado

- `C:\Users\maste\OneDrive\Desktop\index.html.html` — único arquivo do app

---

## Constantes e estrutura de dados relevantes

```js
const MESES = ['jan','fev','mar','abr','mai','jun','jul','ago','set','out','nov','dez'];
// aluno.pag = { jan:0, fev:185, mar:185, ... }
// aluno.mat_pago = 185  // valor da matrícula paga
// state.cadastroExtra[aluno.id].mesInicio = "3"  // string "1"-"12" (1=jan)
// state.avulsos = [{ id, nome, mes, valor, obs }]  // NOVO
```

---

## Task 1: Corrigir saveState e inicializar avulsos

**Arquivos:**
- Modificar: `index.html.html` — função `saveState` (~linha 1972) e init (~linha 5975)

- [ ] **Step 1: Corrigir saveState para incluir cadastroExtra e avulsos**

Localizar a função `saveState` (~linha 1972) e substituir:

```js
// ANTES
function saveState() {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify({
      alunos: state.alunos,
      shows: state.shows,
      despesas_fixas: state.despesas_fixas,
      gastos_inb: state.gastos_inb,
      gastos_nb: state.gastos_nb,
      nextId: state.nextId,
    }));
  } catch(e) { console.warn('Save failed', e); }
}
```

```js
// DEPOIS
function saveState() {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify({
      alunos: state.alunos,
      shows: state.shows,
      despesas_fixas: state.despesas_fixas,
      gastos_inb: state.gastos_inb,
      gastos_nb: state.gastos_nb,
      nextId: state.nextId,
      cadastroExtra: state.cadastroExtra,
      avulsos: state.avulsos,
    }));
  } catch(e) { console.warn('Save failed', e); }
}
```

- [ ] **Step 2: Inicializar state.avulsos no bloco de init**

Localizar o bloco de init (~linha 5975), onde estão os `if (!state.recital)` etc., e adicionar:

```js
if (!state.avulsos) state.avulsos = [];
```

Deve ficar junto com as outras inicializações de state:

```js
if (!state.recital) state.recital = {inscricoes:[],receitas:[],despesas:[],taxaPadrao:150};
if (!state.cadastroExtra) state.cadastroExtra = {};
if (!state.agenda || !state.agenda.length) state.agenda = [];
if (!state.parceladas) state.parceladas = [];
if (!state.avulsos) state.avulsos = [];  // ADICIONAR ESTA LINHA
```

- [ ] **Step 3: Verificar no browser**

Abrir o app, abrir DevTools → Application → localStorage. Verificar que após qualquer ação que chame `saveState()`, o campo `avulsos` aparece no JSON salvo (array vazio `[]`).

- [ ] **Step 4: Commit**

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\maste\controle-lrc\deploy.ps1"
```

---

## Task 2: Regra de Janeiro — calcPago e calcDevedor

**Arquivos:**
- Modificar: `index.html.html` — funções `calcPago` (~linha 3697) e `calcDevedor` (~linha 3701)

- [ ] **Step 1: Reescrever calcPago**

Localizar e substituir a função `calcPago` (~linha 3697):

```js
// ANTES
function calcPago(aluno) {
  return Object.values(aluno.pag).reduce((a,b) => a+(b||0),0) + (aluno.mat_pago||0);
}
```

```js
// DEPOIS
function calcPago(aluno) {
  const extra = (state.cadastroExtra || {})[aluno.id] || {};
  const mesInicioIdx = extra.mesInicio ? parseInt(extra.mesInicio) - 1 : 0; // 0=jan
  return MESES.reduce((s, m, i) => {
    if (m === 'jan') return s; // janeiro não conta como mensalidade
    if (i < mesInicioIdx) return s; // meses antes do início ignorados
    return s + (aluno.pag[m] || 0);
  }, 0) + (aluno.mat_pago || 0);
}
```

- [ ] **Step 2: Reescrever calcDevedor**

Localizar e substituir a função `calcDevedor` (~linha 3701):

```js
// ANTES
function calcDevedor(aluno) {
  // meses já passados (jan=0,fev=1,mar=2 = índice 0,1,2 → 3 meses)
  const mesAtual = 2; // março = índice 2
  let devido = aluno.matricula || 0;
  for (let i = 0; i <= mesAtual; i++) {
    if (aluno.status === 'Ativo') devido += aluno.mensalidade;
  }
  const pago = calcPago(aluno);
  return Math.max(0, devido - pago);
}
```

```js
// DEPOIS
function calcDevedor(aluno) {
  const extra = (state.cadastroExtra || {})[aluno.id] || {};
  const mesInicioIdx = extra.mesInicio ? parseInt(extra.mesInicio) - 1 : 0; // 0=jan
  const mesAtualIdx = new Date().getMonth(); // 0=jan, dinâmico
  let devido = aluno.matricula || 0; // matrícula sempre devida
  for (let i = mesInicioIdx; i <= mesAtualIdx; i++) {
    if (i === 0) continue; // janeiro não tem mensalidade
    if (aluno.status === 'Ativo') devido += aluno.mensalidade;
  }
  const pago = calcPago(aluno);
  return Math.max(0, devido - pago);
}
```

- [ ] **Step 3: Verificar no browser**

Abrir app → aba Painel. Verificar que:
- O saldo/KPI de receita INB ainda está coerente
- Aba INB → Pagamentos: selecionar Janeiro → nenhum aluno deve aparecer como "pendente" de mensalidade
- Selecionar Fevereiro → alunos que não pagaram fev aparecem como pendentes normalmente

- [ ] **Step 4: Commit**

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\maste\controle-lrc\deploy.ps1"
```

---

## Task 3: Mês de Início — salvarCadastro com auto-matrícula

**Arquivos:**
- Modificar: `index.html.html` — função `salvarCadastro` (~linha 2505)

- [ ] **Step 1: Adicionar auto-marcação de matrícula ao salvar mesInicio**

Localizar a função `salvarCadastro` (~linha 2505). Após a linha `ex.mesInicio = get(\`cad-mesinicio-${id}\`)?.value;` e antes de `saveState()`, adicionar:

```js
// Auto-marca matrícula quando mês de início é definido pela primeira vez
if (ex.mesInicio && !(a.mat_pago > 0)) {
  a.mat_pago = a.matricula;
  dbSave('alunos', {...a});
}
```

O trecho completo ficará:

```js
ex.mesInicio      = get(`cad-mesinicio-${id}`)?.value;
ex.mesSaida       = get(`cad-messaida-${id}`)?.value;
ex.aniversario    = get(`cad-aniv-${id}`)?.value;
ex.situacao       = get(`cad-obs-${id}`)?.value.trim();

// Auto-marca matrícula quando mês de início é definido pela primeira vez
if (ex.mesInicio && !(a.mat_pago > 0)) {
  a.mat_pago = a.matricula;
  dbSave('alunos', {...a});
}

saveState();
renderAlunos();
toast(`✓ ${a.nome} salvo com sucesso!`);
```

- [ ] **Step 2: Verificar no browser**

Abrir app → INB → Cadastro. Selecionar um aluno sem matrícula marcada. Definir um mês de início e clicar em Salvar. Verificar:
- Toast "✓ salvo com sucesso"
- Na aba Pagamentos → Tabela Anual: a coluna MAT do aluno deve mostrar ✓

- [ ] **Step 3: Commit**

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\maste\controle-lrc\deploy.ps1"
```

---

## Task 4: Tabela Anual — Janeiro "—" e células antes do mês de início

**Arquivos:**
- Modificar: `index.html.html` — função `renderTabelaAnual` (~linha 2906)

- [ ] **Step 1: Atualizar geração de células mensais na tabela anual**

Dentro de `renderTabelaAnual`, localizar o bloco `${MESES.map((m) => { ... }).join('')}` que gera as células de cada mês (~linha 2943).

Substituir o bloco completo:

```js
// ANTES
${MESES.map(m => {
  const pago = a.pag[m]||0;
  const isFuture = MESES.indexOf(m) > new Date().getMonth();
  const bg2 = isFuture ? 'transparent' : pago>0 ? 'rgba(39,174,96,0.15)' : 'rgba(192,57,43,0.08)';
  const color = isFuture ? 'rgba(255,255,255,0.15)' : pago>0 ? 'var(--green)' : '#E74C3C';
  const label = isFuture ? '·' : pago>0 ? '✓' : '×';
  return `<td onclick="${isFuture?'':'togglePagamento('+a.id+',\''+m+'\')'}" style="cursor:${isFuture?'default':'pointer'};text-align:center;padding:4px;border-bottom:1px solid rgba(255,255,255,0.04);background:${bg2};">
    <span style="font-size:10px;color:${color};">${label}</span>
  </td>`;
}).join('')}
```

```js
// DEPOIS
${MESES.map((m, idx) => {
  const extra2 = (state.cadastroExtra || {})[a.id] || {};
  const mesInicioIdx2 = extra2.mesInicio ? parseInt(extra2.mesInicio) - 1 : 0;
  const pago = a.pag[m] || 0;
  const isFuture = idx > new Date().getMonth();
  const isJan = m === 'jan';
  const beforeStart = idx < mesInicioIdx2;
  if (isJan || beforeStart) {
    return `<td style="text-align:center;padding:4px;border-bottom:1px solid rgba(255,255,255,0.04);background:transparent;">
      <span style="font-size:10px;color:rgba(255,255,255,0.18);">—</span>
    </td>`;
  }
  const bg2 = isFuture ? 'transparent' : pago>0 ? 'rgba(39,174,96,0.15)' : 'rgba(192,57,43,0.08)';
  const color = isFuture ? 'rgba(255,255,255,0.15)' : pago>0 ? 'var(--green)' : '#E74C3C';
  const label = isFuture ? '·' : pago>0 ? '✓' : '×';
  return `<td onclick="${isFuture?'':'togglePagamento('+a.id+',\''+m+'\')'}" style="cursor:${isFuture?'default':'pointer'};text-align:center;padding:4px;border-bottom:1px solid rgba(255,255,255,0.04);background:${bg2};">
    <span style="font-size:10px;color:${color};">${label}</span>
  </td>`;
}).join('')}
```

- [ ] **Step 2: Verificar no browser**

Abrir INB → Pagamentos → Tabela Anual. Verificar:
- Coluna Jan: todos os alunos mostram "—" cinza (sem ✓ ou ×)
- Alunos com mesInicio definido (ex: março): meses Jan e Fev mostram "—" cinza
- Alunos sem mesInicio: Jan mostra "—", outros meses normais

- [ ] **Step 3: Commit**

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\maste\controle-lrc\deploy.ps1"
```

---

## Task 5: Visão Mensal — Janeiro especial e chips de mês

**Arquivos:**
- Modificar: `index.html.html` — funções `renderPagMensal` (~linha 2797) e `renderPagamentos` (~linha 2771)

- [ ] **Step 1: Adicionar tratamento especial de Janeiro em renderPagMensal**

No início da função `renderPagMensal` (~linha 2797), logo após a linha `const mes = pagMesAtual;`, adicionar o bloco de tratamento de janeiro:

```js
function renderPagMensal() {
  const mes = pagMesAtual;

  // Janeiro: mês exclusivo de matrícula — lógica separada
  if (mes === 'jan') {
    const ativos = state.alunos.filter(a => a.status === 'Ativo');
    const container = document.getElementById('pag-mes-lista');
    if (!container) return;
    const matriculados = ativos.filter(a => (a.mat_pago || 0) > 0);
    const semMat = ativos.filter(a => !((a.mat_pago || 0) > 0));
    const recebido = matriculados.reduce((s, a) => s + (a.mat_pago || 0), 0);
    const el = id => document.getElementById(id);
    if (el('pag-mes-recebido'))    el('pag-mes-recebido').textContent    = fmtBRL(recebido);
    if (el('pag-mes-pendente'))    el('pag-mes-pendente').textContent    = fmtBRL(0);
    if (el('pag-mes-pagaram'))     el('pag-mes-pagaram').textContent     = `${matriculados.length} matriculados`;
    if (el('pag-mes-nao-pagaram')) el('pag-mes-nao-pagaram').textContent = `${semMat.length} sem matrícula`;
    if (el('pag-mes-esperado'))    el('pag-mes-esperado').textContent    = fmtBRL(0);
    if (el('pag-mes-total-alunos')) el('pag-mes-total-alunos').textContent = `${ativos.length} alunos ativos`;
    if (el('pag-mes-pct'))         el('pag-mes-pct').textContent         = '—';
    if (el('pag-mes-pct-bar'))     el('pag-mes-pct-bar').style.width     = '0%';
    container.innerHTML = `
      <div style="background:rgba(201,168,76,0.06);border:1px solid rgba(201,168,76,0.2);border-radius:10px;padding:12px;margin-bottom:16px;">
        <div style="font-size:11px;color:var(--gold);font-weight:600;">ℹ️ Janeiro — mês de matrícula/rematrícula</div>
        <div style="font-size:11px;color:var(--muted);margin-top:4px;">Nenhuma mensalidade é cobrada em janeiro. Somente matrículas e rematrículas são contabilizadas.</div>
      </div>
      ${matriculados.length ? `
      <div style="font-size:10px;color:var(--green);letter-spacing:1.5px;text-transform:uppercase;margin-bottom:8px;font-weight:600;">✅ MATRICULADOS (${matriculados.length})</div>
      ${matriculados.sort((a,b)=>a.nome.localeCompare(b.nome)).map(a=>`
        <div style="display:flex;align-items:center;gap:10px;padding:10px 12px;background:rgba(39,174,96,0.06);border:1px solid rgba(39,174,96,0.2);border-radius:10px;margin-bottom:6px;">
          <div style="width:8px;height:8px;border-radius:50%;background:var(--green);flex-shrink:0;"></div>
          <div style="flex:1;font-size:13px;font-weight:500;color:var(--text);">${a.nome}</div>
          <div style="font-family:'Cormorant Garamond',serif;font-size:16px;color:var(--green);font-weight:700;">${fmtBRL(a.mat_pago||0)}</div>
        </div>`).join('')}` : ''}
      ${semMat.length ? `
      <div style="font-size:10px;color:var(--muted);letter-spacing:1.5px;text-transform:uppercase;margin-bottom:8px;font-weight:600;margin-top:16px;">⬜ SEM REMATRÍCULA (${semMat.length})</div>
      ${semMat.sort((a,b)=>a.nome.localeCompare(b.nome)).map(a=>`
        <div style="display:flex;align-items:center;gap:10px;padding:10px 12px;background:rgba(255,255,255,0.03);border:1px solid rgba(255,255,255,0.07);border-radius:10px;margin-bottom:6px;">
          <div style="width:8px;height:8px;border-radius:50%;background:var(--muted);flex-shrink:0;"></div>
          <div style="flex:1;font-size:13px;color:var(--muted);">${a.nome}</div>
        </div>`).join('')}` : ''}`;
    return; // <-- sai da função aqui para janeiro
  }

  // --- código original continua abaixo (sem alteração) ---
  const mesNome = MESES_FULL[MESES.indexOf(mes)];
  // ... resto da função original intacto
```

- [ ] **Step 2: Atualizar chip de Janeiro em renderPagamentos**

Na função `renderPagamentos` (~linha 2788), substituir o loop de chips para tratar Janeiro diferente:

```js
// ANTES
MESES.forEach(m => {
  const total = ativos.reduce((s,a)=>s+(a.pag[m]||0),0);
  const chip = document.getElementById('pag-chip-' + m);
  if (chip) chip.textContent = total > 0 ? fmtBRL(total) : '—';
});
```

```js
// DEPOIS
MESES.forEach(m => {
  let total;
  if (m === 'jan') {
    // Janeiro: mostra soma das matrículas pagas
    total = ativos.reduce((s,a) => s + (a.mat_pago||0), 0);
  } else {
    total = ativos.reduce((s,a) => s + (a.pag[m]||0), 0)
          + (state.avulsos||[]).filter(av=>av.mes===m).reduce((s,av)=>s+av.valor,0);
  }
  const chip = document.getElementById('pag-chip-' + m);
  if (chip) chip.textContent = total > 0 ? fmtBRL(total) : '—';
});
```

- [ ] **Step 3: Verificar no browser**

Abrir INB → Pagamentos:
- Chip de Janeiro: deve mostrar soma das matrículas pagas (não mensalidades)
- Clicar no chip de Janeiro: view mensal deve mostrar o banner informativo + listas de matriculados/sem matrícula
- Clicar em outro mês (ex: Março): funcionar normalmente como antes

- [ ] **Step 4: Commit**

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\maste\controle-lrc\deploy.ps1"
```

---

## Task 6: Alunos Avulsos — funções JS

**Arquivos:**
- Modificar: `index.html.html` — adicionar funções de avulsos após `renderPagamentos`

- [ ] **Step 1: Adicionar funções renderAvulsos, addAvulso, deleteAvulso**

Localizar o final da função `renderPagamentos` (~linha 2795) e adicionar APÓS ela:

```js
// ============ AVULSOS ============
function renderAvulsos() {
  const container = document.getElementById('avulsos-lista');
  if (!container) return;
  const lista = state.avulsos || [];
  if (!lista.length) {
    container.innerHTML = '<div style="font-size:12px;color:var(--muted);text-align:center;padding:16px;">Nenhum aluno avulso cadastrado</div>';
    return;
  }
  container.innerHTML = lista.map(av => `
    <div style="display:flex;align-items:center;gap:10px;padding:10px 12px;background:var(--card2);border:1px solid var(--border);border-radius:10px;margin-bottom:6px;">
      <div style="flex:1;">
        <div style="font-size:13px;font-weight:600;color:var(--text);">${av.nome}</div>
        <div style="font-size:11px;color:var(--muted);">${MESES_FULL[MESES.indexOf(av.mes)]} · ${av.obs||''}</div>
      </div>
      <div style="font-family:'Cormorant Garamond',serif;font-size:16px;color:var(--gold);font-weight:700;margin-right:8px;">${fmtBRL(av.valor)}</div>
      <button onclick="deleteAvulso(${av.id})" style="background:none;border:none;color:var(--muted);font-size:16px;cursor:pointer;padding:4px;" title="Excluir">🗑</button>
    </div>`).join('');
}

function addAvulso() {
  const nome  = document.getElementById('av-nome')?.value.trim();
  const mes   = document.getElementById('av-mes')?.value;
  const valor = parseFloat(document.getElementById('av-valor')?.value) || 0;
  const obs   = document.getElementById('av-obs')?.value.trim();
  if (!nome || !mes || !valor) { toast('⚠️ Preencha nome, mês e valor'); return; }
  if (!state.avulsos) state.avulsos = [];
  const novo = { id: state.nextId++, nome, mes, valor, obs };
  state.avulsos.push(novo);
  dbSave('avulsos', novo);
  saveState();
  document.getElementById('av-nome').value  = '';
  document.getElementById('av-valor').value = '';
  document.getElementById('av-obs').value   = '';
  renderAvulsos();
  updatePainel();
  renderPagamentos();
  toast(`✓ ${nome} adicionado como avulso!`);
}

function deleteAvulso(id) {
  state.avulsos = (state.avulsos || []).filter(av => av.id !== id);
  dbDelete('avulsos', id);
  saveState();
  renderAvulsos();
  updatePainel();
  renderPagamentos();
  toast('Avulso removido');
}
```

- [ ] **Step 2: Verificar que as funções existem**

Abrir o app no browser, abrir DevTools → Console e digitar `typeof addAvulso`. Deve retornar `"function"`.

- [ ] **Step 3: Commit**

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\maste\controle-lrc\deploy.ps1"
```

---

## Task 7: Avulsos — UI no Cadastro e linha na visão mensal

**Arquivos:**
- Modificar: `index.html.html` — HTML da aba INB Cadastro e renderPagMensal

- [ ] **Step 1: Adicionar seção de Avulsos no HTML do INB Cadastro**

Localizar o fechamento da aba Cadastro no HTML, a div com id `inb-cadastro` (~linha 2340). No final do conteúdo dessa div, antes do `</div>` que a fecha, adicionar:

```html
<!-- AVULSOS -->
<div style="margin-top:24px;">
  <div style="font-size:10px;color:var(--gold);letter-spacing:1.5px;text-transform:uppercase;margin-bottom:12px;font-weight:600;">👤 Alunos Avulsos</div>
  <div style="background:var(--card);border:1px solid var(--border);border-radius:12px;padding:14px;margin-bottom:12px;">
    <div style="display:grid;grid-template-columns:1fr auto 1fr;gap:8px;margin-bottom:8px;align-items:end;">
      <div>
        <div style="color:var(--muted);font-size:10px;letter-spacing:1px;text-transform:uppercase;margin-bottom:4px;">Nome</div>
        <input id="av-nome" type="text" placeholder="Nome do aluno"
          style="background:var(--card2);border:1px solid rgba(201,168,76,0.2);border-radius:6px;color:var(--text);font-size:12px;padding:6px 8px;width:100%;outline:none;">
      </div>
      <div>
        <div style="color:var(--muted);font-size:10px;letter-spacing:1px;text-transform:uppercase;margin-bottom:4px;">Mês</div>
        <select id="av-mes"
          style="background:var(--card2);border:1px solid rgba(201,168,76,0.2);border-radius:6px;color:var(--text);font-size:11px;padding:6px 8px;width:100%;outline:none;">
          <option value="">—</option>
          ${MESES.map((m,i)=>`<option value="${m}">${MESES_FULL[i]}</option>`).join('')}
        </select>
      </div>
      <div>
        <div style="color:var(--muted);font-size:10px;letter-spacing:1px;text-transform:uppercase;margin-bottom:4px;">Valor (R$)</div>
        <input id="av-valor" type="number" placeholder="0"
          style="background:var(--card2);border:1px solid rgba(201,168,76,0.2);border-radius:6px;color:var(--text);font-size:12px;padding:6px 8px;width:100%;outline:none;">
      </div>
    </div>
    <div style="margin-bottom:8px;">
      <div style="color:var(--muted);font-size:10px;letter-spacing:1px;text-transform:uppercase;margin-bottom:4px;">Observação (opcional)</div>
      <input id="av-obs" type="text" placeholder="Ex: Aulas avulsas, workshop..."
        style="background:var(--card2);border:1px solid rgba(201,168,76,0.2);border-radius:6px;color:var(--text);font-size:12px;padding:6px 8px;width:100%;outline:none;">
    </div>
    <button onclick="addAvulso()" class="btn btn-gold" style="font-size:12px;padding:8px 16px;">＋ Adicionar Avulso</button>
  </div>
  <div id="avulsos-lista"></div>
</div>
```

**Atenção:** O select de `av-mes` usa template literals com `${MESES.map(...)}`. Como esse HTML fica dentro de um template literal JavaScript (gerado pelo JS), isso funcionará corretamente pois o `MESES` estará disponível no escopo.

Mas se esse HTML está no HTML estático (não gerado por JS), use a lista fixa:

```html
<option value="jan">Janeiro</option>
<option value="fev">Fevereiro</option>
<option value="mar">Março</option>
<option value="abr">Abril</option>
<option value="mai">Maio</option>
<option value="jun">Junho</option>
<option value="jul">Julho</option>
<option value="ago">Agosto</option>
<option value="set">Setembro</option>
<option value="out">Outubro</option>
<option value="nov">Novembro</option>
<option value="dez">Dezembro</option>
```

**Verificar onde está a aba Cadastro:** Localizar `id="inb-cadastro"` no HTML (~linha 1040+) para encontrar o local exato onde inserir.

- [ ] **Step 2: Adicionar linha de Avulsos na visão mensal (renderPagMensal)**

No final do `container.innerHTML = \`...\`` da função `renderPagMensal` (antes do fechamento da template literal, após a lista de não pagaram), adicionar a linha de avulsos:

```js
// Após o bloco dos "Não pagaram", antes do fechamento da template:
${(() => {
  const avulsosMes = (state.avulsos||[]).filter(av => av.mes === mes);
  if (!avulsosMes.length) return '';
  const totalAv = avulsosMes.reduce((s,av)=>s+av.valor,0);
  return `
    <div style="margin-top:16px;padding-top:16px;border-top:1px solid var(--border);">
      <div style="font-size:10px;color:var(--gold);letter-spacing:1.5px;text-transform:uppercase;margin-bottom:8px;font-weight:600;">👤 AVULSOS (${avulsosMes.length})</div>
      ${avulsosMes.map(av=>`
        <div style="display:flex;align-items:center;gap:10px;padding:8px 12px;background:rgba(201,168,76,0.05);border:1px solid rgba(201,168,76,0.15);border-radius:10px;margin-bottom:6px;">
          <div style="flex:1;">
            <div style="font-size:13px;color:var(--text);">${av.nome}</div>
            ${av.obs?`<div style="font-size:10px;color:var(--muted);">${av.obs}</div>`:''}
          </div>
          <div style="font-family:'Cormorant Garamond',serif;font-size:16px;color:var(--gold);font-weight:700;">${fmtBRL(av.valor)}</div>
        </div>`).join('')}
      <div style="text-align:right;font-size:11px;color:var(--gold);margin-top:4px;">Total avulsos: ${fmtBRL(totalAv)}</div>
    </div>`;
})()}
```

- [ ] **Step 3: Chamar renderAvulsos no showInbTab para a aba Cadastro**

Localizar a função `showInbTab` (~linha 2217) e adicionar a chamada:

```js
function showInbTab(tab, btn) {
  document.querySelectorAll('.inb-tab-content').forEach(el => el.style.display = 'none');
  document.querySelectorAll('.inb-subtab').forEach(b => b.classList.remove('active'));
  document.getElementById('inb-' + tab).style.display = 'block';
  btn.classList.add('active');
  if (tab === 'cadastro') renderAlunos(); // já existe
  if (tab === 'cadastro') renderAvulsos(); // ADICIONAR
}
```

Verificar se a função já tem esse padrão e apenas adicionar a linha `if (tab === 'cadastro') renderAvulsos();`.

- [ ] **Step 4: Verificar no browser**

Abrir INB → Cadastro. Verificar:
- Seção "Avulsos" aparece no final da aba
- Adicionar um avulso (ex: "Pedro", Março, R$120). Toast de confirmação.
- O avulso aparece listado.
- Abrir Pagamentos → selecionar Março → avulso aparece como linha separada "AVULSOS"
- Chip do mês Março inclui o valor do avulso no total
- Excluir o avulso → desaparece

- [ ] **Step 5: Commit final**

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\maste\controle-lrc\deploy.ps1"
```

---

## Task 8: Integrar avulsos no updatePainel

**Arquivos:**
- Modificar: `index.html.html` — função `updatePainel` (~linha 5523)

- [ ] **Step 1: Adicionar avulsos à receita INB no updatePainel**

Localizar `updatePainel` (~linha 5523). Encontrar a linha onde `recINB` é calculado:

```js
const recINB = state.alunos.reduce((s,a) => s + calcPago(a), 0);
```

Substituir por:

```js
const recINBAlunos = state.alunos.reduce((s,a) => s + calcPago(a), 0);
const recINBAvulsos = (state.avulsos||[]).reduce((s,av) => s + av.valor, 0);
const recINB = recINBAlunos + recINBAvulsos;
```

- [ ] **Step 2: Verificar no browser**

Abrir app. Adicionar um avulso de R$500 em março. Verificar no Painel:
- KPI "Receitas INB" aumenta em R$500
- Saldo total atualiza

- [ ] **Step 3: Commit**

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\maste\controle-lrc\deploy.ps1"
```
