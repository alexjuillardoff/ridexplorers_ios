# RideXplorers iOS App

Application iOS pour explorer les parcs, ride & coasters du monde entiers.

## Architecture

L'application suit une architecture MVVM (Model-View-ViewModel) avec une séparation claire des responsabilités et une organisation modulaire.

## Structure du Projet

```
RideXplorers/
├── App/                           # Point d'entrée de l'application
│   ├── RideXplorersApp.swift     # Configuration principale de l'app
│   └── ContentView.swift         # Vue racine de l'application
├── Features/                      # Fonctionnalités de l'application
│   ├── Parks/                    # Module des parcs
│   │   ├── ParksView.swift       # Vue principale des parcs
│   │   └── NewsSliderView.swift  # Carrousel des actualités
│   ├── Ride/                     # Module des ride
│   │   └── RideView.swift        # Vue des ride
│   ├── Stats/                    # Module des statistiques
│   │   └── StatsView.swift       # Vue des statistiques
│   └── Search/                   # Module de recherche
│       └── SearchView.swift      # Vue de recherche
├── Models/                        # Modèles de données
│   └── NewsModels.swift          # Modèles pour les actualités
├── Services/                      # Couche de services
│   └── NewsService.swift         # Service pour récupérer les actualités
├── UI/                           # Composants d'interface réutilisables
│   ├── TabBarView.swift          # Barre de navigation par onglets
│   ├── PageView.swift            # Layout de page avec en-tête
│   └── HeaderView.swift          # Composant d'en-tête
├── Shared/                       # Ressources partagées
└── Assets.xcassets/              # Ressources graphiques
```

## Organisation des Couches

### App Layer
- **RideXplorersApp.swift** : Point d'entrée principal de l'application
- **ContentView.swift** : Vue racine qui orchestre la navigation

### Features Layer
Chaque fonctionnalité est organisée dans son propre module :
- **Parks** : Affichage des parks
- **Ride** : Affichage des rides
- **Stats** : Affichage des statistiques
- **Search** : Fonctionnalité de recherche

### Models Layer
- **NewsModels.swift** : Définition des structures de données pour les actualités

### Services Layer
- **NewsService.swift** : Service pour récupérer les données des actualités depuis l'API

### UI Layer
- **TabBarView.swift** : Navigation principale par onglets
- **PageView.swift** : Layout réutilisable pour les pages
- **HeaderView.swift** : En-tête standardisé des pages

## Principes d'Architecture

1. **Séparation des Responsabilités** : Chaque composant a une responsabilité unique et bien définie
2. **Modularité** : Les fonctionnalités sont organisées en modules indépendants
3. **Réutilisabilité** : Les composants UI sont conçus pour être réutilisés
4. **Testabilité** : L'architecture facilite l'écriture de tests unitaires
5. **Maintenabilité** : Code organisé et facile à maintenir

## Technologies Utilisées

- **SwiftUI** : Framework moderne d'interface utilisateur
- **Swift Concurrency** : Gestion asynchrone des données
- **MVVM Pattern** : Architecture de présentation
- **URLSession** : Gestion des appels réseau

## Démarrage Rapide

1. Ouvrir le projet dans Xcode
2. Sélectionner un simulateur iOS
3. Compiler et exécuter l'application

## Structure des Données

L'application utilise une API REST pour récupérer les actualités des parcs. Les données sont structurées selon le modèle `NewsItem`.