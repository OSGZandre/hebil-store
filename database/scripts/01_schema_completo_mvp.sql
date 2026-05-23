-- -----------------------------------------------------------------------------
-- Remover tabelas existentes (ordem inversa das dependências)
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS audit_log;
DROP TABLE IF EXISTS despesa;
DROP TABLE IF EXISTS movimento_caixa;
DROP TABLE IF EXISTS estoque_movimento;
DROP TABLE IF EXISTS venda_item;
DROP TABLE IF EXISTS venda;
DROP TABLE IF EXISTS venda_pagamento;
DROP TABLE IF EXISTS sessao_caixa;
DROP TABLE IF EXISTS admin_autorizacao;
DROP TABLE IF EXISTS produto;
DROP TABLE IF EXISTS caixa;
DROP TABLE IF EXISTS forma_pagamento;
DROP TABLE IF EXISTS categoria;
DROP TABLE IF EXISTS usuario;
DROP TABLE IF EXISTS loja;
DROP TABLE IF EXISTS schema_version;

SET FOREIGN_KEY_CHECKS = 1;

-- =============================================================================
-- TABELAS
-- =============================================================================

CREATE TABLE loja (
    idLoja BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    nome VARCHAR(150) NOT NULL,
    documento VARCHAR(20) NULL,
    status ENUM('Ativo','Inativo') NOT NULL DEFAULT 'Ativo',
    criado_em DATETIME NOT NULL,
    atualizado_em DATETIME NOT NULL,
    PRIMARY KEY (idLoja)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE usuario (
    idUsuario BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    idLoja BIGINT UNSIGNED NOT NULL,
    nome VARCHAR(150) NOT NULL,
    login VARCHAR(60) NOT NULL,
    email VARCHAR(180) NULL,
    senha_hash VARCHAR(255) NOT NULL,
    tipo ENUM('Funcionario','Administrador') NOT NULL,
    status ENUM('Ativo','Inativo') NOT NULL DEFAULT 'Ativo',
    ultimo_login_em DATETIME NULL,
    criado_em DATETIME NOT NULL,
    atualizado_em DATETIME NOT NULL,
    PRIMARY KEY (idUsuario),
    UNIQUE KEY uk_usuario_loja_login (idLoja, login),
    KEY idx_usuario_loja_status (idLoja, status),
    CONSTRAINT fk_usuario_loja FOREIGN KEY (idLoja) REFERENCES loja (idLoja)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE categoria (
    idCategoria BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    idLoja BIGINT UNSIGNED NOT NULL,
    nome VARCHAR(100) NOT NULL,
    status ENUM('Ativo','Inativo') NOT NULL DEFAULT 'Ativo',
    criado_em DATETIME NOT NULL,
    atualizado_em DATETIME NOT NULL,
    PRIMARY KEY (idCategoria),
    KEY idx_categoria_loja_status (idLoja, status),
    CONSTRAINT fk_categoria_loja FOREIGN KEY (idLoja) REFERENCES loja (idLoja)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE forma_pagamento (
    idFormaPagamento BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    idLoja BIGINT UNSIGNED NOT NULL,
    nome VARCHAR(60) NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    afeta_caixa_fisico TINYINT(1) NOT NULL DEFAULT 0,
    status ENUM('Ativo','Inativo') NOT NULL DEFAULT 'Ativo',
    ordem SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    criado_em DATETIME NOT NULL,
    PRIMARY KEY (idFormaPagamento),
    UNIQUE KEY uk_forma_loja_codigo (idLoja, codigo),
    CONSTRAINT fk_forma_loja FOREIGN KEY (idLoja) REFERENCES loja (idLoja)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE caixa (
    idCaixa BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    idLoja BIGINT UNSIGNED NOT NULL,
    nome VARCHAR(80) NOT NULL,
    identificador VARCHAR(50) NULL,
    status ENUM('Ativo','Inativo') NOT NULL DEFAULT 'Ativo',
    criado_em DATETIME NOT NULL,
    atualizado_em DATETIME NOT NULL,
    PRIMARY KEY (idCaixa),
    KEY idx_caixa_loja_status (idLoja, status),
    CONSTRAINT fk_caixa_loja FOREIGN KEY (idLoja) REFERENCES loja (idLoja)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE produto (
    idProduto BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    idLoja BIGINT UNSIGNED NOT NULL,
    idCategoria BIGINT UNSIGNED NULL,
    nome VARCHAR(200) NOT NULL,
    codigo_barras VARCHAR(32) NULL,
    sku VARCHAR(50) NULL,
    preco_venda DECIMAL(12,2) NOT NULL,
    preco_custo DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    estoque_atual DECIMAL(12,3) NOT NULL DEFAULT 0.000,
    estoque_minimo DECIMAL(12,3) NOT NULL DEFAULT 0.000,
    unidade VARCHAR(10) NOT NULL DEFAULT 'UN',
    status ENUM('Ativo','Inativo') NOT NULL DEFAULT 'Ativo',
    criado_em DATETIME NOT NULL,
    atualizado_em DATETIME NOT NULL,
    PRIMARY KEY (idProduto),
    UNIQUE KEY uk_produto_loja_barcode (idLoja, codigo_barras),
    KEY idx_produto_loja_status (idLoja, status),
    KEY idx_produto_loja_nome (idLoja, nome),
    CONSTRAINT fk_produto_loja FOREIGN KEY (idLoja) REFERENCES loja (idLoja),
    CONSTRAINT fk_produto_categoria FOREIGN KEY (idCategoria) REFERENCES categoria (idCategoria)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE admin_autorizacao (
    idAutorizacaoAdmin BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    idLoja BIGINT UNSIGNED NOT NULL,
    codigo_operacao VARCHAR(60) NOT NULL,
    entidade VARCHAR(60) NOT NULL,
    idEntidade BIGINT UNSIGNED NOT NULL,
    idUsuarioSolicitante BIGINT UNSIGNED NOT NULL,
    idUsuarioAutorizador BIGINT UNSIGNED NOT NULL,
    autorizado TINYINT(1) NOT NULL,
    motivo VARCHAR(500) NULL,
    ip VARCHAR(45) NULL,
    terminal VARCHAR(100) NULL,
    criado_em DATETIME NOT NULL,
    PRIMARY KEY (idAutorizacaoAdmin),
    KEY idx_auth_loja_criado (idLoja, criado_em),
    KEY idx_auth_entidade (entidade, idEntidade),
    CONSTRAINT fk_auth_loja FOREIGN KEY (idLoja) REFERENCES loja (idLoja),
    CONSTRAINT fk_auth_solicitante FOREIGN KEY (idUsuarioSolicitante) REFERENCES usuario (idUsuario),
    CONSTRAINT fk_auth_autorizador FOREIGN KEY (idUsuarioAutorizador) REFERENCES usuario (idUsuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE sessao_caixa (
    idSessaoCaixa BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    idLoja BIGINT UNSIGNED NOT NULL,
    idCaixa BIGINT UNSIGNED NOT NULL,
    idUsuario BIGINT UNSIGNED NOT NULL,
    situacao ENUM('Aberta','Fechada') NOT NULL DEFAULT 'Aberta',
    valor_abertura DECIMAL(12,2) NOT NULL,
    valor_fechamento_informado DECIMAL(12,2) NULL,
    valor_fechamento_sistema DECIMAL(12,2) NULL,
    divergencia DECIMAL(12,2) NULL,
    motivo_divergencia VARCHAR(500) NULL,
    aberta_em DATETIME NOT NULL,
    fechada_em DATETIME NULL,
    idUsuarioFechamento BIGINT UNSIGNED NULL,
    PRIMARY KEY (idSessaoCaixa),
    KEY idx_sessao_caixa_situacao (idCaixa, situacao),
    KEY idx_sessao_loja_aberta (idLoja, aberta_em),
    CONSTRAINT fk_sessao_loja FOREIGN KEY (idLoja) REFERENCES loja (idLoja),
    CONSTRAINT fk_sessao_caixa FOREIGN KEY (idCaixa) REFERENCES caixa (idCaixa),
    CONSTRAINT fk_sessao_usuario FOREIGN KEY (idUsuario) REFERENCES usuario (idUsuario),
    CONSTRAINT fk_sessao_usuario_fechamento FOREIGN KEY (idUsuarioFechamento) REFERENCES usuario (idUsuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE venda (
    idVenda BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    idLoja BIGINT UNSIGNED NOT NULL,
    numero INT UNSIGNED NOT NULL,
    idSessaoCaixa BIGINT UNSIGNED NOT NULL,
    idCaixa BIGINT UNSIGNED NOT NULL,
    idUsuario BIGINT UNSIGNED NOT NULL,
    situacao ENUM('Aberta','Finalizada','Cancelada') NOT NULL DEFAULT 'Aberta',
    subtotal DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    desconto_valor DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    desconto_percentual DECIMAL(5,2) NULL,
    valor_total DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    idFormaPagamento BIGINT UNSIGNED NULL,
    observacao VARCHAR(500) NULL,
    motivo_cancelamento VARCHAR(500) NULL,
    idUsuarioCancelamento BIGINT UNSIGNED NULL,
    idAutorizacaoAdminCancelamento BIGINT UNSIGNED NULL,
    finalizada_em DATETIME NULL,
    cancelada_em DATETIME NULL,
    criado_em DATETIME NOT NULL,
    atualizado_em DATETIME NOT NULL,
    PRIMARY KEY (idVenda),
    UNIQUE KEY uk_venda_loja_numero (idLoja, numero),
    KEY idx_venda_loja_situacao (idLoja, situacao, criado_em),
    KEY idx_venda_usuario_finalizada (idUsuario, finalizada_em),
    KEY idx_venda_sessao (idSessaoCaixa),
    CONSTRAINT fk_venda_loja FOREIGN KEY (idLoja) REFERENCES loja (idLoja),
    CONSTRAINT fk_venda_sessao FOREIGN KEY (idSessaoCaixa) REFERENCES sessao_caixa (idSessaoCaixa),
    CONSTRAINT fk_venda_caixa FOREIGN KEY (idCaixa) REFERENCES caixa (idCaixa),
    CONSTRAINT fk_venda_usuario FOREIGN KEY (idUsuario) REFERENCES usuario (idUsuario),
    CONSTRAINT fk_venda_forma FOREIGN KEY (idFormaPagamento) REFERENCES forma_pagamento (idFormaPagamento),
    CONSTRAINT fk_venda_usuario_cancelamento FOREIGN KEY (idUsuarioCancelamento) REFERENCES usuario (idUsuario),
    CONSTRAINT fk_venda_auth_cancel FOREIGN KEY (idAutorizacaoAdminCancelamento) REFERENCES admin_autorizacao (idAutorizacaoAdmin)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE venda_item (
    idVendaItem BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    idVenda BIGINT UNSIGNED NOT NULL,
    idProduto BIGINT UNSIGNED NOT NULL,
    ordem SMALLINT UNSIGNED NOT NULL,
    status ENUM('Ativo','Removido') NOT NULL DEFAULT 'Ativo',
    quantidade DECIMAL(12,3) NOT NULL,
    preco_unitario DECIMAL(12,2) NOT NULL,
    custo_unitario DECIMAL(12,2) NOT NULL,
    desconto_valor DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    subtotal DECIMAL(12,2) NOT NULL,
    total DECIMAL(12,2) NOT NULL,
    motivo_remocao VARCHAR(500) NULL,
    idUsuarioRemocao BIGINT UNSIGNED NULL,
    idAutorizacaoAdminRemocao BIGINT UNSIGNED NULL,
    removido_em DATETIME NULL,
    criado_em DATETIME NOT NULL,
    PRIMARY KEY (idVendaItem),
    KEY idx_venda_item_venda (idVenda, status),
    KEY idx_venda_item_produto (idProduto),
    CONSTRAINT fk_venda_item_venda FOREIGN KEY (idVenda) REFERENCES venda (idVenda),
    CONSTRAINT fk_venda_item_produto FOREIGN KEY (idProduto) REFERENCES produto (idProduto),
    CONSTRAINT fk_venda_item_usuario_remocao FOREIGN KEY (idUsuarioRemocao) REFERENCES usuario (idUsuario),
    CONSTRAINT fk_venda_item_auth FOREIGN KEY (idAutorizacaoAdminRemocao) REFERENCES admin_autorizacao (idAutorizacaoAdmin)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE estoque_movimento (
    idEstoqueMovimento BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    idLoja BIGINT UNSIGNED NOT NULL,
    idProduto BIGINT UNSIGNED NOT NULL,
    tipo ENUM('Entrada','SaidaVenda','Perda','Ajuste','EstornoVenda','EstornoAjuste') NOT NULL,
    quantidade DECIMAL(12,3) NOT NULL,
    saldo_apos DECIMAL(12,3) NOT NULL,
    custo_unitario DECIMAL(12,2) NULL,
    idVenda BIGINT UNSIGNED NULL,
    idVendaItem BIGINT UNSIGNED NULL,
    idUsuario BIGINT UNSIGNED NOT NULL,
    motivo VARCHAR(500) NULL,
    idAutorizacaoAdmin BIGINT UNSIGNED NULL,
    idReferenciaEstorno BIGINT UNSIGNED NULL,
    criado_em DATETIME NOT NULL,
    PRIMARY KEY (idEstoqueMovimento),
    KEY idx_estoque_produto (idProduto, criado_em),
    KEY idx_estoque_venda (idVenda),
    KEY idx_estoque_loja_criado (idLoja, criado_em),
    CONSTRAINT fk_estoque_loja FOREIGN KEY (idLoja) REFERENCES loja (idLoja),
    CONSTRAINT fk_estoque_produto FOREIGN KEY (idProduto) REFERENCES produto (idProduto),
    CONSTRAINT fk_estoque_venda FOREIGN KEY (idVenda) REFERENCES venda (idVenda),
    CONSTRAINT fk_estoque_venda_item FOREIGN KEY (idVendaItem) REFERENCES venda_item (idVendaItem),
    CONSTRAINT fk_estoque_usuario FOREIGN KEY (idUsuario) REFERENCES usuario (idUsuario),
    CONSTRAINT fk_estoque_auth FOREIGN KEY (idAutorizacaoAdmin) REFERENCES admin_autorizacao (idAutorizacaoAdmin),
    CONSTRAINT fk_estoque_ref_estorno FOREIGN KEY (idReferenciaEstorno) REFERENCES estoque_movimento (idEstoqueMovimento)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE movimento_caixa (
    idMovimentoCaixa BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    idLoja BIGINT UNSIGNED NOT NULL,
    idSessaoCaixa BIGINT UNSIGNED NOT NULL,
    tipo ENUM('Abertura','Venda','Sangria','Suprimento','AjusteEntrada','AjusteSaida','Fechamento','Estorno') NOT NULL,
    natureza ENUM('Entrada','Saida') NOT NULL,
    valor DECIMAL(12,2) NOT NULL,
    idVenda BIGINT UNSIGNED NULL,
    idFormaPagamento BIGINT UNSIGNED NULL,
    idUsuario BIGINT UNSIGNED NOT NULL,
    descricao VARCHAR(255) NULL,
    motivo VARCHAR(500) NULL,
    idReferenciaEstorno BIGINT UNSIGNED NULL,
    idAutorizacaoAdmin BIGINT UNSIGNED NULL,
    criado_em DATETIME NOT NULL,
    PRIMARY KEY (idMovimentoCaixa),
    KEY idx_mov_caixa_sessao (idSessaoCaixa, criado_em),
    KEY idx_mov_venda (idVenda),
    CONSTRAINT fk_mov_loja FOREIGN KEY (idLoja) REFERENCES loja (idLoja),
    CONSTRAINT fk_mov_sessao FOREIGN KEY (idSessaoCaixa) REFERENCES sessao_caixa (idSessaoCaixa),
    CONSTRAINT fk_mov_venda FOREIGN KEY (idVenda) REFERENCES venda (idVenda),
    CONSTRAINT fk_mov_forma FOREIGN KEY (idFormaPagamento) REFERENCES forma_pagamento (idFormaPagamento),
    CONSTRAINT fk_mov_usuario FOREIGN KEY (idUsuario) REFERENCES usuario (idUsuario),
    CONSTRAINT fk_mov_auth FOREIGN KEY (idAutorizacaoAdmin) REFERENCES admin_autorizacao (idAutorizacaoAdmin),
    CONSTRAINT fk_mov_ref_estorno FOREIGN KEY (idReferenciaEstorno) REFERENCES movimento_caixa (idMovimentoCaixa)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE despesa (
    idDespesa BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    idLoja BIGINT UNSIGNED NOT NULL,
    descricao VARCHAR(255) NOT NULL,
    valor DECIMAL(12,2) NOT NULL,
    data_competencia DATE NOT NULL,
    categoria_despesa VARCHAR(80) NULL,
    idUsuario BIGINT UNSIGNED NOT NULL,
    status ENUM('Ativo','Inativo') NOT NULL DEFAULT 'Ativo',
    criado_em DATETIME NOT NULL,
    atualizado_em DATETIME NOT NULL,
    PRIMARY KEY (idDespesa),
    KEY idx_despesa_loja_data (idLoja, data_competencia),
    CONSTRAINT fk_despesa_loja FOREIGN KEY (idLoja) REFERENCES loja (idLoja),
    CONSTRAINT fk_despesa_usuario FOREIGN KEY (idUsuario) REFERENCES usuario (idUsuario)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE audit_log (
    idAuditLog BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    idLoja BIGINT UNSIGNED NULL,
    idUsuario BIGINT UNSIGNED NULL,
    acao VARCHAR(80) NOT NULL,
    entidade VARCHAR(60) NULL,
    idEntidade BIGINT UNSIGNED NULL,
    valor_anterior JSON NULL,
    valor_atual JSON NULL,
    motivo VARCHAR(500) NULL,
    ip VARCHAR(45) NULL,
    terminal VARCHAR(100) NULL,
    idAutorizacaoAdmin BIGINT UNSIGNED NULL,
    criado_em DATETIME NOT NULL,
    PRIMARY KEY (idAuditLog),
    KEY idx_audit_loja_criado (idLoja, criado_em),
    KEY idx_audit_entidade (entidade, idEntidade),
    KEY idx_audit_usuario_criado (idUsuario, criado_em),
    CONSTRAINT fk_audit_loja FOREIGN KEY (idLoja) REFERENCES loja (idLoja),
    CONSTRAINT fk_audit_usuario FOREIGN KEY (idUsuario) REFERENCES usuario (idUsuario),
    CONSTRAINT fk_audit_auth FOREIGN KEY (idAutorizacaoAdmin) REFERENCES admin_autorizacao (idAutorizacaoAdmin)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE schema_version (
    versao VARCHAR(20) NOT NULL,
    descricao VARCHAR(255) NULL,
    aplicada_em DATETIME NOT NULL,
    PRIMARY KEY (versao)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================================================
-- DADOS INICIAIS (seed desenvolvimento)
-- =============================================================================

SET @agora = NOW();

INSERT INTO loja (idLoja, nome, documento, status, criado_em, atualizado_em)
VALUES (1, 'Hebil Store', NULL, 'Ativo', @agora, @agora);

-- Login: admin  |  Senha: admin123  (trocar em produção)
INSERT INTO usuario (
    idUsuario, idLoja, nome, login, email, senha_hash, tipo, status,
    ultimo_login_em, criado_em, atualizado_em
) VALUES (
    1, 1, 'Administrador', 'admin', 'admin@hebil.local',
    '$2y$12$NIi8OP1fE7g1kKDaQY0JDux05jiDts0770L4/7iYQDOkH9k2I5sEq',
    'Administrador', 'Ativo', NULL, @agora, @agora
);

INSERT INTO usuario (
    idUsuario, idLoja, nome, login, email, senha_hash, tipo, status,
    ultimo_login_em, criado_em, atualizado_em
) VALUES (
    2, 1, 'Funcionario Teste', 'funcionario', 'func@hebil.local',
    '$2y$12$NIi8OP1fE7g1kKDaQY0JDux05jiDts0770L4/7iYQDOkH9k2I5sEq',
    'Funcionario', 'Ativo', NULL, @agora, @agora
);

INSERT INTO categoria (idCategoria, idLoja, nome, status, criado_em, atualizado_em) VALUES
(1, 1, 'Geral', 'Ativo', @agora, @agora),
(2, 1, 'Bebidas', 'Ativo', @agora, @agora),
(3, 1, 'Limpeza', 'Ativo', @agora, @agora);

INSERT INTO forma_pagamento (idFormaPagamento, idLoja, nome, codigo, afeta_caixa_fisico, status, ordem, criado_em) VALUES
(1, 1, 'Dinheiro', 'dinheiro', 1, 'Ativo', 1, @agora),
(2, 1, 'PIX', 'pix', 0, 'Ativo', 2, @agora),
(3, 1, 'Cartão Débito', 'cartao_debito', 0, 'Ativo', 3, @agora),
(4, 1, 'Cartão Crédito', 'cartao_credito', 0, 'Ativo', 4, @agora);

INSERT INTO caixa (idCaixa, idLoja, nome, identificador, status, criado_em, atualizado_em) VALUES
(1, 1, 'Caixa 01', 'PDV-01', 'Ativo', @agora, @agora);

-- Produtos de exemplo
INSERT INTO produto (
    idProduto, idLoja, idCategoria, nome, codigo_barras, sku,
    preco_venda, preco_custo, estoque_atual, estoque_minimo, unidade,
    status, criado_em, atualizado_em
) VALUES
(1, 1, 1, 'Produto Exemplo A', '7891000000011', 'SKU-001', 10.00, 6.00, 100.000, 5.000, 'UN', 'Ativo', @agora, @agora),
(2, 1, 2, 'Refrigerante 2L', '7891000000028', 'SKU-002', 8.50, 5.00, 50.000, 10.000, 'UN', 'Ativo', @agora, @agora),
(3, 1, 3, 'Detergente 500ml', '7891000000035', 'SKU-003', 4.90, 2.80, 30.000, 5.000, 'UN', 'Ativo', @agora, @agora);

INSERT INTO schema_version (versao, descricao, aplicada_em)
VALUES ('V001', 'Schema MVP inicial + seed desenvolvimento', @agora);

-- =============================================================================
-- Fim — conferir tabelas
-- =============================================================================
SELECT 'Schema MVP aplicado com sucesso.' AS resultado;
SHOW TABLES;
