<?php

declare(strict_types=1);

namespace App\Shared\Database;

use PDO;
use Throwable;

final class TransactionManager
{
    public function __construct(
        private readonly PDO $pdo,
    ) {
    }

    /**
     * @template T
     *
     * @param callable(): T $acao
     *
     * @return T
     */
    public function executarEmTransacao(callable $acao): mixed
    {
        $transacaoAtiva = $this->pdo->inTransaction();

        if (!$transacaoAtiva) {
            $this->pdo->beginTransaction();
        }

        try {
            $resultado = $acao();

            if (!$transacaoAtiva) {
                $this->pdo->commit();
            }

            return $resultado;
        } catch (Throwable $excecao) {
            if (!$transacaoAtiva && $this->pdo->inTransaction()) {
                $this->pdo->rollBack();
            }

            throw $excecao;
        }
    }
}
