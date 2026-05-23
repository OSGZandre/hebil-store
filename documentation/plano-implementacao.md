# Plano de Implementação — Hebil Store

Documento **interno** para dividir o desenvolvimento em partes entregáveis, do mais simples ao mais complexo.

**Referências:**

- Requisitos: [`requisitos-pt1.md`](requisitos-pt1.md)
- Arquitetura: [`arquitetura.md`](arquitetura.md)
- Modelo de dados: [`modelo-dados.md`](modelo-dados.md)
- Stack: [`tecnologias.md`](tecnologias.md)

**Legenda de status:** `Concluído` · `Em andamento` · `Pendente`

---

## Decisão: login e Symfony Security por último

Login, `security.yaml`, roles e rotas protegidas ficam nas **fases 10 e 11** — depois do núcleo operacional (produto, estoque, caixa, PDV).

Até lá o sistema roda em **modo desenvolvimento sem autenticação** (ver seção abaixo).

---

## 1. Modo desenvolvimento (sem Security)

Enquanto as fases 0–9 não estiverem prontas para produção:

| Aspecto | Abordagem temporária |
|---------|----------------------|
| Rotas | Abertas em `dev` (sem `access_control`) |
| `idUsuario` / `idLoja` | Serviço `Shared/Context/UsuarioContext` com valores fixos do seed (`idUsuario = 1`, `idLoja = 1`) ou variáveis em `.env.local` |
| Operador na venda/caixa | Sempre o usuário “mock”; trocar no `.env` para simular outro |
| Autorização admin (Fase 5) | Validar senha do admin **direto no banco** (`password_verify` + `UsuarioRepository`) — **sem** Symfony Security |
| Produção | **Não publicar** sem concluir Fase 10 |

```text
Controllers / Services
        │
        ▼
UsuarioContext (mock em dev)
        │
        ▼
idUsuario, idLoja → repositories
```

Ao implementar a **Fase 10**, o mock é substituído pelo usuário da sessão Symfony.

---

## 2. Como usar este documento

Cada **fase** tem objetivo, requisitos, módulos, critério de pronto e dependências.

```text
Fase 0 → 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → 10 → 11 → 12
         └──── negócio / PDV (sem login) ────┘  └─ Security ─┘  backlog
```

---

## 3. Visão geral das fases

| Fase | Nome | Complexidade | Security? |
|------|------|--------------|-----------|
| 0 | Fundação técnica | Baixa | Não |
| 1 | Produtos e categorias | Baixa | Não |
| 2 | Estoque básico | Média | Não |
| 3 | Caixa (essencial) | Média | Não |
| 4 | PDV — venda feliz | Média | Não |
| 5 | Auditoria e autorização admin | Média-alta | Só `password_verify` |
| 6 | Estoque avançado | Média-alta | Não |
| 7 | Caixa avançado | Média | Não |
| 8 | Relatórios | Média-alta | Não |
| 9 | Dashboards e despesas | Alta | Não |
| **10** | **Autenticação (Symfony Security)** | Média | **Sim** |
| **11** | **Usuários (admin) + proteção de rotas** | Média | **Sim** |
| 12 | Evoluções | Variável | — |

---

## 4. O que já foi feito (planejamento / infra)

| Item | Status |
|------|--------|
| Levantamento de requisitos | Concluído |
| Documentação stack / arquitetura / modelo | Concluído |
| Script SQL MVP | Concluído |
| Banco `loja_system` | A confirmar |
| Código dos módulos | Pendente |

---

## 5. Detalhamento por fase

---

### Fase 0 — Fundação técnica

**Status:** Concluído

**Objetivo:** Base para módulos + SQL direto + layout, **sem** login.

| Entregável | Descrição |
|------------|-----------|
| `Shared/Database/` | `ConnectionFactory`, `TransactionManager` |
| `Shared/Context/UsuarioContext` | Mock `idUsuario` / `idLoja` (dev) |
| `src/Module/*` | Estrutura de pastas |
| Layout Twig + Bootstrap | `base.html.twig`, menu para módulos |
| Home | Links: Produtos, Estoque, Caixa, PDV (sem redirect para login) |
| Doctrine ORM | Remover quando implementar conexão PDO |

**Critério de pronto:**

- [x] PDO conecta em `loja_system`
- [x] Repository de teste: `SELECT 1`
- [x] `UsuarioContext` retorna ids do seed
- [x] Layout base abre sem erro

