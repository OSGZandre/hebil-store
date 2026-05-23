# Arquitetura — Hebil Store

Complementa [`tecnologias.md`](tecnologias.md) e [`requisitos-pt1.md`](requisitos-pt1.md).

**Decisões principais:**

- **Sem Doctrine ORM** — persistência via **SQL explícito** nos repositories.
- **Organização por módulos de negócio** — cada domínio (Venda, Caixa, etc.) concentra seu código.
- **`Shared`** — infraestrutura e código transversal reutilizado por todos os módulos.

---

## 1. Estrutura de pastas (`src/`)

```
src/
├── Kernel.php
│
├── Shared/
│   ├── Database/
│   │   ├── ConnectionFactory.php      # obtém PDO / conexão
│   │   ├── TransactionManager.php     # begin / commit / rollback
│   │   └── AbstractRepository.php     # fetchAll, fetchOne, execute (opcional)
│   ├── Exception/
│   ├── Security/                      # voters genéricos, helpers
│   └── Util/                          # formatadores, helpers puros
│
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

Cada módulo segue o **mesmo padrão interno** (ver seção 3).

Templates Twig ficam em `templates/module/<nome>/` (convenção Symfony), espelhando o módulo.

Migrations SQL em `database/migrations/` (arquivos `.sql` versionados, sem Doctrine ORM).

---

## 2. Módulos — responsabilidade e sugestões

### 2.1 Estrutura adotada (sua proposta + ajustes)

| Módulo | Responsabilidade | Observação |
|--------|------------------|------------|
| **Auth** | Login, logout, sessão, integração com Security Symfony | Não cadastra usuário — só autentica |
| **Usuario** | CRUD de usuários, ativar/desativar, redefinir senha, perfis | Admin; Auth consome `UsuarioRepository` para login |
| **Produto** | Cadastro, edição, inativação, busca, código de barras | Catálogo e preço de venda |
| **Estoque** | Saldo, entradas, perdas, ajustes, alerta mínimo | Movimentações; baixa automática na venda (chamada por Venda) |
| **Venda** | PDV: abrir venda, itens, desconto, pagamento, cancelar | Orquestra estoque + caixa + auditoria em transação |
| **Caixa** | Abertura/fechamento, sangria, suprimento, saldo | Sessão de caixa por operador/terminal |
| **Relatorio** | Consultas filtradas, export CSV, listagens administrativas | Sem “telas bonitas” — foco em dados |
| **Dashboard** | KPIs e gráficos (financeiro, produtos) | **Somente leitura**; reutiliza queries do Relatorio quando fizer sentido |
| **Auditoria** | Gravar e consultar `audit_log` e `admin_authorization` | Chamado por outros módulos via service |

### 2.2 Por que manter Auth e Usuario separados?

- **Auth** muda pouco (firewall, login form, session).
- **Usuario** muda com regras de negócio (perfis, desativação, reset senha).
- Evita módulo “Usuário” gigante misturando sessão com CRUD admin.

**Alternativa válida:** unificar em um único módulo `Usuario` com subpastas `Auth/` e `Admin/` — use se a equipe for pequena e quiser menos pastas.

### 2.3 Produto vs Estoque

| | Produto | Estoque |
|---|---------|---------|
| Foco | Dados do item (nome, barcode, preço, ativo) | Quantidade e movimentações |
| Tabelas típicas | `produto` | `estoque_movimento`, saldo em `produto.quantidade` ou tabela `estoque_saldo` |

**Sugestão:** saldo atual pode ficar em coluna `produto.estoque_atual` atualizada por triggers ou sempre via soma de movimentos — documentar no `modelo-dados.md`. O módulo **Venda** não escreve SQL de estoque direto; chama `EstoqueService::baixar()`.

### 2.4 Relatorio vs Dashboard

| | Relatorio | Dashboard |
|---|-----------|-----------|
| Saída | Tabela, CSV, impressão | Cards, gráficos Chart.js |
| Usuário | Admin exportando dados | Admin visão rápida |

**Sugestão:** queries pesadas ficam em `Relatorio/Repository/`; Dashboard chama os mesmos repositories ou um `RelatorioQuery` compartilhado para não duplicar SQL.

### 2.5 Auditoria transversal

Não duplicar `INSERT INTO audit_log` em cada repository.

```
VendaService → AuditoriaService::registrar(...)
```

O módulo **Auditoria** expõe API estável; outros módulos não montam SQL de log (exceto o próprio `AuditoriaRepository`).

---

## 3. Anatomia de um módulo

Exemplo: `Module/Venda/`

```
Module/Venda/
├── Controller/
│   └── PdvController.php
├── Service/
│   ├── VendaService.php           # casos de uso
│   └── FinalizarVendaService.php  # opcional: classes menores
├── Repository/
│   ├── VendaRepository.php
│   └── VendaItemRepository.php
├── Dto/
│   ├── VendaResumoDto.php
│   └── AdicionarItemInput.php
└── Form/                          # opcional
    └── VendaFiltroType.php
