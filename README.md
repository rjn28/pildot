# BatteryIconApp

Une app macOS extrêmement légère qui affiche dans la barre des menus :

- le jour et la date sur une ligne compacte ;
- un point dont la couleur suit le niveau de batterie ;
- un clignotement discret sous 15 %, uniquement lorsque le Mac est débranché.

L’esthétique originale est conservée. La palette a été corrigée pour que la zone critique soit réellement rouge, puis évolue progressivement vers l’orange, le jaune et le vert.

## Légèreté

L’application utilise uniquement AppKit et IOKit, sans dépendance externe. Elle lit directement l’état de la batterie toutes les 30 secondes, sans lancer de sous-processus. Le minuteur d’animation n’est actif qu’en batterie critique.

## Développement

Prérequis : macOS 13 ou plus récent et Xcode Command Line Tools.

```bash
swift test
./script/build_and_run.sh --verify
```

L’application Release générée se trouve directement à la racine : `BatteryIconApp.app`.

## Créer l’installateur

```bash
./package.sh
```

Cette commande produit `BatteryIconApp.app` et `BatteryIconApp.dmg` à la racine du projet, pour un usage local. Aucune identité de signature ni notarisation n’est utilisée ; sur Apple Silicon, seul le marqueur ad hoc ajouté automatiquement par le compilateur est conservé pour permettre à macOS de lancer le binaire.
