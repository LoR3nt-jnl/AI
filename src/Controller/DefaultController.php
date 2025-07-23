<?php

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Annotation\Route;
use Symfony\Contracts\HttpClient\HttpClientInterface;

class DefaultController extends AbstractController
{
    #[Route('/', name: 'app_home')]
    public function index(HttpClientInterface $httpClient): Response
    {
        $response = $httpClient->request(
            'GET',
            'https://api.open-meteo.com/v1/forecast?latitude=45.1885&longitude=5.7245&current_weather=true'
        );

        $data = $response->toArray();
        $weather = $data['current_weather'] ?? [];

        $temp = $weather['temperature'] ?? 'N/A';
        $wind = $weather['windspeed'] ?? 'N/A';

        $html = sprintf(
            '<html><body><h1>Météo à Grenoble</h1><p>Température: %s °C</p><p>Vent: %s km/h</p></body></html>',
            $temp,
            $wind
        );

        return new Response($html);
    }
}