**Estimativa:** 1–2 dias

---

### Fase 1 — Produtos e categorias

**Status:** Pendente

**Objetivo:** Catálogo para o PDV.

| Entregável | Descrição |
|------------|-----------|
| Módulo `Produto` | CRUD, inativar (`status`), busca, barcode |
| `Categoria` | CRUD (pode ficar no mesmo módulo) |
| Telas | `/produtos`, `/categorias` |

**Requisitos:** cadastrar, editar, inativar, pesquisar produtos; categorias para filtros futuros.

**Depende de:** Fase 0

**Estimativa:** 2–3 dias

---

### Fase 2 — Estoque básico

**Status:** Pendente

**Objetivo:** Saldo, entrada manual, alerta mínimo.

| Entregável | Descrição |
|------------|-----------|
| Módulo `Estoque` | Movimentos + atualização `estoque_atual` |
| Telas | Consulta, entrada, histórico, estoque baixo |

**Requisitos:** consultar estoque, entradas, alerta mínimo.

**Depende de:** Fase 1

**Estimativa:** 2–3 dias

---

### Fase 3 — Caixa (essencial)

**Status:** Pendente

**Objetivo:** Abrir/fechar turno; sangria e suprimento.

| Entregável | Descrição |
|------------|-----------|
| Módulo `Caixa` | Cadastro gaveta, `sessao_caixa`, `movimento_caixa` |
| `idUsuario` | Via `UsuarioContext` (mock) |
| Regra | Uma sessão `Aberta` por caixa |

**Requisitos:** abertura/fechamento, sangria, suprimento, responsável e horários.

**Depende de:** Fase 0

**Estimativa:** 2–3 dias

---

### Fase 4 — PDV — venda feliz

**Status:** Pendente

**Objetivo:** Venda completa com 1 pagamento (Strategy), baixa estoque e caixa.

| Entregável | Descrição |
|------------|-----------|
| Módulo `Venda` | PDV, itens, finalizar |
| `Pagamento/Handler/*` | Factory + dinheiro/PIX/cartão |
| Transação | Venda + estoque + movimento caixa |

**Requisitos:** iniciar venda, itens, busca/barcode, forma pagamento, finalizar, baixa estoque.

**Depende de:** Fases 1, 2, 3

**Estimativa:** 4–6 dias

**Marco:** primeira versão **usável na loja** (ainda sem login).

---

### Fase 5 — Auditoria e autorização admin

**Status:** Pendente

**Objetivo:** Logs e operações críticas — **sem Symfony Security**.

| Entregável | Descrição |
|------------|-----------|
| Módulo `Auditoria` | `audit_log`, `admin_autorizacao` |
| Senha admin | `UsuarioRepository` + `password_verify` (tipo `Administrador`) |
| PDV | Remover item, cancelar venda, desconto crítico + motivo |
| Modal | Stimulus pede login/senha admin (validação no service) |

**Requisitos:** autorização administrativa, logs, motivo obrigatório, venda nunca some.

**Não usa:** `security.yaml`, UserProvider, voters (vêm na Fase 10).

**Depende de:** Fase 4

**Estimativa:** 4–5 dias

**Marco:** requisito central de **auditoria** atendido em dev.

---

### Fase 6 — Estoque avançado

**Status:** Pendente

**Objetivo:** Ajuste, perda, bloqueio sem estoque (e exceção com admin da Fase 5).

**Depende de:** Fases 4, 5

**Estimativa:** 2–3 dias

---

### Fase 7 — Caixa avançado

**Status:** Pendente

**Objetivo:** Fechamento com divergência e motivo; resumo da sessão.

**Depende de:** Fases 3, 4, 5

**Estimativa:** 2 dias

---

### Fase 8 — Relatórios

**Status:** Pendente

**Objetivo:** Listagens, filtros, export CSV (rotas ainda abertas).

**Depende de:** Fases 4–7

**Estimativa:** 4–5 dias

---

### Fase 9 — Dashboards e despesas

**Status:** Pendente

**Objetivo:** KPIs, Chart.js, CRUD `despesa`, lucro (telas “admin” sem bloqueio ainda).

**Depende de:** Fases 4, 8

**Estimativa:** 4–6 dias

**Marco:** **gestão completa em dev** (fases 0–9).

---

### Fase 10 — Autenticação (Symfony Security)

