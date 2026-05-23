<?php

declare(strict_types=1);

namespace App\Module\Caixa\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

#[Route('/caixa', name: 'caixa_')]
final class CaixaController extends AbstractController
{
    /**
     * No MVP a tela inicial do módulo de caixa é a abertura de sessão.
     * Quando houver fechamento/sangria/etc., novas rotas entrarão aqui.
     */
    #[Route('', name: 'index', methods: ['GET'])]
    public function index(): Response
    {
        return $this->render('module/caixa/caixa-abrir.html.twig');
    }
}
