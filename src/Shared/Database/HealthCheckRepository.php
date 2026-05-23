<?php

declare(strict_types=1);

namespace App\Shared\Database;

use PDO;

final class HealthCheckRepository
{
    public function __construct(
        private readonly PDO $conn,
    ) {
    }

    public function ping(): array|false
    {
        $sql = 'SELECT 1 AS ok';
        $query = $this->conn->query($sql);

        return $query->fetch();
    }

    public function bancoAtual(): array|false
    {
        $sql = 'SELECT DATABASE() AS nome';
        $query = $this->conn->query($sql);

        return $query->fetch();
    }
}