```

### Fluxo de uma requisição

```
HTTP Request
    → Controller (valida request, chama service)
        → Service (regras de negócio, transação)
            → Repository (SQL + parâmetros)
            → Outros modules' Services (Estoque, Caixa, Auditoria)
    → Twig ou JsonResponse
```

### Regras

| Camada | Pode | Não pode |
|--------|------|----------|
| **Controller** | Request/response, flash messages, HTTP codes | SQL, regra de negócio pesada |
| **Service** | Orquestrar repos, transações, chamar outros services | SQL direto (preferir repo) |
| **Repository** | SQL, bind de parâmetros, mapear array → DTO | Regra de negócio (ex.: “pode cancelar?”) |

---

## 4. Persistência — SQL nos repositories

### 4.1 Sem ORM

- **Não usar:** entidades Doctrine, `EntityManager`, annotations de mapeamento, DQL.
- **Usar:** SQL escrito à mão (ou views SQL) dentro de classes `*Repository`.
- **Conexão:** PDO via wrapper em `Shared/Database` (Symfony pode expor `Doctrine\DBAL\Connection` **apenas como cliente PDO** — ver [`tecnologias.md`](tecnologias.md#52-acesso-ao-banco-sem-orm)).

### 4.2 Exemplo de repository

```php
namespace App\Module\Produto\Repository;

use App\Shared\Database\AbstractRepository;

final class ProdutoRepository extends AbstractRepository
{
  public function buscarPorCodigoBarras(string $codigo): ?array
  {
    $sql = '
      SELECT id, nome, codigo_barras, preco_venda, estoque_atual, ativo
      FROM produto
      WHERE codigo_barras = :codigo AND ativo = 1
      LIMIT 1
    ';

    return $this->fetchOne($sql, ['codigo' => $codigo]);
  }

  public function listarAtivos(int $limite = 50): array
  {
    $sql = '
      SELECT id, nome, codigo_barras, preco_venda, estoque_atual
      FROM produto
      WHERE ativo = 1
      ORDER BY nome
      LIMIT :limite
    ';

    return $this->fetchAll($sql, ['limite' => $limite]);
  }
}
```

### 4.3 Retorno dos repositories

| Opção | Quando usar |
|-------|-------------|
| `array` associativo | Consultas simples, telas Twig |
| **DTO** readonly (`ProdutoDto`) | Contrato claro entre camadas, PDV, APIs internas |
| `int` / `bool` / `?string` | `execute`, `insert` retornando id |

Services convertem array → DTO quando necessário.

### 4.4 Transações

Operações compostas (finalizar venda) usam `TransactionManager`:

```php
$this->transactionManager->transactional(function () use ($vendaId) {
  $this->vendaRepository->marcarComoFinalizada($vendaId);
  $this->estoqueService->baixarPorVenda($vendaId);
  $this->caixaService->registrarEntradaVenda($vendaId);
  $this->auditoriaService->registrar('venda.finalizada', $vendaId);
});
```

Um único ponto de commit/rollback evita inconsistência entre estoque e caixa.

### 4.5 Segurança SQL

- Sempre **parâmetros nomeados** (`:id`, `:codigo`) — nunca concatenar input do usuário.
- Repositories **não** retornam colunas sensíveis para funcionário (ex.: `custo`, `margem`) — queries diferentes ou views.

---

## 5. Shared — o que colocar

| Item | Motivo |
|------|--------|
| `AbstractRepository` | `fetchAll`, `fetchOne`, `execute`, `lastInsertId` |
| `TransactionManager` | Transações compartilhadas entre módulos |
| Exceções base | `DomainException`, `NotFoundException` |
| Interfaces | `ClockInterface` para testes |
| **Não** colocar regra de negócio de Venda/Caixa em Shared | Shared é técnico, não domínio |

---

## 6. Symfony — integração com módulos

### 6.1 Autoload e namespaces

```json
"autoload": {
  "psr-4": {
    "App\\": "src/"
  }
}
```

Exemplos:

- `App\Module\Venda\Controller\PdvController`
- `App\Shared\Database\AbstractRepository`

### 6.2 Rotas

Opção A — prefixo por módulo em cada controller:

```php
#[Route('/pdv', name: 'pdv_')]
class PdvController { ... }
```

Opção B — arquivo `config/routes/venda.yaml` importando o módulo.

### 6.3 Services (`config/services.yaml`)

```yaml
services:
  _defaults:
    autowire: true
    autoconfigure: true

  App\:
    resource: '../src/'
    exclude:
      - '../src/Kernel.php'
