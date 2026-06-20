# Google Tasks ↔ iCloud Reminders sync

Application Node.js/TypeScript qui synchronise les tâches entre Google Tasks et l'application Rappels iCloud selon les règles demandées.

## Règles de synchronisation

### Depuis iOS / Rappels vers Google Tasks

- Les rappels de la liste iOS `Live Session` sont ajoutés dans Google Tasks, liste `Laurent.janolin`, avec le préfixe `iOS` devant le titre.
- Les rappels de toutes les autres listes iOS sont ajoutés dans Google Tasks, liste `Tâches domestiques`.
- Pour conserver l'information de liste iOS d'origine, les tâches domestiques créées dans Google Tasks reçoivent le suffixe ` - Nom de liste`.

### Depuis Google Tasks vers iOS / Rappels

- Les tâches de la liste Google Tasks `Tâches domestiques` sont synchronisées vers Rappels.
- Les tâches de la liste Google Tasks `Laurent.janolin` ne sont synchronisées vers Rappels que si elles commencent par `iOS`.
- Exemple : `iOS prendre rdv chez le coiffeur - Maison`
  - titre créé dans Rappels : `prendre rdv chez le coiffeur`
  - liste Rappels cible : `Maison`
- Si aucune liste n'est indiquée après ` - `, la liste iCloud par défaut est utilisée.
- Si la liste demandée n'existe pas, l'application choisit la liste iCloud au nom le plus proche lorsque la distance est acceptable, sinon la liste par défaut.

### Anti-doublons

- Les rappels créés depuis Google Tasks reçoivent un marqueur `GOOGLE_TASK_ID`.
- Les tâches Google créées depuis Rappels reçoivent un marqueur `ICLOUD_REMINDER_UID`.

## Configuration

1. Créer un client OAuth Google Desktop et télécharger le fichier sous `credentials.json`.
2. Créer un mot de passe spécifique à l'app pour iCloud.
3. Installer les dépendances :

```bash
npm install
```

4. Exporter les variables d'environnement :

```bash
export ICLOUD_USERNAME="votre-identifiant-icloud@example.com"
export ICLOUD_APP_PASSWORD="xxxx-xxxx-xxxx-xxxx"
export ICLOUD_DEFAULT_REMINDER_LIST="Rappels"
```

Variables optionnelles :

| Variable | Défaut | Rôle |
| --- | --- | --- |
| `LIVE_SESSION_LIST_NAME` | `Live Session` | Liste Rappels iOS dont les tâches vont vers `Laurent.janolin` |
| `GOOGLE_PERSONAL_LIST_NAME` | `Laurent.janolin` | Liste Google Tasks personnelle |
| `GOOGLE_DOMESTIC_LIST_NAME` | `Tâches domestiques` | Liste Google Tasks domestique |
| `TASK_PREFIX` | `iOS` | Préfixe déclenchant l'envoi de `Laurent.janolin` vers Rappels |
| `FUZZY_LIST_MAX_DISTANCE` | `3` | Distance de Levenshtein maximale pour accepter une liste iOS proche |
| `GOOGLE_CREDENTIALS_PATH` | `credentials.json` | Chemin du client OAuth Google |
| `GOOGLE_TOKEN_PATH` | `token.json` | Cache OAuth local |
| `DRY_RUN` | `false` | Affiche les créations sans écrire dans Google Tasks ni iCloud |

## Utilisation

Premier lancement, pour autoriser Google Tasks :

```bash
npm run sync
```

Test sans écriture :

```bash
DRY_RUN=true npm run sync
```

Compilation :

```bash
npm run build
```

## Publication avec ChatGPT Sites

Le dossier `site/` contient une page statique prête à publier pour présenter l'application. Depuis l'interface ChatGPT Sites, importer le contenu de `site/index.html`, puis publier le site.
