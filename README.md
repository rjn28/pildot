# Pildot

**Votre batterie, en un point.**

Une application macOS discrète qui affiche la date et un indicateur coloré de batterie dans la barre des menus.

- Couleur progressive du rouge au vert selon la charge.
- Clignotement sous 15 %, uniquement lorsque le Mac est débranché.
- Niveau de charge et état de l’alimentation accessibles depuis le menu.
- Lancement à l’ouverture de session, activable dans **Réglages → Lancer au démarrage**.

Je partage le code de ce petit projet personnel pour celles et ceux que sa conception intéresse, qui souhaitent l’adapter ou le compiler pour leur propre usage.

Pildot est proposé ici sous forme de sources, avec ses ressources et ses scripts de compilation. Ce dépôt ne propose pas de version prête à installer ni de téléchargement `.app` ou `.dmg` : c’est un choix de partage du projet.

## Prérequis

- macOS 13 ou plus récent pour exécuter l’application.
- **Swift 6.0 ou plus récent**, fourni avec une version compatible de Xcode ou des Command Line Tools. Vérifier avec `swift --version`.
- Les scripts produisent un binaire pour l’architecture du Mac qui le compile (Apple Silicon ou Intel), pas un binaire universel.

## Compiler pour son propre usage

Pour essayer Pildot sur votre Mac, vous pouvez le compiler à partir des sources :

```bash
git clone https://github.com/rjn28/battery-bar-app.git
cd battery-bar-app
./script/build_app_bundle.sh release
```

Déplacer ensuite `Pildot.app` dans `/Applications`, puis l’ouvrir. Activer le lancement automatique seulement après ce déplacement : son enregistrement utilise le chemin de l’application.

L’application n’affiche pas de fenêtre principale ni d’icône dans le Dock. Cliquer sur son indicateur dans la barre des menus pour accéder aux réglages et la quitter.

## Passer de BatteryIconApp à Pildot

1. Dans BatteryIconApp, désactiver **Réglages → Lancer au démarrage**, puis quitter l’application.
2. Compiler Pildot et déplacer `Pildot.app` dans `/Applications`.
3. Ouvrir Pildot et réactiver le lancement automatique si souhaité.
4. Supprimer l’ancienne `BatteryIconApp.app` pour éviter de lancer les deux versions.

L’identifiant interne `com.rjn28.BatteryIconApp` et le nom du LaunchAgent sont conservés pour reconnaître l’enregistrement existant. La désactivation puis la réactivation mettent à jour le chemin vers `Pildot.app`.

## Développement et tests

```bash
swift build
swift test
./script/build_and_run.sh --verify
```

La dernière commande construit une version **Debug**, redémarre l’application et vérifie que son processus est présent. Elle nécessite une session graphique macOS. Les tests automatisés vérifient la palette, les états de batterie, le rendu et la gestion du lancement automatique avec un contrôleur simulé.

GitHub Actions exécute les tests et construit le bundle Release sur macOS à chaque push et pull request. Aucun binaire n’est publié par ce workflow.

## Optionnel : créer un installateur pour soi

```bash
./package.sh
```

Cette commande produit `Pildot.app` et `Pildot.dmg` à la racine, pour un usage local. Ces fichiers générés sont ignorés par Git et ne font pas partie du dépôt.

## Fonctionnement et données locales

L’application utilise AppKit et IOKit, sans dépendance externe. Elle lit l’état de la batterie toutes les 30 secondes. Le minuteur d’animation fonctionne uniquement en batterie critique. Elle n’utilise aucun service réseau ni outil d’analyse d’usage.

Le lancement automatique crée `~/Library/LaunchAgents/com.rjn28.BatteryIconApp.login.plist`. `launchctl` est appelé uniquement lors de l’activation ou de la désactivation du réglage.

## Désinstallation

1. Désactiver **Réglages → Lancer au démarrage** dans le menu de l’application.
2. Quitter Pildot depuis ce même menu.
3. Mettre `Pildot.app` à la corbeille.

Si l’application a déjà été supprimée, retirer son enregistrement résiduel avec :

```bash
launchctl bootout "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.rjn28.BatteryIconApp.login.plist"
rm -f "$HOME/Library/LaunchAgents/com.rjn28.BatteryIconApp.login.plist"
```

`bootout` peut signaler que le service n’est pas chargé s’il a déjà été désactivé.

## Contribuer

Les retours et les contributions sont les bienvenus. Pour signaler un problème, décrire les étapes de reproduction, la version de macOS et l’architecture du Mac dans une issue. Pour une pull request, limiter les changements au problème traité et exécuter `swift build` et `swift test` avant de la proposer.

## Licence

Le projet est distribué sous [licence MIT](LICENSE).
