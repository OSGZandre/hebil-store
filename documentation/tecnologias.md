# Stack Tecnológica — Hebil Store

Documento de referência para o **Sistema de Gestão para Loja / PDV**. Complementa o levantamento de requisitos em [`requisitos-pt1.md`](requisitos-pt1.md).

**Status:** planejamento  
**Última atualização:** maio/2026  

**Documento relacionado:** estrutura de módulos e SQL nos repositories → [`arquitetura.md`](arquitetura.md)

---

## 1. Visão geral

O Hebil Store será um **monolito web** desenvolvido em **Symfony**, com renderização **server-side** via **Twig**. O banco de dados relacional será **MySQL**. A interface usará **Bootstrap 5**, **CSS** customizado e **JavaScript** (com **Stimulus** e **Turbo**, já presentes no projeto Symfony).

A arquitetura prioriza:

- **Auditoria** — toda ação relevante rastreável (diretriz principal do projeto)
- **Integridade** — transações de banco para venda, estoque e caixa
- **Simplicidade operacional** — PDV rápido, fluxo por teclado, pouca complexidade no front
- **Evolução** — preparação para multi-loja e novos módulos sem reescrever o núcleo

### 1.1 Escopo de implantação (MVP)

| Aspecto | Decisão |
|---------|---------|
| Tipo de aplicação | Web, acessada pelo navegador em cada terminal/caixa |
| Conectividade | **Online** — servidor Symfony + MySQL na rede local ou hospedagem |
| Modo offline | **Fora do escopo do MVP** (sem PWA/service worker no início) |
| Cliente mobile nativo | **Fora do escopo do MVP** |
| API pública / API Platform | **Fora do escopo do MVP** (endpoints internos AJAX quando necessário) |

---

## 2. Stack resumida

| Camada | Tecnologia | Versão (projeto) |
|--------|------------|------------------|
| Linguagem | PHP | ≥ 8.2 |
| Framework | Symfony | 7.4.x |
| Templates | Twig | 3.x |
| Persistência | **SQL direto** nos repositories (PDO) | — |
| ORM | **Não utilizado** (sem Doctrine ORM) | — |
| Migrações de schema | Arquivos `.sql` em `database/migrations/` | — |
| Banco de dados | MySQL | 8.x (utf8mb4, InnoDB) |
| CSS / UI | Bootstrap | 5.x |
| JavaScript | ES modules via Asset Mapper + Stimulus + Turbo | 3.x / 8.x |
| Testes | PHPUnit | 13.x |
| Logs técnicos | Monolog (Symfony Monolog Bundle) | — |

---

## 3. Arquitetura da aplicação

Detalhamento completo (módulos, exemplos de repository, comunicação entre módulos): **[`arquitetura.md`](arquitetura.md)**.

### 3.1 Padrão geral

```
Navegador (Bootstrap + JS/Stimulus)
        │
        ▼
Controller (por módulo: Venda, Caixa, …)
        │
        ▼
Service (regras de negócio, transações)
        │
        ├── Repository (SQL explícito + parâmetros)
        ├── Services de outros módulos (Estoque, Auditoria, …)
        └── Shared (TransactionManager, AbstractRepository)
        │
        ▼
Twig (HTML)  ou  JSON (AJAX do PDV)
        │
        ▼
MySQL (PDO)
```

**Princípios:**

- Controllers finos: recebem request, delegam ao service, retornam resposta.
- Regras de negócio nos **services**, não no Twig, controller nem repository.
- **SQL apenas nos repositories** — sempre com parâmetros nomeados (`:id`, `:codigo`).
- Operações que alteram venda, estoque e caixa rodam em **uma transação** (`TransactionManager`).
- **Auditoria de negócio** via módulo `Auditoria` + tabela `audit_log` (não só Monolog).

### 3.2 Organização por módulos (`src/`)

