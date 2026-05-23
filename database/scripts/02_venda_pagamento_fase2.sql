-- =============================================================================
-- Hebil Store — Fase 2: pagamento dividido (opcional)
-- Executar APÓS 01_schema_completo_mvp.sql
-- =============================================================================

USE loja_system;

CREATE TABLE IF NOT EXISTS venda_pagamento (
    idVendaPagamento BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    idVenda BIGINT UNSIGNED NOT NULL,
    idFormaPagamento BIGINT UNSIGNED NOT NULL,
    valor DECIMAL(12,2) NOT NULL,
    referencia_externa VARCHAR(100) NULL,
    criado_em DATETIME NOT NULL,
    PRIMARY KEY (idVendaPagamento),
    KEY idx_venda_pagamento_venda (idVenda),
    CONSTRAINT fk_vp_venda FOREIGN KEY (idVenda) REFERENCES venda (idVenda),
    CONSTRAINT fk_vp_forma FOREIGN KEY (idFormaPagamento) REFERENCES forma_pagamento (idFormaPagamento)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO schema_version (versao, descricao, aplicada_em)
VALUES ('V002', 'Pagamento dividido na venda', NOW())
ON DUPLICATE KEY UPDATE aplicada_em = NOW();

SELECT 'Tabela venda_pagamento criada (fase 2).' AS resultado;
