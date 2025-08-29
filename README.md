# RideXplorers iOS

Application iOS (SwiftUI) pour explorer les parcs, attractions et coasters dans le monde. L’onglet d’accueil affiche un carrousel de news et une liste de parcs à proximité.

## Aperçu des écrans

- Parks: carrousel de news + parcs à proximité (géolocalisation)
- Ride: placeholder pour fonctionnalités ride à venir
- Stats: placeholder pour statistiques
- Search: placeholder pour recherche

## Architecture

L’app suit MVVM avec une séparation claire des couches et de la logique métier.

- App: point d’entrée et injection d’environnements
- Features: vues par fonctionnalité (Parks, Ride, Stats, Search)
- Services: appels réseau, localisation, cache image, agrégation
- Models: modèles décodés depuis les APIs distantes
- UI: composants réutilisables (Page, Header, TabBar)
- Config: constantes centralisées (URLs, timings, UI)
- Extensions: utilitaires ciblés (ex. chunking, image helpers)

## Arborescence du projet

```
RideXplorers/
├── App/
│   ├── RideXplorersApp.swift
│   └── ContentView.swift
├── Config/
│   └── AppConfig.swift               # URLs d’API, timings, constantes UI
├── Extensions/
│   ├── Array+Chunk.swift
│   └── ImageExtensions.swift
├── Features/
│   ├── Parks/
│   │   ├── ParksView.swift
│   │   ├── NewsSliderView.swift
│   │   ├── NewsDetailView.swift
│   │   ├── NearbyParksViewModel.swift
│   │   └── NearbyParksListView.swift
│   ├── Ride/
│   │   └── RideView.swift
│   ├── Stats/
│   │   └── StatsView.swift
│   └── Search/
│       └── SearchView.swift
├── Models/
│   ├── NewsModels.swift
│   ├── ParkModels.swift
│   └── ThemeParksModels.swift
├── Services/
│   ├── NewsService.swift             # cache UserDefaults + auto-refresh
│   ├── ParksService.swift            # fusion Queue-Times + ThemeParks
│   ├── ThemeParksService.swift       # recherche images, matching fuzzy
│   ├── ImageCacheService.swift       # cache disque images (JPEG compressées)
│   └── LocationService.swift         # CoreLocation (WhenInUse)
├── UI/
│   ├── TabBarView.swift
│   ├── PageView.swift
│   └── HeaderView.swift
└── Assets.xcassets/
```

## Fonctionnalités clés

- Carrousel de news: auto-défilement, pagination, pull-to-refresh, fiche détaillée en sheet
- Parcs à proximité: autorisation WhenInUse, calcul distance, pagination avec peek (UICollectionViewCompositionalLayout) iOS 16+
- Agrégation de parcs: merge/dédoublonnage entre Queue-Times et ThemeParks, normalisation de noms + proximité géographique (~1km)
- Images de parcs: recherche via ThemeParks + RCDB, construction d’URLs absolues, cache disque JPEG (150×150, 0.75)
- Cache News: persistance UserDefaults, horodatage, auto-refresh (5 min)

## APIs consommées

Définies dans `RideXplorers/Config/AppConfig.swift`.

- News: `https://free.alexjuillard.fr:8000/blog/news`
- Parks (Queue-Times): `https://queue-times.com/parks.json`
- ThemeParks (liste): `https://free.alexjuillard.fr:8000/api/theme-parks`
- ThemeParks (search): `https://free.alexjuillard.fr:8000/api/theme-parks/search?q=...`
- RCDB (base URL pour images relatives): `https://rcdb.com`

## Données & modèles

- `NewsItem`: élément affiché dans le carrousel et la fiche (mapping de clés distantes: `id_news`, `main_news`, `ride`, `description`, `pictures`, etc.)
- `QueueTimesPark`/`QueueTimesParksGroup`: parcs Queue-Times (décodage tolérant des coordonnées)
- `ThemePark`/`ThemeParksListResponse`: modèles ThemeParks (coords en chaînes, mapping vers `QueueTimesPark`)

## Permissions & confidentialité

- Localisation: `NSLocationWhenInUseUsageDescription` configurée (texte: « Votre localisation est utilisée pour trouver les parcs à proximité. »)
- Réseau: appels sortants vers les domaines listés ci-dessus

## Qualité du code

- Lint: `.swiftlint.yml` (longueur de ligne 140/200, règles optionnelles activées)
- Format: `.swiftformat` (wrap args/collections, max width 140, imports nettoyés)

## Prérequis

- Xcode 15+ (Swift 5.7+ recommandé pour Concurrency)
- iOS 16+ (UIKIt pager avec peek disponible iOS 16+ ; fallback TabView sinon)
- Accès réseau et autorisation de localisation sur l’appareil/simulateur

## Démarrage rapide

1. Ouvrir `RideXplorers.xcodeproj`
2. Sélectionner le schéma `RideXplorers`
3. Choisir un simulateur iOS (ou appareil)
4. Lancer ▶︎ (Cmd+R)

En ligne de commande (facultatif):

```
xcodebuild -scheme RideXplorers -project RideXplorers.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 15' build
```

## Tests

- Unitaires: cible `RideXplorersTests` (Swift Testing)
- UI: cibles `RideXplorersUITests` et `RideXplorersUITestsLaunchTests` (XCTest UI)

Exécution (Xcode): Product → Test (Cmd+U)

CLI (exemple):

```
xcodebuild test -scheme RideXplorers -project RideXplorers.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Personnalisation

- Timings & UI: ajuster `AppConfig.UI` (hauteur des cartes, intervalle auto-slide)
- Intervalle d’auto-refresh des news: `AppConfig.News.refreshInterval`
- Endpoints: `AppConfig.Endpoints` (facile à rediriger vers d’autres environnements)

## Limitations actuelles / TODO

- Écrans Ride/Stats/Search en placeholders
- Gestion offline limitée (fallback minimal)
- Améliorer la pertinence de matching ThemeParks/RCDB si besoin
- Ajouter des tests unitaires ciblant les services (merge/dédupe parcs, cache news/images)

## Contribution

- Respecter SwiftFormat/SwiftLint (exécuter localement si installés via Homebrew)
- Garder les services purs/testables (protocols d’abstraction présents: `ParksProviding`, `LocationProviding`)
- Documenter toute modification d’API dans `AppConfig`

---

Ce README évoluera avec le code. Signale-moi ce que tu veux détailler (diagrammes, captures, scripts de tooling, CI, etc.) et je l’enrichis.
