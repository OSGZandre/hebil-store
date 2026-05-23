<?php

declare(strict_types=1);

namespace App\Shared\Context;

/**
 * Em dev, substitui o usuário logado até a Fase 10 (Symfony Security).
 * Só guarda idUsuario e idLoja vindos do .env — sem regra de negócio aqui.
 */
final class UsuarioContext
{
    public function __construct(
        private readonly int $idUsuario,
        private readonly int $idLoja,
    ) {
    }

    public function obterIdUsuario(): int
    {
        return $this->idUsuario;
    }

    public function obterIdLoja(): int
    {
        return $this->idLoja;
    }
}
