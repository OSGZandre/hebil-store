<?php

declare(strict_types=1);

namespace App\Shared\Repository;

use PDO;

final class UsuarioLeituraRepository
{
    public function __construct(
        private readonly PDO $conn,
    ) {
    }

    public function buscarPorId(int $idUsuario): array|false
    {
        $sql = 'SELECT idUsuario, idLoja, nome, login, email, tipo, status
                FROM usuario
                WHERE idUsuario = :idUsuario
                LIMIT 1';

        $query = $this->conn->prepare($sql);
        $query->execute(['idUsuario' => $idUsuario]);

        return $query->fetch();
    }

    public function buscarLojaPorId(int $idLoja): array|false
    {
        $sql = 'SELECT idLoja, nome, documento, status
                FROM loja
                WHERE idLoja = :idLoja
                LIMIT 1';

        $query = $this->conn->prepare($sql);
        $query->execute(['idLoja' => $idLoja]);

        return $query->fetch();
    }
}
