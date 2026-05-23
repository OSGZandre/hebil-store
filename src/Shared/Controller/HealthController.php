<?php

declare(strict_types=1);

namespace App\Shared\Controller;

use App\Shared\Database\HealthCheckRepository;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;
use Throwable;

#[Route('/_dev/health', name: 'dev_health_')]
final class HealthController extends AbstractController
{
    public function __construct(
        private readonly HealthCheckRepository $healthCheckRepository,
    ) {
    }

    #[Route('/db', name: 'db', methods: ['GET'])]
    public function banco(): JsonResponse
    {
        if ($this->getParameter('kernel.environment') !== 'dev') {
            throw $this->createNotFoundException();
        }

        try {
            $ping = $this->healthCheckRepository->ping();
            $banco = $this->healthCheckRepository->bancoAtual();

            if ($ping === false || !isset($ping['ok']) || (int) $ping['ok'] !== 1) {
                return $this->json(
                    ['ok' => false, 'erro' => 'SELECT 1 não retornou resultado esperado.'],
                    Response::HTTP_SERVICE_UNAVAILABLE,
                );
            }

            return $this->json([
                'ok' => true,
                'database' => $banco['nome'] ?? null,
            ]);
        } catch (Throwable $excecao) {
            return $this->json(
                [
                    'ok' => false,
                    'erro' => $excecao->getMessage(),
                ],
                Response::HTTP_SERVICE_UNAVAILABLE,
            );
        }
    }
}
