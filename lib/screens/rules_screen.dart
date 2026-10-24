import 'package:flutter/material.dart';

import '../theme.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  static const _sections = [
    (
      'Le principe',
      'Tous les joueurs reçoivent le même mot secret, sauf un : l’imposteur. Il doit se fondre dans le groupe '
          'sans se faire repérer.',
    ),
    (
      'Mode mot similaire',
      'L’imposteur reçoit un mot proche de celui des autres (par exemple Piscine au lieu de Plage) '
          'et ne sait pas qu’il est l’imposteur. À chacun de deviner, en écoutant les indices, '
          's’il a le même mot que les autres.',
    ),
    (
      'Mode classique',
      'L’imposteur ne reçoit aucun mot : il sait qu’il est l’imposteur et voit seulement la catégorie '
          'si l’hôte l’a autorisé. Il pourra tenter de deviner le mot à la fin de la manche.',
    ),
    (
      'Le mot',
      'Au début de chaque manche, chacun touche sa carte pour découvrir son mot en secret, '
          'dans le temps choisi par l’hôte.',
    ),
    (
      'Les indices',
      'Un ordre de passage est tiré au hasard. À votre tour, donnez un indice en rapport avec le mot, '
          'par écrit ou en message vocal. Trop précis, vous aidez l’imposteur. Trop vague, vous devenez suspect.',
    ),
    (
      'Le vote',
      'Après les tours d’indices, chacun vote pour le joueur qu’il soupçonne. Le joueur qui reçoit le plus de voix est accusé. '
          'En cas d’égalité, personne n’est accusé.',
    ),
    (
      'La dernière chance',
      'En mode classique, une fois les votes révélés, l’imposteur peut tenter de deviner le mot secret.',
    ),
    (
      'Les points',
      'Imposteur démasqué : chaque joueur gagne 1 point, et 2 points s’il a voté contre l’imposteur.\n'
          'Imposteur démasqué mais mot trouvé : l’imposteur vole la manche et gagne 2 points.\n'
          'Imposteur non démasqué : il gagne 2 points, et 1 point bonus s’il trouve le mot.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Règles du jeu')),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _sections.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final (title, body) = _sections[i];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(body, style: const TextStyle(color: AppColors.muted, height: 1.45)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
