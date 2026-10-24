# Imposteur - Application mobile

Application Flutter (Android et iOS) du jeu Imposteur, jouable en ligne même quand les joueurs ne sont
pas dans la même pièce. Le serveur se trouve dans le dépôt
[impostor-backend](https://github.com/GUIND0/impostor-backend).

## Fonctionnalités

- Profil avec nom et photo (caméra ou galerie), modifiable à tout moment
- Création d'une partie avec un code à partager, ou participation avec un code reçu
- Salle d'attente en temps réel, réglages de la partie par l'hôte, retrait d'un joueur
- Carte à retourner pour découvrir son mot en secret, avec un temps réglable par l'hôte
- Deux modes : mot similaire pour l'imposteur (il ne sait pas qu'il l'est) ou classique (aucun mot)
- Ordre de passage tiré au hasard, indices écrits ou vocaux (jusqu'à 30 secondes)
- Vote, dernière chance de l'imposteur, détail des votes et des points
- Classement général et historique des parties
- Reconnexion automatique en cas de coupure réseau

## Règles

Tous les joueurs reçoivent le même mot secret, sauf l'imposteur. En mode mot similaire, l'imposteur reçoit
un mot proche et ne sait pas qu'il est l'imposteur. En mode classique, il ne reçoit aucun mot. À tour de rôle, chacun donne un indice
sur le mot sans le dire. Ensuite, tout le monde vote pour désigner l'imposteur. Une fois les votes
révélés, l'imposteur peut tenter de deviner le mot (mode classique).

Les catégories et les mots se gèrent depuis l'administration web du serveur (`/admin`).

| Situation | Points |
| --- | --- |
| Imposteur démasqué | 1 point par joueur, 2 points pour ceux qui ont voté contre lui |
| Imposteur démasqué mais mot trouvé | 2 points pour l'imposteur |
| Imposteur non démasqué | 2 points pour l'imposteur, 3 s'il trouve le mot |

## Prérequis

- Flutter 3.41 ou plus récent
- Android Studio ou Xcode

## Lancement

```bash
flutter pub get
flutter run
```

L'application se connecte par défaut au serveur `http://151.80.60.71:3000`. Pour utiliser un autre serveur :

```bash
flutter run --dart-define=API_URL=http://192.168.1.10:3000
```

## Compilation

Android :

```bash
flutter build apk --release --dart-define=API_URL=https://votre-domaine
```

iOS :

```bash
flutter build ipa --release --dart-define=API_URL=https://votre-domaine
```

Le trafic HTTP non chiffré est autorisé pour pouvoir utiliser le serveur par son adresse IP. Une fois
le serveur placé derrière un nom de domaine en HTTPS, il est conseillé de retirer
`android:usesCleartextTraffic` dans `AndroidManifest.xml` et `NSAllowsArbitraryLoads` dans `Info.plist`.

## Structure

```
lib/
  config.dart              adresse du serveur
  theme.dart               couleurs et thème
  models/                  profil, partie, manche, indices
  services/api.dart        appels HTTP
  services/app_state.dart  état de l'application et connexion temps réel
  screens/                 profil, accueil, salle d'attente, classement, règles
  screens/game/            carte, indices, vote, devinette, résultats
  widgets/                 avatar, compte à rebours, lecteur et enregistreur vocal
```