```
src/
├── Kernel.php
├── Shared/          # Database, transações, exceções, helpers técnicos
└── Module/
     ├── Auth/
     ├── Usuario/
     ├── Produto/
     ├── Estoque/
     ├── Venda/
     ├── Caixa/
     ├── Relatorio/
     ├── Dashboard/
     └── Auditoria/
```

Cada módulo contém, no mínimo: `Controller/`, `Service/`, `Repository/` (e `Dto/`, `Form/` quando fizer sentido).

| Módulo | Foco |
|--------|------|
| Auth | Login, logout, sessão |
| Usuario | CRUD e perfis (admin) |
| Produto | Catálogo, barcode, preços |
| Estoque | Movimentações e saldo |
| Venda | PDV e ciclo da venda |
| Caixa | Sessão, sangria, suprimento |
| Relatorio | Listagens e exportações |
| Dashboard | KPIs e gráficos (somente leitura) |
| Auditoria | Logs e autorização admin |

**Sugestões adotadas na doc de arquitetura:** manter Auth + Usuario separados; Relatorio concentra SQL pesado e Dashboard reutiliza; Venda orquestra Estoque/Caixa/Auditoria via services (não SQL cruzado entre repos).

### 3.3 Camadas de interface (Twig)

| Layout | Uso | Público |
|--------|-----|---------|
| `layouts/base.html.twig` | Estrutura comum, assets | Todos |
| `layouts/pdv.html.twig` | Tela de venda, foco em teclado e velocidade | Funcionário, Admin |
| `layouts/admin.html.twig` | Dashboards, relatórios, cadastros sensíveis | Admin |

Separação visual e de rotas entre **PDV** (`/pdv/*`) e **administração** (`/admin/*`) facilita `access_control` e UX.

---

## 4. Backend — Symfony e pacotes

### 4.1 Pacotes já instalados no projeto

| Pacote | Função no Hebil Store |
|--------|------------------------|
| `symfony/framework-bundle` | Kernel, configuração, HTTP |
| `symfony/twig-bundle` | Templates, layouts, partials |
| `symfony/security-bundle` | Login, roles, firewalls, hash de senha |
| `symfony/form` + `symfony/validator` | Cadastros, motivo obrigatório em operações sensíveis |
| `symfony/messenger` | Tarefas assíncronas (relatórios pesados, agregações futuras) |
| `symfony/monolog-bundle` | Logs técnicos (erros, debug) — **não substitui** auditoria de negócio |
| `symfony/asset-mapper` | CSS/JS sem Webpack no MVP |
| `symfony/stimulus-bundle` + `symfony/ux-turbo` | Comportamento JS e navegação parcial |
| `symfony/mailer` | Recuperação de senha, notificações (fase posterior) |
| `phpunit/phpunit` | Testes automatizados de regras críticas |

### 4.2 Persistência — sem ORM (decisão do projeto)

| Usar | Não usar |
|------|----------|
| SQL escrito nos `*Repository` | Doctrine ORM, entidades mapeadas, DQL |
| PDO (via wrapper em `Shared/Database`) | `EntityManager`, repositories gerados pelo ORM |
| DTOs / arrays como retorno | Lazy loading, cascades do ORM |
| `database/migrations/*.sql` | Doctrine Migrations (remover do projeto ao implementar) |

O scaffold Symfony atual ainda lista Doctrine no `composer.json` — será **removido** na implementação. Conexão MySQL via **PDO**; opcionalmente manter apenas `doctrine/dbal` como factory de conexão (sem ORM), ou PDO puro configurado em `services.yaml`.

### 4.3 Pacotes opcionais (documentar, adotar quando necessário)

| Pacote / recurso | Quando adotar |
|------------------|---------------|
| `symfony/rate-limiter` | Limitar tentativas de login inválidas |
| `symfony/scheduler` ou cron do SO | Backups agendados, resumos diários de dashboard |
| Dompdf / Snappy | Exportação PDF de relatórios |
| Redis (sessão/cache) | Múltiplos terminais, impedir login simultâneo, cache de dashboard |
| API Platform | Integração externa ou app mobile — não no MVP |

