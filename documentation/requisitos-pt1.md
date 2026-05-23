# Sistema de Gestão para Loja / PDV

## Visão Geral

O sistema será uma plataforma completa de gerenciamento para loja, focada em:

- Controle de vendas
- Controle de estoque
- Controle de caixa
- Relatórios gerenciais
- Dashboards administrativos
- Auditoria completa das operações

O principal objetivo do sistema é garantir:

- rastreabilidade
- segurança operacional
- controle financeiro
- controle de estoque
- prevenção de fraudes e erros operacionais

---

# Objetivos do Sistema

O sistema deverá permitir:

- registrar vendas
- controlar movimentações de caixa
- controlar entradas e saídas de estoque
- emitir relatórios detalhados
- gerar dashboards administrativos
- manter logs completos de todas as ações importantes

---

# Perfis de Usuário

## Funcionário

Usuário operacional responsável pelas vendas e operações do dia a dia.

### Permissões

- realizar login/logout
- abrir e fechar caixa
- realizar vendas
- adicionar produtos na venda
- remover produtos da venda
- pesquisar produtos
- cadastrar produtos
- consultar estoque
- movimentar estoque
- registrar entradas e saídas de caixa

### Restrições

- não pode acessar dashboards administrativos
- não pode visualizar lucro
- não pode emitir relatórios gerenciais
- não pode gerenciar usuários
- não pode realizar ações críticas sem autorização administrativa

---

## Administrador

Usuário com acesso total ao sistema.

### Permissões

- todas as permissões do funcionário
- acessar dashboards
- visualizar lucro
- emitir relatórios detalhados
- criar usuários
- editar usuários
- desativar usuários
- visualizar logs do sistema
- autorizar operações restritas
- editar configurações críticas

---

# Requisitos Funcionais

# 1. Autenticação e Controle de Usuários

O sistema deve permitir:

- login/logout
- controle de sessão
- diferentes níveis de acesso
- cadastro de usuários
- edição de usuários
- ativação/desativação de contas
- redefinição de senha
- controle de permissões

---

# 2. Controle de Vendas (PDV)

O sistema deve permitir:

- iniciar venda
- adicionar produtos na venda
- remover produtos da venda
- pesquisar produtos
- leitura por código de barras
- alterar quantidade
- aplicar desconto
- selecionar forma de pagamento
- finalizar venda
- cancelar venda

---

## Regras de Venda

### Remoção e cancelamento restritos

Quando um funcionário tentar:

- remover item
- cancelar venda
- alterar preço
- aplicar descontos críticos

o sistema deverá:

- solicitar autorização administrativa
- solicitar senha/admin
- registrar log completo da ação

---

# 3. Controle de Estoque

O sistema deve permitir:

- cadastrar produtos
- editar produtos
- inativar produtos
- consultar estoque
- registrar entradas
- registrar perdas
- registrar ajustes de estoque

---

## Regras de Estoque

O sistema deverá:

- atualizar estoque automaticamente após vendas
- impedir vendas sem estoque disponível (ou exigir autorização)
- alertar estoque mínimo
- registrar motivo de ajustes e perdas

---

# 4. Controle de Caixa

O sistema deve permitir:

- abertura de caixa
- fechamento de caixa
- sangria
- suprimento
- registrar entradas
- registrar saídas
- visualizar saldo atual

---

## Regras de Caixa

O sistema deverá:

- registrar responsável por cada movimentação
- controlar horários de abertura e fechamento
- impedir inconsistências financeiras
- registrar divergências de caixa

---

# 5. Dashboards Administrativos

Apenas administradores poderão acessar.

---

## Dashboard Financeiro

Deve exibir:

- faturamento diário
- faturamento mensal
- lucro bruto
- lucro líquido
- despesas
- ticket médio
- vendas por forma de pagamento
- vendas por operador

---

## Dashboard de Produtos

Deve exibir:

