<?php

declare(strict_types=1);

namespace App\Shared\Twig;

use App\Shared\Context\UsuarioContext;
use App\Shared\Repository\UsuarioLeituraRepository;
use PDOException;
use Twig\Extension\AbstractExtension;
use Twig\Extension\GlobalsInterface;

final class AppContextExtension extends AbstractExtension implements GlobalsInterface
{
    public function __construct(
        private readonly UsuarioContext $usuarioContext,
        private readonly UsuarioLeituraRepository $usuarioLeituraRepository,
    ) {
    }

    public function getGlobals(): array
    {
        return $this->montarNavbar(
            $this->usuarioContext->obterIdUsuario(),
            $this->usuarioContext->obterIdLoja(),
        );
    }

    private function montarNavbar(int $idUsuario, int $idLoja): array
    {
        try {
            $usuario = $this->usuarioLeituraRepository->buscarPorId($idUsuario);
            $loja = $this->usuarioLeituraRepository->buscarLojaPorId($idLoja);
        } catch (PDOException) {
            $usuario = false;
            $loja = false;
        }

        $nome = is_array($usuario) ? (string) $usuario['nome'] : 'Usuário dev #' . $idUsuario;
        $tipo = is_array($usuario) ? (string) $usuario['tipo'] : 'Funcionario';
        $nomeLoja = is_array($loja) ? (string) $loja['nome'] : 'Loja Matriz';

        return [
            'navbar_usuario' => $nome,
            'navbar_perfil' => $tipo === 'Administrador' ? 'Administrador' : 'Funcionário',
            'navbar_loja' => $nomeLoja,
        ];
    }
}