### 4.4 Convenções PHP

- **Atributos** para rotas (`#[Route]`) e, se útil, injeção em services.
- **Enums** PHP 8.1+ para status (`VendaStatus`, `SessaoCaixaStatus`, etc.).
- **Tipagem estrita** nos services e DTOs.
- **Injeção de dependência** via construtor (autowire Symfony).
- **Repositories finais** (`final class`) por agregado/tabela principal.

### 4.5 Acesso ao banco (sem ORM)

Wrapper sugerido em `Shared/Database/AbstractRepository`:

| Método | Uso |
|--------|-----|
| `fetchAll($sql, $params)` | Listagens |
| `fetchOne($sql, $params)` | Um registro ou `null` |
| `execute($sql, $params)` | INSERT/UPDATE/DELETE |
| `lastInsertId()` | Após insert |

Implementação interna: `PDO::prepare()` + `execute()` + `fetchAll(PDO::FETCH_ASSOC)`.

Exemplo de uso no módulo (ver código completo em [`arquitetura.md`](arquitetura.md#42-exemplo-de-repository)):

```php
$sql = 'SELECT id, nome, preco_venda FROM produto WHERE codigo_barras = :codigo LIMIT 1';
return $this->fetchOne($sql, ['codigo' => $codigo]);
```

---

## 5. Banco de dados — MySQL

### 5.1 Configuração

- **SGBD:** MySQL 8.x  
- **Engine:** InnoDB (transações ACID)  
- **Charset / collation:** `utf8mb4` / `utf8mb4_unicode_ci`  
- **Conexão:** variável de ambiente `DATABASE_URL` (ver `.env` / `.env.local`)

Exemplo (desenvolvimento):

```
DATABASE_URL="mysql://usuario:senha@127.0.0.1:3306/hebil_store?serverVersion=8.0.32&charset=utf8mb4"
```

Credenciais e segredos **nunca** são commitados — usar `.env.local` fora do controle de versão.

### 5.2 Convenções de modelagem

Alinhadas às [regras de negócio](requisitos-pt1.md#regras-de-negócio):

| Regra de negócio | Implementação no banco |
|------------------|------------------------|
| Venda nunca desaparece | `sale.status` (ex.: `open`, `completed`, `cancelled`); sem `DELETE` em vendas |
| Movimentação financeira não é apagada | Apenas estorno ou nova movimentação corretiva |
| Produto não é deletado | Campo `active` / `deleted_at` (soft inactivate) |
| Toda ação crítica rastreável | Tabela `audit_log` + `admin_authorization` quando aplicável |
| Multi-loja futura | Coluna `store_id` nas tabelas operacionais desde o MVP |

### 5.3 Entidades principais (modelo conceitual)

Diagrama lógico simplificado — detalhamento em documento de modelo de dados (futuro).

```
Store ──┬── User
        ├── Product ── StockMovement
        ├── CashRegister ── CashSession ── CashMovement
        └── Sale ── SaleItem ── Payment

AuditLog (polimórfico ou referência entity + entity_id)
AdminAuthorization (ação crítica autorizada por admin)
```

| Entidade | Descrição resumida |
|----------|-------------------|
| `User` | Login, perfil (funcionário/admin), ativo/inativo |
| `Store` | Loja (uma no MVP; várias no futuro) |
| `Product` | Cadastro, código de barras, preço, estoque mínimo, ativo |
| `StockMovement` | Entrada, saída, perda, ajuste — sempre com motivo quando exigido |
| `Sale` / `SaleItem` | PDV; itens, descontos, status |
| `Payment` | Forma de pagamento por venda |
| `CashRegister` | Caixa físico/lógico por terminal |
| `CashSession` | Abertura/fechamento, responsável, horários |
| `CashMovement` | Sangria, suprimento, entradas/saídas |
| `AuditLog` | Usuário, data/hora, ação, valores anterior/atual, motivo, terminal |
| `AdminAuthorization` | Registro de senha/admin em operação crítica |

### 5.4 Integridade e concorrência

- **Finalização de venda:** uma transação envolve baixa de estoque, registro de pagamento, movimento de caixa (se aplicável) e `audit_log`.
- **Estoque:** evitar venda sem saldo via checagem na transação (`UPDATE ... WHERE quantity >= :qty` ou lock pessimista na linha do produto).
- **Índices recomendados:** `product.barcode`, `sale.created_at`, `sale.status`, `audit_log.created_at`, `cash_session.status`.

### 5.5 Migrações

- Scripts SQL versionados em `database/migrations/` (ex.: `V001__criar_usuario.sql`, `V002__criar_produto.sql`).
- Controle de versão aplicada: tabela `schema_version` ou ferramenta/cli própria.
- Nunca alterar produção sem script SQL correspondente commitado no repositório.

---

## 6. Segurança e controle de acesso

### 6.1 Perfis (roles)

| Role Symfony | Perfil | Observação |
|--------------|--------|------------|
| `ROLE_USER` | Base autenticado | Mínimo para área logada |
| `ROLE_FUNCIONARIO` | Funcionário | PDV, caixa, estoque operacional |
| `ROLE_ADMIN` | Administrador | Inclui `ROLE_FUNCIONARIO` + dashboards, usuários, logs, lucro |

Hierarquia sugerida em `security.yaml`:

```yaml
role_hierarchy:
    ROLE_FUNCIONARIO: ROLE_USER
    ROLE_ADMIN: [ROLE_FUNCIONARIO, ROLE_ADMIN]
```

### 6.2 Controle de rotas

Exemplos de `access_control`:

| Caminho | Role mínima |
|---------|-------------|
| `/login` | Público |
| `/pdv/*` | `ROLE_FUNCIONARIO` |
| `/admin/*` | `ROLE_ADMIN` |
| `/relatorios/*` | `ROLE_ADMIN` |

### 6.3 Restrições de dados (não só de rota)

Funcionário **não** pode ver lucro nem relatórios gerenciais:

- **Voters** Symfony (`SaleVoter`, `ReportVoter`) para ações pontuais.
- **Queries** que omitem campos de margem/lucro em listagens do PDV.
- **Twig** não exibe o que a query não envia (defesa em profundidade).

### 6.4 Autorização administrativa (operações críticas)

Fluxo padrão para: cancelamento de venda, remoção de item, desconto elevado, alteração de preço, venda sem estoque (se permitida).

1. Funcionário dispara a ação.
2. Modal solicita **credencial de administrador** (senha validada no servidor).
3. Backend grava `AdminAuthorization` + `AuditLog` e só então executa a ação.
4. A autorização fica vinculada à venda/movimento afetado.

### 6.5 Outras medidas

| Medida | Implementação |
|--------|---------------|
| Senhas | `password_hashers: auto` (bcrypt/argon) |
| CSRF | Forms Symfony + tokens em POST/AJAX críticos |
| Sessão | Cookie seguro em produção (`secure`, `httponly`, `samesite`) |
| Tentativas de login | Rate limiter ou contador em `User` / tabela auxiliar (fase 2) |
| Login simultâneo | Sessão em DB/Redis + invalidação (fase 2) |

---

## 7. Frontend — Twig, Bootstrap, JavaScript

### 7.1 Twig

- **Layouts** por contexto (PDV vs admin).
- **Partials** reutilizáveis: tabela de itens da venda, modal de autorização admin, alertas.
- **Macros** para formatação de moeda, data e badges de status.
- Internacionalização: `symfony/translation` disponível; idioma padrão **pt_BR** (configurar quando houver telas).

### 7.2 Bootstrap 5

**Decisão (MVP):** incluir Bootstrap via **Asset Mapper** (`importmap`) ou **arquivos estáticos em `assets/`**, preferindo assets locais para ambiente de loja sem depender de CDN externo.

Uso previsto:

- Grid e utilitários de layout
- Formulários, tabelas, modais (autorização admin, confirmações)
- Componentes de feedback (`alert`, `toast`)

### 7.3 JavaScript e interatividade

| Ferramenta | Uso no Hebil Store |
|------------|-------------------|
| **Asset Mapper** + `importmap.php` | Entrada `assets/app.js`, sem Webpack no MVP |
| **Stimulus** | Controllers: busca de produto, código de barras, atalhos de teclado no PDV, modal admin |
| **Turbo** | Navegação mais rápida em telas administrativas; no PDV avaliar página completa vs frames para previsibilidade |
| **Fetch / AJAX** | Adicionar/remover item, buscar produto, validar autorização admin sem reload |

### 7.4 PDV — requisitos de usabilidade

Conforme requisitos não funcionais:

- Campo de busca/código de barras com **foco automático**
- **Atalhos de teclado** documentados na tela (F2 pagamento, Esc cancelar fluxo, etc. — definir na UX)
- Feedback imediato (erro de estoque, necessidade de admin)
- Layout enxuto: poucos cliques até finalizar venda

### 7.5 Dashboards e gráficos

- Biblioteca sugerida: **Chart.js** (via importmap ou asset local).
- Dados carregados pelo controller via repositories (agregações SQL); JSON opcional para gráficos dinâmicos.
- Cache de consultas pesadas em produção: Symfony Cache ou materialized summaries (fase 2).

---

## 8. Módulos × tecnologia

Mapeamento dos requisitos para módulos em `src/Module/` (detalhes em [`arquitetura.md`](arquitetura.md)).

| Requisito | Módulo Symfony | Repository / tabelas principais |
|-----------|----------------|----------------------------------|
| Login / sessão | `Auth` | `usuario` (leitura para autenticação) |
| Cadastro de usuários | `Usuario` | `usuario` |
| Produtos / barcode | `Produto` | `produto` |
| Estoque / ajustes | `Estoque` | `estoque_movimento`, saldo em `produto` |
| PDV / vendas | `Venda` | `venda`, `venda_item`, `pagamento` |
| Caixa | `Caixa` | `caixa`, `sessao_caixa`, `movimento_caixa` |
| Dashboards | `Dashboard` | SQL de leitura (via `Relatorio` ou repos próprios) |
| Relatórios | `Relatorio` | Consultas filtradas, export CSV |
| Auditoria / admin auth | `Auditoria` | `audit_log`, `admin_authorization` |

| Camada transversal | Onde |
|--------------------|------|
| Transações | `Shared/Database/TransactionManager` |
| SQL base | `Shared/Database/AbstractRepository` |
| Templates | `templates/module/<nome>/` |
| Front PDV | Bootstrap + Stimulus em `assets/` |

---

## 9. Mensageria e tarefas em background

**Symfony Messenger** pode usar transporte em tabela MySQL (`doctrine://` no scaffold) ou `sync://` no MVP — revisar ao remover Doctrine ORM.

| Uso | Prioridade |
|-----|------------|
| Geração de relatório grande / exportação | Pós-MVP ou quando relatórios pesarem |
| Agregação noturna para dashboards | Fase 2 |
| Envio de e-mail (reset senha) | Quando houver `MAILER_DSN` real |

No MVP, fluxo síncrono é aceitável para PDV e operações de caixa; mensageria evita travar a UI em relatórios futuros.

---

## 10. Testes

| Tipo | Ferramenta | Foco |
|------|------------|------|
| Unitário | PHPUnit | Services: cálculo de totais, regras de desconto, estoque |
| Funcional | Symfony BrowserKit | Login, rotas protegidas, fluxo de venda feliz |
| Integração | PHPUnit + MySQL de teste (ou SQLite em memória) | Transação venda + estoque + audit_log |

Banco de testes: base separada (`hebil_store_test`), migrations SQL aplicadas no setup do CI.

Cenários **obrigatórios** antes de produção (amostra):

- Não finalizar venda sem estoque (sem autorização)
- Cancelamento registra venda como cancelada + log
- Funcionário não acessa `/admin`
- Autorização admin inválida bloqueia remoção de item

---

## 11. Ambientes e configuração

| Ambiente | `APP_ENV` | Uso |
|----------|-----------|-----|
| Desenvolvimento | `dev` | Máquina local, Web Profiler, logs verbosos |
| Testes | `test` | CI e PHPUnit |
| Produção | `prod` | Loja — cache, logs, `APP_DEBUG=0` |

Arquivos de ambiente (precedência Symfony):

1. `.env`
2. `.env.local` (não commitado)
3. `.env.$APP_ENV` / `.env.$APP_ENV.local`

Variáveis críticas: `APP_SECRET`, `DATABASE_URL`, `MAILER_DSN` (quando usado).

---

## 12. Operação, deploy e disponibilidade

Requisitos não funcionais incluem backups e recuperação. Responsabilidades divididas entre **código** e **infraestrutura**.

### 12.1 Servidor de aplicação (sugestão)

| Componente | Opção |
|------------|--------|
| PHP | 8.2+ com extensões: `pdo_mysql`, `intl`, `mbstring`, `xml` |
| Servidor web | Nginx ou Apache + **PHP-FPM**, ou **FrankenPHP** |
| Processo | `symfony serve` apenas em dev |

### 12.2 MySQL em produção

- Usuário de aplicação com permissões mínimas (sem `DROP DATABASE`).
- Backup automático: `mysqldump` agendado (cron) ou backup gerenciado do provedor.
- Teste periódico de **restore**.

### 12.3 Logs

| Tipo | Onde |
|------|------|
| Técnico (erros PHP, exceções) | `var/log/`, Monolog |
| Negócio (auditoria) | Tabela `audit_log` — retenção conforme política da loja |

### 12.4 Performance (PDV)

- Índices em colunas de busca e filtro por data.
- Evitar N+1: preferir `JOIN` na query em vez de loop com várias queries no PHP.
- OPcache habilitado em PHP produção.

---

## 13. Fora de escopo do MVP (roadmap técnico)

| Item | Preparação no MVP |
|------|-------------------|
| Multi-loja | `loja_id` nas tabelas operacionais |
| Offline / PWA | — |
| App mobile | — |
| API REST pública | — |
| Impressão fiscal / SAT / NFC-e | Integração futura via módulo ou serviço externo |
| PDF de relatórios | Export CSV primeiro |
| Login simultâneo bloqueado | Schema de sessão compatível |

---

## 14. Referências

- [Documentação Symfony 7.4](https://symfony.com/doc/7.4/index.html)
- [PDO PHP](https://www.php.net/manual/en/book.pdo.php)
- [Bootstrap 5](https://getbootstrap.com/docs/5.3/getting-started/introduction/)
- Requisitos: [`requisitos-pt1.md`](requisitos-pt1.md)
- Arquitetura modular e SQL: [`arquitetura.md`](arquitetura.md)
- Dependências atuais: [`composer.json`](../composer.json) *(Doctrine ORM será removido na implementação)*

---

## 15. Próximos documentos de planejamento

| Documento | Conteúdo |
|-----------|----------|
| [`arquitetura.md`](arquitetura.md) | Módulos, camadas, SQL nos repos, comunicação entre módulos |
| [`modelo-dados.md`](modelo-dados.md) | Tabelas, enums, FKs, DDL MVP (`V001`) e fase 2 (`V002`) |
| [`plano-implementacao.md`](plano-implementacao.md) | Fases 0–12, ordem de entrega, critérios de pronto |
| `matriz-permissoes.md` | Ação × perfil × exige autorização admin |
| `fluxos-operacionais.md` | Abertura de caixa → venda → fechamento; cancelamento |
| `ux-pdv.md` | Atalhos de teclado, wireframes, estados da tela |

---

*Este documento deve ser revisado quando houver mudança de stack, decisão de offline, ou inclusão de integrações fiscais/externas.*