**Status:** Pendente — **adiada de propósito**

**Objetivo:** Login/logout, sessão, roles, proteger rotas.

| Entregável | Descrição |
|------------|-----------|
| Módulo `Auth` | Form login, logout |
| `UsuarioRepository` | UserProvider para Security |
| `security.yaml` | Firewalls, `access_control`, hierarquia roles |
| Substituir mock | `UsuarioContext` lê usuário autenticado |
| Remover | Acesso aberto em rotas sensíveis |

**Requisitos:** login/logout, níveis de acesso, bloquear não autenticado, senhas hash.

**Depende de:** Fases 0–9 estáveis (rotas e módulos existentes)

**Estimativa:** 2–3 dias

---

### Fase 11 — Usuários (admin) + permissões finas

**Status:** Pendente

**Objetivo:** CRUD usuários **com** rotas já protegidas pela Fase 10.

| Entregável | Descrição |
|------------|-----------|
| Módulo `Usuario` | CRUD, ativar/desativar, redefinir senha |
| Voters (opcional) | Reforçar “funcionário não vê lucro/relatórios” |
| `matriz-permissoes.md` | Documentar ação × perfil |

**Requisitos:** cadastro, edição, desativação, reset senha; funcionário não gerencia usuários.

**Depende de:** Fase 10

**Estimativa:** 2 dias

**Marco:** **pronto para ambiente piloto com login real**.

---

### Fase 12 — Evoluções (backlog)

| Item | Nota |
|------|------|
| Pagamento dividido (`venda_pagamento`) | SQL `02_*.sql` + Strategy em loop |
| Login simultâneo / sessões ativas | Após Security |
| Tentativas de login inválidas | Rate limiter |
| Multi-loja na UI | `idLoja` já no schema |
| Atalhos teclado PDV | UX |
| Export PDF, backups, NFC-e | Conforme prioridade |

---

## 6. Mapa requisito → fase (atualizado)

| # | Requisito (resumo) | Fase |
|---|-------------------|------|
| 1 | Autenticação e usuários | **10, 11** |
| 2 | Vendas PDV | 4, 5, 12 |
| 3 | Estoque | 2, 6 |
| 4 | Caixa | 3, 7 |
| 5 | Dashboards | 9 |
| 6 | Relatórios | 8 |
| 7 | Logs e auditoria | 5 |
| — | Autorização admin (senha) | 5 (verify manual); rotas na 10–11 |
| — | Motivo obrigatório | 5, 6, 7 |

---

## 7. Checklist de desenvolvimento

```text
[x] Fase 0  — Fundação + UsuarioContext mock
[ ] Fase 1  — Produtos e categorias
[ ] Fase 2  — Estoque básico
[ ] Fase 3  — Caixa essencial
[ ] Fase 4  — PDV venda feliz              ← operação básica
[ ] Fase 5  — Auditoria + senha admin      ← sem Symfony Security
[ ] Fase 6  — Estoque avançado
[ ] Fase 7  — Caixa avançado
[ ] Fase 8  — Relatórios
[ ] Fase 9  — Dashboards
[ ] Fase 10 — Login + Symfony Security     ← antes de produção
[ ] Fase 11 — CRUD usuários + permissões
[ ] Fase 12 — Backlog
```

| Marco | Fases |
|-------|--------|
| PDV funcionando (dev, sem login) | 0–4 |
| Auditoria completa (dev) | 0–5 |
| Gestão (relatórios + dashboard, dev) | 0–9 |
| **Produção / loja piloto** | 0–11 |

---

## 8. Riscos e cuidados

| Risco | Mitigação |
|-------|-----------|
| Esquecer e subir produção sem login | Checklist Fase 10 obrigatória antes de deploy |
| Mock `idUsuario` errado em testes | Centralizar só em `UsuarioContext` |
| Duplicar lógica de senha admin | Fase 5: um `AdminAutorizacaoService`; Fase 10 reutiliza o mesmo verify |
| Doctrine ainda no projeto | Remover na Fase 0 |

---

## 9. Próximo passo imediato

**Fase 0** → **Fase 1 (produtos)** — sem mexer em `security.yaml`.

Documento útil antes do PDV: [`fluxos-operacionais.md`](fluxos-operacionais.md) (criar na Fase 4).

---

*Atualizado: login/Symfony Security movidos para fases 10–11.*
