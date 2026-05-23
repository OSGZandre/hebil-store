<?php

declare(strict_types=1);

namespace App\Module\Dashboard\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

#[Route('/dashboard', name: 'dashboard_')]
final class DashboardController extends AbstractController
{
    /**
     * Dashboard financeiro é a tela inicial do módulo.
     * Acesso ainda aberto enquanto Symfony Security não entra (Fase 10).
     */
    #[Route('', name: 'index', methods: ['GET'])]
    public function index(): Response
    {
        return $this->render('module/dashboard/dashboard-financeiro.html.twig');
    }
}
