<?php

declare(strict_types=1);

namespace App\Shared\Database;

use PDO;

final class ConnectionFactory
{
    private ?PDO $pdo = null;

    public function __construct(
        private readonly string $databaseUrl,
    ) {
    }

    public function obterPdo(): PDO
    {
        if ($this->pdo === null) {
            $this->pdo = $this->criarConexao($this->databaseUrl);
        }

        return $this->pdo;
    }

    private function criarConexao(string $url): PDO
    {
        $partes = parse_url($url);

        if ($partes === false || !isset($partes['scheme'])) {
            throw new \InvalidArgumentException('DATABASE_URL inválida.');
        }

        $esquema = $partes['scheme'];

        if ($esquema !== 'mysql') {
            throw new \InvalidArgumentException(sprintf('Esquema "%s" não suportado. Use mysql.', $esquema));
        }

        $host = $partes['host'] ?? '127.0.0.1';
        $porta = $partes['port'] ?? 3306;
        $banco = isset($partes['path']) ? ltrim($partes['path'], '/') : '';
        $usuario = isset($partes['user']) ? urldecode($partes['user']) : '';
        $senha = isset($partes['pass']) ? urldecode($partes['pass']) : '';

        parse_str($partes['query'] ?? '', $query);
        $charset = $query['charset'] ?? 'utf8mb4';

        $dsn = sprintf(
            'mysql:host=%s;port=%d;dbname=%s;charset=%s',
            $host,
            (int) $porta,
            $banco,
            $charset,
        );

        $pdo = new PDO($dsn, $usuario, $senha, [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
        ]);

        return $pdo;
    }
}
