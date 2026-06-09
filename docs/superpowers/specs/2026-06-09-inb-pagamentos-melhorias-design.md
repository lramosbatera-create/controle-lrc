# Design: INB Pagamentos — Janeiro, Avulsos e Mês de Início

**Data:** 2026-06-09  
**Projeto:** Controle LRC — `index.html` (single-file app)  
**Escopo:** Três melhorias na aba INB → Pagamentos e Cadastro

---

## 1. Modelo de Dados

### Aluno (existente — novos campos)
```js
{
  // campos existentes mantidos intactos
  mesInicio: 'fev',  // string com mês (jan/fev/.../dez) ou null (sem restrição)
  mat_pago: 185,     // já existe — valor da matrícula paga (0 = não paga)
}
```

### Avulsos (novo array no state)
```js
state.avulsos = [
  { id: 1, nome: 'Pedro Silva', mes: 'mar', valor: 120, obs: 'Aulas avulsas' }
]
```

- `id`: número sequencial via `state.nextId++`
- `mes`: um dos 12 meses (`jan`, `fev`, ..., `dez`)
- `obs`: campo livre, opcional
- Persistido em localStorage e Supabase (tabela `avulsos`)

---

## 2. Janeiro — Mês de Matrícula

### Regra central
Janeiro é mês exclusivo de matrícula/rematrícula. Nenhum aluno é cobrado de mensalidade em janeiro.

### Mudanças em funções de cálculo
- **`calcPago(aluno)`**: ignora `aluno.pag.jan` — janeiro não conta como mensalidade paga
- **`calcDevedor(aluno)`**: exclui janeiro do cálculo de pendências — ninguém deve mensalidade de janeiro
- **`updatePainel`**: receita INB de janeiro = somatória de `mat_pago` dos alunos que pagaram + avulsos de janeiro

### Mudanças na tabela de pagamentos
- Coluna `Jan` removida do grid de mensalidades mensais
- A coluna `Matrícula` (já existente) é o indicador do mês de janeiro para todos os alunos

---

## 3. Alunos Avulsos

### Interface
Nova sub-seção em **INB → Cadastro**, abaixo dos alunos regulares:

- **Formulário de adição:** campos nome, mês (select), valor (número), obs (texto livre)
- **Listagem:** cards simples com nome, mês, valor e botão excluir
- **Edição:** inline nos cards (campos editáveis direto)

### Financeiro
- `state.avulsos` integrado ao `updatePainel`: avulsos são somados à receita INB do mês correspondente
- **Aba Pagamentos → tabela mensal:** nova linha "Avulsos" exibindo valor agrupado por mês, abaixo do subtotal de mensalidades
- Avulsos entram na somatória do faturamento mensal e total anual

### Persistência
- Salvo em `localStorage` via `saveState()` (campo `avulsos` no objeto de state)
- Sincronizado com Supabase via `dbSave('avulsos', row)` e `dbDelete('avulsos', id)`

---

## 4. Mês de Início

### Interface
Campo `mesInicio` adicionado no **INB → Cadastro** de cada aluno, como select com os 12 meses (mais opção "Desde o início"). Campo posicionado na seção de dados principais do card do aluno.

### Comportamento ao salvar
Ao definir `mesInicio`, o sistema automaticamente marca `aluno.mat_pago = aluno.matricula` (matrícula registrada como paga no mês de início), sem intervenção manual.

### Mudanças em funções de cálculo
- **`calcPago(aluno)`**: soma mensalidades apenas a partir de `mesInicio` (meses anteriores ignorados)
- **`calcDevedor(aluno)`**: conta pendências apenas a partir de `mesInicio`

### Tabela de pagamentos
- Células de meses anteriores ao `mesInicio` exibidas em cinza com traço "—"
- Sem indicador de pago/pendente nesses meses

### Interação com a regra de janeiro
Aluno com `mesInicio: 'jan'` segue a regra da seção 2 — matrícula conta, mensalidade de janeiro não existe.

---

## 5. Sem impacto em

- Estrutura de `aluno.pag` (os dados brutos permanecem inalterados)
- Outras abas do app (Shows, Despesas, Chat, WhatsApp, Recital, Relatórios)
- Lógica de Supabase para outras tabelas

---

## 6. Sequência de implementação sugerida

1. Adicionar campo `mesInicio` no Cadastro e na lógica de `calcPago`/`calcDevedor`
2. Implementar regra de janeiro nas funções de cálculo e na tabela de pagamentos
3. Implementar Alunos Avulsos (state + UI + integração financeira)