- produtos mais vendidos
- produtos mais lucrativos
- produtos menos vendidos
- produtos sem movimentação
- estoque baixo
- giro de estoque

---

# 6. Relatórios

O sistema deverá gerar:

- relatório de vendas
- relatório de caixa
- relatório de estoque
- relatório de movimentações
- relatório de produtos
- relatório por funcionário

---

## Filtros dos Relatórios

- período
- operador
- forma de pagamento
- produto
- categoria
- status

---

# 7. Logs e Auditoria

## Objetivo

Garantir rastreabilidade total das operações do sistema.

---

## O sistema deverá registrar:

- login/logout
- vendas realizadas
- cancelamentos
- remoções de itens
- alterações de estoque
- alterações financeiras
- alterações de usuários
- ações administrativas
- alterações de preços
- descontos aplicados
- autorizações administrativas

---

## Cada log deverá conter:

- usuário responsável
- data/hora
- ação executada
- valor anterior
- valor atualizado
- terminal/dispositivo (opcional)
- motivo da ação (quando necessário)

---

# Regras de Negócio

## 1. Nenhuma venda poderá desaparecer

Mesmo cancelada:

- deverá permanecer registrada no sistema

---

## 2. Nenhuma movimentação financeira poderá ser apagada

Movimentações financeiras apenas poderão:

- ser estornadas
- ser canceladas
- receber correções através de novas movimentações

---

## 3. Produtos não deverão ser deletados

Produtos apenas poderão:

- ser inativados

---

## 4. Toda ação crítica deverá possuir rastreabilidade

Principalmente:

- cancelamentos
- descontos
- ajustes de estoque
- remoções de itens
- alterações financeiras

---

## 5. Funcionários possuirão permissões limitadas

Funcionários não poderão:

- visualizar lucro
- acessar dashboards financeiros
- gerenciar usuários
- emitir relatórios administrativos

---

# Requisitos Não Funcionais

# Segurança

O sistema deverá:

- proteger senhas criptografadas
- controlar sessões ativas
- impedir acessos não autorizados
- registrar tentativas inválidas
- exigir autorização administrativa em operações críticas

---

# Performance

O sistema deverá:

- responder rapidamente no PDV
- suportar múltiplas vendas simultâneas
- manter dashboards performáticos

---

# Confiabilidade

O sistema deverá:

- evitar perda de dados
- garantir integridade financeira
- manter consistência do estoque

---

# Escalabilidade

O sistema deverá permitir:

- múltiplas lojas futuramente
- crescimento do volume de vendas
- adição de novos módulos

---

# Usabilidade

O sistema deverá possuir:

- interface rápida
- fluxo simples para operadores
- operação otimizada para teclado
- facilidade de uso no PDV

---

# Disponibilidade

O sistema deverá possuir:

- backups automáticos
- persistência de logs
- recuperação de falhas

---

# Funcionalidades Estratégicas

# 1. Sistema de Autorização Administrativa

Operações críticas deverão exigir:

- senha de administrador
- autorização explícita
- registro da autorização em log

Exemplos:

- cancelamento de venda
- remoção de item
- alteração de preço
- desconto elevado

---

# 2. Controle de Sessões

O sistema deverá permitir:

- controle de sessões ativas
- identificação de terminal utilizado
- possibilidade de impedir login simultâneo

---

# 3. Motivo Obrigatório em Operações Sensíveis

O sistema deverá exigir justificativa para:

- cancelamentos
- ajustes de estoque
- perdas
- divergências financeiras

---

# Diretriz Principal do Projeto

## Todo o sistema deverá ser auditável.

Toda ação relevante deverá:

- possuir histórico
- possuir responsável
- possuir data/hora
- possuir rastreabilidade

O foco principal do sistema será garantir:

- segurança operacional
- transparência
- controle interno
- prevenção de fraudes
- prevenção de inconsistências financeiras e de estoque