```

Controllers e services em `Module/*` são registrados automaticamente.

### 6.4 Security

- **UserProvider** custom em `Module/Auth` ou `Module/Usuario`, lendo usuário via `UsuarioRepository`.
- **Voters** podem ficar no módulo dono da regra (`Venda/Voter/`) ou em `Shared/Security` se forem genéricos.

---

## 7. Comunicação entre módulos

| Permitido | Evitar |
|-----------|--------|
| `VendaService` injeta `EstoqueService`, `AuditoriaService` | `VendaRepository` chamando `CaixaRepository` direto sem service |
| Services de outros módulos | Import circular (Venda ↔ Caixa): extrair orquestração ou evento interno |
| DTOs simples entre módulos | Expor repositories de outro módulo publicamente |

Para o tamanho do Hebil Store, **injeção de services** entre módulos é suficiente; não é necessário Event Bus no MVP.

---

## 8. Pagamentos — Strategy + Factory (código, não substitui o banco)

O processamento de pagamento usa **design patterns na camada de aplicação** (`Module/Venda/`). Isso é independente de quantas tabelas existem: o pattern organiza **comportamento**; o MySQL guarda **fato** para relatório e auditoria.

### 8.1 Papéis

| Peça | Pattern | Responsabilidade |
|------|---------|------------------|
| `FormaPagamentoHandlerInterface` | Strategy | Contrato: validar, aplicar efeitos (caixa, etc.) |
| `DinheiroHandler`, `PixHandler`, … | Strategy concreta | Regra por forma de pagamento |
| `FormaPagamentoHandlerFactory` | Factory | Dado `codigo` (`dinheiro`, `pix`), devolve o handler certo |
| `FinalizarVendaService` | Orquestrador | Chama factory + persiste via repository |
| `VendaRepository` / `VendaPagamentoRepository` | Persistência | SQL (`INSERT`/`UPDATE`) — sem regra de negócio |

### 8.2 Estrutura de pastas sugerida

```
Module/Venda/
├── Service/
│   └── FinalizarVendaService.php
└── Pagamento/
    ├── FormaPagamentoHandlerInterface.php
    ├── FormaPagamentoHandlerFactory.php
    ├── PagamentoContext.php              # DTO: idVenda, valor, idFormaPagamento, ...
    └── Handler/
        ├── DinheiroHandler.php
        ├── PixHandler.php
        └── CartaoHandler.php
```

Handlers são registrados no Symfony com tag ou lista injetada na Factory (`config/services.yaml`).

### 8.3 Contrato do handler (exemplo)

```php
interface FormaPagamentoHandlerInterface
{
    public function suporta(string $codigoFormaPagamento): bool;

    /** Validações antes de gravar (valor mínimo, sessão de caixa aberta, etc.) */
    public function validar(PagamentoContext $context): void;

    /**
     * Efeitos colaterais: movimento de caixa, campos extras, etc.
     * Persistência da venda fica no service/repository — handler não faz SQL de venda.
     */
    public function aplicar(PagamentoContext $context): void;
}
```

### 8.4 Fluxo na finalização da venda

```
FinalizarVendaService
  1. Valida venda aberta, itens ativos, estoque (EstoqueService)
  2. Para cada pagamento (MVP: 1 linha; fase 2: N linhas)
       → $handler = $factory->para($codigoForma)
       → $handler->validar($context)
       → grava pagamento (repository)
       → $handler->aplicar($context)   // ex.: DinheiroHandler → CaixaService
  3. Atualiza venda (situacao = Finalizada)
  4. AuditoriaService::registrar(...)
  (tudo dentro de TransactionManager)
