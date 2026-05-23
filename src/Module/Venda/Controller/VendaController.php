<?php

declare(strict_types=1);

namespace App\Module\Venda\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

#[Route('/pdv', name: 'venda_')]
final class VendaController extends AbstractController
{
    #[Route('', name: 'index', methods: ['GET'])]
    public function index(): Response
    {
        return $this->render('module/venda/pdv-venda.html.twig');
    }
}
