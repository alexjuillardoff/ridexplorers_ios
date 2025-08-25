# RideXplorers

Une application iOS développée avec SwiftUI pour explorer les parcs et les attractions.

## Description

RideXplorers est une application mobile iOS qui permet aux utilisateurs de découvrir et explorer différents parcs et attractions. L'application propose une interface utilisateur moderne avec une navigation par onglets.

## Fonctionnalités

L'application comprend quatre sections principales :

- **Parks** : Découverte et exploration des parcs
- **Ride** : Gestion des attractions et manèges
- **Stats** : Statistiques et analyses
- **Search** : Recherche dans l'application

## Architecture

L'application utilise SwiftUI et suit une architecture modulaire :

- `RideXplorersApp.swift` : Point d'entrée de l'application
- `ContentView.swift` : Vue principale qui gère la navigation
- `TabBarView.swift` : Navigation par onglets avec persistance de l'état
- `PageView.swift` : Composant réutilisable pour les pages avec en-tête
- `HeaderView.swift` : En-tête standard avec titre et bouton profil

## Structure du projet

```
RideXplorers/
├── RideXplorers/
│   ├── RideXplorersApp.swift
│   ├── ContentView.swift
│   ├── TabBarView.swift
│   ├── PageView.swift
│   ├── HeaderView.swift
│   ├── ParksView.swift
│   ├── RideView.swift
│   ├── StatsView.swift
│   ├── SearchView.swift
│   └── Assets.xcassets/
├── RideXplorersTests/
└── RideXplorersUITests/
```

## Technologies utilisées

- **SwiftUI** : Framework UI moderne d'Apple
- **iOS** : Plateforme cible
- **Xcode** : Environnement de développement

## Développement

Créé par Alexis JUILLARD le 24/08/2025.

## Installation

1. Clonez le dépôt
2. Ouvrez le projet dans Xcode
3. Compilez et exécutez sur un simulateur ou appareil iOS

## Tests

Le projet inclut des tests unitaires et des tests d'interface utilisateur dans les dossiers respectifs.