```

### 8.5 MVP vs fase 2 (banco)

| Fase | Banco | Strategy |
|------|-------|----------|
| **MVP** | `venda.idFormaPagamento` + `venda.valor` (pagamento único) | Um handler por finalização |
| **Fase 2** | Tabela `venda_pagamento` (split: dinheiro + PIX) | Loop: um handler **por linha** de pagamento |

A Factory e os handlers **não mudam de ideia** — só o orquestrador passa de 1 para N pagamentos.

### 8.6 O que fica em cada handler (exemplos)

| Handler | `aplicar()` típico |
|---------|-------------------|
| `DinheiroHandler` | `CaixaService::registrarEntradaVenda()` se `forma_pagamento.afeta_caixa_fisico` |
| `PixHandler` | Sem movimento de gaveta; opcional: `referencia_externa` |
| `CartaoHandler` | Idem PIX; preparado para integração TEF futura |

Cadastro de formas continua em `forma_pagamento` (tabela). O `codigo` da tabela é a chave da Factory.

### 8.7 O que não colocar no handler

- SQL de `venda` / `venda_pagamento` (fica no repository).
- Transação global (fica em `FinalizarVendaService` + `TransactionManager`).
- Autorização admin de desconto (fica antes, no fluxo da venda).

Assim os handlers permanecem pequenos e testáveis com PHPUnit (mock de `CaixaService`).

---

## 9. O que NÃO fazer (lições para este projeto)

1. **God Repository** — um `AppRepository` com 2000 linhas SQL.
2. **SQL no Controller** — dificulta teste e reuso.
3. **Duplicar query de lucro** no PDV — um método `listarParaPdv()` sem colunas de margem.
4. **Módulo Dashboard com regra de escrita** — dashboard só lê.
5. **Deletar registro de venda/movimento** — updates de status + auditoria (requisitos).

---

## 10. Roadmap de refatoração do projeto atual

O repositório hoje ainda traz **Doctrine ORM** no `composer.json` (scaffold Symfony). Passos planejados:

1. Remover `doctrine/orm`, mappings em `config/packages/doctrine.yaml` (manter só DBAL/PDO se desejado).
2. Criar `src/Shared/Database/` e `src/Module/`.
3. Adicionar pasta `database/migrations/` com SQL versionado.
4. Mover primeiro módulo piloto: **Auth** + **Usuario**.

---

## 11. Resumo visual

```
┌─────────────────────────────────────────────────────────┐
│                     Controllers                          │
│  Auth   Usuario   Produto   Venda   Caixa   Dashboard   │
└──────────────────────────┬──────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────┐
│                      Services                            │
│         (regras de negócio + transações)                 │
└──────────────────────────┬──────────────────────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        ▼                  ▼                  ▼
┌───────────────┐  ┌───────────────┐  ┌───────────────┐
│ Repositories  │  │ Repositories  │  │  Auditoria    │
│  (SQL puro)   │  │  outros mods  │  │  Service      │
└───────┬───────┘  └───────┬───────┘  └───────────────┘
        │                  │
        └────────┬─────────┘
                 ▼
         ┌───────────────┐
         │  MySQL (PDO)  │
         └───────────────┘
```

---

*Revisar este documento ao adicionar novo módulo (ex.: Fiscal, MultiLoja). Schema: [`modelo-dados.md`](modelo-dados.md).*
