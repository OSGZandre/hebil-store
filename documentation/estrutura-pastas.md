# Estrutura de pastas — Hebil Store

Referência rápida. Convenção de **nomes de arquivos** (sem `_` no início).

---

## Convenção de nomes

### Regra geral

- **Nunca** usar `_` no **início** do nome do arquivo (ex.: ~~`_navbar.html.twig`~~).
- Nomes **descritivos**, em **português** ou termos do domínio, fáceis de achar no explorador.

### Backend (`src/`)

| Tipo | Padrão | Exemplo |
|------|--------|---------|
| Controller | `{Contexto}Controller` | `ProdutoController`, `PdvController` |
| Service | `{Contexto}Service` | `ProdutoService`, `VendaService` |
| Repository | `{Contexto}Repository` | `ProdutoRepository` |
| DTO | `{Nome}Dto` | `ProdutoResumoDto`, `AdicionarItemDto` |

Namespace: `App\Module\Produto\Controller\ProdutoController`

### Frontend — Twig (`templates/`)

| Tipo | Padrão | Exemplo |
|------|--------|---------|
| Página | `{pasta}/{pagina}.html.twig` | `home/home.html.twig` |
| Módulo | `module/{modulo}/{pagina}.html.twig` | `module/produto/produto-listar.html.twig` |
| Layout | `layouts/{nome}.html.twig` | `layouts/admin.html.twig` |
| Partial reutilizável | `partials/{nome}.html.twig` | `partials/navbar.html.twig` |

Renderizar: `$this->render('module/produto/produto-form.html.twig')`

### Frontend — CSS (`assets/styles/`)

| Tipo | Padrão | Exemplo |
|------|--------|---------|
| Página | `pages/{pagina}.css` | `pages/home.css`, `pages/produto-listar.css` |
| Layout | `layouts/{nome}.css` | `layouts/pdv.css` |
| Componente | `components/{nome}.css` | `components/alerts.css` |
| Tokens | `variables/tokens.css` | — |

Entrada única: `assets/styles/app.css` (imports).

---

## `src/`

```text
src/
├── Kernel.php
├── Shared/
│   ├── Context/
│   ├── Controller/       # HomeController
│   ├── Database/
│   ├── Exception/
│   ├── Security/
│   └── Util/
└── Module/
    ├── Auth/
    ├── Usuario/
    ├── Produto/          # ProdutoController, ProdutoService, ...
    ├── Estoque/
    ├── Venda/
    ├── Caixa/
    ├── Relatorio/
    ├── Dashboard/
    └── Auditoria/
```

Cada módulo:

```text
Module/{Nome}/
├── Controller/
├── Service/
├── Repository/
├── Dto/
└── Form/
```

---

## `templates/`

```text
templates/
├── base.html.twig
├── layouts/
│   ├── base.html.twig
│   ├── admin.html.twig
│   └── pdv.html.twig
├── partials/
│   ├── navbar.html.twig
│   └── flash-messages.html.twig
├── home/
│   └── home.html.twig
└── module/
    ├── produto/
    ├── venda/
    └── ...
```

---

## `assets/styles/`

```text
assets/styles/
├── app.css
├── variables/tokens.css
├── base/reset.css
├── layouts/app-shell.css, admin.css, pdv.css
├── components/alerts.css
├── pages/home.css
└── vendor/               # Bootstrap (futuro)
```

---

## `database/scripts/`

- `01_schema_completo_mvp.sql`
- `02_venda_pagamento_fase2.sql`

---

Ver também: [`arquitetura.md`](arquitetura.md) · [`plano-implementacao.md`](plano-implementacao.md)
