<?php

declare(strict_types=1);

namespace App\Module\Produto\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

#[Route('/produtos', name: 'produto_')]
final class ProdutoController extends AbstractController
{
    #[Route('', name: 'index', methods: ['GET'])]
    public function index(): Response
    {
        return $this->render('module/produto/produto-listar.html.twig');
    }

    #[Route('/novo', name: 'novo', methods: ['GET'])]
    public function novo(): Response
    {
        return $this->render('module/produto/produto-form.html.twig');
    }
}
